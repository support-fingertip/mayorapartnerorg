/**
 * @description Data-driven approval engine. Reads Approval_Rule__c rules at
 *              runtime to route any record through multi-level approval, fully
 *              configurable from the Configuration Console tab (no Setup metadata).
 *
 *              Lifecycle: submit -> Approval_Request__c + Approval_Step__c per level
 *              -> approvers act via the My Approvals tab -> source record is stamped
 *              and notifications fire through NotificationDispatchService.
 */
public with sharing class DynamicApprovalEngine {

    public class ApprovalException extends Exception {}

    // ============================================================== Submit

    public class SubmitRequest {
        @InvocableVariable(required=true label='Record Id') public Id recordId;
    }

    @InvocableMethod(label='Submit For Dynamic Approval'
        description='Routes a record for approval using the Approval Matrix.')
    public static void submitForApprovalFlow(List<SubmitRequest> requests) {
        for (SubmitRequest r : requests) {
            if (r.recordId != null) {
                submit(r.recordId, UserInfo.getUserId());
            }
        }
    }

    @AuraEnabled
    public static Id submitForApproval(Id recordId) {
        try {
            return submit(recordId, UserInfo.getUserId());
        } catch (ApprovalException ae) {
            throw new AuraHandledException(ae.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Id submit(Id recordId, Id submittedBy) {
        if (recordId == null) {
            throw new ApprovalException('No record was provided to submit.');
        }
        String objApi = recordId.getSObjectType().getDescribe().getName();

        List<Approval_Rule__c> rules = [
            SELECT Id, Object_Process__c, Approval_Level__c, Approver_Type__c, Approver_Role_Queue__c,
                   User__c, Condition_Field__c, Min_Value__c, Max_Value__c,
                   Auto_Approve__c, Status_Field_API_Name__c, Status_Value_On_Submit__c,
                   Status_Value_On_Approve__c, Status_Value_On_Reject__c
            FROM Approval_Rule__c
            WHERE Is_Active__c = true AND Object_Process__c = :objApi
            ORDER BY Approval_Level__c ASC NULLS FIRST
        ];
        if (rules.isEmpty()) {
            throw new ApprovalException('No active approval rules are configured for ' + objApi + '.');
        }

        // Block duplicate pending requests for the same record.
        List<Approval_Request__c> open = [
            SELECT Id FROM Approval_Request__c
            WHERE Record_Id__c = :String.valueOf(recordId) AND Status__c = 'Pending' LIMIT 1
        ];
        if (!open.isEmpty()) {
            throw new ApprovalException('This record is already pending approval.');
        }

        // Read the condition field (first rule that defines one).
        String conditionField = null;
        for (Approval_Rule__c r : rules) {
            if (String.isNotBlank(r.Condition_Field__c)) { conditionField = r.Condition_Field__c; break; }
        }
        SObject record = loadRecord(objApi, recordId, conditionField);
        Decimal conditionValue = toDecimal(safeGet(record, conditionField));

        // Choose the applicable rule per level (first matching band wins).
        Map<Decimal, Approval_Rule__c> ruleByLevel = new Map<Decimal, Approval_Rule__c>();
        List<Decimal> levels = new List<Decimal>();
        for (Approval_Rule__c r : rules) {
            if (!matchesBand(r, conditionValue)) continue;
            Decimal lvl = (r.Approval_Level__c == null) ? 1 : r.Approval_Level__c;
            if (!ruleByLevel.containsKey(lvl)) {
                ruleByLevel.put(lvl, r);
                levels.add(lvl);
            }
        }
        if (levels.isEmpty()) {
            throw new ApprovalException('No approval rule matches this record\'s values.');
        }
        levels.sort();

        Approval_Rule__c firstRule = ruleByLevel.get(levels[0]);

        Approval_Request__c req = new Approval_Request__c(
            Record_Id__c       = String.valueOf(recordId),
            Record_Name__c     = (String) safeGet(record, 'Name'),
            Object_Type__c     = objApi,
            Status__c          = 'Pending',
            Current_Level__c   = levels[0],
            Total_Levels__c    = levels.size(),
            Submitted_By__c    = submittedBy,
            Submitted_Date__c  = System.now(),
            Condition_Value__c = conditionValue,
            Status_Field_API_Name__c = firstRule.Status_Field_API_Name__c,
            Status_Value_On_Approve__c = firstRule.Status_Value_On_Approve__c,
            Status_Value_On_Reject__c  = firstRule.Status_Value_On_Reject__c
        );
        insert req;

        List<Approval_Step__c> steps = new List<Approval_Step__c>();
        for (Decimal lvl : levels) {
            Approval_Rule__c r = ruleByLevel.get(lvl);
            steps.add(new Approval_Step__c(
                Approval_Request__c   = req.Id,
                Level__c              = lvl,
                Approver__c           = resolveApprover(r, submittedBy),
                Approver_Type__c      = r.Approver_Type__c,
                Approver_Reference__c = r.Approver_Role_Queue__c,
                Auto_Approve__c       = (r.Auto_Approve__c == true),
                Status__c             = 'Pending',
                Is_Current__c         = false
            ));
        }
        insert steps;

        // Stamp the source record as submitted (if configured).
        stampSource(recordId, objApi, firstRule.Status_Field_API_Name__c, firstRule.Status_Value_On_Submit__c);

        // Fire configured "Submitted" notifications.
        safeDispatch(recordId, 'Submitted');

        // Activate the chain (auto-approving levels as needed).
        processCurrent(req.Id);

        return req.Id;
    }

    // ============================================================== Decisions

    @AuraEnabled
    public static void approve(Id stepId, String comments) {
        decide(stepId, comments, true);
    }

    @AuraEnabled
    public static void reject(Id stepId, String comments) {
        decide(stepId, comments, false);
    }

    private static void decide(Id stepId, String comments, Boolean approved) {
        try {
            Approval_Step__c step = [
                SELECT Id, Status__c, Is_Current__c, Approver__c, Approval_Request__c
                FROM Approval_Step__c WHERE Id = :stepId
            ];
            if (step.Status__c != 'Pending' || step.Is_Current__c != true) {
                throw new ApprovalException('This step is not awaiting a decision.');
            }
            if (step.Approver__c != UserInfo.getUserId() && !isAdmin()) {
                throw new ApprovalException('You are not the assigned approver for this step.');
            }

            step.Status__c       = approved ? 'Approved' : 'Rejected';
            step.Decision_Date__c = System.now();
            step.Comments__c      = comments;
            step.Is_Current__c    = false;
            update step;

            if (approved) {
                processCurrent(step.Approval_Request__c);
            } else {
                Approval_Request__c req = [
                    SELECT Id, Status__c, Record_Id__c, Object_Type__c,
                           Status_Field_API_Name__c, Status_Value_On_Reject__c
                    FROM Approval_Request__c WHERE Id = :step.Approval_Request__c
                ];
                req.Status__c         = 'Rejected';
                req.Completed_Date__c = System.now();
                req.Current_Approver__c = null;
                req.Comments__c       = comments;
                update req;
                stampSource((Id) req.Record_Id__c, req.Object_Type__c,
                            req.Status_Field_API_Name__c, req.Status_Value_On_Reject__c);
                safeDispatch((Id) req.Record_Id__c, 'Rejected');
            }
        } catch (ApprovalException ae) {
            throw new AuraHandledException(ae.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void recall(Id requestId) {
        try {
            Approval_Request__c req = [
                SELECT Id, Status__c, Submitted_By__c FROM Approval_Request__c WHERE Id = :requestId
            ];
            if (req.Status__c != 'Pending') {
                throw new ApprovalException('Only pending requests can be recalled.');
            }
            if (req.Submitted_By__c != UserInfo.getUserId() && !isAdmin()) {
                throw new ApprovalException('Only the submitter can recall this request.');
            }
            req.Status__c         = 'Recalled';
            req.Completed_Date__c = System.now();
            req.Current_Approver__c = null;
            update req;

            List<Approval_Step__c> pending = [
                SELECT Id FROM Approval_Step__c
                WHERE Approval_Request__c = :requestId AND Status__c = 'Pending'
            ];
            for (Approval_Step__c s : pending) {
                s.Status__c = 'Skipped';
                s.Is_Current__c = false;
            }
            if (!pending.isEmpty()) update pending;
        } catch (ApprovalException ae) {
            throw new AuraHandledException(ae.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ============================================================== My Approvals

    @AuraEnabled(cacheable=true)
    public static List<Approval_Step__c> getMyApprovals() {
        return [
            SELECT Id, Level__c, Approver_Type__c, Status__c,
                   Approval_Request__r.Name, Approval_Request__r.Record_Name__c,
                   Approval_Request__r.Object_Type__c, Approval_Request__r.Record_Id__c,
                   Approval_Request__r.Condition_Value__c,
                   Approval_Request__r.Submitted_By__r.Name,
                   Approval_Request__r.Submitted_Date__c
            FROM Approval_Step__c
            WHERE Approver__c = :UserInfo.getUserId()
              AND Status__c = 'Pending'
              AND Is_Current__c = true
            ORDER BY Approval_Request__r.Submitted_Date__c ASC
        ];
    }

    // ============================================================== Internals

    private static void processCurrent(Id requestId) {
        Approval_Request__c req = [
            SELECT Id, Status__c, Record_Id__c, Object_Type__c, Record_Name__c,
                   Current_Level__c, Current_Approver__c,
                   Status_Field_API_Name__c, Status_Value_On_Approve__c
            FROM Approval_Request__c WHERE Id = :requestId
        ];
        if (req.Status__c != 'Pending') return;

        List<Approval_Step__c> steps = [
            SELECT Id, Level__c, Status__c, Approver__c, Auto_Approve__c, Is_Current__c
            FROM Approval_Step__c WHERE Approval_Request__c = :requestId
            ORDER BY Level__c ASC
        ];

        for (Approval_Step__c s : steps) {
            if (s.Status__c != 'Pending') continue;

            if (s.Auto_Approve__c == true) {
                s.Status__c = 'Auto-Approved';
                s.Decision_Date__c = System.now();
                s.Is_Current__c = false;
                update s;
                continue;
            }

            // First human-pending step becomes the active one.
            s.Is_Current__c = true;
            update s;
            req.Current_Level__c   = s.Level__c;
            req.Current_Approver__c = s.Approver__c;
            update req;
            notifyApprover(req, s.Approver__c);
            return;
        }

        // No pending human step remaining -> fully approved.
        req.Status__c         = 'Approved';
        req.Completed_Date__c = System.now();
        req.Current_Approver__c = null;
        update req;
        stampSource((Id) req.Record_Id__c, req.Object_Type__c,
                    req.Status_Field_API_Name__c, req.Status_Value_On_Approve__c);
        safeDispatch((Id) req.Record_Id__c, 'Approved');
    }

    private static Id resolveApprover(Approval_Rule__c r, Id submittedBy) {
        String type = r.Approver_Type__c;
        if (type == 'User') {
            return r.User__c;
        } else if (type == 'Manager') {
            for (User u : [SELECT ManagerId FROM User WHERE Id = :submittedBy AND ManagerId != null LIMIT 1]) {
                return u.ManagerId;
            }
            return null;
        } else if (type == 'Role' && String.isNotBlank(r.Approver_Role_Queue__c)) {
            for (User u : [SELECT Id FROM User
                           WHERE IsActive = true AND UserRole.DeveloperName = :r.Approver_Role_Queue__c
                           ORDER BY Name LIMIT 1]) {
                return u.Id;
            }
            return null;
        } else if (type == 'Queue' && String.isNotBlank(r.Approver_Role_Queue__c)) {
            for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember
                                   WHERE Group.DeveloperName = :r.Approver_Role_Queue__c
                                   AND Group.Type = 'Queue']) {
                if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) return gm.UserOrGroupId;
            }
            return null;
        }
        return r.User__c;
    }

    private static Boolean matchesBand(Approval_Rule__c r, Decimal val) {
        if (String.isBlank(r.Condition_Field__c)) return true;
        if (val == null) return (r.Min_Value__c == null && r.Max_Value__c == null);
        if (r.Min_Value__c != null && val < r.Min_Value__c) return false;
        if (r.Max_Value__c != null && val > r.Max_Value__c) return false;
        return true;
    }

    private static void stampSource(Id recordId, String objApi, String fieldApi, String value) {
        if (String.isBlank(fieldApi) || value == null) return;
        Map<String, Schema.SObjectField> fmap =
            Schema.getGlobalDescribe().get(objApi).getDescribe().fields.getMap();
        if (!fmap.containsKey(fieldApi.toLowerCase())) return;
        if (!fmap.get(fieldApi.toLowerCase()).getDescribe().isUpdateable()) return;
        SObject rec = recordId.getSObjectType().newSObject(recordId);
        rec.put(fieldApi, value);
        try {
            update rec;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Source stamp failed: ' + e.getMessage());
        }
    }

    private static void notifyApprover(Approval_Request__c req, Id approverId) {
        if (approverId == null) return;
        String subject = 'Approval required: ' + req.Record_Name__c;
        String body = 'A ' + req.Object_Type__c + ' record requires your approval (Level '
                    + req.Current_Level__c + ').';
        try {
            NotificationDispatchService.notify(
                new Set<Id>{ approverId }, (Id) req.Record_Id__c, subject, body);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Approver notification failed: ' + e.getMessage());
        }
    }

    private static void safeDispatch(Id recordId, String eventType) {
        try {
            NotificationDispatchService.dispatch(recordId, eventType);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Notification dispatch failed: ' + e.getMessage());
        }
    }

    private static SObject loadRecord(String objApi, Id recordId, String conditionField) {
        Map<String, Schema.SObjectField> fmap =
            Schema.getGlobalDescribe().get(objApi).getDescribe().fields.getMap();
        Set<String> fields = new Set<String>{ 'Id', 'OwnerId' };
        if (fmap.containsKey('name')) fields.add('Name');
        if (String.isNotBlank(conditionField) && fmap.containsKey(conditionField.toLowerCase())) {
            fields.add(conditionField);
        }
        String q = 'SELECT ' + String.join(new List<String>(fields), ',')
                 + ' FROM ' + objApi + ' WHERE Id = :recordId LIMIT 1';
        List<SObject> recs = Database.query(q);
        return recs.isEmpty() ? null : recs[0];
    }

    private static Object safeGet(SObject rec, String field) {
        if (rec == null || String.isBlank(field)) return null;
        try { return rec.get(field); } catch (Exception e) { return null; }
    }

    private static Decimal toDecimal(Object v) {
        if (v == null) return null;
        if (v instanceof Decimal) return (Decimal) v;
        try { return Decimal.valueOf(String.valueOf(v)); } catch (Exception e) { return null; }
    }

    private static Boolean isAdmin() {
        return [SELECT PermissionsModifyAllData FROM Profile
                WHERE Id = :UserInfo.getProfileId()].PermissionsModifyAllData;
    }
}