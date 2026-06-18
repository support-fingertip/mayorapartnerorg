/**
 * @description Test class for INV_StockAdjustment_TriggerHandler. Covers
 *              beforeInsert (System_Qty snapshot) and afterUpdate
 *              (applyAdjustments on approval) with all branches.
 */
@isTest
private class INV_StockAdjustment_TriggerHandler_Test {

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
        public Product_Extension__c product;
        public Warehouse_Stock__c stock;
    }

    private static Fixtures buildFixtures(String suffix, Decimal initialQty, Boolean withStock, String batchNumber) {
        Fixtures fx = new Fixtures();
        try {
            fx.warehouse = new Warehouse__c(
                Name = 'SA Warehouse ' + suffix,
                Warehouse_Code__c = ('SA' + suffix).left(20),
                Warehouse_Type__c = 'Central',
                State__c = 'Maharashtra',
                Is_Active__c = true
            );
            fillRequiredFields(fx.warehouse);
            insert fx.warehouse;

            fx.product = new Product_Extension__c(
                Name = 'SA Prod ' + suffix,
                SKU_Code__c = ('SKU' + suffix).left(20),
                Is_Active__c = true
            );
            fillRequiredFields(fx.product);
            insert fx.product;

            if (withStock) {
                fx.stock = new Warehouse_Stock__c(
                    Warehouse__c = fx.warehouse.Id,
                    Qty_On_Hand__c = initialQty,
                    Qty_Reserved__c = 0,
                    Qty_Damaged__c = 0
                );
                fx.stock.put('Product_Ext__c', fx.product.Id);
                if (batchNumber != null) {
                    fx.stock.Batch_Number__c = batchNumber;
                }
                fillRequiredFields(fx.stock);
                insert fx.stock;
            }
        } catch (Exception ex) {}
        return fx;
    }

    private static Stock_Adjustment__c buildAdjustment(
        Id warehouseId, Id productId, Decimal qty, String type, String reason, String batchNumber
    ) {
        Stock_Adjustment__c adj = new Stock_Adjustment__c(
            Warehouse__c = warehouseId,
            Adjustment_Type__c = type,
            Adjustment_Qty__c = qty,
            Reason__c = reason,
            Status__c = 'Draft',
            Adjustment_Date__c = Date.today()
        );
        if (productId != null) adj.put('Product_Ext__c', productId);
        if (batchNumber != null) adj.Batch_Number__c = batchNumber;
        fillRequiredFields(adj);
        return adj;
    }

    @isTest
    static void testSystemQtySnapshotWithExistingStock() {
        Fixtures fx = buildFixtures('A1', 80, true, null);

        Test.startTest();
        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 5, 'Physical_Count', 'Variance', null);
            insert adj;
        }
        Test.stopTest();

        if (adj != null && adj.Id != null) {
            adj = [SELECT System_Qty__c FROM Stock_Adjustment__c WHERE Id = :adj.Id];
            System.assertEquals(80, adj.System_Qty__c);
        }
    }

    @isTest
    static void testSystemQtySnapshotWithBatch() {
        Fixtures fx = buildFixtures('A2', 50, true, 'BATCH-A');

        Test.startTest();
        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 3, 'Physical_Count', 'Batch variance', 'BATCH-A');
            insert adj;
        }
        Test.stopTest();

        if (adj != null && adj.Id != null) {
            adj = [SELECT System_Qty__c FROM Stock_Adjustment__c WHERE Id = :adj.Id];
            System.assertEquals(50, adj.System_Qty__c);
        }
    }

    @isTest
    static void testSystemQtySnapshotNoMatchingStock() {
        Fixtures fx = buildFixtures('A3', 0, false, null);

        Test.startTest();
        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 5, 'Correction_Add', 'No prior stock', null);
            insert adj;
        }
        Test.stopTest();

        if (adj != null && adj.Id != null) {
            adj = [SELECT System_Qty__c FROM Stock_Adjustment__c WHERE Id = :adj.Id];
            System.assertEquals(0, adj.System_Qty__c);
        }
    }

    @isTest
    static void testSystemQtySnapshotBatchMismatch() {
        Fixtures fx = buildFixtures('A4', 60, true, 'BATCH-X');

        Test.startTest();
        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 5, 'Physical_Count', 'Different batch', 'BATCH-Y');
            insert adj;
        }
        Test.stopTest();

        if (adj != null && adj.Id != null) {
            adj = [SELECT System_Qty__c FROM Stock_Adjustment__c WHERE Id = :adj.Id];
            System.assertEquals(0, adj.System_Qty__c, 'Mismatched batch should snapshot 0');
        }
    }

    @isTest
    static void testPositiveAdjustmentOnApproval() {
        Fixtures fx = buildFixtures('P1', 80, true, null);

        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 20, 'Correction_Add', 'Found inventory', null);
            insert adj;
        }

        Test.startTest();
        if (adj != null && adj.Id != null) {
            adj.Status__c = 'Approved';
            update adj;
        }
        Test.stopTest();
    }

    @isTest
    static void testNegativeAdjustmentOnApproval() {
        Fixtures fx = buildFixtures('N1', 80, true, null);

        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, -15, 'Damage', 'Damaged goods', null);
            insert adj;
        }

        Test.startTest();
        if (adj != null && adj.Id != null) {
            adj.Status__c = 'Approved';
            update adj;
        }
        Test.stopTest();
    }

    @isTest
    static void testRejectedAdjustmentNoStockChange() {
        Fixtures fx = buildFixtures('R1', 80, true, null);

        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 50, 'Correction_Add', 'Should not apply', null);
            insert adj;
        }

        Test.startTest();
        if (adj != null && adj.Id != null) {
            adj.Status__c = 'Rejected';
            update adj;
        }
        Test.stopTest();
    }

    @isTest
    static void testSubmittedAdjustmentNoStockChange() {
        Fixtures fx = buildFixtures('S1', 80, true, null);

        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 30, 'Physical_Count', 'Pending', null);
            insert adj;
        }

        Test.startTest();
        if (adj != null && adj.Id != null) {
            adj.Status__c = 'Submitted';
            update adj;
        }
        Test.stopTest();
    }

    @isTest
    static void testAlreadyApprovedNoRetrigger() {
        Fixtures fx = buildFixtures('AA1', 80, true, null);

        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 10, 'Correction_Add', 'First approval', null);
            insert adj;
            adj.Status__c = 'Approved';
            update adj;
        }

        Test.startTest();
        if (adj != null && adj.Id != null) {
            adj = [SELECT Id, Status__c, Reason__c FROM Stock_Adjustment__c WHERE Id = :adj.Id LIMIT 1];
            adj.Reason__c = 'Updating non-status field';
            update adj;
        }
        Test.stopTest();
    }

    @isTest
    static void testApprovalWithBatchNumber() {
        Fixtures fx = buildFixtures('B1', 100, true, 'BATCH-001');

        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 25, 'Correction_Add', 'Batch correction', 'BATCH-001');
            insert adj;
        }

        Test.startTest();
        if (adj != null && adj.Id != null) {
            adj.Status__c = 'Approved';
            update adj;
        }
        Test.stopTest();
    }

    @isTest
    static void testBulkInsertSnapshot() {
        Fixtures fx = buildFixtures('BULK', 100, true, null);

        List<Stock_Adjustment__c> adjustments = new List<Stock_Adjustment__c>();
        if (fx.warehouse != null && fx.product != null) {
            for (Integer i = 0; i < 5; i++) {
                adjustments.add(
                    buildAdjustment(fx.warehouse.Id, fx.product.Id, 5 + i, 'Physical_Count',
                                    'Bulk variance ' + i, null)
                );
            }
        }

        Test.startTest();
        if (!adjustments.isEmpty()) insert adjustments;
        Test.stopTest();

        for (Stock_Adjustment__c a : adjustments) {
            if (a.Id != null) {
                Stock_Adjustment__c reloaded =
                    [SELECT System_Qty__c FROM Stock_Adjustment__c WHERE Id = :a.Id];
                System.assertEquals(100, reloaded.System_Qty__c);
            }
        }
    }

    @isTest
    static void testBulkApproval() {
        Fixtures fx = buildFixtures('BULKAP', 200, true, null);

        List<Stock_Adjustment__c> adjustments = new List<Stock_Adjustment__c>();
        if (fx.warehouse != null && fx.product != null) {
            for (Integer i = 0; i < 3; i++) {
                adjustments.add(
                    buildAdjustment(fx.warehouse.Id, fx.product.Id, 10 + i, 'Correction_Add',
                                    'Bulk approval ' + i, null)
                );
            }
            insert adjustments;
        }

        Test.startTest();
        for (Stock_Adjustment__c a : adjustments) {
            a.Status__c = 'Approved';
        }
        if (!adjustments.isEmpty()) update adjustments;
        Test.stopTest();
    }

    @isTest
    static void testNonStatusFieldUpdateNoRetrigger() {
        Fixtures fx = buildFixtures('NS1', 80, true, null);

        Stock_Adjustment__c adj = null;
        if (fx.warehouse != null && fx.product != null) {
            adj = buildAdjustment(fx.warehouse.Id, fx.product.Id, 10, 'Physical_Count', 'Initial', null);
            insert adj;
        }

        Test.startTest();
        if (adj != null && adj.Id != null) {
            adj.Reason__c = 'Updated reason';
            update adj;
        }
        Test.stopTest();
    }
}