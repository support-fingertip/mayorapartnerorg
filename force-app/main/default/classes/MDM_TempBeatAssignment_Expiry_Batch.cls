/**
 * @description Scheduled batch that expires Temporary Beat Assignments
 *              (BRD §5.3) whose End_Date has passed. Schedule daily, e.g.:
 *              System.schedule('Temp Beat Expiry', '0 30 0 * * ?',
 *                  new MDM_TempBeatAssignment_Expiry_Batch());
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class MDM_TempBeatAssignment_Expiry_Batch
        implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c
            FROM Temporary_Beat_Assignment__c
            WHERE Status__c = 'Active' AND End_Date__c < TODAY
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Temporary_Beat_Assignment__c> scope) {
        for (Temporary_Beat_Assignment__c rec : scope) {
            rec.Status__c = 'Expired';
        }
        if (!scope.isEmpty()) {
            update scope;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // no-op
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new MDM_TempBeatAssignment_Expiry_Batch(), 200);
    }
}