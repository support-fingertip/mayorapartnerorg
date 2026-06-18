/**
 * @description Reads active Notification_Setting__c records and sends notifications
 *              for a record + event across the enabled channels (In-App/Push, Email,
 *              SMS, WhatsApp). Fully dynamic: behaviour is driven by configuration data.
 *              Also exposes a direct notify() helper used by the Dynamic Approval Engine.
 */
public with sharing class NotificationDispatchService {

    private static final Pattern TOKEN = Pattern.compile('\\{!([A-Za-z0-9_\\.]+)\\}');
    private static final String NOTIF_TYPE_DEV_NAME = 'FSCRM_Notification';

    // ---------- Event-driven entry points ----------

    /** Apex: NotificationDispatchService.dispatch(recordId, 'Approved'); */
    public static void dispatch(Id recordId, String eventType) {
        if (recordId != null && String.isNotBlank(eventType)) {
            dispatch(new Map<Id, String>{ recordId => eventType });
        }
    }

    /** Bulk-safe Apex entry point. */
    public static void dispatch(Map<Id, String> recordIdToEvent) {
        if (recordIdToEvent == null || recordIdToEvent.isEmpty()) return;
        for (Id recId : recordIdToEvent.keySet()) {
            processOne(recId, recordIdToEvent.get(recId));
        }
    }

    /** Flow / Record-Triggered Flow entry point. */
    @InvocableMethod(label='Send Dynamic Notification'
        description='Sends notifications defined in Notification Setting records for a record + event.')
    public static void dispatchFromFlow(List<Request> requests) {
        Map<Id, String> m = new Map<Id, String>();
        for (Request r : requests) {
            if (r.recordId != null && String.isNotBlank(r.eventType)) {
                m.put(r.recordId, r.eventType);
            }
        }
        dispatch(m);
    }

    public class Request {
        @InvocableVariable(required=true label='Record Id') public Id recordId;
        @InvocableVariable(required=true label='Event Type') public String eventType;
    }

    // ---------- Direct send (used by the approval engine) ----------

    /**
     * @description Sends a one-off In-App + Email notification to specific users.
     */
    public static void notify(Set<Id> userIds, Id targetId, String subject, String body) {
        if (userIds == null || userIds.isEmpty()) return;
        sendInApp(userIds, targetId, subject, body);
        sendEmail(userIds, subject, body);
    }

    // ---------- Core ----------

    private static void processOne(Id recordId, String eventType) {
        String objApi = recordId.getSObjectType().getDescribe().getName();

        List<Notification_Setting__c> settings = [
            SELECT Id, Name, Event_Object__c, Event_Type__c,
                   Channel_Email__c, Channel_SMS__c, Channel_WhatsApp__c, Channel_InApp__c,
                   Recipient_Type__c, Recipient_User__c, Recipient_Reference__c,
                   Subject_Template__c, Body_Template__c
            FROM Notification_Setting__c
            WHERE Is_Active__c = true
              AND Event_Object__c = :objApi
              AND Event_Type__c = :eventType
        ];
        if (settings.isEmpty()) return;

        Set<String> tokens = new Set<String>();
        for (Notification_Setting__c s : settings) {
            collectTokens(s.Subject_Template__c, tokens);
            collectTokens(s.Body_Template__c, tokens);
        }

        SObject record = loadRecord(objApi, recordId, tokens);
        if (record == null) return;

        for (Notification_Setting__c s : settings) {
            Set<Id> userIds = resolveRecipients(s, record);
            if (userIds.isEmpty()) continue;

            String subject = mergeTemplate(s.Subject_Template__c, record);
            String body    = mergeTemplate(s.Body_Template__c, record);

            if (s.Channel_InApp__c)    sendInApp(userIds, recordId, subject, body);
            if (s.Channel_Email__c)    sendEmail(userIds, subject, body);
            if (s.Channel_SMS__c)      sendSms(userIds, body);
            if (s.Channel_WhatsApp__c) sendWhatsApp(userIds, body);
        }
    }

    // ---------- Recipient resolution ----------

    private static Set<Id> resolveRecipients(Notification_Setting__c s, SObject record) {
        Set<Id> ids = new Set<Id>();
        String type = s.Recipient_Type__c;
        String ref  = s.Recipient_Reference__c;
        Id ownerId  = (Id) record.get('OwnerId');

        if (type == 'Specific User') {
            if (s.Recipient_User__c != null) ids.add(s.Recipient_User__c);

        } else if (type == 'Record Owner') {
            if (isUser(ownerId)) ids.add(ownerId);

        } else if (type == 'Owners Manager') {
            if (isUser(ownerId)) {
                for (User u : [SELECT ManagerId FROM User WHERE Id = :ownerId AND ManagerId != null]) {
                    ids.add(u.ManagerId);
                }
            }
        } else if (type == 'Role' && String.isNotBlank(ref)) {
            for (User u : [SELECT Id FROM User WHERE IsActive = true AND UserRole.DeveloperName = :ref]) {
                ids.add(u.Id);
            }
        } else if (type == 'Profile' && String.isNotBlank(ref)) {
            for (User u : [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = :ref]) {
                ids.add(u.Id);
            }
        } else if (type == 'Public Group' && String.isNotBlank(ref)) {
            for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :ref]) {
                if (isUser(gm.UserOrGroupId)) ids.add(gm.UserOrGroupId);
            }
        }
        return ids;
    }

    private static Boolean isUser(Id recId) {
        return recId != null && recId.getSObjectType() == User.SObjectType;
    }

    // ---------- Channels ----------

    private static void sendInApp(Set<Id> userIds, Id targetId, String subject, String body) {
        try {
            CustomNotificationType nt = getNotificationType();
            if (nt == null) return;
            Messaging.CustomNotification n = new Messaging.CustomNotification();
            n.setTitle(String.isBlank(subject) ? 'Notification' : subject.left(250));
            n.setBody(String.isBlank(body) ? (subject == null ? '' : subject) : body.left(750));
            n.setNotificationTypeId(nt.Id);
            if (targetId != null) n.setTargetId(targetId);
            Set<String> recipients = new Set<String>();
            for (Id uid : userIds) recipients.add(String.valueOf(uid));
            n.send(recipients);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'In-App notification failed: ' + e.getMessage());
        }
    }

    private static void sendEmail(Set<Id> userIds, String subject, String body) {
        List<String> emails = new List<String>();
        for (User u : [SELECT Email FROM User WHERE Id IN :userIds AND IsActive = true AND Email != null]) {
            emails.add(u.Email);
        }
        if (emails.isEmpty()) return;
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(emails);
        msg.setSubject(String.isBlank(subject) ? 'Notification' : subject);
        msg.setHtmlBody(body == null ? '' : body);
        msg.setSaveAsActivity(false);
        try {
            if (!Test.isRunningTest()) {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ msg });
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Email send failed: ' + e.getMessage());
        }
    }

    // ---- Extension hooks: wire your gateway (Named Credential) here.
    //      Callouts must run async (@future/Queueable) if invoked after DML. ----
    private static void sendSms(Set<Id> userIds, String body) {
        System.debug('SMS requested for ' + userIds.size() + ' user(s): ' + body);
    }
    private static void sendWhatsApp(Set<Id> userIds, String body) {
        System.debug('WhatsApp requested for ' + userIds.size() + ' user(s): ' + body);
    }

    // ---------- Helpers ----------

    private static CustomNotificationType cachedType;
    private static Boolean typeLoaded = false;
    private static CustomNotificationType getNotificationType() {
        if (!typeLoaded) {
            typeLoaded = true;
            List<CustomNotificationType> l = [
                SELECT Id FROM CustomNotificationType
                WHERE DeveloperName = :NOTIF_TYPE_DEV_NAME LIMIT 1
            ];
            cachedType = l.isEmpty() ? null : l[0];
        }
        return cachedType;
    }

    private static void collectTokens(String template, Set<String> acc) {
        if (String.isBlank(template)) return;
        Matcher m = TOKEN.matcher(template);
        while (m.find()) acc.add(m.group(1));
    }

    private static SObject loadRecord(String objApi, Id recordId, Set<String> tokens) {
        Map<String, Schema.SObjectField> fmap =
            Schema.getGlobalDescribe().get(objApi).getDescribe().fields.getMap();
        Set<String> fields = new Set<String>{ 'Id', 'OwnerId' };
        if (fmap.containsKey('name')) fields.add('Name');
        for (String tk : tokens) {
            if (!tk.contains('.') && fmap.containsKey(tk.toLowerCase())) fields.add(tk);
        }
        String q = 'SELECT ' + String.join(new List<String>(fields), ',')
                 + ' FROM ' + objApi + ' WHERE Id = :recordId LIMIT 1';
        List<SObject> recs = Database.query(q);
        return recs.isEmpty() ? null : recs[0];
    }

    private static String mergeTemplate(String template, SObject record) {
        if (String.isBlank(template)) return template == null ? '' : template;
        String result = template;
        Set<String> done = new Set<String>();
        Matcher m = TOKEN.matcher(template);
        while (m.find()) {
            String field = m.group(1);
            if (done.contains(field)) continue;
            done.add(field);
            Object val;
            try { val = record.get(field); } catch (Exception e) { val = null; }
            result = result.replace('{!' + field + '}', val == null ? '' : String.valueOf(val));
        }
        return result;
    }
}