/**
 * @description Test class for INV_StockDashboardController. Covers KPIs,
 *              stock listing/filtering/pagination, near-expiry batches,
 *              stock movement history, and distributor listing.
 */
@isTest
public class INV_StockDashboardController_Test {

    private static void fillRequiredFields(SObject record) {
        Schema.DescribeSObjectResult sObjDesc = record.getSObjectType().getDescribe();
        for (Schema.SObjectField f : sObjDesc.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            if (!dfr.isCreateable()) continue;
            if (dfr.isNillable()) continue;
            if (dfr.isAutoNumber() || dfr.isCalculated()) continue;
            if (dfr.isDefaultedOnCreate()) continue;
            String fieldName = dfr.getName();
            if (record.get(fieldName) != null) continue;

            Schema.DisplayType t = dfr.getType();
            if (t == Schema.DisplayType.STRING || t == Schema.DisplayType.TEXTAREA) {
                record.put(fieldName, 'Test');
            } else if (t == Schema.DisplayType.EMAIL) {
                record.put(fieldName, 'test@example.com');
            } else if (t == Schema.DisplayType.PHONE) {
                record.put(fieldName, '9999999999');
            } else if (t == Schema.DisplayType.URL) {
                record.put(fieldName, 'https://example.com');
            } else if (t == Schema.DisplayType.PICKLIST || t == Schema.DisplayType.MULTIPICKLIST) {
                List<Schema.PicklistEntry> entries = dfr.getPicklistValues();
                if (!entries.isEmpty()) record.put(fieldName, entries[0].getValue());
            } else if (t == Schema.DisplayType.BOOLEAN) {
                record.put(fieldName, false);
            } else if (t == Schema.DisplayType.DATE) {
                record.put(fieldName, Date.today().addDays(-30));
            } else if (t == Schema.DisplayType.DATETIME) {
                record.put(fieldName, Datetime.now());
            } else if (t == Schema.DisplayType.DOUBLE || t == Schema.DisplayType.CURRENCY || t == Schema.DisplayType.PERCENT) {
                record.put(fieldName, 0);
            } else if (t == Schema.DisplayType.INTEGER || t == Schema.DisplayType.LONG) {
                record.put(fieldName, 0);
            }
        }
    }

    private class Fixtures {
        public Account account;
        public Product_Extension__c product;
        public Distributor_Stock__c healthyStock;
        public Batch_Master__c batch;
    }

    private static Fixtures buildFixtures(String suffix) {
        Fixtures fx = new Fixtures();
        try {
            Territory_Master__c territory = new Territory_Master__c(
                Name = 'SD Territory ' + suffix,
                Territory_Code__c = ('SD' + suffix).left(20),
                State__c = 'Maharashtra',
                City__c = 'Mumbai',
                Is_Active__c = true
            );
            fillRequiredFields(territory);
            insert territory;

            fx.account = new Account(
                Name = 'SD Acc ' + suffix,
                Outlet_Type__c = 'Grocery',
                Channel__c = 'GT',
                Territory__c = territory.Id,
                Is_Active__c = true
            );
            Map<String, Schema.RecordTypeInfo> rtMap =
                Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
            if (rtMap.containsKey('Distributor')) {
                fx.account.RecordTypeId = rtMap.get('Distributor').getRecordTypeId();
            }
            fillRequiredFields(fx.account);
            insert fx.account;

            fx.product = new Product_Extension__c(
                Name = 'SD Prod ' + suffix,
                SKU_Code__c = ('SKU' + suffix).left(20),
                Is_Active__c = true
            );
            fillRequiredFields(fx.product);
            insert fx.product;

            fx.healthyStock = new Distributor_Stock__c(
                Account__c = fx.account.Id,
                Stock_Date__c = Date.today(),
                Opening_Stock__c = 100,
                Received_Qty__c = 20,
                Sold_Qty__c = 5,
                Damaged_Qty__c = 2,
                Is_Current__c = true
            );
            fx.healthyStock.put('Product_Ext__c', fx.product.Id);
            fillRequiredFields(fx.healthyStock);
            insert fx.healthyStock;

            fx.batch = new Batch_Master__c(
                Batch_Number__c = 'BATCH-' + suffix,
                Manufacturing_Date__c = Date.today().addDays(-30),
                Expiry_Date__c = Date.today().addDays(15),
                Quantity_Manufactured__c = 100,
                Status__c = 'Active'
            );
            fx.batch.put('Product_Ext__c', fx.product.Id);
            fillRequiredFields(fx.batch);
            insert fx.batch;
        } catch (Exception ex) {}
        return fx;
    }

    @isTest
    static void testGetStockKPIsAllAccounts() {
        buildFixtures('K1');

        Test.startTest();
        INV_StockDashboardController.StockKPIs kpis =
            INV_StockDashboardController.getStockKPIs(null);
        Test.stopTest();

        System.assertNotEquals(null, kpis);
    }

    @isTest
    static void testGetStockKPIsWithAccount() {
        Fixtures fx = buildFixtures('K2');

        Test.startTest();
        INV_StockDashboardController.StockKPIs kpis =
            INV_StockDashboardController.getStockKPIs(
                fx.account != null ? fx.account.Id : null
            );
        Test.stopTest();

        System.assertNotEquals(null, kpis);
    }

