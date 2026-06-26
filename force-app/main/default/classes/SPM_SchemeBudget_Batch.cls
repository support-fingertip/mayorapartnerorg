/**
 * @description Scheduled batch (BRD 13.2) that auto-stops schemes whose budget
 *              is exhausted (Budget Used >= Budget Amount) and notifies the
 *              scheme owner. Deactivation is done by setting Status to Cancelled
 *              (Is_Active__c is a formula on Status + date range). Schedule a few
 *              times a day, e.g. every 4 hours with cron "0 0 0/4 * * ?":
 *              System.schedule('SPM Scheme Budget', '0 0 0/4 * * ?',
 *                  new SPM_SchemeBudget_Batch());
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class SPM_SchemeBudget_Batch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId, Budget_Amount__c, Budget_Used__c, Status__c
            FROM Scheme__c
            WHERE Status__c = 'Active'
              AND Budget_Amount__c != null
              AND Budget_Amount__c > 0
              AND Budget_Used__c >= Budget_Amount__c
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Scheme__c> scope) {
        if (scope.isEmpty()) {
            return;
        }
        Set<Id> ownerIds = new Set<Id>();
        for (Scheme__c s : scope) {
            s.Status__c = 'Cancelled';
            ownerIds.add(s.OwnerId);
        }
        update scope;

        NotificationDispatchService.notify(
            ownerIds,
            scope[0].Id,
            'Scheme budget exhausted',
            scope.size() + ' scheme(s) reached their budget and were auto-deactivated (BRD 13.2).'
        );
    }

    public void finish(Database.BatchableContext bc) {
        // No post-processing required.
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }
}
