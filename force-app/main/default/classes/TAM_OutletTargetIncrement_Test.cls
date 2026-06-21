/**
 * @description Tests for outlet-target auto-increment (BRD §13.2) — the service
 *              builder and the batch that persists the next cycle.
 */
@isTest
private class TAM_OutletTargetIncrement_Test {

    @testSetup
    static void setup() {
        insert new Outlet_Target_Increment__c(
            State__c = 'Maharashtra',
            Outlet_Type__c = 'Retail',
            Increment_Percent__c = 10,
            Basis__c = 'Target',
            Is_Active__c = true
        );
    }

    @isTest
    static void serviceIncrementsByConfiguredPercent() {
        Target__c src = new Target__c(
            Tier__c = 'Outlet',
            State__c = 'Maharashtra',
            Outlet_Type__c = 'Retail',
            Target_Value__c = 1000,
            Period_Start__c = Date.newInstance(2026, 6, 1),
            Period_End__c = Date.newInstance(2026, 6, 28)
        );
        insert src;

        Test.startTest();
        List<Target__c> next = TAM_OutletTargetIncrement_Service.buildNextCycleTargets(
            new List<Target__c>{ src }
        );
        Test.stopTest();

        System.assertEquals(1, next.size(), 'One next-cycle target expected.');
        System.assertEquals(1100.00, next[0].Target_Value__c, '1000 + 10% = 1100.');
        System.assertEquals(
            Date.newInstance(2026, 6, 29), next[0].Period_Start__c,
            'Period should shift forward one 28-day JC.'
        );
    }

    @isTest
    static void unmatchedConfigLeavesValueUnchanged() {
        Target__c src = new Target__c(
            Tier__c = 'Outlet',
            State__c = 'Gujarat',
            Outlet_Type__c = 'Wholesale',
            Target_Value__c = 500
        );
        List<Target__c> next = TAM_OutletTargetIncrement_Service.buildNextCycleTargets(
            new List<Target__c>{ src }
        );
        System.assertEquals(500.00, next[0].Target_Value__c, 'No matching config => unchanged.');
    }

    @isTest
    static void batchInsertsNextCycle() {
        Date srcStart = Date.newInstance(2026, 6, 1);
        insert new Target__c(
            Tier__c = 'Outlet',
            State__c = 'Maharashtra',
            Outlet_Type__c = 'Retail',
            Target_Value__c = 2000,
            Period_Start__c = srcStart,
            Period_End__c = srcStart.addDays(27)
        );

        Test.startTest();
        Database.executeBatch(new TAM_OutletTargetIncrement_Batch(srcStart), 200);
        Test.stopTest();

        Target__c created = [
            SELECT Target_Value__c, Period_Start__c
            FROM Target__c
            WHERE Tier__c = 'Outlet' AND Period_Start__c = :srcStart.addDays(28)
            LIMIT 1
        ];
        System.assertEquals(2200.00, created.Target_Value__c, '2000 + 10% = 2200.');
    }
}