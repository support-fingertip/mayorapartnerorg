/**
 * @description Batch + Schedulable that recomputes tiered Target__c actuals
 *              (BRD §13) for every active target whose period covers today.
 *              Delegates to TAM_TargetActuals_Service.
 *
 * Usage (Execute Anonymous):
 *   Database.executeBatch(new TAM_TargetActuals_Batch(), 50);
 *   System.schedule('Target Actuals Daily', '0 0 5 * * ?', new TAM_TargetActuals_Batch());
 *
 * @author  SFA Development Team
 * @date    2026
 */
public without sharing class TAM_TargetActuals_Batch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date today = Date.today();
        return Database.getQueryLocator([
            SELECT Id, Tier__c, Target_Type__c, Target_Value__c, Target_Product_Level__c,
                   Customer__c, User__c, Salesperson__c, Brand__c, Sub_Brand__c, Brand_Alias__c,
                   Product__c, Product_Ext__c, Period_Start__c, Period_End__c
            FROM Target__c
            WHERE Tier__c != null
              AND Target_Type__c IN ('Revenue', 'Volume')
              AND Status__c IN ('Active', 'Published')
              AND Period_Start__c <= :today
              AND Period_End__c >= :today
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Target__c> scope) {
        TAM_TargetActuals_Service.calculateForTargets(scope);
    }

    public void finish(Database.BatchableContext bc) {
        // No post-processing required.
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 50);
    }
}
