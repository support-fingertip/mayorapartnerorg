/**
 * @description DMS secondary billing: a distributor sells onward to a retailer,
 *              billed OUT OF the distributor's own stock (not a company warehouse).
 *              Performs FEFO batch allocation across the distributor's current
 *              Distributor_Stock__c snapshots, a retailer credit check, creates a
 *              secondary Invoice (+ batch-level lines), decrements distributor
 *              stock, and writes distributor Stock_Transaction (Out) rows.
 *
 *              Gated by the DMS master + secondary-billing toggles.
 * @author  SFA Development Team
 * @date    2024
 */
public without sharing class DMS_SecondaryBilling_Service {

    /** A requested product line for a secondary sale. */
    public class LineRequest {
        public Id productId;
        public Decimal quantity;
        public Decimal unitPrice;

        public LineRequest(Id productId, Decimal quantity, Decimal unitPrice) {
            this.productId = productId;
            this.quantity = quantity;
            this.unitPrice = unitPrice;
        }
    }

    /**
     * @description Creates a secondary invoice from distributor stock (FEFO).
     * @param distributorId The distributor billing the sale (stock source).
     * @param retailerId    The retailer being billed.
     * @param lines         Requested product lines.
     * @return The created Invoice__c id.
     * @throws DMS_SecondaryBillingException on insufficient stock or credit breach.
     */
    public static Id createSecondaryInvoice(Id distributorId, Id retailerId, List<LineRequest> lines) {
        if (!BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_MASTER) ||
            !BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_SECONDARY_BILLING)) {
            throw new DMS_SecondaryBillingException('Secondary billing is not enabled.');
        }
        if (distributorId == null || retailerId == null || lines == null || lines.isEmpty()) {
            throw new DMS_SecondaryBillingException('Distributor, retailer and at least one line are required.');
        }

        Set<Id> productIds = new Set<Id>();
        for (LineRequest lr : lines) {
            if (lr.productId != null && lr.quantity != null && lr.quantity > 0) {
                productIds.add(lr.productId);
            }
        }
        if (productIds.isEmpty()) {
            throw new DMS_SecondaryBillingException('No valid order lines.');
        }

        // Pricing fallback + GST origin/destination states.
        Map<Id, Decimal> productPrice = new Map<Id, Decimal>();
        for (Product_Extension__c p : [SELECT Id, Unit_Price__c FROM Product_Extension__c WHERE Id IN :productIds]) {
            productPrice.put(p.Id, p.Unit_Price__c);
        }
        Map<Id, String> stateByAccount = new Map<Id, String>();
        for (Account a : [SELECT Id, BillingState FROM Account WHERE Id IN :new Set<Id>{ distributorId, retailerId }]) {
            stateByAccount.put(a.Id, a.BillingState);
        }
        String fromState = stateByAccount.get(distributorId);
        String toState = stateByAccount.get(retailerId);

        // 1. FEFO-allocate from the distributor's current stock snapshots.
        Map<Id, List<Distributor_Stock__c>> stockByProduct = currentStockByProduct(distributorId, productIds);
        List<Allocation> allocations = new List<Allocation>();
        Decimal invoiceTotal = 0;
        for (LineRequest lr : lines) {
            if (lr.productId == null || lr.quantity == null || lr.quantity <= 0) {
                continue;
            }
            // Price: requested price, else fall back to product master price.
            Decimal price = (lr.unitPrice != null && lr.unitPrice > 0)
                ? lr.unitPrice
                : (productPrice.get(lr.productId) != null ? productPrice.get(lr.productId) : 0);
            List<Allocation> lineAllocations = allocateFefo(lr.productId, lr.quantity,
                stockByProduct.get(lr.productId), price);
            allocations.addAll(lineAllocations);
            invoiceTotal += lr.quantity * price;
        }

        // 2. GST per allocation line.
        List<DMS_Tax_Service.LineTaxInput> taxInputs = new List<DMS_Tax_Service.LineTaxInput>();
        for (Allocation a : allocations) {
            taxInputs.add(new DMS_Tax_Service.LineTaxInput(
                a.productId, a.quantity * a.unitPrice, fromState, toState));
        }
        List<DMS_Tax_Service.LineTax> taxes = DMS_Tax_Service.calculate(taxInputs);
        Decimal invoiceTax = 0;
        for (DMS_Tax_Service.LineTax t : taxes) {
            invoiceTax += t.totalTax;
        }

        // 3. Retailer credit check on the gross amount (base + GST).
        assertWithinCredit(retailerId, invoiceTotal + invoiceTax);

        // 4. Create the secondary invoice header.
        Invoice__c invoice = new Invoice__c(
            Account__c               = retailerId,
            Sold_From_Distributor__c = distributorId,
            Order_Type__c            = DMS_Constants.ORDER_TYPE_SECONDARY,
            Invoice_Date__c          = Date.today(),
            Invoice_Number__c        = 'SINV-' + String.valueOf(Datetime.now().getTime()),
            Status__c                = 'Draft',
            Subtotal__c              = invoiceTotal,
            Tax_Amount__c            = invoiceTax,
            Total_Amount__c          = invoiceTotal + invoiceTax,
            Balance_Due__c           = invoiceTotal + invoiceTax
        );
        insert invoice;

        // 4. Invoice lines (batch-level), stock-out snapshots, and transactions.
        List<Invoice_Line__c> invoiceLines = new List<Invoice_Line__c>();
        List<Distributor_Stock__c> stockOut = new List<Distributor_Stock__c>();
        List<Stock_Transaction__c> txns = new List<Stock_Transaction__c>();
        Integer lineNo = 1;

        for (Integer i = 0; i < allocations.size(); i++) {
            Allocation a = allocations[i];
            DMS_Tax_Service.LineTax t = taxes[i];
            invoiceLines.add(new Invoice_Line__c(
                Invoice__c     = invoice.Id,
                Product_Ext__c = a.productId,
                Batch_No__c    = a.batch,
                Quantity__c    = a.quantity,
                Unit_Price__c  = a.unitPrice,
                Line_Number__c = lineNo,
                Total_Amount__c = a.quantity * a.unitPrice,
                Tax_Rate__c    = t.taxRate,
                CGST__c        = t.cgst,
                SGST__c        = t.sgst,
                IGST__c        = t.igst,
                Tax_Amount__c  = t.totalTax
            ));
            lineNo++;

            stockOut.add(new Distributor_Stock__c(
                Account__c       = distributorId,
                Product_Ext__c   = a.productId,
                Batch_No__c      = a.batch,
                Expiry_Date__c   = a.expiryDate,
                Opening_Stock__c = a.currentClosing,
                Received_Qty__c  = 0,
                Sold_Qty__c      = a.quantity,
                Damaged_Qty__c   = 0,
                Stock_Date__c    = Date.today(),
                Is_Current__c    = true
            ));

            txns.add(new Stock_Transaction__c(
                Account__c          = distributorId,
                Product_Ext__c      = a.productId,
                Batch_Number__c     = a.batch,
                Direction__c        = DMS_Constants.DIRECTION_OUT,
                Transaction_Type__c = DMS_Constants.TXN_OUTBOUND_DISPATCH,
                Quantity__c         = a.quantity,
                Transaction_Date__c = Date.today(),
                Reference_Type__c   = 'Invoice',
                Reference_Id__c     = invoice.Id
            ));
        }

        if (!invoiceLines.isEmpty()) {
            insert invoiceLines;
        }
        if (!stockOut.isEmpty()) {
            insert stockOut;
        }
        if (!txns.isEmpty()) {
            insert txns;
        }

        return invoice.Id;
    }

    // ── FEFO allocation ───────────────────────────────────────────────────

    /** A resolved allocation of a quantity to a specific batch snapshot. */
    private class Allocation {
        Id productId;
        String batch;
        Date expiryDate;
        Decimal quantity;
        Decimal unitPrice;
        Decimal currentClosing;
    }

    private static Map<Id, List<Distributor_Stock__c>> currentStockByProduct(
        Id distributorId, Set<Id> productIds
    ) {
        Map<Id, List<Distributor_Stock__c>> byProduct = new Map<Id, List<Distributor_Stock__c>>();
        // Earliest expiry first (FEFO); nulls last so dated batches are consumed first.
        for (Distributor_Stock__c ds : [
            SELECT Product_Ext__c, Batch_No__c, Expiry_Date__c, Closing_Stock__c
            FROM Distributor_Stock__c
            WHERE Account__c = :distributorId
              AND Product_Ext__c IN :productIds
              AND Is_Current__c = true
              AND Closing_Stock__c > 0
            ORDER BY Expiry_Date__c ASC NULLS LAST
        ]) {
            if (!byProduct.containsKey(ds.Product_Ext__c)) {
                byProduct.put(ds.Product_Ext__c, new List<Distributor_Stock__c>());
            }
            byProduct.get(ds.Product_Ext__c).add(ds);
        }
        return byProduct;
    }

    private static List<Allocation> allocateFefo(
        Id productId, Decimal requested, List<Distributor_Stock__c> batches, Decimal unitPrice
    ) {
        List<Allocation> result = new List<Allocation>();
        Decimal remaining = requested;
        if (batches != null) {
            for (Distributor_Stock__c ds : batches) {
                if (remaining <= 0) {
                    break;
                }
                Decimal available = ds.Closing_Stock__c != null ? ds.Closing_Stock__c : 0;
                if (available <= 0) {
                    continue;
                }
                Decimal take = Math.min(available, remaining);
                Allocation a = new Allocation();
                a.productId = productId;
                a.batch = ds.Batch_No__c;
                a.expiryDate = ds.Expiry_Date__c;
                a.quantity = take;
                a.unitPrice = unitPrice;
                a.currentClosing = available;
                result.add(a);
                remaining -= take;
            }
        }
        if (remaining > 0) {
            throw new DMS_SecondaryBillingException(
                'Insufficient distributor stock for product ' + productId +
                '. Short by ' + remaining + ' unit(s).');
        }
        return result;
    }

    // ── Credit check ──────────────────────────────────────────────────────

    private static void assertWithinCredit(Id retailerId, Decimal invoiceTotal) {
        Account retailer = [
            SELECT Credit_Limit__c, Outstanding_Balance__c FROM Account WHERE Id = :retailerId
        ];
        Decimal creditLimit = retailer.Credit_Limit__c != null ? retailer.Credit_Limit__c : 0;
        if (creditLimit <= 0) {
            return; // 0/blank limit = no credit ceiling enforced.
        }
        Decimal outstanding = retailer.Outstanding_Balance__c != null ? retailer.Outstanding_Balance__c : 0;
        if (outstanding + invoiceTotal > creditLimit) {
            throw new DMS_SecondaryBillingException(
                'Credit limit exceeded for retailer. Limit: ' + creditLimit +
                ', Outstanding: ' + outstanding + ', This sale: ' + invoiceTotal + '.');
        }
    }
}