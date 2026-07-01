/**
 * @description Target-vs-Actuals engine for the tiered targets of BRD §13.
 *              Computes each Target__c's actual from the correct source per tier,
 *              scoped by the target's customer / user and product hierarchy over
 *              the target's JC period, then updates Achievement Value / % in place:
 *
 *                - P1, P2   → actuals from INVOICES  (Invoice_Line__c) for the
 *                             target's Customer (SS / DB / SD).
 *                - Secondary→ actuals from SECONDARY ORDERS (Order_Line_Item__c)
 *                             for the target's User.
 *                - Outlet   → actuals from SECONDARY ORDERS for the target's
 *                             Customer (the outlet).
 *
 *              Product hierarchy (Brand → Sub Brand → Brand Alias → SKU) is applied
 *              from Target_Product_Level__c. Revenue = SUM(Net Amount),
 *              Volume = SUM(Quantity). Config-driven and additive — the legacy
 *              TAM_Achievement_Service is untouched.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public without sharing class TAM_TargetActuals_Service {

    private static final Set<String> TIERS = new Set<String>{ 'P1', 'P2', 'Secondary', 'Outlet' };
    // Sales_Order.Order_Status__c values that count as a placed secondary sale.
    private static final Set<String> ORDER_STATUSES = new Set<String>{
        'Submitted', 'Approved'
    };

    /** Bulk: compute + persist actuals for a list of tiered targets. */
    public static void calculateForTargets(List<Target__c> targets) {
        if (targets == null || targets.isEmpty()) { return; }
        List<Target__c> updates = new List<Target__c>();
        for (Target__c t : targets) {
            if (t.Tier__c == null || !TIERS.contains(t.Tier__c)) { continue; }
            Decimal actual = computeActual(t);
            Decimal tv = t.Target_Value__c == null ? 0 : t.Target_Value__c;
            Decimal pct = tv > 0 ? (actual / tv * 100).setScale(2, RoundingMode.HALF_UP) : 0;
            updates.add(new Target__c(
                Id = t.Id,
                Achievement_Value__c = actual,
                Achievement_Percent__c = pct,
                Last_Calculated__c = DateTime.now()
            ));
        }
        if (!updates.isEmpty()) { update updates; }
    }

    /** Convenience: compute for a single target by Id. */
    public static void calculateForTarget(Id targetId) {
        if (targetId == null) { return; }
        calculateForTargets(queryTargets(new Set<Id>{ targetId }));
    }

    public static List<Target__c> queryTargets(Set<Id> ids) {
        return [
            SELECT Id, Tier__c, Target_Type__c, Target_Value__c, Target_Product_Level__c,
                   Customer__c, User__c, Salesperson__c, Brand__c, Sub_Brand__c, Brand_Alias__c,
                   Product__c, Product_Ext__c, Period_Start__c, Period_End__c
            FROM Target__c WHERE Id IN :ids
        ];
    }

    private static Decimal computeActual(Target__c t) {
        String metric = t.Target_Type__c == 'Volume' ? 'SUM(Quantity__c) v'
                      : t.Target_Type__c == 'Revenue' ? 'SUM(Net_Amount__c) v'
                      : null;
        if (metric == null) { return 0; }

        Date ps = t.Period_Start__c;
        Date pe = t.Period_End__c;
        if (ps == null || pe == null) { return 0; }

        Id cust = t.Customer__c;
        Id usr = t.User__c != null ? t.User__c : t.Salesperson__c;
        Id pext = t.Product_Ext__c;
        Id prod = t.Product__c;
        String brand = t.Brand__c;
        String subbrand = t.Sub_Brand__c;
        String alias = t.Brand_Alias__c;
        Set<String> statuses = ORDER_STATUSES;

        String obj;
        String whereClause;
        if (t.Tier__c == 'P1' || t.Tier__c == 'P2') {
            if (cust == null) { return 0; }
            obj = 'Invoice_Line__c';
            whereClause = 'Invoice__r.Account__c = :cust'
                + ' AND Invoice__r.Invoice_Date__c >= :ps AND Invoice__r.Invoice_Date__c <= :pe'
                + ' AND Invoice__r.Status__c != \'Cancelled\'';
        } else if (t.Tier__c == 'Secondary') {
            if (usr == null) { return 0; }
            obj = 'Order_Line_Item__c';
            whereClause = '(Sales_Order__r.Sales_Rep__c = :usr OR Sales_Order__r.Salesperson__c = :usr)'
                + ' AND Sales_Order__r.Order_Date__c >= :ps AND Sales_Order__r.Order_Date__c <= :pe'
                + ' AND Sales_Order__r.Order_Status__c IN :statuses';
        } else { // Outlet
            if (cust == null) { return 0; }
            obj = 'Order_Line_Item__c';
            whereClause = 'Sales_Order__r.Account__c = :cust'
                + ' AND Sales_Order__r.Order_Date__c >= :ps AND Sales_Order__r.Order_Date__c <= :pe'
                + ' AND Sales_Order__r.Order_Status__c IN :statuses';
        }

        // Product-hierarchy scope from the target's level
        String lvl = t.Target_Product_Level__c;
        if (lvl == 'SKU' && (pext != null || prod != null)) {
            whereClause += pext != null ? ' AND Product_Ext__c = :pext' : ' AND Product__c = :prod';
        } else if (lvl == 'Brand' && String.isNotBlank(brand)) {
            whereClause += ' AND Product_Ext__r.Brand__c = :brand';
        } else if (lvl == 'Sub Brand' && String.isNotBlank(subbrand)) {
            whereClause += ' AND Product_Ext__r.Sub_Brand__c = :subbrand';
        } else if (lvl == 'Brand Alias' && String.isNotBlank(alias)) {
            whereClause += ' AND Product_Ext__r.Brand_Alias__c = :alias';
        }

        try {
            List<AggregateResult> rs = Database.query(
                'SELECT ' + metric + ' FROM ' + obj + ' WHERE ' + whereClause
            );
            if (rs.isEmpty() || rs[0].get('v') == null) { return 0; }
            return (Decimal) rs[0].get('v');
        } catch (Exception e) {
            return 0;
        }
    }
}
