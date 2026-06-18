/**
 * @description Tests for DMS scheme accrual on primary invoices and reconciliation
 *              of approved scheme claims against open accruals.
 * @author  SFA Development Team
 * @date    2024
 */
@isTest
private class DMS_SchemeAccrual_Test {

    private static void enableSchemeClaim() {
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, true);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_SCHEME_CLAIM, true);
    }

    private static void disableSchemeClaim() {
        // Force the toggles OFF in cache. Without this, isEnabled() falls back to the
        // live Feature_Toggle__mdt records (which ship as Is_Enabled__c = true), so the
        // accrual would actually be created.
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, false);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_SCHEME_CLAIM, false);
    }

    private static Scheme__c createPercentScheme(Decimal percent) {
        // Is_Active__c is a formula (Status = Active AND within date range), so drive
        // it via Status + dates rather than writing it directly.
        // Budget_Amount__c defaults to 0 and a validation rule requires it > 0, so set it.
        Scheme__c sch = new Scheme__c(
            Name = 'Primary 5pct',
            Scheme_Code__c = 'SCH-DMS-' + String.valueOf(Datetime.now().getTime()),
            Status__c = 'Active',
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(30),
            Discount_Percent__c = percent,
            Budget_Amount__c = 100000
        );
        insert sch;
        return sch;
    }

    @isTest
    static void accruesPercentOfPrimaryInvoiceValue() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist SA', 'Distributor');
        Scheme__c scheme = createPercentScheme(5);

        // A standalone primary invoice (value 1000) to accrue against.
        Invoice__c inv = new Invoice__c(
            Account__c = dist.Id, Order_Type__c = 'Primary', Invoice_Date__c = Date.today(),
            Invoice_Number__c = 'PINV-SA-1', Status__c = 'Draft', Total_Amount__c = 1000,
            Balance_Due__c = 1000
        );
        insert inv;

        enableSchemeClaim();
        Test.startTest();
        DMS_SchemeAccrual_Service.accrueForPrimaryInvoices(
            new Map<Id, Decimal>{ inv.Id => 1000 },
            new Map<Id, Id>{ inv.Id => dist.Id });
        Test.stopTest();

        List<Scheme_Accrual__c> accruals = [
            SELECT Accrued_Amount__c, Status__c, Scheme__c FROM Scheme_Accrual__c WHERE Invoice__c = :inv.Id
        ];
        System.assertEquals(1, accruals.size(), 'One accrual for the applicable scheme');
        System.assertEquals(50, accruals[0].Accrued_Amount__c, '5% of 1000');
        System.assertEquals('Open', accruals[0].Status__c, 'Accrual is Open');
        System.assertEquals(scheme.Id, accruals[0].Scheme__c, 'Linked to scheme');
    }

    @isTest
    static void claimReconciliation_marksAccrualsClaimed() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist SA2', 'Distributor');
        Scheme__c scheme = createPercentScheme(10);

        enableSchemeClaim();
        // Seed an open accrual directly.
        Scheme_Accrual__c accrual = new Scheme_Accrual__c(
            Account__c = dist.Id, Scheme__c = scheme.Id,
            Accrued_Amount__c = 200, Accrual_Date__c = Date.today(), Status__c = 'Open'
        );
        insert accrual;

        Claim__c claim = new Claim__c(
            Account__c = dist.Id, Scheme__c = scheme.Id, Claim_Type__c = 'Scheme Claim',
            Claim_Date__c = Date.today(), Total_Amount__c = 200, Status__c = 'Submitted'
        );
        insert claim;

        Test.startTest();
        update new Claim__c(Id = claim.Id, Status__c = 'Approved', Approved_Amount__c = 200);
        Test.stopTest();

        Scheme_Accrual__c after = [
            SELECT Status__c, Claim__c FROM Scheme_Accrual__c WHERE Id = :accrual.Id
        ];
        System.assertEquals('Claimed', after.Status__c, 'Accrual marked Claimed');
        System.assertEquals(claim.Id, after.Claim__c, 'Accrual linked to claim');

        // Claim settlement also posts a credit-note ledger entry (Phase 4 behavior).
        System.assertEquals(1, [SELECT COUNT() FROM Ledger_Entry__c WHERE Reference_Id__c = :claim.Id],
            'Credit-note ledger entry posted');
    }

    @isTest
    static void togglesOff_noAccrual() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist SA3', 'Distributor');
        createPercentScheme(5);
        Invoice__c inv = new Invoice__c(
            Account__c = dist.Id, Order_Type__c = 'Primary', Invoice_Date__c = Date.today(),
            Invoice_Number__c = 'PINV-SA-3', Status__c = 'Draft', Total_Amount__c = 1000,
            Balance_Due__c = 1000
        );
        insert inv;

        // Toggles off — set explicitly so behavior never depends on deployed metadata.
        disableSchemeClaim();
        Test.startTest();
        DMS_SchemeAccrual_Service.accrueForPrimaryInvoices(
            new Map<Id, Decimal>{ inv.Id => 1000 },
            new Map<Id, Id>{ inv.Id => dist.Id });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Scheme_Accrual__c WHERE Invoice__c = :inv.Id],
            'No accrual when DMS disabled');
    }
}