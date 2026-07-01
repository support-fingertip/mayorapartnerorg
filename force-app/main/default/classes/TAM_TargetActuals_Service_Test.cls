/**
 * @description Tests for TAM_TargetActuals_Service / _Batch (BRD §13 tiered
 *              Target vs Actuals): P1 from invoices by customer, Secondary from
 *              orders by user, scoped by product hierarchy and JC period.
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class TAM_TargetActuals_Service_Test {

    @isTest
    static void p1RevenueFromInvoices() {
        Account cust = TestDataFactory.createAndInsertAccount('DB One', 'Distributor');
        Product_Extension__c pe = TestDataFactory.createProduct('Kopiko', 'SKU-1');
        pe.Brand__c = 'Kopiko';
        insert pe;

        Sales_Order__c so = TestDataFactory.createSalesOrder(cust.Id, UserInfo.getUserId(), null);
        insert so;
        Invoice__c inv = TestDataFactory.createInvoice(so.Id, cust.Id);
        insert inv;
        insert new Invoice_Line__c(Invoice__c = inv.Id, Product_Ext__c = pe.Id,
            Net_Amount__c = 1000, Quantity__c = 10);

        Target__c t = new Target__c(
            Tier__c = 'P1', Target_Type__c = 'Revenue', Customer__c = cust.Id,
            Target_Product_Level__c = 'Brand', Brand__c = 'Kopiko',
            Target_Value__c = 2000, Status__c = 'Active',
            Period_Start__c = Date.today().addDays(-5), Period_End__c = Date.today().addDays(5)
        );
        insert t;

        Test.startTest();
        TAM_TargetActuals_Service.calculateForTarget(t.Id);
        Test.stopTest();

        t = [SELECT Achievement_Value__c, Achievement_Percent__c FROM Target__c WHERE Id = :t.Id];
        System.assertEquals(1000, t.Achievement_Value__c, 'P1 actual = invoice line net amount');
        System.assertEquals(50, t.Achievement_Percent__c, '1000 / 2000 = 50%');
    }

    @isTest
    static void secondaryVolumeFromOrders() {
        Account cust = TestDataFactory.createAndInsertAccount('Outlet One', 'Outlet');
        Product_Extension__c pe = TestDataFactory.createProduct('Beng Beng', 'SKU-2');
        insert pe;

        Sales_Order__c so = TestDataFactory.createSalesOrder(cust.Id, UserInfo.getUserId(), null);
        so.Order_Status__c = 'Approved';
        insert so;
        Order_Line_Item__c li = TestDataFactory.createOrderLineItem(so.Id, pe.Id, 25, 8);
        li.Net_Amount__c = 200;
        insert li;

        Target__c t = new Target__c(
            Tier__c = 'Secondary', Target_Type__c = 'Volume', User__c = UserInfo.getUserId(),
            Target_Value__c = 50, Status__c = 'Active',
            Period_Start__c = Date.today().addDays(-5), Period_End__c = Date.today().addDays(5)
        );
        insert t;

        Test.startTest();
        new TAM_TargetActuals_Batch().execute(null, TAM_TargetActuals_Service.queryTargets(new Set<Id>{ t.Id }));
        Test.stopTest();

        t = [SELECT Achievement_Value__c, Achievement_Percent__c FROM Target__c WHERE Id = :t.Id];
        System.assertEquals(25, t.Achievement_Value__c, 'Secondary actual = order line quantity');
        System.assertEquals(50, t.Achievement_Percent__c, '25 / 50 = 50%');
    }

    @isTest
    static void batchAndScheduleRun() {
        Account cust = TestDataFactory.createAndInsertAccount('DB Two', 'Distributor');
        Target__c t = new Target__c(
            Tier__c = 'P2', Target_Type__c = 'Revenue', Customer__c = cust.Id,
            Target_Value__c = 100, Status__c = 'Active',
            Period_Start__c = Date.today().addDays(-1), Period_End__c = Date.today().addDays(1)
        );
        insert t;

        Test.startTest();
        Database.executeBatch(new TAM_TargetActuals_Batch(), 50);
        String jobId = System.schedule('TAM Target Actuals Test', '0 0 5 * * ?', new TAM_TargetActuals_Batch());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Schedulable returns a job id');
        // No invoices → actual 0, still calculated
        t = [SELECT Achievement_Value__c FROM Target__c WHERE Id = :t.Id];
        System.assertEquals(0, t.Achievement_Value__c);
    }
}
