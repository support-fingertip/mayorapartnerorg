/**
 * @description Phase 4 tests for primary-indent credit enforcement (DMS-009):
 *              approval is blocked when the distributor's outstanding plus the
 *              indent value would exceed the credit limit.
 * @author  SFA Development Team
 * @date    2024
 */
@isTest
private class DMS_CreditEnforcement_Test {

    private static void enableCreditEnforcement() {
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, true);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_CREDIT_ENFORCEMENT, true);
        // Primary fulfillment left OFF so the approval only exercises the credit gate.
    }

    private static void disableCreditEnforcement() {
        // Force the toggles OFF in cache. Without this, isEnabled() falls back to the
        // live Feature_Toggle__mdt records (which ship as Is_Enabled__c = true), so the
        // credit gate would actually run and block the approval.
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, false);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_CREDIT_ENFORCEMENT, false);
    }

    private static Indent__c indentWithValue(Id accountId, Decimal qty, Decimal price) {
        Indent__c indent = new Indent__c(
            Account__c = accountId,
            Indent_Date__c = Date.today(),
            Status__c = 'Submitted'
        );
        insert indent;
        insert new Indent_Line__c(
            Indent__c = indent.Id,
            Product_Ext__c = TestDataFactory.createAndInsertProducts(1)[0].Id,
            Requested_Qty__c = qty,
            Unit_Price__c = price
        );
        return indent;
    }

    @isTest
    static void approval_blockedWhenOverLimit() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist CE', 'Distributor');
        dist.Credit_Limit__c = 1000;
        dist.Outstanding_Balance__c = 0;
        update dist;

        Indent__c indent = indentWithValue(dist.Id, 20, 100); // value 2000 > 1000

        enableCreditEnforcement();
        Boolean blocked = false;
        Test.startTest();
        try {
            update new Indent__c(Id = indent.Id, Status__c = 'Approved');
        } catch (DmlException e) {
            blocked = true;
            System.assert(e.getMessage().contains('credit limit exceeded'), e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(true, blocked, 'Approval blocked over credit limit');
        System.assertEquals('Submitted',
            [SELECT Status__c FROM Indent__c WHERE Id = :indent.Id].Status__c,
            'Status not advanced');
    }

    @isTest
    static void approval_allowedWhenWithinLimit() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist CE2', 'Distributor');
        dist.Credit_Limit__c = 100000;
        dist.Outstanding_Balance__c = 0;
        update dist;

        Indent__c indent = indentWithValue(dist.Id, 20, 100); // value 2000 < 100000

        enableCreditEnforcement();
        Test.startTest();
        update new Indent__c(Id = indent.Id, Status__c = 'Approved');
        Test.stopTest();

        System.assertEquals('Approved',
            [SELECT Status__c FROM Indent__c WHERE Id = :indent.Id].Status__c,
            'Approval allowed within credit limit');
    }

    @isTest
    static void approval_allowedWhenEnforcementDisabled() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist CE3', 'Distributor');
        dist.Credit_Limit__c = 1000;
        dist.Outstanding_Balance__c = 0;
        update dist;

        Indent__c indent = indentWithValue(dist.Id, 20, 100); // value 2000 > 1000

        // Enforcement toggle intentionally OFF — set explicitly so behavior never
        // depends on the deployed Feature_Toggle__mdt records.
        disableCreditEnforcement();
        Test.startTest();
        update new Indent__c(Id = indent.Id, Status__c = 'Approved');
        Test.stopTest();

        System.assertEquals('Approved',
            [SELECT Status__c FROM Indent__c WHERE Id = :indent.Id].Status__c,
            'Approval allowed when enforcement disabled');
    }
}