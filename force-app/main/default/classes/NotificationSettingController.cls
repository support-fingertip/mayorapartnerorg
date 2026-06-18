/**
 * @description Backs the Notification Settings admin tab. CRUD + picklist
 * metadata for the configurable notification rule list.
 *
 * Phase 1: configuration UI only — does not actually fire notifications.
 * The dispatcher that reads these rows and sends Email / In-app / WhatsApp /
 * SMS lives in a follow-up class (NotificationDispatcher).
 */
public with sharing class NotificationSettingController {

    @AuraEnabled(cacheable=true)
    public static List<Notification_Setting__c> getAllSettings() {
        return [
            SELECT Id, Name,
                   Event_Object__c, Event_Type__c,
                   Recipient_Type__c, Recipient_User__c, Recipient_User__r.Name,
                   Recipient_Reference__c,
                   Channel_Email__c, Channel_InApp__c, Channel_WhatsApp__c, Channel_SMS__c,
                   Subject_Template__c, Body_Template__c,
                   Is_Active__c, Description__c,
                   LastModifiedDate
            FROM Notification_Setting__c
            ORDER BY Event_Object__c, Event_Type__c, CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static Notification_Setting__c saveSetting(Notification_Setting__c setting) {
        if (setting == null) {
            throw new AuraHandledException('Setting is required.');
        }
        upsert setting;
        return [
            SELECT Id, Name,
                   Event_Object__c, Event_Type__c,
                   Recipient_Type__c, Recipient_User__c, Recipient_User__r.Name,
                   Recipient_Reference__c,
                   Channel_Email__c, Channel_InApp__c, Channel_WhatsApp__c, Channel_SMS__c,
                   Subject_Template__c, Body_Template__c,
                   Is_Active__c, Description__c,
                   LastModifiedDate
            FROM Notification_Setting__c
            WHERE Id = :setting.Id
        ];
    }

    @AuraEnabled
    public static void deleteSetting(Id settingId) {
        if (settingId == null) return;
        delete new Notification_Setting__c(Id = settingId);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getPicklistOptions() {
        Map<String, List<Map<String, String>>> result = new Map<String, List<Map<String, String>>>();
        result.put('Event_Object__c', describePicklist('Event_Object__c'));
        result.put('Event_Type__c', describePicklist('Event_Type__c'));
        result.put('Recipient_Type__c', describePicklist('Recipient_Type__c'));
        return result;
    }

    private static List<Map<String, String>> describePicklist(String fieldName) {
        List<Map<String, String>> values = new List<Map<String, String>>();
        Schema.DescribeFieldResult f = Notification_Setting__c.SObjectType
            .getDescribe().fields.getMap().get(fieldName).getDescribe();
        for (Schema.PicklistEntry e : f.getPicklistValues()) {
            if (e.isActive()) {
                values.add(new Map<String, String>{
                    'label' => e.getLabel(),
                    'value' => e.getValue()
                });
            }
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchUsers(String searchTerm) {
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            return new List<Map<String, String>>();
        }
        String pattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        List<User> users = [
            SELECT Id, Name, Email, Username
            FROM User
            WHERE IsActive = true
              AND (Name LIKE :pattern OR Email LIKE :pattern OR Username LIKE :pattern)
            ORDER BY Name
            LIMIT 20
        ];
        List<Map<String, String>> result = new List<Map<String, String>>();
        for (User u : users) {
            result.add(new Map<String, String>{
                'value' => u.Id,
                'label' => u.Name,
                'subtitle' => u.Email
            });
        }
        return result;
    }
}