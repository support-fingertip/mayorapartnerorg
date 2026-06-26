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
        // SOQL cannot compare two fields (Budget_Used__c >= Budget_Amount__c),
        // so the budget-exhausted test is applied in execute() below.
        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId, Budget_Amount__c, Budget_Used__c, Status__c
            FROM Scheme__c
            WHERE Status__c = 'Active'
              AND Budget_Amount__c != null
              AND Budget_Amount__c > 0
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Scheme__c> scope) {
        List<Scheme__c> exhausted = new List<Scheme__c>();
        Set<Id> ownerIds = new Set<Id>();
        for (Scheme__c s : scope) {
            if (s.Budget_Used__c != null && s.Budget_Used__c >= s.Budget_Amount__c) {
                s.Status__c = 'Cancelled';
                exhausted.add(s);
                ownerIds.add(s.OwnerId);
            }
        }
        if (exhausted.isEmpty()) {
            return;
        }
        update exhausted;

        NotificationDispatchService.notify(
            ownerIds,
            exhausted[0].Id,
            'Scheme budget exhausted',
            exhausted.size() + ' scheme(s) reached their budget and were auto-deactivated (BRD 13.2).'
        );
    }

    public void finish(Database.BatchableContext bc) {
        // No post-processing required.
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }
}
