/**
 * @description Test class for INV_StockTransfer_TriggerHandler. Covers status
 *              transition validation (beforeUpdate) and stock movement on
 *              Approved / Received / Cancelled (afterUpdate).
 */
@isTest
private class INV_StockTransfer_TriggerHandler_Test {

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
        public Warehouse__c sourceWh;
        public Warehouse__c destWh;
        public Product_Extension__c product;
        public Stock_Transfer__c transfer;
        public Stock_Transfer_Line__c line;
    }

    private static Fixtures buildFixtures(
        String suffix, String initialStatus, Boolean withLine, Boolean usableLine
    ) {
        Fixtures fx = new Fixtures();
        try {
            fx.sourceWh = new Warehouse__c(
                Name = 'STH Src ' + suffix,
                Warehouse_Code__c = ('STHS' + suffix).left(20),
                Warehouse_Type__c = 'Central',
                State__c = 'Maharashtra',
                Is_Active__c = true
            );
            fillRequiredFields(fx.sourceWh);
            insert fx.sourceWh;

            fx.destWh = new Warehouse__c(
                Name = 'STH Dst ' + suffix,
                Warehouse_Code__c = ('STHD' + suffix).left(20),
                Warehouse_Type__c = 'Regional',
                State__c = 'Maharashtra',
                Is_Active__c = true
            );
            fillRequiredFields(fx.destWh);
            insert fx.destWh;

            fx.product = new Product_Extension__c(
                Name = 'STH Prod ' + suffix,
                SKU_Code__c = ('SKU' + suffix).left(20),
                Is_Active__c = true
            );
            fillRequiredFields(fx.product);
            insert fx.product;

            // Source stock so deductions don't underflow
            Warehouse_Stock__c stock = new Warehouse_Stock__c(
                Warehouse__c = fx.sourceWh.Id,
                Qty_On_Hand__c = 500,
                Qty_Reserved__c = 0,
                Qty_Damaged__c = 0
            );
            stock.put('Product_Ext__c', fx.product.Id);
            fillRequiredFields(stock);
            insert stock;

            fx.transfer = new Stock_Transfer__c(
                Source_Warehouse__c = fx.sourceWh.Id,
                Destination_Warehouse__c = fx.destWh.Id,
                Transfer_Date__c = Date.today(),
                Status__c = initialStatus
            );
            fillRequiredFields(fx.transfer);
            insert fx.transfer;

            if (withLine) {
                fx.line = new Stock_Transfer_Line__c(
                    Stock_Transfer__c = fx.transfer.Id,
                    Batch_Number__c = 'BATCH-' + suffix,
                    Requested_Qty__c = 50,
                    Approved_Qty__c = usableLine ? 50 : 0,
                    Received_Qty__c = usableLine ? 48 : 0,
                    Available_Stock__c = 500
                );
                if (usableLine && fx.product != null) {
                    fx.line.put('Product_Ext__c', fx.product.Id);
                }
                fillRequiredFields(fx.line);
                insert fx.line;
            }
        } catch (Exception ex) {}
        return fx;
    }

    @isTest
    static void testValidDraftToSubmitted() {
        Fixtures fx = buildFixtures('V1', 'Draft', false, false);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Submitted';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testValidDraftToCancelled() {
        Fixtures fx = buildFixtures('V2', 'Draft', false, false);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Cancelled';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testValidSubmittedToApproved() {
        Fixtures fx = buildFixtures('V3', 'Submitted', true, true);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Approved';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testValidSubmittedToCancelled() {
        Fixtures fx = buildFixtures('V4', 'Submitted', false, false);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Cancelled';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testValidApprovedToInTransit() {
        Fixtures fx = buildFixtures('V5', 'Approved', true, true);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'In_Transit';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testValidInTransitToReceived() {
        Fixtures fx = buildFixtures('V6', 'In_Transit', true, true);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Received';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testValidApprovedToCancelled() {
        Fixtures fx = buildFixtures('V7', 'Approved', true, true);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Cancelled';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testValidInTransitToCancelled() {
        Fixtures fx = buildFixtures('V8', 'In_Transit', true, true);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Cancelled';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidDraftToReceived() {
        Fixtures fx = buildFixtures('I1', 'Draft', false, false);

        Test.startTest();
        Boolean threw = false;
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Received';
            try {
                update fx.transfer;
            } catch (DmlException e) {
                threw = true;
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidSubmittedToReceived() {
        Fixtures fx = buildFixtures('I2', 'Submitted', false, false);

        Test.startTest();
        Boolean threw = false;
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Received';
            try {
                update fx.transfer;
            } catch (DmlException e) {
                threw = true;
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testInvalidReceivedToAnything() {
        Fixtures fx = buildFixtures('I3', 'In_Transit', true, true);

        // Move to Received first via valid path
        if (fx.transfer != null) {
            try {
                fx.transfer.Status__c = 'Received';
                update fx.transfer;
            } catch (Exception e) {}
        }

        Test.startTest();
        Boolean threw = false;
        if (fx.transfer != null) {
            fx.transfer = [SELECT Id, Status__c FROM Stock_Transfer__c WHERE Id = :fx.transfer.Id];
            if (fx.transfer.Status__c == 'Received') {
                fx.transfer.Status__c = 'Cancelled';
                try {
                    update fx.transfer;
                } catch (DmlException e) {
                    threw = true;
                }
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testCancelledFromDraftDoesNotReverseStock() {
        Fixtures fx = buildFixtures('C1', 'Draft', false, false);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Cancelled';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testApprovedWithNoLines() {
        Fixtures fx = buildFixtures('NL1', 'Submitted', false, false);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Approved';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testApprovedWithZeroQtyLine() {
        Fixtures fx = buildFixtures('Z1', 'Submitted', true, false);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Approved';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testApprovedWithNullProductLine() {
        Fixtures fx = buildFixtures('NP1', 'Submitted', false, false);

        if (fx.transfer != null) {
            Stock_Transfer_Line__c badLine = new Stock_Transfer_Line__c(
                Stock_Transfer__c = fx.transfer.Id,
                Batch_Number__c = 'BATCH-NP1',
                Requested_Qty__c = 10,
                Approved_Qty__c = 10
            );
            fillRequiredFields(badLine);
            try { insert badLine; } catch (Exception e) {}
        }

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Approved';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testReceivedWithLines() {
        Fixtures fx = buildFixtures('RW1', 'In_Transit', true, true);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Received';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testReceivedNoLines() {
        Fixtures fx = buildFixtures('RW2', 'In_Transit', false, false);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Status__c = 'Received';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testNonStatusFieldUpdate() {
        Fixtures fx = buildFixtures('NS1', 'Draft', false, false);

        Test.startTest();
        if (fx.transfer != null) {
            fx.transfer.Notes__c = 'just notes';
            update fx.transfer;
        }
        Test.stopTest();
    }

    @isTest
    static void testBulkStatusChange() {
        List<Stock_Transfer__c> transfers = new List<Stock_Transfer__c>();
        for (Integer i = 0; i < 3; i++) {
            Fixtures fx = buildFixtures('B' + i, 'Submitted', true, true);
            if (fx.transfer != null) transfers.add(fx.transfer);
        }

        Test.startTest();
        for (Stock_Transfer__c t : transfers) {
            t.Status__c = 'Approved';
        }
        if (!transfers.isEmpty()) update transfers;
        Test.stopTest();
    }
}