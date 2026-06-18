/**
 * @description Generates next-cycle outlet targets from a source Journey Cycle
 *              (BRD §13.2). Run on demand for a completed cycle by passing its
 *              Period_Start date; uses TAM_OutletTargetIncrement_Service to step
 *              each outlet target up by the configured per State + Outlet Type
 *              percentage and inserts the resulting Target__c records.
 *
 *              Usage: Database.executeBatch(
 *                  new TAM_OutletTargetIncrement_Batch(Date.newInstance(2026,6,1)), 200);
 *
 * @author  SFA Development Team
 * @date    2026
 */
public with sharing class TAM_OutletTargetIncrement_Batch
        implements Database.Batchable<SObject> {

    private final Date sourcePeriodStart;

    public TAM_OutletTargetIncrement_Batch(Date sourcePeriodStart) {
        this.sourcePeriodStart = sourcePeriodStart;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Account__c, Product__c, Brand__c, State__c, Outlet_Type__c,
                   Target_Type__c, Target_Value__c, Achievement_Value__c,
                   Period_Start__c, Period_End__c
            FROM Target__c
            WHERE Tier__c = 'Outlet' AND Period_Start__c = :sourcePeriodStart
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Target__c> scope) {
        List<Target__c> nextCycle = TAM_OutletTargetIncrement_Service.buildNextCycleTargets(scope);
        if (!nextCycle.isEmpty()) {
            insert nextCycle;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // no-op
    }
}