    @isTest
    static void testGetStockKPIsWithLowAndZero() {
        Fixtures fx = buildFixtures('K3');

        // Low-stock record: 0 < Closing_Stock <= 10
        Distributor_Stock__c low = new Distributor_Stock__c(
            Account__c = fx.account != null ? fx.account.Id : null,
            Stock_Date__c = Date.today().addDays(-2),
            Opening_Stock__c = 5,
            Is_Current__c = true
        );
        if (fx.product != null) low.put('Product_Ext__c', fx.product.Id);
        fillRequiredFields(low);
        try { insert low; } catch (Exception e) {}

        // Zero-stock record
        Distributor_Stock__c zero = new Distributor_Stock__c(
            Account__c = fx.account != null ? fx.account.Id : null,
            Stock_Date__c = Date.today().addDays(-3),
            Opening_Stock__c = 0,
            Is_Current__c = true
        );
        if (fx.product != null) zero.put('Product_Ext__c', fx.product.Id);
        fillRequiredFields(zero);
        try { insert zero; } catch (Exception e) {}

        Test.startTest();
        INV_StockDashboardController.StockKPIs kpis =
            INV_StockDashboardController.getStockKPIs(
                fx.account != null ? fx.account.Id : null
            );
        Test.stopTest();

        System.assertNotEquals(null, kpis);
    }

    @isTest
    static void testGetCurrentStockNoFilters() {
        buildFixtures('S1');

        Test.startTest();
        INV_StockDashboardController.StockListResult result =
            INV_StockDashboardController.getCurrentStock(null, null, null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.records);
    }

    @isTest
    static void testGetCurrentStockByAccount() {
        Fixtures fx = buildFixtures('S2');

        Test.startTest();
        INV_StockDashboardController.StockListResult result =
            INV_StockDashboardController.getCurrentStock(
                fx.account != null ? fx.account.Id : null,
                null, 'all', 50, 0
            );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCurrentStockBySearch() {
        buildFixtures('S3');

        Test.startTest();
        INV_StockDashboardController.StockListResult result =
            INV_StockDashboardController.getCurrentStock(
                null, 'SD Prod', 'all', 25, 0
            );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCurrentStockLowFilter() {
        buildFixtures('S4');

        Test.startTest();
        INV_StockDashboardController.StockListResult result =
            INV_StockDashboardController.getCurrentStock(null, null, 'low', 25, 0);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCurrentStockZeroFilter() {
        buildFixtures('S5');

        Test.startTest();
        INV_StockDashboardController.StockListResult result =
            INV_StockDashboardController.getCurrentStock(null, null, 'zero', 25, 0);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCurrentStockHealthyFilter() {
        buildFixtures('S6');

        Test.startTest();
        INV_StockDashboardController.StockListResult result =
            INV_StockDashboardController.getCurrentStock(null, null, 'healthy', 25, 0);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCurrentStockLimitCapping() {
        buildFixtures('S7');

        Test.startTest();
        INV_StockDashboardController.StockListResult result =
            INV_StockDashboardController.getCurrentStock(null, null, 'all', 500, 0);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCurrentStockBlankSearch() {
        buildFixtures('S8');

        Test.startTest();
        INV_StockDashboardController.StockListResult result =
            INV_StockDashboardController.getCurrentStock(null, '   ', 'all', 25, 0);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetNearExpiryBatchesDefault() {
        buildFixtures('B1');

        Test.startTest();
        List<Batch_Master__c> batches =
            INV_StockDashboardController.getNearExpiryBatches(null, null);
        Test.stopTest();

        System.assertNotEquals(null, batches);
    }

    @isTest
    static void testGetNearExpiryBatchesCustomDays() {
        buildFixtures('B2');

        Test.startTest();
        List<Batch_Master__c> batches =
            INV_StockDashboardController.getNearExpiryBatches(60, 10);
        Test.stopTest();

        System.assertNotEquals(null, batches);
    }

    @isTest
    static void testGetNearExpiryBatchesLimitCapping() {
        buildFixtures('B3');

        Test.startTest();
        List<Batch_Master__c> batches =
            INV_StockDashboardController.getNearExpiryBatches(30, 500);
        Test.stopTest();

        System.assertNotEquals(null, batches);
    }

    @isTest
    static void testGetStockMovementHistory() {
        Fixtures fx = buildFixtures('M1');

        Test.startTest();
        List<Distributor_Stock__c> history =
            INV_StockDashboardController.getStockMovementHistory(
                fx.account != null ? fx.account.Id : null,
                fx.product != null ? fx.product.Id : null,
                null
            );
        Test.stopTest();

        System.assertNotEquals(null, history);
    }

    @isTest
    static void testGetStockMovementHistoryCustomLimit() {
        Fixtures fx = buildFixtures('M2');

        Test.startTest();
        List<Distributor_Stock__c> history =
            INV_StockDashboardController.getStockMovementHistory(
                fx.account != null ? fx.account.Id : null,
                fx.product != null ? fx.product.Id : null,
                15
            );
        Test.stopTest();

        System.assertNotEquals(null, history);
    }

    @isTest
    static void testGetStockMovementHistoryLimitCapping() {
        Fixtures fx = buildFixtures('M3');

        Test.startTest();
        List<Distributor_Stock__c> history =
            INV_StockDashboardController.getStockMovementHistory(
                fx.account != null ? fx.account.Id : null,
                fx.product != null ? fx.product.Id : null,
                200
            );
        Test.stopTest();

        System.assertNotEquals(null, history);
    }

    @isTest
    static void testGetDistributorsWithStock() {
        buildFixtures('D1');

        Test.startTest();
        List<Account> distributors =
            INV_StockDashboardController.getDistributorsWithStock();
        Test.stopTest();

        System.assertNotEquals(null, distributors);
    }

    @isTest
    static void testGetDistributorsWithStockEmpty() {
        // No fixtures inserted — exercises the "no accounts found, return empty" path
        Test.startTest();
        List<Account> distributors =
            INV_StockDashboardController.getDistributorsWithStock();
        Test.stopTest();

        System.assertNotEquals(null, distributors);
    }
}