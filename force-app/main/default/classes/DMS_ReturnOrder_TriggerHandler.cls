/**
 * @description DMS return posting. When a SECONDARY return (retailer → distributor)
 *              is approved, posts the returned goods back into the distributor's
 *              Distributor_Stock__c (new current snapshot) and writes a distributor
 *              Stock_Transaction__c (In). Credit notes for the returning account are
 *              still handled by OMS_ReturnOrder_TriggerHandler (both return types);
 *              primary returns continue to restock the company warehouse there.
 *              Inert unless the DMS master + returns toggles are enabled.
 * @author  SFA Development Team
 * @date    2024
 */
public without sharing class DMS_ReturnOrder_TriggerHandler extends TriggerHandler {

    protected override void afterUpdate() {
        if (!BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_MASTER) ||
            !BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_RETURNS)) {
            return;
        }

        List<Return_Order__c> newRecords = (List<Return_Order__c>) Trigger.new;
        Map<Id, Return_Order__c> oldMap = (Map<Id, Return_Order__c>) Trigger.oldMap;

        List<Return_Order__c> secondaryApproved = new List<Return_Order__c>();
        Set<Id> invoiceIds = new Set<Id>();
        for (Return_Order__c ret : newRecords) {
            Return_Order__c oldRet = oldMap.get(ret.Id);
            if (ret.Return_Type__c == DMS_Constants.RETURN_TYPE_SECONDARY &&
                ret.Status__c == 'Approved' && oldRet.Status__c != 'Approved') {
                secondaryApproved.add(ret);
                if (ret.Invoice__c != null) {
                    invoiceIds.add(ret.Invoice__c);
                }
            }
        }
        if (secondaryApproved.isEmpty()) {
            return;
        }

        // Resolve the distributor: explicit field, else the secondary invoice's source.
        Map<Id, Id> invoiceToDistributor = new Map<Id, Id>();
        for (Invoice__c inv : [
            SELECT Id, Sold_From_Distributor__c FROM Invoice__c WHERE Id IN :invoiceIds
        ]) {
            invoiceToDistributor.put(inv.Id, inv.Sold_From_Distributor__c);
        }

        Map<Id, Id> distributorByReturn = new Map<Id, Id>();
        for (Return_Order__c ret : secondaryApproved) {
            Id distributorId = ret.Returned_To_Distributor__c != null
                ? ret.Returned_To_Distributor__c
                : (ret.Invoice__c != null ? invoiceToDistributor.get(ret.Invoice__c) : null);
            if (distributorId != null) {
                distributorByReturn.put(ret.Id, distributorId);
            }
        }
        if (distributorByReturn.isEmpty()) {
            return;
        }

        postReturnedStock(distributorByReturn);
    }

    private void postReturnedStock(Map<Id, Id> distributorByReturn) {
        Set<Id> returnIds = distributorByReturn.keySet();

        Map<Id, List<Return_Line__c>> linesByReturn = new Map<Id, List<Return_Line__c>>();
        Set<Id> productIds = new Set<Id>();
        for (Return_Line__c line : [
            SELECT Id, Return_Order__c, Product_Ext__c, Quantity__c, Return_Quantity__c,
                   Batch_No__c, Expiry_Date__c
            FROM Return_Line__c
            WHERE Return_Order__c IN :returnIds
        ]) {
            if (!linesByReturn.containsKey(line.Return_Order__c)) {
                linesByReturn.put(line.Return_Order__c, new List<Return_Line__c>());
            }
            linesByReturn.get(line.Return_Order__c).add(line);
            if (line.Product_Ext__c != null) {
                productIds.add(line.Product_Ext__c);
            }
        }
        if (linesByReturn.isEmpty()) {
            return;
        }

        // Current closing per distributor+product+batch for opening balances.
        Map<String, Decimal> currentClosing = new Map<String, Decimal>();
        for (Distributor_Stock__c ds : [
            SELECT Account__c, Product_Ext__c, Batch_No__c, Closing_Stock__c
            FROM Distributor_Stock__c
            WHERE Account__c IN :distributorByReturn.values()
              AND Product_Ext__c IN :productIds AND Is_Current__c = true
        ]) {
            currentClosing.put(stockKey(ds.Account__c, ds.Product_Ext__c, ds.Batch_No__c),
                               ds.Closing_Stock__c != null ? ds.Closing_Stock__c : 0);
        }

        List<Distributor_Stock__c> snapshots = new List<Distributor_Stock__c>();
        List<Stock_Transaction__c> txns = new List<Stock_Transaction__c>();

        for (Id returnId : returnIds) {
            Id distributorId = distributorByReturn.get(returnId);
            List<Return_Line__c> lines = linesByReturn.get(returnId);
            if (lines == null) {
                continue;
            }
            for (Return_Line__c line : lines) {
                Decimal qty = line.Return_Quantity__c != null && line.Return_Quantity__c > 0
                    ? line.Return_Quantity__c
                    : (line.Quantity__c != null ? line.Quantity__c : 0);
                if (qty <= 0 || line.Product_Ext__c == null) {
                    continue;
                }
                String key = stockKey(distributorId, line.Product_Ext__c, line.Batch_No__c);
                Decimal opening = currentClosing.containsKey(key) ? currentClosing.get(key) : 0;

                snapshots.add(new Distributor_Stock__c(
                    Account__c       = distributorId,
                    Product_Ext__c   = line.Product_Ext__c,
                    Batch_No__c      = line.Batch_No__c,
                    Expiry_Date__c   = line.Expiry_Date__c,
                    Opening_Stock__c = opening,
                    Received_Qty__c  = qty,
                    Sold_Qty__c      = 0,
                    Damaged_Qty__c   = 0,
                    Stock_Date__c    = Date.today(),
                    Is_Current__c    = true
                ));

                txns.add(new Stock_Transaction__c(
                    Account__c          = distributorId,
                    Product_Ext__c      = line.Product_Ext__c,
                    Batch_Number__c     = line.Batch_No__c,
                    Direction__c        = DMS_Constants.DIRECTION_IN,
                    Transaction_Type__c = DMS_Constants.TXN_INBOUND_GRN,
                    Quantity__c         = qty,
                    Transaction_Date__c = Date.today(),
                    Reference_Type__c   = 'Return_Order',
                    Reference_Id__c     = returnId
                ));
            }
        }

        if (!snapshots.isEmpty()) {
            insert snapshots;
        }
        if (!txns.isEmpty()) {
            insert txns;
        }
    }

    private String stockKey(Id accountId, Id productId, String batch) {
        return String.valueOf(accountId) + '|' + String.valueOf(productId) + '|' +
               (String.isNotBlank(batch) ? batch : '');
    }
}