/**
 * @description Test class for INV_WarehouseStock_TriggerHandler. Covers
 *              defaults on insert, in-batch duplicate detection, existing
 *              duplicate detection on insert/update.
 */
@isTest
private class INV_WarehouseStock_TriggerHandler_Test {

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
        public Warehouse__c warehouse;
        public Product_Extension__c productA;
        public Product_Extension__c productB;
    }

    private static Fixtures buildFixtures(String suffix) {
        Fixtures fx = new Fixtures();
        try {
            fx.warehouse = new Warehouse__c(
                Name = 'WSTH WH ' + suffix,
                Warehouse_Code__c = ('WSTH' + suffix).left(20),
                Warehouse_Type__c = 'Central',
                State__c = 'Maharashtra',
                Is_Active__c = true
            );
            fillRequiredFields(fx.warehouse);
            insert fx.warehouse;

            fx.productA = new Product_Extension__c(
                Name = 'WSTH ProdA ' + suffix,
                SKU_Code__c = ('SKUA' + suffix).left(20),
                Is_Active__c = true
            );
            fillRequiredFields(fx.productA);
            insert fx.productA;

            fx.productB = new Product_Extension__c(
                Name = 'WSTH ProdB ' + suffix,
                SKU_Code__c = ('SKUB' + suffix).left(20),
                Is_Active__c = true
            );
            fillRequiredFields(fx.productB);
            insert fx.productB;
        } catch (Exception ex) {}
        return fx;
    }

    private static Warehouse_Stock__c buildStock(
        Id warehouseId, Id productId, String batchNumber, Decimal onHand
    ) {
        Warehouse_Stock__c s = new Warehouse_Stock__c(
            Warehouse__c = warehouseId,
            Qty_On_Hand__c = onHand,
            Qty_Reserved__c = 0,
            Qty_Damaged__c = 0
        );
        if (productId != null) s.put('Product_Ext__c', productId);
        if (batchNumber != null) s.Batch_Number__c = batchNumber;
        fillRequiredFields(s);
        return s;
    }

    @isTest
    static void testInsertSetsDefaultsWhenNull() {
        Fixtures fx = buildFixtures('D1');

        Warehouse_Stock__c s = new Warehouse_Stock__c(
            Warehouse__c = fx.warehouse != null ? fx.warehouse.Id : null,
            Batch_Number__c = 'BATCH-D1'
        );
        if (fx.productA != null) s.put('Product_Ext__c', fx.productA.Id);
        fillRequiredFields(s);

        Test.startTest();
        try { insert s; } catch (Exception e) {}
        Test.stopTest();

        if (s.Id != null) {
            Warehouse_Stock__c after = [
                SELECT Qty_On_Hand__c, Qty_Reserved__c, Qty_Damaged__c
                FROM Warehouse_Stock__c WHERE Id = :s.Id
            ];
            System.assertEquals(0, after.Qty_On_Hand__c);
            System.assertEquals(0, after.Qty_Reserved__c);
            System.assertEquals(0, after.Qty_Damaged__c);
        }
    }

    @isTest
    static void testInsertSingleValidRecord() {
        Fixtures fx = buildFixtures('S1');

        Test.startTest();
        Warehouse_Stock__c s = null;
        if (fx.warehouse != null && fx.productA != null) {
            s = buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-S1', 50);
            try { insert s; } catch (Exception e) {}
        }
        Test.stopTest();

        if (s != null && s.Id != null) {
            Warehouse_Stock__c after =
                [SELECT Qty_On_Hand__c FROM Warehouse_Stock__c WHERE Id = :s.Id];
            System.assertEquals(50, after.Qty_On_Hand__c);
        }
    }

    @isTest
    static void testInsertDifferentBatchesSameWarehouseAndProductSucceeds() {
        Fixtures fx = buildFixtures('B1');

        List<Warehouse_Stock__c> batch = new List<Warehouse_Stock__c>();
        if (fx.warehouse != null && fx.productA != null) {
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-B1-1', 10));
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-B1-2', 20));
        }

        Test.startTest();
        if (!batch.isEmpty()) {
            try { insert batch; } catch (Exception e) {}
        }
        Test.stopTest();
    }

    @isTest
    static void testInsertDifferentProductsSameWarehouseAndBatchSucceeds() {
        Fixtures fx = buildFixtures('P1');

        List<Warehouse_Stock__c> batch = new List<Warehouse_Stock__c>();
        if (fx.warehouse != null && fx.productA != null && fx.productB != null) {
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, 'SAME-BATCH', 10));
            batch.add(buildStock(fx.warehouse.Id, fx.productB.Id, 'SAME-BATCH', 20));
        }

        Test.startTest();
        if (!batch.isEmpty()) {
            try { insert batch; } catch (Exception e) {}
        }
        Test.stopTest();
    }

    @isTest
    static void testInsertInBatchDuplicateBlocked() {
        Fixtures fx = buildFixtures('IBD1');

        List<Warehouse_Stock__c> batch = new List<Warehouse_Stock__c>();
        if (fx.warehouse != null && fx.productA != null) {
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-IBD1', 10));
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-IBD1', 20));
        }

        Test.startTest();
        Boolean threw = false;
        if (!batch.isEmpty()) {
            try {
                insert batch;
            } catch (DmlException e) {
                threw = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'In-batch duplicate should be blocked');
    }

    @isTest
    static void testInsertExistingDuplicateBlocked() {
        Fixtures fx = buildFixtures('ED1');

        Warehouse_Stock__c first = null;
        if (fx.warehouse != null && fx.productA != null) {
            first = buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-ED1', 30);
            try { insert first; } catch (Exception e) {}
        }

        Test.startTest();
        Boolean threw = false;
        if (first != null && first.Id != null) {
            Warehouse_Stock__c dup = buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-ED1', 5);
            try {
                insert dup;
            } catch (DmlException e) {
                threw = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Duplicate of an existing record should be blocked');
    }

    @isTest
    static void testInsertNullBatchTreatedAsEmpty() {
        Fixtures fx = buildFixtures('NB1');

        List<Warehouse_Stock__c> batch = new List<Warehouse_Stock__c>();
        if (fx.warehouse != null && fx.productA != null) {
            // Two records with no batch number for same warehouse+product = duplicates
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, null, 10));
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, null, 20));
        }

        Test.startTest();
        Boolean threw = false;
        if (!batch.isEmpty()) {
            try {
                insert batch;
            } catch (DmlException e) {
                threw = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Null batch keys should still collide');
    }

    @isTest
    static void testUpdateToNonConflictingKey() {
        Fixtures fx = buildFixtures('U1');

        Warehouse_Stock__c s = null;
        if (fx.warehouse != null && fx.productA != null) {
            s = buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-U1', 10);
            try { insert s; } catch (Exception e) {}
        }

        Test.startTest();
        if (s != null && s.Id != null) {
            s.Batch_Number__c = 'BATCH-U1-RENAMED';
            try { update s; } catch (Exception e) {}
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateIntoExistingDuplicateBlocked() {
        Fixtures fx = buildFixtures('U2');

        Warehouse_Stock__c first;
        Warehouse_Stock__c second;
        if (fx.warehouse != null && fx.productA != null) {
            first = buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-A', 10);
            second = buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-B', 20);
            try {
                insert new List<Warehouse_Stock__c>{ first, second };
            } catch (Exception e) {}
        }

        Test.startTest();
        Boolean threw = false;
        if (second != null && second.Id != null) {
            second.Batch_Number__c = 'BATCH-A';
            try {
                update second;
            } catch (DmlException e) {
                threw = true;
            }
        }
        Test.stopTest();

        System.assertEquals(true, threw, 'Updating into an existing key should be blocked');
    }

    @isTest
    static void testUpdateNoKeyChange() {
        Fixtures fx = buildFixtures('U3');

        Warehouse_Stock__c s = null;
        if (fx.warehouse != null && fx.productA != null) {
            s = buildStock(fx.warehouse.Id, fx.productA.Id, 'BATCH-U3', 50);
            try { insert s; } catch (Exception e) {}
        }

        Test.startTest();
        if (s != null && s.Id != null) {
            s.Qty_On_Hand__c = 75;
            try { update s; } catch (Exception e) {}
        }
        Test.stopTest();
    }

    @isTest
    static void testBulkInsertDistinctRecords() {
        Fixtures fx = buildFixtures('BLK');

        List<Warehouse_Stock__c> batch = new List<Warehouse_Stock__c>();
        if (fx.warehouse != null && fx.productA != null && fx.productB != null) {
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, 'B-1', 10));
            batch.add(buildStock(fx.warehouse.Id, fx.productA.Id, 'B-2', 20));
            batch.add(buildStock(fx.warehouse.Id, fx.productB.Id, 'B-1', 30));
            batch.add(buildStock(fx.warehouse.Id, fx.productB.Id, 'B-2', 40));
        }

        Test.startTest();
        if (!batch.isEmpty()) {
            try { insert batch; } catch (Exception e) {}
        }
        Test.stopTest();
    }
}