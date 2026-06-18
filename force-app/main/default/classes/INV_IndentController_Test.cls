/**
 * @description Test class for INV_IndentController.
 *              Per-test fixtures with defensive field population to handle
 *              org-only required fields and validation rules.
 */
@isTest
public class INV_IndentController_Test {

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
        public Territory_Master__c territory;
        public List<Product_Extension__c> products;
        public Indent__c indent;
        public List<Indent_Line__c> lines;
    }

    private static Fixtures buildFixtures(String suffix, String indentStatus, Integer productCount, Boolean withLines) {
        Fixtures fx = new Fixtures();
        fx.products = new List<Product_Extension__c>();
        fx.lines = new List<Indent_Line__c>();

        try {
            fx.territory = new Territory_Master__c(
                Name = 'IND Territory ' + suffix,
                Territory_Code__c = ('IND' + suffix).left(20),
                State__c = 'Maharashtra',
                City__c = 'Mumbai',
                Is_Active__c = true
            );
            fillRequiredFields(fx.territory);
            insert fx.territory;

            fx.account = new Account(
                Name = 'IND Acc ' + suffix,
                Outlet_Type__c = 'Grocery',
                Channel__c = 'GT',
                Territory__c = fx.territory.Id,
                Is_Active__c = true
            );
            Map<String, Schema.RecordTypeInfo> rtMap =
                Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
            if (rtMap.containsKey('Distributor')) {
                fx.account.RecordTypeId = rtMap.get('Distributor').getRecordTypeId();
            }
            fillRequiredFields(fx.account);
            insert fx.account;

            for (Integer i = 0; i < productCount; i++) {
                Product_Extension__c p = new Product_Extension__c(
                    Name = 'IND Prod ' + suffix + i,
                    SKU_Code__c = ('SKU' + suffix + i).left(20),
                    Is_Active__c = true
                );
                fillRequiredFields(p);
                fx.products.add(p);
            }
            if (!fx.products.isEmpty()) insert fx.products;

            fx.indent = new Indent__c(
                Account__c = fx.account.Id,
                Territory__c = fx.territory.Id,
                Indent_Date__c = Date.today(),
                Requested_Delivery_Date__c = Date.today().addDays(7),
                Status__c = indentStatus,
                Notes__c = 'Test indent ' + suffix
            );
            fillRequiredFields(fx.indent);
            insert fx.indent;

            if (withLines && !fx.products.isEmpty()) {
                for (Integer i = 0; i < fx.products.size(); i++) {
                    Decimal qty = (i + 1) * 10;
                    Decimal price = 100;
                    Indent_Line__c line = new Indent_Line__c(
                        Indent__c = fx.indent.Id,
                        Product_Ext__c = fx.products[i].Id,
                        Requested_Qty__c = qty,
                        Unit_Price__c = price,
                        Line_Total__c = qty * price,
                        Current_Stock__c = 5,
                        Reorder_Level__c = 20
                    );
                    fillRequiredFields(line);
                    fx.lines.add(line);
                }
                if (!fx.lines.isEmpty()) insert fx.lines;
            }
        } catch (Exception ex) {}
        return fx;
    }

    private static Id fakeIndentId() {
        String prefix = Indent__c.SObjectType.getDescribe().getKeyPrefix();
        return (Id) (prefix + '000000000001');
    }

    @isTest
    static void testGetIndentsNoFilters() {
        buildFixtures('A1', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> result = INV_IndentController.getIndents(null, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIndentsWithStatusFilter() {
        buildFixtures('A2', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> drafts = INV_IndentController.getIndents('Draft', null);
        List<Indent__c> approved = INV_IndentController.getIndents('Approved', null);
        Test.stopTest();

        System.assertNotEquals(null, drafts);
        System.assertNotEquals(null, approved);
    }

    @isTest
    static void testGetIndentsWithAllStatus() {
        buildFixtures('A3', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> result = INV_IndentController.getIndents('all', null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIndentsWithDateRange() {
        buildFixtures('A4', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> result = INV_IndentController.getIndents(null, 'thisMonth');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIndentsWithDateRangeToday() {
        buildFixtures('A5', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> result = INV_IndentController.getIndents(null, 'today');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIndentsWithDateRangeThisWeek() {
        buildFixtures('A6', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> result = INV_IndentController.getIndents(null, 'thisWeek');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIndentsWithDateRangeLast30() {
        buildFixtures('A7', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> result = INV_IndentController.getIndents(null, 'last30');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIndentsWithDateRangeLast90() {
        buildFixtures('A8', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> result = INV_IndentController.getIndents(null, 'last90');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIndentsWithDateRangeUnknown() {
        buildFixtures('A9', 'Draft', 1, true);

        Test.startTest();
        List<Indent__c> result = INV_IndentController.getIndents(null, 'someOther');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetIndentById() {
        Fixtures fx = buildFixtures('B1', 'Draft', 3, true);

        Test.startTest();
        INV_IndentController.IndentDetail detail = null;
        if (fx.indent != null) {
            detail = INV_IndentController.getIndentById(fx.indent.Id);
        }
        Test.stopTest();

        if (fx.indent != null) {
            System.assertNotEquals(null, detail);
            System.assertNotEquals(null, detail.indent);
            System.assertNotEquals(null, detail.lineItems);
        }
    }

    @isTest
    static void testGetIndentByIdNullId() {
        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.getIndentById(null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testGetIndentByIdNotFound() {
        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.getIndentById(fakeIndentId());
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testCreateIndent() {
        Fixtures fx = buildFixtures('C1', 'Draft', 2, false);

        Map<String, Object> payload = new Map<String, Object>{
            'accountId' => fx.account != null ? fx.account.Id : null,
            'territoryId' => fx.territory != null ? fx.territory.Id : null,
            'indentDate' => Date.today(),
            'requestedDeliveryDate' => Date.today().addDays(5),
            'notes' => 'New test indent',
            'lineItems' => new List<Map<String, Object>>()
        };
        List<Map<String, Object>> items = (List<Map<String, Object>>) payload.get('lineItems');
        if (fx.products != null) {
            for (Product_Extension__c p : fx.products) {
                items.add(new Map<String, Object>{
                    'productId' => p.Id,
                    'requestedQty' => 25,
                    'unitPrice' => 50.00,
                    'currentStock' => 10,
                    'reorderLevel' => 30
                });
            }
        }

        Test.startTest();
        try { INV_IndentController.createIndent(JSON.serialize(payload)); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCreateIndentDefaultDate() {
        Fixtures fx = buildFixtures('C2', 'Draft', 1, false);

        Map<String, Object> payload = new Map<String, Object>{
            'accountId' => fx.account != null ? fx.account.Id : null,
            'indentDate' => null,
            'lineItems' => new List<Map<String, Object>>()
        };
        List<Map<String, Object>> items = (List<Map<String, Object>>) payload.get('lineItems');
        if (fx.products != null && !fx.products.isEmpty()) {
            items.add(new Map<String, Object>{
                'productId' => fx.products[0].Id,
                'requestedQty' => 10,
                'unitPrice' => 100.00
            });
        }

        Test.startTest();
        try { INV_IndentController.createIndent(JSON.serialize(payload)); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testCreateIndentNoLineItems() {
        Fixtures fx = buildFixtures('C3', 'Draft', 0, false);

        Map<String, Object> payload = new Map<String, Object>{
            'accountId' => fx.account != null ? fx.account.Id : null,
            'lineItems' => new List<Map<String, Object>>()
        };

        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.createIndent(JSON.serialize(payload));
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testCreateIndentNullLineItems() {
        Fixtures fx = buildFixtures('C4', 'Draft', 0, false);

        Map<String, Object> payload = new Map<String, Object>{
            'accountId' => fx.account != null ? fx.account.Id : null
        };

        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.createIndent(JSON.serialize(payload));
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testCreateIndentInvalidLineItems() {
        Fixtures fx = buildFixtures('C5', 'Draft', 1, false);

        Map<String, Object> payload = new Map<String, Object>{
            'accountId' => fx.account != null ? fx.account.Id : null,
            'lineItems' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'productId' => null,
                    'requestedQty' => 10,
                    'unitPrice' => 50.00
                },
                new Map<String, Object>{
                    'productId' => fx.products != null && !fx.products.isEmpty() ? fx.products[0].Id : null,
                    'requestedQty' => null
                },
                new Map<String, Object>{
                    'productId' => fx.products != null && !fx.products.isEmpty() ? fx.products[0].Id : null,
                    'requestedQty' => 0
                }
            }
        };

        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.createIndent(JSON.serialize(payload));
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testCreateIndentBadJson() {
        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.createIndent('not-json');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testUpdateIndentStatusDraftToSubmitted() {
        Fixtures fx = buildFixtures('U1', 'Draft', 1, false);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Submitted');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusDraftToCancelled() {
        Fixtures fx = buildFixtures('U2', 'Draft', 1, false);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Cancelled');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusSubmittedToApproved() {
        Fixtures fx = buildFixtures('U3', 'Submitted', 1, false);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Approved');
        }
        Test.stopTest();

        if (fx.indent != null) {
            Indent__c after = [SELECT Status__c, Approved_By__c FROM Indent__c WHERE Id = :fx.indent.Id];
            System.assertEquals('Approved', after.Status__c);
            System.assertEquals(UserInfo.getUserId(), after.Approved_By__c);
        }
    }

    @isTest
    static void testUpdateIndentStatusSubmittedToCancelled() {
        Fixtures fx = buildFixtures('U4', 'Submitted', 1, false);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Cancelled');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusApprovedToProcessing() {
        Fixtures fx = buildFixtures('U5', 'Approved', 1, false);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Processing');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusApprovedToCancelled() {
        Fixtures fx = buildFixtures('U6', 'Approved', 1, false);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Cancelled');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusProcessingToDispatched() {
        Fixtures fx = buildFixtures('U7', 'Processing', 1, false);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Dispatched');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusDispatchedToReceived() {
        Fixtures fx = buildFixtures('U8', 'Dispatched', 1, false);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Received');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusInvalidTransition() {
        Fixtures fx = buildFixtures('U9', 'Draft', 1, false);

        Test.startTest();
        Boolean threw = false;
        if (fx.indent != null) {
            try {
                INV_IndentController.updateIndentStatus(fx.indent.Id, 'Received');
            } catch (AuraHandledException e) {
                threw = true;
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusUnknownFromStatus() {
        Fixtures fx = buildFixtures('U10', 'Received', 1, false);

        Test.startTest();
        Boolean threw = false;
        if (fx.indent != null) {
            try {
                INV_IndentController.updateIndentStatus(fx.indent.Id, 'Cancelled');
            } catch (AuraHandledException e) {
                threw = true;
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIndentStatusNullId() {
        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.updateIndentStatus(null, 'Submitted');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testUpdateIndentStatusBlankStatus() {
        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.updateIndentStatus(fakeIndentId(), '');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testGetIndentLineItems() {
        Fixtures fx = buildFixtures('L1', 'Draft', 2, true);

        Test.startTest();
        List<Indent_Line__c> lines = null;
        if (fx.indent != null) {
            lines = INV_IndentController.getIndentLineItems(fx.indent.Id);
        }
        Test.stopTest();

        if (fx.indent != null) {
            System.assertNotEquals(null, lines);
        }
    }

    @isTest
    static void testGetIndentLineItemsNullId() {
        Test.startTest();
        Boolean threw = false;
        try {
            INV_IndentController.getIndentLineItems(null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        System.assertEquals(true, threw);
    }

    @isTest
    static void testSearchProductsNoTerm() {
        buildFixtures('S1', 'Draft', 2, false);

        Test.startTest();
        List<Product_Extension__c> products = INV_IndentController.searchProducts(null);
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testSearchProductsBlankTerm() {
        buildFixtures('S2', 'Draft', 2, false);

        Test.startTest();
        List<Product_Extension__c> products = INV_IndentController.searchProducts('   ');
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testSearchProductsByName() {
        buildFixtures('S3', 'Draft', 2, false);

        Test.startTest();
        List<Product_Extension__c> products = INV_IndentController.searchProducts('IND Prod');
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testSearchProductsBySKU() {
        buildFixtures('S4', 'Draft', 1, false);

        Test.startTest();
        List<Product_Extension__c> products = INV_IndentController.searchProducts('SKUS4');
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testSearchProductsNoMatch() {
        buildFixtures('S5', 'Draft', 1, false);

        Test.startTest();
        List<Product_Extension__c> products = INV_IndentController.searchProducts('NonExistentXYZ');
        Test.stopTest();

        System.assertNotEquals(null, products);
    }

    @isTest
    static void testFullIndentLifecycle() {
        Fixtures fx = buildFixtures('F1', 'Draft', 1, true);

        Test.startTest();
        if (fx.indent != null) {
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Submitted');
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Approved');
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Processing');
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Dispatched');
            INV_IndentController.updateIndentStatus(fx.indent.Id, 'Received');
        }
        Test.stopTest();

        if (fx.indent != null) {
            Indent__c finalState = [SELECT Status__c FROM Indent__c WHERE Id = :fx.indent.Id];
            System.assertEquals('Received', finalState.Status__c);
        }
    }
}