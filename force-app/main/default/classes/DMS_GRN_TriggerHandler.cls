/**
 * @description DMS GRN posting. When a GRN against a PRIMARY dispatch invoice is
 *              Received/Partial, posts the received goods into Distributor_Stock__c
 *              (new current snapshot per product/batch), writes a distributor
 *              Stock_Transaction__c (In), and advances the linked indent to
 *              Received. Inert unless the DMS toggles are enabled.
 *
 *              Warehouse GRNs (non-primary) are handled by INV_GRN_TriggerHandler;
 *              this handler only processes GRNs whose Invoice.Order_Type__c = Primary.
 * @author  SFA Development Team
 * @date    2024
 */
public without sharing class DMS_GRN_TriggerHandler extends TriggerHandler {

    protected override void afterUpdate() {
        if (!BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_MASTER) ||
            !BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_PRIMARY_FULFILLMENT)) {
            return;
        }

        List<GRN__c> newRecords = (List<GRN__c>) Trigger.new;
        Map<Id, GRN__c> oldMap = (Map<Id, GRN__c>) Trigger.oldMap;

        List<GRN__c> received = new List<GRN__c>();
        Set<Id> invoiceIds = new Set<Id>();
        for (GRN__c grn : newRecords) {
            GRN__c oldGrn = oldMap.get(grn.Id);
            Boolean nowReceived = (grn.Status__c == 'Received' || grn.Status__c == 'Partial');
            Boolean wasReceived = (oldGrn.Status__c == 'Received' || oldGrn.Status__c == 'Partial');
            if (nowReceived && !wasReceived && grn.Invoice__c != null) {
                received.add(grn);
                invoiceIds.add(grn.Invoice__c);
            }
        }
        if (received.isEmpty()) {
            return;
        }

        // Keep only GRNs linked to a PRIMARY invoice; capture distributor account.
        Map<Id, Invoice__c> primaryInvoices = new Map<Id, Invoice__c>();
        for (Invoice__c inv : [
            SELECT Id, Account__c, Order_Type__c
            FROM Invoice__c
            WHERE Id IN :invoiceIds AND Order_Type__c = :DMS_Constants.ORDER_TYPE_PRIMARY
        ]) {
            primaryInvoices.put(inv.Id, inv);
        }

        List<GRN__c> primaryGRNs = new List<GRN__c>();
        Set<Id> grnIds = new Set<Id>();
        for (GRN__c grn : received) {
            if (primaryInvoices.containsKey(grn.Invoice__c)) {
                primaryGRNs.add(grn);
                grnIds.add(grn.Id);
            }
        }
        if (primaryGRNs.isEmpty()) {
            return;
        }

        postDistributorStock(primaryGRNs, primaryInvoices, grnIds);
    }

    private void postDistributorStock(
        List<GRN__c> primaryGRNs, Map<Id, Invoice__c> primaryInvoices, Set<Id> grnIds
    ) {
        // GRN lines by GRN.
        Map<Id, List<GRN_Line__c>> linesByGRN = new Map<Id, List<GRN_Line__c>>();
        Set<Id> productIds = new Set<Id>();
        for (GRN_Line__c line : [
            SELECT Id, GRN__c, Product_Ext__c, Received_Qty__c, Damaged_Qty__c,
                   Batch_No__c, Expiry_Date__c
            FROM GRN_Line__c
            WHERE GRN__c IN :grnIds
        ]) {
            if (!linesByGRN.containsKey(line.GRN__c)) {
                linesByGRN.put(line.GRN__c, new List<GRN_Line__c>());
            }
            linesByGRN.get(line.GRN__c).add(line);
            if (line.Product_Ext__c != null) {
                productIds.add(line.Product_Ext__c);
            }
        }

        // Current closing stock per Account+Product+Batch for opening balances.
        Set<Id> accountIds = new Set<Id>();
        for (GRN__c grn : primaryGRNs) {
            accountIds.add(primaryInvoices.get(grn.Invoice__c).Account__c);
        }
        Map<String, Decimal> currentClosing = new Map<String, Decimal>();
        for (Distributor_Stock__c ds : [
            SELECT Account__c, Product_Ext__c, Batch_No__c, Closing_Stock__c
            FROM Distributor_Stock__c
            WHERE Account__c IN :accountIds AND Product_Ext__c IN :productIds
              AND Is_Current__c = true
        ]) {
            currentClosing.put(stockKey(ds.Account__c, ds.Product_Ext__c, ds.Batch_No__c),
                               ds.Closing_Stock__c != null ? ds.Closing_Stock__c : 0);
        }

        List<Distributor_Stock__c> newSnapshots = new List<Distributor_Stock__c>();
        List<Stock_Transaction__c> txns = new List<Stock_Transaction__c>();

        for (GRN__c grn : primaryGRNs) {
            Id distributorId = primaryInvoices.get(grn.Invoice__c).Account__c;
            List<GRN_Line__c> lines = linesByGRN.get(grn.Id);
            if (lines == null) {
                continue;
            }
            for (GRN_Line__c line : lines) {
                Decimal recvd = line.Received_Qty__c != null ? line.Received_Qty__c : 0;
                Decimal damaged = line.Damaged_Qty__c != null ? line.Damaged_Qty__c : 0;
                Decimal usable = recvd - damaged;
                if (usable <= 0 || line.Product_Ext__c == null) {
                    continue;
                }
                String key = stockKey(distributorId, line.Product_Ext__c, line.Batch_No__c);
                Decimal opening = currentClosing.containsKey(key) ? currentClosing.get(key) : 0;

                newSnapshots.add(new Distributor_Stock__c(
                    Account__c     = distributorId,
                    Product_Ext__c = line.Product_Ext__c,
                    Batch_No__c    = line.Batch_No__c,
                    Expiry_Date__c = line.Expiry_Date__c,
                    Opening_Stock__c = opening,
                    Received_Qty__c  = usable,
                    Sold_Qty__c      = 0,
                    Damaged_Qty__c   = 0,
                    Stock_Date__c    = Date.today(),
                    Is_Current__c    = true
                ));

                txns.add(new Stock_Transaction__c(
                    Account__c        = distributorId,
                    Product_Ext__c    = line.Product_Ext__c,
                    Batch_Number__c   = line.Batch_No__c,
                    Direction__c      = DMS_Constants.DIRECTION_IN,
                    Transaction_Type__c = DMS_Constants.TXN_INBOUND_GRN,
                    Quantity__c       = usable,
                    Transaction_Date__c = Date.today(),
                    Reference_Type__c = 'GRN',
                    Reference_Id__c   = grn.Id
                ));
            }
        }

        if (!newSnapshots.isEmpty()) {
            insert newSnapshots;
        }
        if (!txns.isEmpty()) {
            insert txns;
        }

        advanceIndents(grnIds, primaryGRNs);
    }

    private void advanceIndents(Set<Id> grnIds, List<GRN__c> primaryGRNs) {
        Set<Id> invoiceIds = new Set<Id>();
        for (GRN__c grn : primaryGRNs) {
            invoiceIds.add(grn.Invoice__c);
        }
        List<Indent__c> indentUpdates = new List<Indent__c>();
        for (Indent__c ind : [
            SELECT Id, Status__c FROM Indent__c WHERE Invoice__c IN :invoiceIds
        ]) {
            if (ind.Status__c != DMS_Constants.INDENT_RECEIVED) {
                indentUpdates.add(new Indent__c(Id = ind.Id, Status__c = DMS_Constants.INDENT_RECEIVED));
            }
        }
        if (!indentUpdates.isEmpty()) {
            TriggerHandler.bypass('DMS_Indent_TriggerHandler');
            try {
                update indentUpdates;
            } finally {
                TriggerHandler.clearBypass('DMS_Indent_TriggerHandler');
            }
        }
    }

    private String stockKey(Id accountId, Id productId, String batch) {
        return String.valueOf(accountId) + '|' + String.valueOf(productId) + '|' +
               (String.isNotBlank(batch) ? batch : '');
    }
}