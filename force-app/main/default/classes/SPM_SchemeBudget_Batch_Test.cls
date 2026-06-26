/**
 * @description Tests for SPM_SchemeBudget_Batch (BRD §13.2 budget auto-stop).
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class SPM_SchemeBudget_Batch_Test {

    @isTest
    static void exhaustedSchemeIsDeactivated() {
        Scheme__c s = new Scheme__c(
            Name = 'Budget Exhausted',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(30),
            Budget_Amount__c = 100,
            Budget_Used__c = 120,
            Is_Active__c = true
        );
        insert s;

        Test.startTest();
        Database.executeBatch(new SPM_SchemeBudget_Batch());
        Test.stopTest();

        s = [SELECT Is_Active__c FROM Scheme__c WHERE Id = :s.Id];
        System.assertEquals(false, s.Is_Active__c, 'Scheme over budget should be auto-deactivated');
    }

    @isTest
    static void withinBudgetSchemeStaysActive() {
        Scheme__c s = new Scheme__c(
            Name = 'Within Budget',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(30),
            Budget_Amount__c = 100,
            Budget_Used__c = 40,
            Is_Active__c = true
        );
        insert s;

        Test.startTest();
        Database.executeBatch(new SPM_SchemeBudget_Batch());
        Test.stopTest();

        s = [SELECT Is_Active__c FROM Scheme__c WHERE Id = :s.Id];
        System.assertEquals(true, s.Is_Active__c, 'Scheme within budget should stay active');
    }

    @isTest
    static void schedulableSchedules() {
        Test.startTest();
        String jobId = System.schedule('SPM Budget Test', '0 0 23 * * ?', new SPM_SchemeBudget_Batch());
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}
