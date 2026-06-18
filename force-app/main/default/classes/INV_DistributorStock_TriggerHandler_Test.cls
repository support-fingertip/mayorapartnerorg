/**
 * @description Test class for INV_DistributorStock_TriggerHandler.
 *              Covers closing stock calculation, current flag management,
 *              beforeInsert / beforeUpdate / afterInsert / afterUpdate paths.
 */
@isTest
private class INV_DistributorStock_TriggerHandler_Test {

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

    @TestSetup
    static void setupTestData() {
        Territory_Master__c territory = new Territory_Master__c(
            Name = 'DS Territory',
            Territory_Code__c = 'DS-' + String.valueOf(DateTime.now().getTime()).right(6),
            State__c = 'Maharashtra',
            City__c = 'Mumbai',
            Is_Active__c = true
        );
        fillRequiredFields(territory);
        insert territory;

        Account testAccount = new Account(
            Name = 'Test Distributor',
            Outlet_Type__c = 'Grocery',
            Channel__c = 'GT',
            Territory__c = territory.Id,
            Is_Active__c = true
        );
        Map<String, Schema.RecordTypeInfo> rtMap =
            Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        if (rtMap.containsKey('Distributor')) {
            testAccount.RecordTypeId = rtMap.get('Distributor').getRecordTypeId();
        }
        fillRequiredFields(testAccount);
        insert testAccount;

        Product_Extension__c testProductExt = new Product_Extension__c(
            Name = 'Test FMCG Product Ext',
            Is_Active__c = true
        );
        fillRequiredFields(testProductExt);
        insert testProductExt;
    }

    private static Distributor_Stock__c buildStock(Id accountId, Id productId, Decimal opening, Boolean current, Date stockDate) {
        Distributor_Stock__c s = new Distributor_Stock__c(
            Account__c = accountId,
            Product_Ext__c = productId,
            Stock_Date__c = stockDate,
            Opening_Stock__c = opening,
            Is_Current__c = current
        );
        fillRequiredFields(s);
        return s;
    }

    @isTest
    static void testClosingStockCalculation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock = new Distributor_Stock__c(
            Account__c = acc.Id,
            Product_Ext__c = prod.Id,
            Stock_Date__c = Date.today(),
            Opening_Stock__c = 100,
            Received_Qty__c = 50,
            Sold_Qty__c = 30,
            Damaged_Qty__c = 5,
            Is_Current__c = true
        );
        fillRequiredFields(stock);

        Test.startTest();
        insert stock;
        Test.stopTest();

