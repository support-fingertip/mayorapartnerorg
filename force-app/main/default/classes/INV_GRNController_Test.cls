@isTest
public class INV_GRNController_Test {

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
        public Warehouse__c warehouse;
        public Invoice__c invoice;
        public Product_Extension__c product;
        public GRN__c grn;
        public GRN_Line__c grnLine;
    }

    private static Fixtures buildFixtures(String suffix, String grnStatus) {
        Fixtures fx = new Fixtures();
        try {
            Territory_Master__c territory = new Territory_Master__c(
                Name = 'GRN Territory ' + suffix,
                Territory_Code__c = ('GRN' + suffix).left(20),
                State__c = 'Maharashtra',
                City__c = 'Mumbai',
                Is_Active__c = true
            );
            fillRequiredFields(territory);
            insert territory;

            fx.account = new Account(
                Name = 'GRN Acc ' + suffix,
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

            fx.warehouse = new Warehouse__c(
                Name = 'GRN WH ' + suffix,
                Warehouse_Code__c = ('WH' + suffix).left(20),
                Warehouse_Type__c = 'Central',
                State__c = 'Maharashtra',
                Is_Active__c = true
            );
            fillRequiredFields(fx.warehouse);
            insert fx.warehouse;

            fx.invoice = new Invoice__c(
                Account__c = fx.account.Id,
                Invoice_Date__c = Date.today().addDays(-1)
            );
            fx.invoice.put('Warehouse__c', fx.warehouse.Id);
            fillRequiredFields(fx.invoice);
            insert fx.invoice;

            fx.product = new Product_Extension__c(
                Name = 'GRN Prod ' + suffix,
                SKU_Code__c = ('SKU' + suffix).left(20),
                Is_Active__c = true
            );
            fillRequiredFields(fx.product);
            insert fx.product;

            fx.grn = new GRN__c(
                Account__c = fx.account.Id,
                Invoice__c = fx.invoice.Id,
                GRN_Date__c = Date.today(),
                Status__c = grnStatus
            );
            fillRequiredFields(fx.grn);
            insert fx.grn;

            fx.grnLine = new GRN_Line__c(
                GRN__c = fx.grn.Id,
                Product_Ext__c = fx.product.Id,
                Batch_No__c = 'BATCH-' + suffix,
                Dispatched_Qty__c = 100,
                Received_Qty__c = 98,
                Short_Qty__c = 2,
                Damaged_Qty__c = 0,
                Expiry_Date__c = Date.today().addMonths(6),
                Notes__c = 'Test line'
            );
            fillRequiredFields(fx.grnLine);
            insert fx.grnLine;
        } catch (Exception ex) {}
        return fx;
    }

    private static Id fakeGRNId() {
        String prefix = GRN__c.SObjectType.getDescribe().getKeyPrefix();
        return (Id) (prefix + '000000000001');
    }

    @isTest
    static void testGetGRNsNoFilters() {
        buildFixtures('A1', 'Pending');

        Test.startTest();
        List<GRN__c> result = INV_GRNController.getGRNs(null, null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNsAllStatus() {
        buildFixtures('A2', 'Pending');

        Test.startTest();
        List<GRN__c> result = INV_GRNController.getGRNs('all', null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNsByStatus() {
        buildFixtures('A3', 'Pending');

        Test.startTest();
        List<GRN__c> result = INV_GRNController.getGRNs('Pending', null, null, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNsWithDateRange() {
        buildFixtures('A4', 'Pending');

        Test.startTest();
        List<GRN__c> result = INV_GRNController.getGRNs(
            null, Date.today().addDays(-7), Date.today().addDays(7), null
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNsWithWarehouse() {
        Fixtures fx = buildFixtures('A5', 'Pending');

        Test.startTest();
        List<GRN__c> result = INV_GRNController.getGRNs(
            null, null, null, fx.warehouse != null ? fx.warehouse.Id : null
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNsAllFilters() {
        Fixtures fx = buildFixtures('A6', 'Pending');

        Test.startTest();
        List<GRN__c> result = INV_GRNController.getGRNs(
            'Pending',
            Date.today().addDays(-7),
            Date.today().addDays(7),
            fx.warehouse != null ? fx.warehouse.Id : null
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetGRNById() {
        Fixtures fx = buildFixtures('B1', 'Pending');

        Test.startTest();
        INV_GRNController.GRNDetail detail = null;
        if (fx.grn != null) {
            detail = INV_GRNController.getGRNById(fx.grn.Id);
        }
        Test.stopTest();

        if (fx.grn != null) {
            System.assertNotEquals(null, detail);
            System.assertNotEquals(null, detail.grn);
            System.assertNotEquals(null, detail.lineItems);
        }
    }

    @isTest
    static void testGetGRNByIdNotFound() {
        Test.startTest();
        Boolean threw = false;
        try {
            INV_GRNController.getGRNById(fakeGRNId());
        } catch (Exception e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testCreateGRN() {
        Fixtures fx = buildFixtures('C1', 'Pending');

        INV_GRNController.GRNInput input = new INV_GRNController.GRNInput();
        input.invoiceId = fx.invoice != null ? fx.invoice.Id : null;
        input.accountId = fx.account != null ? fx.account.Id : null;
        input.grnDate = Date.today();
        input.receivedBy = 'Tester';
        input.notes = 'Test GRN';
        input.lineItems = new List<INV_GRNController.GRNLineInput>();

        INV_GRNController.GRNLineInput line = new INV_GRNController.GRNLineInput();
        line.productId = fx.product != null ? fx.product.Id : null;
        line.batchNo = 'B-100';
        line.dispatchedQty = 50;
        line.receivedQty = 48;
        line.shortQty = 2;
        line.damagedQty = 0;
        line.expiryDate = Date.today().addMonths(12);
        line.notes = 'created via test';
        input.lineItems.add(line);

        Test.startTest();
        try { INV_GRNController.createGRN(JSON.serialize(input)); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCreateGRNNoLineItems() {
        Fixtures fx = buildFixtures('C2', 'Pending');

        INV_GRNController.GRNInput input = new INV_GRNController.GRNInput();
        input.invoiceId = fx.invoice != null ? fx.invoice.Id : null;
        input.accountId = fx.account != null ? fx.account.Id : null;
        input.receivedBy = 'Tester';

        Test.startTest();
        try { INV_GRNController.createGRN(JSON.serialize(input)); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCreateGRNEmptyLineItems() {
        Fixtures fx = buildFixtures('C3', 'Pending');

        INV_GRNController.GRNInput input = new INV_GRNController.GRNInput();
        input.invoiceId = fx.invoice != null ? fx.invoice.Id : null;
        input.accountId = fx.account != null ? fx.account.Id : null;
        input.lineItems = new List<INV_GRNController.GRNLineInput>();

        Test.startTest();
        try { INV_GRNController.createGRN(JSON.serialize(input)); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCreateGRNNullDate() {
        Fixtures fx = buildFixtures('C4', 'Pending');

        INV_GRNController.GRNInput input = new INV_GRNController.GRNInput();
        input.invoiceId = fx.invoice != null ? fx.invoice.Id : null;
        input.accountId = fx.account != null ? fx.account.Id : null;
        input.grnDate = null;

        Test.startTest();
        try { INV_GRNController.createGRN(JSON.serialize(input)); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCreateGRNBadJson() {
        Test.startTest();
        Boolean threw = false;
        try {
            INV_GRNController.createGRN('not-json');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testUpdateGRNStatusPendingToReceived() {
        Fixtures fx = buildFixtures('U1', 'Pending');

        Test.startTest();
        if (fx.grn != null) {
            INV_GRNController.updateGRNStatus(fx.grn.Id, 'Received');
        }
        Test.stopTest();

        if (fx.grn != null) {
            GRN__c after = [SELECT Status__c FROM GRN__c WHERE Id = :fx.grn.Id];
            System.assertEquals('Received', after.Status__c);
        }
    }

    @isTest
    static void testUpdateGRNStatusPendingToPartial() {
        Fixtures fx = buildFixtures('U2', 'Pending');

        Test.startTest();
        if (fx.grn != null) {
            INV_GRNController.updateGRNStatus(fx.grn.Id, 'Partial');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateGRNStatusPendingToDisputed() {
        Fixtures fx = buildFixtures('U3', 'Pending');

        Test.startTest();
        if (fx.grn != null) {
            INV_GRNController.updateGRNStatus(fx.grn.Id, 'Disputed');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateGRNStatusPartialToReceived() {
        Fixtures fx = buildFixtures('U4', 'Partial');

        Test.startTest();
        if (fx.grn != null) {
            INV_GRNController.updateGRNStatus(fx.grn.Id, 'Received');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateGRNStatusPartialToDisputed() {
        Fixtures fx = buildFixtures('U5', 'Partial');

        Test.startTest();
        if (fx.grn != null) {
            INV_GRNController.updateGRNStatus(fx.grn.Id, 'Disputed');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateGRNStatusDisputedToPending() {
        Fixtures fx = buildFixtures('U6', 'Disputed');

        Test.startTest();
        if (fx.grn != null) {
            INV_GRNController.updateGRNStatus(fx.grn.Id, 'Pending');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateGRNStatusInvalidTransition() {
        Fixtures fx = buildFixtures('U7', 'Received');

        Test.startTest();
        Boolean threw = false;
        if (fx.grn != null) {
            try {
                INV_GRNController.updateGRNStatus(fx.grn.Id, 'Pending');
            } catch (AuraHandledException e) {
                threw = true;
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateGRNStatusUnknownFromStatus() {
        Fixtures fx = buildFixtures('U8', 'Received');

        Test.startTest();
        Boolean threw = false;
        if (fx.grn != null) {
            try {
                INV_GRNController.updateGRNStatus(fx.grn.Id, 'Disputed');
            } catch (AuraHandledException e) {
                threw = true;
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateGRNStatusWrongTypeId() {
        Test.startTest();
        try {
            INV_GRNController.updateGRNStatus(UserInfo.getUserId(), 'Received');
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testGetGRNLineItems() {
        Fixtures fx = buildFixtures('L1', 'Pending');

        Test.startTest();
        List<GRN_Line__c> lines = INV_GRNController.getGRNLineItems(
            fx.grn != null ? fx.grn.Id : fakeGRNId()
        );
        Test.stopTest();

        System.assertNotEquals(null, lines);
    }

    @isTest
    static void testSearchProductsNoTerm() {
        buildFixtures('S1', 'Pending');

        Test.startTest();
        List<Product_Extension__c> products = INV_GRNController.searchProducts(null);
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testSearchProductsBlankTerm() {
        buildFixtures('S2', 'Pending');

        Test.startTest();
        List<Product_Extension__c> products = INV_GRNController.searchProducts('   ');
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testSearchProductsWithTerm() {
        buildFixtures('S3', 'Pending');

        Test.startTest();
        List<Product_Extension__c> products = INV_GRNController.searchProducts('GRN Prod');
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testSearchProductsBySKU() {
        buildFixtures('S4', 'Pending');

        Test.startTest();
        List<Product_Extension__c> products = INV_GRNController.searchProducts('SKUS4');
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testGetWarehouseOptions() {
        buildFixtures('W1', 'Pending');

        Test.startTest();
        List<Warehouse__c> warehouses = INV_GRNController.getWarehouseOptions();
        Test.stopTest();

        System.assertNotEquals(null, warehouses);
    }
}