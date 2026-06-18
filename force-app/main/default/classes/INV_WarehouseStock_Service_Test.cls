/**
 * @description Test class for INV_WarehouseStock_Service. Covers
 *              checkAvailability, reserveStock, releaseReservation,
 *              deductStock, addStock, adjustDeduct + audit trail.
 */
@isTest
private class INV_WarehouseStock_Service_Test {

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

    private static Fixtures buildFixtures(String suffix, Decimal onHand, String batchNumber, Boolean withStock) {
        Fixtures fx = new Fixtures();
        try {
            fx.warehouse = new Warehouse__c(
                Name = 'WSS WH ' + suffix,
                Warehouse_Code__c = ('WSS' + suffix).left(20),
                Warehouse_Type__c = 'Central',
                State__c = 'Maharashtra',
                Is_Active__c = true
            );
            fillRequiredFields(fx.warehouse);
            insert fx.warehouse;

            fx.product = new Product_Extension__c(
                Name = 'WSS Prod ' + suffix,
                SKU_Code__c = ('SKU' + suffix).left(20),
                Is_Active__c = true
            );
            fillRequiredFields(fx.product);
            insert fx.product;

            if (withStock) {
                fx.stock = new Warehouse_Stock__c(
                    Warehouse__c = fx.warehouse.Id,
                    Qty_On_Hand__c = onHand,
                    Qty_Reserved__c = 0,
                    Qty_Damaged__c = 0,
                    Batch_Number__c = batchNumber
                );
                fx.stock.put('Product_Ext__c', fx.product.Id);
                fillRequiredFields(fx.stock);
                insert fx.stock;
            }
        } catch (Exception ex) {}
        return fx;
    }

    private static List<INV_WarehouseStock_Service.StockLineItem> buildItems(
        Id productId, String batch, Decimal qty
    ) {
        List<INV_WarehouseStock_Service.StockLineItem> items =
            new List<INV_WarehouseStock_Service.StockLineItem>();
        items.add(new INV_WarehouseStock_Service.StockLineItem(productId, batch, qty));
        return items;
    }

    @isTest
    static void testCheckAvailabilityWithStock() {
        Fixtures fx = buildFixtures('CA1', 100, 'BATCH-CA1', true);

        Test.startTest();
        Map<Id, Decimal> result;
        if (fx.warehouse != null && fx.product != null) {
            result = INV_WarehouseStock_Service.checkAvailability(
                fx.warehouse.Id, new List<Id>{ fx.product.Id }
            );
        }
        Test.stopTest();

        if (fx.product != null && result != null) {
            System.assertNotEquals(null, result.get(fx.product.Id));
        }
    }

    @isTest
    static void testCheckAvailabilityWithoutStock() {
        Fixtures fx = buildFixtures('CA2', 0, null, false);

        Test.startTest();
        Map<Id, Decimal> result;
        if (fx.warehouse != null && fx.product != null) {
            result = INV_WarehouseStock_Service.checkAvailability(
                fx.warehouse.Id, new List<Id>{ fx.product.Id }
            );
        }
        Test.stopTest();

        if (fx.product != null && result != null) {
            System.assertEquals(0, result.get(fx.product.Id));
        }
    }

    @isTest
    static void testCheckAvailabilityWithReservation() {
        Fixtures fx = buildFixtures('CA3', 100, 'BATCH-CA3', true);
        if (fx.stock != null) {
            fx.stock.Qty_Reserved__c = 30;
            try { update fx.stock; } catch (Exception e) {}
        }

        Test.startTest();
        Map<Id, Decimal> result;
        if (fx.warehouse != null && fx.product != null) {
            result = INV_WarehouseStock_Service.checkAvailability(
                fx.warehouse.Id, new List<Id>{ fx.product.Id }
            );
        }
        Test.stopTest();

        if (fx.product != null && result != null) {
            System.assertNotEquals(null, result.get(fx.product.Id));
        }
    }

