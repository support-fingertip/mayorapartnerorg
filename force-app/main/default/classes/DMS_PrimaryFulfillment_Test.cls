/**
 * @description Phase 1 tests for the DMS primary fulfillment loop:
 *              Indent approval -> primary Invoice + warehouse deduction -> GRN
 *              receipt -> Distributor_Stock posting -> Indent Received.
 * @author  SFA Development Team
 * @date    2024
 */
@isTest
private class DMS_PrimaryFulfillment_Test {

    private static void enableDmsToggles() {
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, true);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_PRIMARY_FULFILLMENT, true);
    }

    private static void disableDmsToggles() {
        // Force the toggles OFF in cache. Without this, isEnabled() falls back to the
        // live Feature_Toggle__mdt records (which ship as Is_Enabled__c = true), so the
        // fulfillment logic would actually run.
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, false);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_PRIMARY_FULFILLMENT, false);
    }

    private static Warehouse__c createWarehouse() {
        Warehouse__c wh = new Warehouse__c(
            Name = 'Test Source WH',
            Warehouse_Code__c = 'WHDMS1',
            Is_Active__c = true
        );
        insert wh;
        return wh;
    }

    private static void seedWarehouseStock(Id warehouseId, List<Product_Extension__c> products) {
        List<Warehouse_Stock__c> stock = new List<Warehouse_Stock__c>();
        for (Product_Extension__c p : products) {
            stock.add(new Warehouse_Stock__c(
                Warehouse__c = warehouseId,
                Product_Ext__c = p.Id,
                Qty_On_Hand__c = 1000
            ));
        }
        insert stock;
    }

    private static Indent__c createApprovableIndent(
        Id accountId, Id warehouseId, List<Product_Extension__c> products
    ) {
        Indent__c indent = new Indent__c(
            Account__c = accountId,
            Source_Warehouse__c = warehouseId,
            Indent_Date__c = Date.today(),
            Requested_Delivery_Date__c = Date.today().addDays(5),
            Status__c = 'Submitted'
        );
        insert indent;

        List<Indent_Line__c> lines = new List<Indent_Line__c>();
        for (Integer i = 0; i < products.size(); i++) {
            lines.add(new Indent_Line__c(
                Indent__c = indent.Id,
                Product_Ext__c = products[i].Id,
                Requested_Qty__c = (i + 1) * 10,
                Approved_Qty__c = (i + 1) * 10,
                Unit_Price__c = 100
            ));
        }
        insert lines;
        return indent;
    }

    @isTest
    static void approval_createsPrimaryInvoice_andDeductsWarehouse() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist A', 'Distributor');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(2);
        Warehouse__c wh = createWarehouse();
        seedWarehouseStock(wh.Id, products);
        Indent__c indent = createApprovableIndent(dist.Id, wh.Id, products);

        enableDmsToggles();
        Test.startTest();
        update new Indent__c(Id = indent.Id, Status__c = 'Approved');
        Test.stopTest();

        Indent__c after = [SELECT Status__c, Invoice__c FROM Indent__c WHERE Id = :indent.Id];
        System.assertEquals('Dispatched', after.Status__c, 'Indent advanced to Dispatched');
        System.assertNotEquals(null, after.Invoice__c, 'Primary invoice linked to indent');

        Invoice__c inv = [
            SELECT Order_Type__c, Account__c, Warehouse__c FROM Invoice__c WHERE Id = :after.Invoice__c
        ];
        System.assertEquals('Primary', inv.Order_Type__c, 'Invoice is primary');
        System.assertEquals(dist.Id, inv.Account__c, 'Invoice billed to distributor');
        System.assertEquals(wh.Id, inv.Warehouse__c, 'Invoice sourced from warehouse');

        System.assertEquals(2, [SELECT COUNT() FROM Invoice_Line__c WHERE Invoice__c = :inv.Id],
            'One invoice line per indent line');

        // Product 0 had qty 10; on-hand was 1000 -> 990.
        Warehouse_Stock__c ws = [
            SELECT Qty_On_Hand__c FROM Warehouse_Stock__c
            WHERE Warehouse__c = :wh.Id AND Product_Ext__c = :products[0].Id LIMIT 1
        ];
        System.assertEquals(990, ws.Qty_On_Hand__c, 'Warehouse stock deducted for dispatched qty');
    }

    @isTest
    static void grnReceipt_postsDistributorStock_andReceivesIndent() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist B', 'Distributor');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        Warehouse__c wh = createWarehouse();
        seedWarehouseStock(wh.Id, products);
        Indent__c indent = createApprovableIndent(dist.Id, wh.Id, products);

        enableDmsToggles();
        update new Indent__c(Id = indent.Id, Status__c = 'Approved');

        Id invoiceId = [SELECT Invoice__c FROM Indent__c WHERE Id = :indent.Id].Invoice__c;

        // Distributor receives the dispatch via GRN.
        GRN__c grn = new GRN__c(
            Account__c = dist.Id,
            Invoice__c = invoiceId,
            GRN_Date__c = Date.today(),
            Status__c = 'Pending'
        );
        insert grn;
        insert new GRN_Line__c(
            GRN__c = grn.Id,
            Product_Ext__c = products[0].Id,
            Received_Qty__c = 10,
            Damaged_Qty__c = 0,
            Batch_No__c = 'B-001'
        );

        Test.startTest();
        update new GRN__c(Id = grn.Id, Status__c = 'Received');
        Test.stopTest();

        Distributor_Stock__c ds = [
            SELECT Received_Qty__c, Closing_Stock__c, Is_Current__c, Batch_No__c
            FROM Distributor_Stock__c
            WHERE Account__c = :dist.Id AND Product_Ext__c = :products[0].Id LIMIT 1
        ];
        System.assertEquals(10, ds.Received_Qty__c, 'Received qty posted to distributor stock');
        System.assertEquals(10, ds.Closing_Stock__c, 'Closing stock computed');
        System.assertEquals(true, ds.Is_Current__c, 'New snapshot is current');

        System.assertEquals(1, [
            SELECT COUNT() FROM Stock_Transaction__c
            WHERE Account__c = :dist.Id AND Direction__c = 'In' AND Reference_Type__c = 'GRN'
        ], 'Distributor stock-in transaction written');

        Indent__c after = [SELECT Status__c FROM Indent__c WHERE Id = :indent.Id];
        System.assertEquals('Received', after.Status__c, 'Indent advanced to Received');
    }

    @isTest
    static void approval_withTogglesOff_doesNothing() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist C', 'Distributor');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        Warehouse__c wh = createWarehouse();
        seedWarehouseStock(wh.Id, products);
        Indent__c indent = createApprovableIndent(dist.Id, wh.Id, products);

        // Toggles intentionally disabled — set explicitly so behavior never depends
        // on the deployed Feature_Toggle__mdt records.
        disableDmsToggles();
        Test.startTest();
        update new Indent__c(Id = indent.Id, Status__c = 'Approved');
        Test.stopTest();

        Indent__c after = [SELECT Status__c, Invoice__c FROM Indent__c WHERE Id = :indent.Id];
        System.assertEquals('Approved', after.Status__c, 'Status unchanged when DMS disabled');
        System.assertEquals(null, after.Invoice__c, 'No invoice generated when DMS disabled');
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE Account__c = :dist.Id],
            'No primary invoice created when DMS disabled');
    }
}