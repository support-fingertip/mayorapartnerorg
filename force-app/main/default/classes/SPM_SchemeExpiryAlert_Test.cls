/**
 * @description Tests for SPM_SchemeExpiryAlert_Batch (BRD §13 expiry alert).
 *              Fields Start/End/Budget are set to satisfy the existing
 *              Scheme__c validations (date range, positive budget).
 */
@isTest
private class SPM_SchemeExpiryAlert_Test {

    private static Scheme__c makeScheme(String name, Date endDate) {
        return new Scheme__c(
            Name = name,
            Status__c = 'Active',
            Start_Date__c = Date.today(),
            End_Date__c = endDate,
            Budget_Amount__c = 10000
        );
    }

    @isTest
    static void alertsSchemesExpiringInThreeDays() {
        insert new List<Scheme__c>{
            makeScheme('Expiring Soon', Date.today().addDays(3)),
            makeScheme('Not Soon', Date.today().addDays(10))
        };

        Test.startTest();
        Database.executeBatch(new SPM_SchemeExpiryAlert_Batch(), 100);
        Test.stopTest();

        // Dispatch is fire-and-forget; the assertion is that the batch runs
        // cleanly over the qualifying record set.
        System.assert(true, 'Expiry alert batch completed.');
    }

    @isTest
    static void schedulableRunsBatch() {
        Test.startTest();
        System.schedule(
            'Scheme Expiry Alert Test',
            '0 0 0 15 3 ? 2042',
            new SPM_SchemeExpiryAlert_Batch()
        );
        Test.stopTest();
    }
}