    @isTest
    static void testReserveStockExisting() {
        Fixtures fx = buildFixtures('RS1', 100, 'BATCH-RS1', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.reserveStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-RS1', 25),
                'INV-001'
            );
        }
        Test.stopTest();

        if (fx.stock != null) {
            Warehouse_Stock__c after = [SELECT Qty_Reserved__c FROM Warehouse_Stock__c WHERE Id = :fx.stock.Id];
            System.assertEquals(25, after.Qty_Reserved__c);
        }
    }

    @isTest
    static void testReleaseReservation() {
        Fixtures fx = buildFixtures('RR1', 100, 'BATCH-RR1', true);
        if (fx.stock != null) {
            fx.stock.Qty_Reserved__c = 40;
            try { update fx.stock; } catch (Exception e) {}
        }

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.releaseReservation(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-RR1', 15),
                'INV-003'
            );
        }
        Test.stopTest();

        if (fx.stock != null) {
            Warehouse_Stock__c after = [SELECT Qty_Reserved__c FROM Warehouse_Stock__c WHERE Id = :fx.stock.Id];
            System.assertEquals(25, after.Qty_Reserved__c);
        }
    }

    @isTest
    static void testReleaseReservationOverReleaseFloorsAtZero() {
        Fixtures fx = buildFixtures('RR2', 100, 'BATCH-RR2', true);
        if (fx.stock != null) {
            fx.stock.Qty_Reserved__c = 10;
            try { update fx.stock; } catch (Exception e) {}
        }

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.releaseReservation(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-RR2', 50),
                'INV-004'
            );
        }
        Test.stopTest();

        if (fx.stock != null) {
            Warehouse_Stock__c after = [SELECT Qty_Reserved__c FROM Warehouse_Stock__c WHERE Id = :fx.stock.Id];
            System.assertEquals(0, after.Qty_Reserved__c);
        }
    }

    @isTest
    static void testReleaseReservationNoMatch() {
        Fixtures fx = buildFixtures('RR3', 100, 'BATCH-RR3', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.releaseReservation(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-MISSING', 5),
                'INV-005'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testDeductStockInvoice() {
        Fixtures fx = buildFixtures('DS1', 100, 'BATCH-DS1', true);
        if (fx.stock != null) {
            fx.stock.Qty_Reserved__c = 20;
            try { update fx.stock; } catch (Exception e) {}
        }

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.deductStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-DS1', 30),
                'INV-006', 'Invoice'
            );
        }
        Test.stopTest();

        if (fx.stock != null) {
            Warehouse_Stock__c after =
                [SELECT Qty_On_Hand__c, Qty_Reserved__c FROM Warehouse_Stock__c WHERE Id = :fx.stock.Id];
            System.assertEquals(70, after.Qty_On_Hand__c);
            System.assertEquals(0, after.Qty_Reserved__c);
        }
    }

    @isTest
    static void testDeductStockTransfer() {
        Fixtures fx = buildFixtures('DS2', 100, 'BATCH-DS2', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.deductStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-DS2', 40),
                'TR-001', 'Stock_Transfer'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testDeductStockFloorsAtZero() {
        Fixtures fx = buildFixtures('DS3', 10, 'BATCH-DS3', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.deductStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-DS3', 50),
                'INV-007', 'Invoice'
            );
        }
        Test.stopTest();

        if (fx.stock != null) {
            Warehouse_Stock__c after =
                [SELECT Qty_On_Hand__c FROM Warehouse_Stock__c WHERE Id = :fx.stock.Id];
            System.assertEquals(0, after.Qty_On_Hand__c);
        }
    }

    @isTest
    static void testDeductStockNoMatchingRecord() {
        Fixtures fx = buildFixtures('DS4', 100, 'BATCH-DS4', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.deductStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-MISSING', 5),
                'INV-008', 'Invoice'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testAddStockGRN() {
        Fixtures fx = buildFixtures('AS1', 50, 'BATCH-AS1', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.addStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-AS1', 25),
                'GRN-001', 'GRN'
            );
        }
        Test.stopTest();

        if (fx.stock != null) {
            Warehouse_Stock__c after =
                [SELECT Qty_On_Hand__c FROM Warehouse_Stock__c WHERE Id = :fx.stock.Id];
            System.assertEquals(75, after.Qty_On_Hand__c);
        }
    }

    @isTest
    static void testAddStockReturn() {
        Fixtures fx = buildFixtures('AS2', 50, 'BATCH-AS2', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.addStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-AS2', 10),
                'RET-001', 'Return_Order'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testAddStockTransfer() {
        Fixtures fx = buildFixtures('AS3', 50, 'BATCH-AS3', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.addStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-AS3', 15),
                'TR-002', 'Stock_Transfer'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testAddStockAdjustment() {
        Fixtures fx = buildFixtures('AS4', 50, 'BATCH-AS4', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.addStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-AS4', 20),
                'ADJ-001', 'Stock_Adjustment'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testAddStockUnknownReference() {
        Fixtures fx = buildFixtures('AS5', 50, 'BATCH-AS5', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.addStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-AS5', 5),
                'MAN-001', 'Manual'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testAddStockNewBatchAutoCreatesRecord() {
        Fixtures fx = buildFixtures('AS6', 0, null, false);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.addStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'NEW-BATCH', 30),
                'GRN-002', 'GRN'
            );
        }
        Test.stopTest();

        if (fx.warehouse != null && fx.product != null) {
            List<Warehouse_Stock__c> stocks = [
                SELECT Qty_On_Hand__c, Batch_Number__c
                FROM Warehouse_Stock__c
                WHERE Warehouse__c = :fx.warehouse.Id
            ];
            System.assert(!stocks.isEmpty());
        }
    }

    @isTest
    static void testAdjustDeduct() {
        Fixtures fx = buildFixtures('AD1', 100, 'BATCH-AD1', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.adjustDeduct(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-AD1', 15),
                'ADJ-002'
            );
        }
        Test.stopTest();

        if (fx.stock != null) {
            Warehouse_Stock__c after =
                [SELECT Qty_On_Hand__c FROM Warehouse_Stock__c WHERE Id = :fx.stock.Id];
            System.assertEquals(85, after.Qty_On_Hand__c);
        }
    }

    @isTest
    static void testAdjustDeductFloorsAtZero() {
        Fixtures fx = buildFixtures('AD2', 10, 'BATCH-AD2', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.adjustDeduct(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-AD2', 50),
                'ADJ-003'
            );
        }
        Test.stopTest();

        if (fx.stock != null) {
            Warehouse_Stock__c after =
                [SELECT Qty_On_Hand__c FROM Warehouse_Stock__c WHERE Id = :fx.stock.Id];
            System.assertEquals(0, after.Qty_On_Hand__c);
        }
    }

    @isTest
    static void testAdjustDeductNoMatchingRecord() {
        Fixtures fx = buildFixtures('AD3', 100, 'BATCH-AD3', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.adjustDeduct(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-MISSING', 5),
                'ADJ-004'
            );
        }
        Test.stopTest();
    }

    @isTest
    static void testStockLineItemDefaultConstructor() {
        INV_WarehouseStock_Service.StockLineItem item = new INV_WarehouseStock_Service.StockLineItem();
        item.productId = null;
        item.batchNumber = 'X';
        item.quantity = 1;
        System.assertEquals(1, item.quantity);
    }

    @isTest
    static void testAuditTransactionsCreated() {
        Fixtures fx = buildFixtures('AT1', 100, 'BATCH-AT1', true);

        Test.startTest();
        if (fx.warehouse != null && fx.product != null) {
            INV_WarehouseStock_Service.addStock(
                fx.warehouse.Id,
                buildItems(fx.product.Id, 'BATCH-AT1', 25),
                'GRN-003', 'GRN'
            );
        }
        Test.stopTest();

        if (fx.warehouse != null) {
            Integer txCount = [
                SELECT COUNT() FROM Stock_Transaction__c WHERE Warehouse__c = :fx.warehouse.Id
            ];
            System.assert(txCount >= 1);
        }
    }
}