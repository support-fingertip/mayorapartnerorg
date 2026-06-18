/**
 * @description Tests for the distributor portal API, focused on data isolation:
 *              every method must return/write only the context distributor's data.
 * @author  SFA Development Team
 * @date    2024
 */
@isTest
private class DMS_PortalController_Test {

    private static void enablePortal() {
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, true);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_PORTAL, true);
    }

    private static void disablePortal() {
        // Force the toggles OFF in cache. Without this, isEnabled() falls back to the
        // live Feature_Toggle__mdt records (which ship as Is_Enabled__c = true), so the
        // portal would actually be enabled and getDashboard() would not throw.
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, false);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_PORTAL, false);
    }

    private static void seedFor(Id accountId, Id productId, String tag) {
        insert new Distributor_Stock__c(Account__c = accountId, Product_Ext__c = productId,
            Opening_Stock__c = 100, Stock_Date__c = Date.today(), Is_Current__c = true,
            Expiry_Date__c = Date.today().addDays(20));
        Indent__c ind = new Indent__c(Account__c = accountId, Indent_Date__c = Date.today(),
            Status__c = 'Submitted');
        insert ind;
        insert new Invoice__c(Account__c = accountId, Invoice_Number__c = 'INV-' + tag,
            Invoice_Date__c = Date.today(), Status__c = 'Draft', Total_Amount__c = 500,
            Balance_Due__c = 500, Order_Type__c = 'Primary');
        insert new Ledger_Entry__c(Account__c = accountId, Entry_Type__c = 'Payment',
            Amount__c = 100, Entry_Date__c = Date.today(), Status__c = 'Posted');
        insert new Claim__c(Account__c = accountId, Claim_Type__c = 'Damage Claim',
            Claim_Date__c = Date.today(), Total_Amount__c = 50, Status__c = 'Submitted');
        insert new Ticket__c(Account__c = accountId, Subject__c = 'Issue ' + tag,
            Status__c = 'Open', Ticket_Date__c = Date.today());
    }

    @isTest
    static void allReads_scopedToContextAccount() {
        Account distA = TestDataFactory.createAndInsertAccount('Dist A', 'Distributor');
        distA.Outstanding_Balance__c = 200;
        distA.Credit_Limit__c = 1000;
        update distA;
        Account distB = TestDataFactory.createAndInsertAccount('Dist B', 'Distributor');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);

        seedFor(distA.Id, products[0].Id, 'A');
        seedFor(distB.Id, products[0].Id, 'B');

        enablePortal();
        DMS_PortalController.testAccountIdOverride = distA.Id;

        Test.startTest();
        DMS_PortalController.Dashboard dash = DMS_PortalController.getDashboard();
        System.assertEquals(200, dash.outstanding, 'Outstanding from context account');
        System.assertEquals(800, dash.creditAvailable, 'Credit available = 1000 - 200');
        System.assertEquals(100, dash.onHandUnits, 'On-hand from A only');
        System.assertEquals(1, dash.openIndents, 'One open indent for A');
        System.assertEquals(1, dash.nearExpiryBatches, 'One near-expiry batch for A');

        System.assertEquals(1, DMS_PortalController.getInventory().size(), 'Only A inventory');
        System.assertEquals(1, DMS_PortalController.getIndents().size(), 'Only A indents');
        System.assertEquals(1, DMS_PortalController.getInvoices().size(), 'Only A invoices');
        System.assertEquals(1, DMS_PortalController.getLedger().size(), 'Only A ledger');
        System.assertEquals(1, DMS_PortalController.getClaims().size(), 'Only A claims');
        System.assertEquals(1, DMS_PortalController.getTickets().size(), 'Only A tickets');
        System.assertNotEquals(null, DMS_PortalController.getAging(), 'Aging returned');
        Test.stopTest();
    }

    @isTest
    static void selfService_writesForContextAccount() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist W', 'Distributor');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);

        enablePortal();
        DMS_PortalController.testAccountIdOverride = dist.Id;

        Test.startTest();
        DMS_PortalController.IndentLineInput li = new DMS_PortalController.IndentLineInput();
        li.productId = products[0].Id;
        li.quantity = 25;
        Id indentId = DMS_PortalController.placeIndent(
            new List<DMS_PortalController.IndentLineInput>{ li });
        Id claimId = DMS_PortalController.submitClaim('Damage Claim', 75, 'Broken cartons');
        Id ticketId = DMS_PortalController.raiseTicket('Late delivery', 'Order was late', 'Delivery Issue', 'High');
        Test.stopTest();

        System.assertEquals(dist.Id, [SELECT Account__c FROM Indent__c WHERE Id = :indentId].Account__c,
            'Indent created for context account');
        System.assertEquals(25, [SELECT Requested_Qty__c FROM Indent_Line__c WHERE Indent__c = :indentId].Requested_Qty__c,
            'Indent line qty');
        System.assertEquals(dist.Id, [SELECT Account__c FROM Claim__c WHERE Id = :claimId].Account__c,
            'Claim created for context account');
        System.assertEquals(dist.Id, [SELECT Account__c FROM Ticket__c WHERE Id = :ticketId].Account__c,
            'Ticket created for context account');
    }

    @isTest
    static void disabledPortal_throws() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist D', 'Distributor');
        DMS_PortalController.testAccountIdOverride = dist.Id;
        // Toggles off — set explicitly so the portal is genuinely disabled.
        disablePortal();
        Boolean thrown = false;
        Test.startTest();
        try {
            DMS_PortalController.getDashboard();
        } catch (Exception e) {
            thrown = true;
        }
        Test.stopTest();
        System.assertEquals(true, thrown, 'Should throw when portal disabled');
    }

    @isTest
    static void internalUser_seesAllData() {
        // Seed data across two distributors; an internal (admin) user sees ALL.
        Account distA = TestDataFactory.createAndInsertAccount('Dist All A', 'Distributor');
        Account distB = TestDataFactory.createAndInsertAccount('Dist All B', 'Distributor');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        insert new List<Distributor_Stock__c>{
            new Distributor_Stock__c(Account__c = distA.Id, Product_Ext__c = products[0].Id,
                Opening_Stock__c = 10, Stock_Date__c = Date.today(), Is_Current__c = true),
            new Distributor_Stock__c(Account__c = distB.Id, Product_Ext__c = products[0].Id,
                Opening_Stock__c = 20, Stock_Date__c = Date.today(), Is_Current__c = true)
        };

        enablePortal();
        // No override → running test user is internal (Standard) → admin/all mode.
        Test.startTest();
        DMS_PortalController.Dashboard d = DMS_PortalController.getDashboard();
        Integer inventoryRows = DMS_PortalController.getInventory().size();
        Test.stopTest();

        System.assertEquals(30, d.onHandUnits, 'Admin dashboard aggregates all distributors');
        System.assert(inventoryRows >= 2, 'Admin sees inventory across all distributors');
    }

    @isTest
    static void secondarySale_placesInvoiceForContextDistributor() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist SS', 'Distributor');
        Account retailer = TestDataFactory.createAndInsertAccount('Retailer SS', 'Retailer');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        // Distributor on-hand for the product.
        insert new Distributor_Stock__c(Account__c = dist.Id, Product_Ext__c = products[0].Id,
            Batch_No__c = 'B1', Opening_Stock__c = 100, Stock_Date__c = Date.today(),
            Is_Current__c = true, Expiry_Date__c = Date.today().addDays(60));

        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_MASTER, true);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_PORTAL, true);
        BPM_FeatureToggle_Util.toggleCache.put(DMS_Constants.TOGGLE_SECONDARY_BILLING, true);
        DMS_PortalController.testAccountIdOverride = dist.Id;

        DMS_PortalController.IndentLineInput li = new DMS_PortalController.IndentLineInput();
        li.productId = products[0].Id;
        li.quantity = 10;

        Test.startTest();
        Id invId = DMS_PortalController.placeSecondarySale(retailer.Id,
            new List<DMS_PortalController.IndentLineInput>{ li });
        Test.stopTest();

        Invoice__c inv = [
            SELECT Order_Type__c, Account__c, Sold_From_Distributor__c FROM Invoice__c WHERE Id = :invId
        ];
        System.assertEquals('Secondary', inv.Order_Type__c, 'Secondary invoice created');
        System.assertEquals(retailer.Id, inv.Account__c, 'Billed to retailer');
        System.assertEquals(dist.Id, inv.Sold_From_Distributor__c, 'Sold from the context distributor');
    }

    @isTest
    static void getRetailersAndProducts_returnData() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist L', 'Distributor');
        TestDataFactory.createAndInsertAccount('Retailer L', 'Retailer');
        TestDataFactory.createAndInsertProducts(2);

        enablePortal();
        DMS_PortalController.testAccountIdOverride = dist.Id;

        Test.startTest();
        System.assert(DMS_PortalController.getProducts().size() >= 2, 'Products returned');
        System.assert(DMS_PortalController.getRetailers().size() >= 1, 'Retailers returned');
        Test.stopTest();
    }

    @isTest
    static void homeSummary_adminAndScoped() {
        Account dist = TestDataFactory.createAndInsertAccount('Dist Home', 'Distributor');
        List<Product_Extension__c> products = TestDataFactory.createAndInsertProducts(1);
        insert new Distributor_Stock__c(Account__c = dist.Id, Product_Ext__c = products[0].Id,
            Opening_Stock__c = 50, Stock_Date__c = Date.today(), Is_Current__c = true);

        enablePortal();
        Test.startTest();
        // Admin (no override) → org-wide.
        DMS_PortalController.HomeSummary admin = DMS_PortalController.getHomeSummary('THIS_JC');
        // Scoped (override) → distributor.
        DMS_PortalController.testAccountIdOverride = dist.Id;
        DMS_PortalController.HomeSummary scoped = DMS_PortalController.getHomeSummary('THIS_YEAR');
        Test.stopTest();

        System.assertNotEquals(null, admin, 'Admin home summary returned');
        System.assertNotEquals(null, scoped, 'Scoped home summary returned');
    }
}