        stock = [SELECT Closing_Stock__c FROM Distributor_Stock__c WHERE Id = :stock.Id];
        System.assertEquals(115, stock.Closing_Stock__c,
            'Closing = 100 + 50 - 30 - 5 = 115');
    }

    @isTest
    static void testClosingStockWithAllNullQuantities() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock = new Distributor_Stock__c(
            Account__c = acc.Id,
            Product_Ext__c = prod.Id,
            Stock_Date__c = Date.today()
        );
        fillRequiredFields(stock);

        Test.startTest();
        insert stock;
        Test.stopTest();

        stock = [SELECT Closing_Stock__c FROM Distributor_Stock__c WHERE Id = :stock.Id];
        System.assertEquals(0, stock.Closing_Stock__c, 'Null quantities should default to 0');
    }

    @isTest
    static void testClosingStockWithOpeningOnly() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock = buildStock(acc.Id, prod.Id, 100, false, Date.today());

        Test.startTest();
        insert stock;
        Test.stopTest();

        stock = [SELECT Closing_Stock__c FROM Distributor_Stock__c WHERE Id = :stock.Id];
        System.assertEquals(100, stock.Closing_Stock__c);
    }

    @isTest
    static void testClosingStockRecalculationOnQuantityChange() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock = new Distributor_Stock__c(
            Account__c = acc.Id,
            Product_Ext__c = prod.Id,
            Stock_Date__c = Date.today(),
            Opening_Stock__c = 100,
            Received_Qty__c = 50,
            Sold_Qty__c = 30,
            Damaged_Qty__c = 5,
            Is_Current__c = true
        );
        fillRequiredFields(stock);
        insert stock;

        Test.startTest();
        stock.Sold_Qty__c = 60;
        update stock;
        Test.stopTest();

        stock = [SELECT Closing_Stock__c FROM Distributor_Stock__c WHERE Id = :stock.Id];
        System.assertEquals(85, stock.Closing_Stock__c,
            'Closing = 100 + 50 - 60 - 5 = 85');
    }

    @isTest
    static void testNoRecalculationWhenNoQuantityChange() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock = new Distributor_Stock__c(
            Account__c = acc.Id,
            Product_Ext__c = prod.Id,
            Stock_Date__c = Date.today(),
            Opening_Stock__c = 100,
            Received_Qty__c = 50,
            Sold_Qty__c = 30,
            Damaged_Qty__c = 5,
            Is_Current__c = false
        );
        fillRequiredFields(stock);
        insert stock;

        Decimal originalClosing = [SELECT Closing_Stock__c FROM Distributor_Stock__c WHERE Id = :stock.Id].Closing_Stock__c;

        Test.startTest();
        stock.Batch_No__c = 'BATCH-001';
        update stock;
        Test.stopTest();

        stock = [SELECT Closing_Stock__c FROM Distributor_Stock__c WHERE Id = :stock.Id];
        System.assertEquals(originalClosing, stock.Closing_Stock__c,
            'Closing stock should not change when quantities are unchanged');
    }

    @isTest
    static void testUnmarkPreviousCurrentOnInsert() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock1 = buildStock(acc.Id, prod.Id, 50, true, Date.today().addDays(-1));
        insert stock1;

        Test.startTest();
        Distributor_Stock__c stock2 = buildStock(acc.Id, prod.Id, 60, true, Date.today());
        insert stock2;
        Test.stopTest();

        stock1 = [SELECT Is_Current__c FROM Distributor_Stock__c WHERE Id = :stock1.Id];
        stock2 = [SELECT Is_Current__c FROM Distributor_Stock__c WHERE Id = :stock2.Id];

        System.assertEquals(false, stock1.Is_Current__c);
        System.assertEquals(true, stock2.Is_Current__c);
    }

    @isTest
    static void testInsertNonCurrentDoesNotTriggerUnmark() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock1 = buildStock(acc.Id, prod.Id, 50, true, Date.today().addDays(-1));
        insert stock1;

        Test.startTest();
        Distributor_Stock__c stock2 = buildStock(acc.Id, prod.Id, 60, false, Date.today());
        insert stock2;
        Test.stopTest();

        stock1 = [SELECT Is_Current__c FROM Distributor_Stock__c WHERE Id = :stock1.Id];
        System.assertEquals(true, stock1.Is_Current__c,
            'Original current entry should remain current when new entry is non-current');
    }

    @isTest
    static void testMarkAsCurrentOnUpdateUnmarksPrevious() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock1 = buildStock(acc.Id, prod.Id, 50, true, Date.today().addDays(-2));
        insert stock1;

        Distributor_Stock__c stock2 = buildStock(acc.Id, prod.Id, 60, false, Date.today().addDays(-1));
        insert stock2;

        Test.startTest();
        stock2.Is_Current__c = true;
        update stock2;
        Test.stopTest();

        stock1 = [SELECT Is_Current__c FROM Distributor_Stock__c WHERE Id = :stock1.Id];
        stock2 = [SELECT Is_Current__c FROM Distributor_Stock__c WHERE Id = :stock2.Id];

        System.assertEquals(false, stock1.Is_Current__c,
            'Previous current should be unmarked when other entry becomes current');
        System.assertEquals(true, stock2.Is_Current__c);
    }

    @isTest
    static void testUpdateAlreadyCurrentDoesNotRetrigger() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Distributor_Stock__c stock = buildStock(acc.Id, prod.Id, 50, true, Date.today());
        insert stock;

        Test.startTest();
        stock.Batch_No__c = 'NEW-BATCH';
        update stock;
        Test.stopTest();

        stock = [SELECT Is_Current__c FROM Distributor_Stock__c WHERE Id = :stock.Id];
        System.assertEquals(true, stock.Is_Current__c);
    }

    @isTest
    static void testDifferentProductsCoexistAsCurrent() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prodA = [SELECT Id FROM Product_Extension__c LIMIT 1];

        Product_Extension__c prodB = new Product_Extension__c(
            Name = 'Test FMCG Product B Ext',
            Is_Active__c = true
        );
        fillRequiredFields(prodB);
        insert prodB;

        Distributor_Stock__c stockA = buildStock(acc.Id, prodA.Id, 100, true, Date.today());
        insert stockA;

        Test.startTest();
        Distributor_Stock__c stockB = buildStock(acc.Id, prodB.Id, 100, true, Date.today());
        insert stockB;
        Test.stopTest();

        stockA = [SELECT Is_Current__c FROM Distributor_Stock__c WHERE Id = :stockA.Id];
        stockB = [SELECT Is_Current__c FROM Distributor_Stock__c WHERE Id = :stockB.Id];

        System.assertEquals(true, stockA.Is_Current__c,
            'Different product entries can both be current for the same account');
        System.assertEquals(true, stockB.Is_Current__c);
    }

    @isTest
    static void testBulkInsert() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        List<Distributor_Stock__c> stockList = new List<Distributor_Stock__c>();
        for (Integer i = 0; i < 50; i++) {
            Distributor_Stock__c s = new Distributor_Stock__c(
                Account__c = acc.Id,
                Product_Ext__c = prod.Id,
                Stock_Date__c = Date.today().addDays(-i),
                Opening_Stock__c = 100 + i,
                Received_Qty__c = 50,
                Sold_Qty__c = 20,
                Damaged_Qty__c = 2,
                Is_Current__c = (i == 0)
            );
            fillRequiredFields(s);
            stockList.add(s);
        }

        Test.startTest();
        insert stockList;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Distributor_Stock__c WHERE Account__c = :acc.Id];
        System.assertEquals(50, count);
    }

    @isTest
    static void testBulkUpdate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product_Extension__c prod = [SELECT Id FROM Product_Extension__c LIMIT 1];

        List<Distributor_Stock__c> stockList = new List<Distributor_Stock__c>();
        for (Integer i = 0; i < 20; i++) {
            Distributor_Stock__c s = buildStock(acc.Id, prod.Id, 100 + i, false, Date.today().addDays(-i));
            s.Received_Qty__c = 10;
            stockList.add(s);
        }
        insert stockList;

        for (Distributor_Stock__c s : stockList) s.Received_Qty__c = 25;

        Test.startTest();
        update stockList;
        Test.stopTest();

        List<Distributor_Stock__c> results = [
            SELECT Closing_Stock__c, Opening_Stock__c
            FROM Distributor_Stock__c
            WHERE Account__c = :acc.Id
        ];
        for (Distributor_Stock__c s : results) {
            System.assertEquals(s.Opening_Stock__c + 25, s.Closing_Stock__c);
        }
    }
}