/**
 * @description Phase 3 tests for DMS secondary billing: FEFO batch allocation
 *              across distributor stock, stock-out + invoice creation, retailer
 *              credit enforcement, insufficient-stock handling, and gating.
 * @author  SFA Development Team
 * @date    2024
 */
@isTest
private class DMS_SecondaryBilling_Test {

    private static void enableToggles() {
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, true);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_SECONDARY_BILLING, true);
    }

    private static void disableToggles() {
        // Force the toggles OFF in cache. Without this, isEnabled() falls back to the
        // live Feature_Toggle__mdt records (which ship as Is_Enabled__c = true), so the
        // service would run instead of throwing the "not enabled" error.
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, false);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_SECONDARY_BILLING, false);
    }

    private static void seedBatch(Id accountId, Id productId, String batch, Date expiry, Decimal qty) {
        insert new Distributor_Stock__c(
            Account__c = accountId,
            Product_Ext__c = productId,
            Batch_No__c = batch,
            Expiry_Date__c = expiry,
            Opening_Stock__c = qty,
            Stock_Date__c = Date.today(),
            Is_Current__c = true
        );
    }

    private static Decimal onHand(Id accountId, Id productId) {
        Map<String, Decimal> m = DMS_DistributorInventory_Service.getCurrentOnHand(
            new Set<Id>{ accountId }, new Set<Id>{ productId });
        String k = DMS_DistributorInventory_Service.key(accountId, productId);
        return m.containsKey(k) ? m.get(k) : 0;
    }

    @isTest
    static void fefoAcrossBatches_billsAndDeducts() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist SB', 'Distributor');
        Account retailer = TestDataFactory.createAndInsertAccount('Retailer SB', 'Retailer');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        Id productId = products[0].Id;

        // Two current batches; earlier-expiry batch should be consumed first.
        seedBatch(dist.Id, productId, 'EARLY', Date.today().addDays(10), 30);
        seedBatch(dist.Id, productId, 'LATE',  Date.today().addDays(60), 50);

        enableToggles();
        Test.startTest();
        Id invoiceId = DMS_SecondaryBilling_Service.createSecondaryInvoice(
            dist.Id, retailer.Id,
            new List<DMS_SecondaryBilling_Service.LineRequest>{
                new DMS_SecondaryBilling_Service.LineRequest(productId, 60, 10)
            });
        Test.stopTest();

        Invoice__c inv = [
            SELECT Order_Type__c, Account__c, Sold_From_Distributor__c, Total_Amount__c
            FROM Invoice__c WHERE Id = :invoiceId
        ];
        System.assertEquals('Secondary', inv.Order_Type__c, 'Secondary invoice');
        System.assertEquals(retailer.Id, inv.Account__c, 'Billed to retailer');
        System.assertEquals(dist.Id, inv.Sold_From_Distributor__c, 'Sourced from distributor stock');
        System.assertEquals(600, inv.Total_Amount__c, 'Total = 60 * 10');

        // FEFO: 30 from EARLY + 30 from LATE -> two lines.
        List<Invoice_Line__c> ilines = [
            SELECT Batch_No__c, Quantity__c FROM Invoice_Line__c WHERE Invoice__c = :invoiceId ORDER BY Line_Number__c
        ];
        System.assertEquals(2, ilines.size(), 'One line per allocated batch');
        System.assertEquals('EARLY', ilines[0].Batch_No__c, 'Earliest-expiry batch consumed first');
        System.assertEquals(30, ilines[0].Quantity__c, 'Full EARLY batch consumed');
        System.assertEquals(30, ilines[1].Quantity__c, 'Remainder from LATE batch');

        // Remaining on-hand: EARLY 0 + LATE 20 = 20.
        System.assertEquals(20, onHand(dist.Id, productId), 'Distributor stock reduced to 20');

        System.assertEquals(2, [
            SELECT COUNT() FROM Stock_Transaction__c
            WHERE Account__c = :dist.Id AND Direction__c = 'Out'
              AND Transaction_Type__c = 'Outbound_Dispatch' AND Reference_Type__c = 'Invoice'
        ], 'Two stock-out transactions written');
    }

    @isTest
    static void insufficientStock_throws() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist SB2', 'Distributor');
        Account retailer = TestDataFactory.createAndInsertAccount('Retailer SB2', 'Retailer');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        seedBatch(dist.Id, products[0].Id, 'B1', Date.today().addDays(30), 20);

        enableToggles();
        Boolean thrown = false;
        Test.startTest();
        try {
            DMS_SecondaryBilling_Service.createSecondaryInvoice(
                dist.Id, retailer.Id,
                new List<DMS_SecondaryBilling_Service.LineRequest>{
                    new DMS_SecondaryBilling_Service.LineRequest(products[0].Id, 50, 10)
                });
        } catch (DMS_SecondaryBillingException e) {
            thrown = true;
            System.assert(e.getMessage().contains('Insufficient'), 'Insufficient stock message');
        }
        Test.stopTest();
        System.assertEquals(true, thrown, 'Should throw on insufficient stock');
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE Sold_From_Distributor__c = :dist.Id],
            'No invoice created on failure');
    }

    @isTest
    static void creditLimitExceeded_throws() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist SB3', 'Distributor');
        Account retailer = TestDataFactory.createAndInsertAccount('Retailer SB3', 'Retailer');
        retailer.Credit_Limit__c = 100;
        retailer.Outstanding_Balance__c = 0;
        update retailer;

        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        seedBatch(dist.Id, products[0].Id, 'B1', Date.today().addDays(30), 1000);

        enableToggles();
        Boolean thrown = false;
        Test.startTest();
        try {
            DMS_SecondaryBilling_Service.createSecondaryInvoice(
                dist.Id, retailer.Id,
                new List<DMS_SecondaryBilling_Service.LineRequest>{
                    new DMS_SecondaryBilling_Service.LineRequest(products[0].Id, 60, 10) // 600 > 100
                });
        } catch (DMS_SecondaryBillingException e) {
            thrown = true;
            System.assert(e.getMessage().contains('Credit limit exceeded'), 'Credit message');
        }
        Test.stopTest();
        System.assertEquals(true, thrown, 'Should throw on credit breach');
    }

    @isTest
    static void disabled_throws() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist SB4', 'Distributor');
        Account retailer = TestDataFactory.createAndInsertAccount('Retailer SB4', 'Retailer');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        seedBatch(dist.Id, products[0].Id, 'B1', Date.today().addDays(30), 100);

        // Toggles disabled — set explicitly so the service is genuinely off.
        disableToggles();
        Boolean thrown = false;
        Test.startTest();
        try {
            DMS_SecondaryBilling_Service.createSecondaryInvoice(
                dist.Id, retailer.Id,
                new List<DMS_SecondaryBilling_Service.LineRequest>{
                    new DMS_SecondaryBilling_Service.LineRequest(products[0].Id, 10, 10)
                });
        } catch (DMS_SecondaryBillingException e) {
            thrown = true;
            System.assert(e.getMessage().contains('not enabled'), 'Disabled message');
        }
        Test.stopTest();
        System.assertEquals(true, thrown, 'Should throw when secondary billing disabled');
    }
}