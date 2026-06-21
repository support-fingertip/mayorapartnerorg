/**
 * @description Tests for the Temporary Beat Assignment lifecycle (BRD §5.3) —
 *              insert defaults, auto-expiry on save, and the scheduled batch.
 */
@isTest
private class MDM_TempBeatAssignment_Test {

    private static Beat__c makeBeat() {
        Beat__c b = new Beat__c(Name = 'Test Beat ' + System.now().getTime());
        insert b;
        return b;
    }

    @isTest
    static void defaultsAndAutoExpireOnSave() {
        Beat__c beat = makeBeat();

        // Defaults: Start_Date => today, Status => Active.
        Temporary_Beat_Assignment__c fresh = new Temporary_Beat_Assignment__c(
            Beat__c = beat.Id,
            Assigned_To_User__c = UserInfo.getUserId()
        );
        insert fresh;
        fresh = [SELECT Start_Date__c, Status__c FROM Temporary_Beat_Assignment__c WHERE Id = :fresh.Id];
        System.assertEquals(Date.today(), fresh.Start_Date__c, 'Start_Date should default to today.');
        System.assertEquals('Active', fresh.Status__c, 'Status should default to Active.');

        // A past End_Date auto-expires the record on save.
        Temporary_Beat_Assignment__c past = new Temporary_Beat_Assignment__c(
            Beat__c = beat.Id,
            Assigned_To_User__c = UserInfo.getUserId(),
            Status__c = 'Active',
            End_Date__c = Date.today().addDays(-1)
        );
        insert past;
        past = [SELECT Status__c FROM Temporary_Beat_Assignment__c WHERE Id = :past.Id];
        System.assertEquals('Expired', past.Status__c, 'Past End_Date should auto-expire on save.');
    }

    @isTest
    static void expiryBatchExpiresStaleAssignments() {
        Beat__c beat = makeBeat();

        // Stage an Active record with a past End_Date by bypassing the trigger,
        // simulating an assignment that lapsed over time without a DML touch.
        TriggerHandler.bypass('MDM_TempBeatAssignment_TriggerHandler');
        Temporary_Beat_Assignment__c stale = new Temporary_Beat_Assignment__c(
            Beat__c = beat.Id,
            Assigned_To_User__c = UserInfo.getUserId(),
            Start_Date__c = Date.today().addDays(-5),
            End_Date__c = Date.today().addDays(-1),
            Status__c = 'Active'
        );
        insert stale;
        TriggerHandler.clearBypass('MDM_TempBeatAssignment_TriggerHandler');

        Test.startTest();
        Database.executeBatch(new MDM_TempBeatAssignment_Expiry_Batch(), 200);
        Test.stopTest();

        stale = [SELECT Status__c FROM Temporary_Beat_Assignment__c WHERE Id = :stale.Id];
        System.assertEquals('Expired', stale.Status__c, 'Batch should expire stale assignments.');
    }

    @isTest
    static void schedulableRunsBatch() {
        Test.startTest();
        System.schedule(
            'Temp Beat Expiry Test',
            '0 0 0 15 3 ? 2042',
            new MDM_TempBeatAssignment_Expiry_Batch()
        );
        Test.stopTest();
        // No assertion needed — exercises the Schedulable entry point.
    }
}