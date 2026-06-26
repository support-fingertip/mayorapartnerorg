/**
 * @description Trigger handler for Beat_Day_Request__c (BRD 7.4). Sets defaults
 *              and enforces the rule that a "No-PJP Day" request can be approved
 *              at most 3 times per Journey Cycle per salesperson.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class BPM_BeatDayRequest_TriggerHandler extends TriggerHandler {

    /** Max approved No-PJP-Day requests per salesperson per Journey Cycle (BRD 7.4). */
    @TestVisible
    private static final Integer NO_PJP_CAP = 3;

    // ── Before Insert ─────────────────────────────────────────────────────────

    protected override void beforeInsert() {
        setDefaults((List<Beat_Day_Request__c>) Trigger.new);
    }

    // ── Before Update ─────────────────────────────────────────────────────────

    protected override void beforeUpdate() {
        enforceNoPjpCap(
            (List<Beat_Day_Request__c>) Trigger.new,
            (Map<Id, Beat_Day_Request__c>) Trigger.oldMap
        );
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void setDefaults(List<Beat_Day_Request__c> records) {
        for (Beat_Day_Request__c r : records) {
            if (r.Request_Date__c == null) {
                r.Request_Date__c = Date.today();
            }
            if (String.isBlank(r.Status__c)) {
                r.Status__c = 'Pending';
            }
        }
    }

    /**
     * Blocks the 4th (and beyond) approval of a No-PJP-Day request for the same
     * salesperson within the same Journey Cycle (BRD 7.4).
     */
    private void enforceNoPjpCap(List<Beat_Day_Request__c> records, Map<Id, Beat_Day_Request__c> oldMap) {
        List<Beat_Day_Request__c> transitioning = new List<Beat_Day_Request__c>();
        Set<Id> excludeIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> jcIds = new Set<Id>();

        for (Beat_Day_Request__c r : records) {
            Beat_Day_Request__c old = oldMap.get(r.Id);
            Boolean nowApproved = r.Status__c == 'Approved';
            Boolean wasApproved = old != null && old.Status__c == 'Approved';
            if (nowApproved && !wasApproved
                && r.Request_Type__c == 'No-PJP Day'
                && r.Salesperson__c != null
                && r.Journey_Cycle__c != null) {
                transitioning.add(r);
                excludeIds.add(r.Id);
                userIds.add(r.Salesperson__c);
                jcIds.add(r.Journey_Cycle__c);
            }
        }
        if (transitioning.isEmpty()) {
            return;
        }

        // Count already-approved No-PJP-Day requests per salesperson + JC.
        Map<String, Integer> approvedCounts = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Salesperson__c sp, Journey_Cycle__c jc, COUNT(Id) cnt
            FROM Beat_Day_Request__c
            WHERE Request_Type__c = 'No-PJP Day'
              AND Status__c = 'Approved'
              AND Salesperson__c IN :userIds
              AND Journey_Cycle__c IN :jcIds
              AND Id NOT IN :excludeIds
            GROUP BY Salesperson__c, Journey_Cycle__c
        ]) {
            String key = (Id) ar.get('sp') + '|' + (Id) ar.get('jc');
            approvedCounts.put(key, (Integer) ar.get('cnt'));
        }

        // Walk the transitioning records, counting newly-approved ones in-batch too.
        Map<String, Integer> batchCounts = new Map<String, Integer>();
        for (Beat_Day_Request__c r : transitioning) {
            String key = r.Salesperson__c + '|' + r.Journey_Cycle__c;
            Integer existing = approvedCounts.containsKey(key) ? approvedCounts.get(key) : 0;
            Integer inBatch = batchCounts.containsKey(key) ? batchCounts.get(key) : 0;
            if (existing + inBatch >= NO_PJP_CAP) {
                r.addError('A maximum of ' + NO_PJP_CAP
                    + ' No-PJP day requests can be approved per Journey Cycle (BRD 7.4).');
            } else {
                batchCounts.put(key, inBatch + 1);
            }
        }
    }
}
