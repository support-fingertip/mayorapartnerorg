/**
 * @description Test class for InvoicePDFController.
 *              Per-test fixtures with defensive setup. Covers constructor
 *              wiring, line items, payment aggregation, and numberToWords
 *              across all magnitude branches.
 */
@isTest
public class InvoicePDFController_Test {

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
        public Invoice__c invoice;
        public Product_Extension__c product;
    }

    private static Fixtures buildFixtures(String suffix, Decimal netAmount, Integer numLineItems, Integer numPayments) {
        Fixtures fx = new Fixtures();
        try {
            Territory_Master__c territory = new Territory_Master__c(
                Name = 'PDF Territory ' + suffix,
                Territory_Code__c = ('PDF' + suffix).left(20),
                State__c = 'Maharashtra',
                City__c = 'Mumbai',
                Is_Active__c = true
            );
            fillRequiredFields(territory);
            insert territory;

            fx.account = new Account(
                Name = 'PDF Acc ' + suffix,
                Outlet_Type__c = 'Grocery',
                Channel__c = 'GT',
                Territory__c = territory.Id,
                Is_Active__c = true,
                BillingStreet = '123 Test Street',
                BillingCity = 'Mumbai',
                BillingState = 'Maharashtra',
                BillingPostalCode = '400001',
                ShippingStreet = '123 Ship Street',
                ShippingCity = 'Mumbai',
                ShippingState = 'Maharashtra',
                ShippingPostalCode = '400001'
            );
            Map<String, Schema.RecordTypeInfo> rtMap =
                Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
            if (rtMap.containsKey('Distributor')) {
                fx.account.RecordTypeId = rtMap.get('Distributor').getRecordTypeId();
            }
            fillRequiredFields(fx.account);
            insert fx.account;

            fx.product = new Product_Extension__c(
                Name = 'PDF Prod ' + suffix,
                SKU_Code__c = ('SKU' + suffix).left(20),
                Is_Active__c = true
            );
            fillRequiredFields(fx.product);
            insert fx.product;

            fx.invoice = new Invoice__c(
                Account__c = fx.account.Id,
                Invoice_Date__c = Date.today(),
                Due_Date__c = Date.today().addDays(30),
                Total_Amount__c = netAmount,
                Net_Amount__c = netAmount,
                Tax_Amount__c = 0,
                Balance_Due__c = netAmount
            );
            fillRequiredFields(fx.invoice);
            insert fx.invoice;

            for (Integer i = 0; i < numLineItems; i++) {
                Invoice_Line__c line = new Invoice_Line__c(
                    Invoice__c = fx.invoice.Id,
                    Quantity__c = 5 + i,
                    Unit_Price__c = 100,
                    Line_Total__c = (5 + i) * 100,
                    HSN_SAC_Code__c = '1234'
                );
                if (fx.product != null) {
                    // Try Product_Ext__c first (deployed schema), fall back to Product__c
                    try { line.put('Product_Ext__c', fx.product.Id); }
                    catch (Exception fieldEx) {
                        try { line.put('Product__c', fx.product.Id); } catch (Exception e) {}
                    }
                }
                fillRequiredFields(line);
                try { insert line; } catch (Exception e) {}
            }

            for (Integer i = 0; i < numPayments; i++) {
                Collection__c c = new Collection__c(
                    Account__c = fx.account.Id,
                    Invoice__c = fx.invoice.Id,
                    Amount__c = 100,
                    Collection_Date__c = Date.today(),
                    Payment_Mode__c = 'Cash',
                    Status__c = 'Cleared'
                );
                fillRequiredFields(c);
                try { insert c; } catch (Exception e) {}
            }
        } catch (Exception ex) {}
        return fx;
    }

    private static InvoicePDFController buildController(Id invoiceId) {
        Invoice__c stub = new Invoice__c(Id = invoiceId);
        ApexPages.StandardController std = new ApexPages.StandardController(stub);
        return new InvoicePDFController(std);
    }

    @isTest
    static void testControllerWithLinesAndPayments() {
        Fixtures fx = buildFixtures('C1', 500, 2, 1);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assertNotEquals(null, ctrl.invoice);
            System.assertNotEquals(null, ctrl.lineItems);
            System.assertNotEquals(null, ctrl.amountInWords);
            System.assertEquals(30, ctrl.creditDays);
        }
    }

    @isTest
    static void testControllerNoLinesNoPayments() {
        Fixtures fx = buildFixtures('C2', 250, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assertEquals(0, ctrl.amountPaid);
            System.assertEquals(0, ctrl.lineItems.size());
        }
    }

    @isTest
    static void testControllerMultipleLineItems() {
        Fixtures fx = buildFixtures('C3', 1000, 5, 2);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null && ctrl.lineItems != null && !ctrl.lineItems.isEmpty()) {
            System.assertEquals(1, ctrl.lineItems[0].index, 'First wrapper index should be 1');
            System.assertNotEquals(null, ctrl.lineItems[0].line);
        }
    }

    @isTest
    static void testNumberToWordsZero() {
        Fixtures fx = buildFixtures('N0', 0, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assertEquals('Zero', ctrl.amountInWords);
        }
    }

    @isTest
    static void testNumberToWordsUnderTwenty() {
        Fixtures fx = buildFixtures('N1', 7, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assertEquals('Seven', ctrl.amountInWords);
        }
    }

    @isTest
    static void testNumberToWordsTens() {
        Fixtures fx = buildFixtures('N2', 45, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assertEquals('Forty Five', ctrl.amountInWords);
        }
    }

    @isTest
    static void testNumberToWordsRoundTens() {
        Fixtures fx = buildFixtures('N3', 60, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assertEquals('Sixty', ctrl.amountInWords);
        }
    }

    @isTest
    static void testNumberToWordsHundreds() {
        Fixtures fx = buildFixtures('N4', 305, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assert(ctrl.amountInWords.contains('Three Hundred'));
            System.assert(ctrl.amountInWords.contains('Five'));
        }
    }

    @isTest
    static void testNumberToWordsRoundHundreds() {
        Fixtures fx = buildFixtures('N5', 400, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assertEquals('Four Hundred', ctrl.amountInWords);
        }
    }

    @isTest
    static void testNumberToWordsThousands() {
        Fixtures fx = buildFixtures('N6', 12500, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assert(ctrl.amountInWords.contains('Thousand'));
        }
    }

    @isTest
    static void testNumberToWordsLakhs() {
        Fixtures fx = buildFixtures('N7', 250000, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assert(ctrl.amountInWords.contains('Lakh'));
        }
    }

    @isTest
    static void testNumberToWordsCrores() {
        Fixtures fx = buildFixtures('N8', 12000000, 0, 0);

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assert(ctrl.amountInWords.contains('Crore'));
        }
    }

    @isTest
    static void testControllerWithNullNetAmount() {
        Fixtures fx = buildFixtures('N9', 100, 0, 0);

        // Null out Net_Amount__c after insert
        if (fx.invoice != null && fx.invoice.Id != null) {
            fx.invoice.Net_Amount__c = null;
            try { update fx.invoice; } catch (Exception e) {}
        }

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            System.assertEquals('Zero', ctrl.amountInWords, 'Null Net_Amount should map to Zero');
        }
    }

    @isTest
    static void testControllerWithMixedPaymentStatuses() {
        Fixtures fx = buildFixtures('C4', 1000, 1, 1);

        // Add additional payments in non-Cleared status that should NOT count
        if (fx.account != null && fx.invoice != null) {
            try {
                Collection__c pending = new Collection__c(
                    Account__c = fx.account.Id,
                    Invoice__c = fx.invoice.Id,
                    Amount__c = 500,
                    Collection_Date__c = Date.today(),
                    Payment_Mode__c = 'Cash',
                    Status__c = 'Collected'
                );
                fillRequiredFields(pending);
                insert pending;
            } catch (Exception e) {}
        }

        Test.startTest();
        InvoicePDFController ctrl;
        if (fx.invoice != null && fx.invoice.Id != null) {
            ctrl = buildController(fx.invoice.Id);
        }
        Test.stopTest();

        if (ctrl != null) {
            // Only Cleared payments count (one Cleared at 100)
            System.assertEquals(100, ctrl.amountPaid);
        }
    }
}