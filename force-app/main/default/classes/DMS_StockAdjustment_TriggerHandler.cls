/**
 * @description DMS distributor stock-adjustment handler. Complements the
 *              warehouse-only INV_StockAdjustment_TriggerHandler by handling
 *              adjustments where Location_Type = Distributor:
 *                - beforeInsert: snapshot System_Qty from current distributor on-hand
 *                - afterUpdate (Approved): apply the signed Adjustment_Qty by writing
 *                  a new current Distributor_Stock snapshot + a Stock_Transaction.
 *              Inert unless the DMS master + stock-activities toggles are enabled.
 * @author  SFA Development Team
 * @date    2024
 */
public without sharing class DMS_StockAdjustment_TriggerHandler extends TriggerHandler {

    protected override void beforeInsert() {
        if (!enabled()) {
            return;
        }
        List<Stock_Adjustment__c> distAdjustments = distributorRecords((List<Stock_Adjustment__c>) Trigger.new);
        if (distAdjustments.isEmpty()) {
            return;
        }
        Map<String, Decimal> currentClosing = currentClosingFor(distAdjustments);
        for (Stock_Adjustment__c adj : distAdjustments) {
            String k = key(adj.Account__c, adj.Product_Ext__c, adj.Batch_Number__c);
            adj.System_Qty__c = currentClosing.containsKey(k) ? currentClosing.get(k) : 0;
        }
    }

    protected override void afterUpdate() {
        if (!enabled()) {
            return;
        }
        List<Stock_Adjustment__c> newRecords = (List<Stock_Adjustment__c>) Trigger.new;
        Map<Id, Stock_Adjustment__c> oldMap = (Map<Id, Stock_Adjustment__c>) Trigger.oldMap;

        List<Stock_Adjustment__c> newlyApproved = new List<Stock_Adjustment__c>();
        for (Stock_Adjustment__c adj : newRecords) {
            Stock_Adjustment__c oldAdj = oldMap.get(adj.Id);
            if (adj.Location_Type__c == DMS_Constants.LOCATION_DISTRIBUTOR &&
                adj.Status__c == DMS_Constants.ADJ_APPROVED &&
                oldAdj.Status__c != DMS_Constants.ADJ_APPROVED) {
                newlyApproved.add(adj);
            }
        }
        if (!newlyApproved.isEmpty()) {
            applyDistributorAdjustments(newlyApproved);
        }
    }

    private void applyDistributorAdjustments(List<Stock_Adjustment__c> adjustments) {
        Map<String, Decimal> currentClosing = currentClosingFor(adjustments);

        List<Distributor_Stock__c> snapshots = new List<Distributor_Stock__c>();
        List<Stock_Transaction__c> txns = new List<Stock_Transaction__c>();

        for (Stock_Adjustment__c adj : adjustments) {
            if (adj.Account__c == null || adj.Product_Ext__c == null) {
                continue;
            }
            Decimal delta = signedDelta(adj);
            if (delta == 0) {
                continue;
            }
            String k = key(adj.Account__c, adj.Product_Ext__c, adj.Batch_Number__c);
            Decimal opening = currentClosing.containsKey(k) ? currentClosing.get(k) : 0;

            snapshots.add(new Distributor_Stock__c(
                Account__c       = adj.Account__c,
                Product_Ext__c   = adj.Product_Ext__c,
                Batch_No__c      = adj.Batch_Number__c,
                Opening_Stock__c = opening,
                Received_Qty__c  = delta > 0 ? delta : 0,
                Sold_Qty__c      = 0,
                Damaged_Qty__c   = delta < 0 ? Math.abs(delta) : 0,
                Stock_Date__c    = Date.today(),
                Is_Current__c    = true
            ));

            txns.add(new Stock_Transaction__c(
                Account__c          = adj.Account__c,
                Product_Ext__c      = adj.Product_Ext__c,
                Batch_Number__c     = adj.Batch_Number__c,
                Direction__c        = delta > 0 ? DMS_Constants.DIRECTION_IN : DMS_Constants.DIRECTION_OUT,
                Transaction_Type__c = delta > 0 ? DMS_Constants.TXN_ADJUSTMENT_ADD : DMS_Constants.TXN_ADJUSTMENT_DEDUCT,
                Quantity__c         = Math.abs(delta),
                Transaction_Date__c = Date.today(),
                Reference_Type__c   = 'Stock_Adjustment',
                Reference_Id__c     = adj.Id
            ));
        }

        if (!snapshots.isEmpty()) {
            insert snapshots;
        }
        if (!txns.isEmpty()) {
            insert txns;
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private Boolean enabled() {
        return BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_MASTER) &&
               BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_STOCK_ACTIVITIES);
    }

    private List<Stock_Adjustment__c> distributorRecords(List<Stock_Adjustment__c> records) {
        List<Stock_Adjustment__c> result = new List<Stock_Adjustment__c>();
        for (Stock_Adjustment__c adj : records) {
            if (adj.Location_Type__c == DMS_Constants.LOCATION_DISTRIBUTOR) {
                result.add(adj);
            }
        }
        return result;
    }

    /** Signed delta: explicit Adjustment_Qty if set, else Actual - System. */
    private Decimal signedDelta(Stock_Adjustment__c adj) {
        if (adj.Adjustment_Qty__c != null && adj.Adjustment_Qty__c != 0) {
            return adj.Adjustment_Qty__c;
        }
        Decimal actual = adj.Actual_Qty__c != null ? adj.Actual_Qty__c : 0;
        Decimal systemQty = adj.System_Qty__c != null ? adj.System_Qty__c : 0;
        return actual - systemQty;
    }

    /** Current closing stock per account|product|batch for the given adjustments. */
    private Map<String, Decimal> currentClosingFor(List<Stock_Adjustment__c> adjustments) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        for (Stock_Adjustment__c adj : adjustments) {
            accountIds.add(adj.Account__c);
            productIds.add(adj.Product_Ext__c);
        }
        Map<String, Decimal> closing = new Map<String, Decimal>();
        if (accountIds.isEmpty()) {
            return closing;
        }
        for (Distributor_Stock__c ds : [
            SELECT Account__c, Product_Ext__c, Batch_No__c, Closing_Stock__c
            FROM Distributor_Stock__c
            WHERE Account__c IN :accountIds AND Product_Ext__c IN :productIds
              AND Is_Current__c = true
        ]) {
            closing.put(key(ds.Account__c, ds.Product_Ext__c, ds.Batch_No__c),
                        ds.Closing_Stock__c != null ? ds.Closing_Stock__c : 0);
        }
        return closing;
    }

    private String key(Id accountId, Id productId, String batch) {
        return String.valueOf(accountId) + '|' + String.valueOf(productId) + '|' +
               (String.isNotBlank(batch) ? batch : '');
    }
}