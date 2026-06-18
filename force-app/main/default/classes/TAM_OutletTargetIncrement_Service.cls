/**
 * @description Outlet-target auto-increment (BRD §13.2). Given a set of
 *              outlet-tier Target__c records for one Journey Cycle, produces the
 *              next-cycle targets with the value stepped up by the percentage
 *              configured per State + Outlet Type in Outlet_Target_Increment__c.
 *              The base value is the prior cycle's Target or Actual depending on
 *              the config Basis. Pure builder — it does not insert, so it is
 *              easy to preview/test; callers (e.g. TAM_OutletTargetIncrement_Batch)
 *              persist the result.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public with sharing class TAM_OutletTargetIncrement_Service {

    /** One Journey Cycle = 28 days (BRD §8). */
    public static final Integer JC_DAYS = 28;

    public static List<Target__c> buildNextCycleTargets(List<Target__c> sources) {
        List<Target__c> result = new List<Target__c>();
        if (sources == null || sources.isEmpty()) {
            return result;
        }

        Map<String, Outlet_Target_Increment__c> configByKey =
            new Map<String, Outlet_Target_Increment__c>();
        for (Outlet_Target_Increment__c cfg : [
            SELECT State__c, Outlet_Type__c, Increment_Percent__c, Basis__c
            FROM Outlet_Target_Increment__c
            WHERE Is_Active__c = true
        ]) {
            configByKey.put(buildKey(cfg.State__c, cfg.Outlet_Type__c), cfg);
        }

        for (Target__c src : sources) {
            Outlet_Target_Increment__c cfg = configByKey.get(buildKey(src.State__c, src.Outlet_Type__c));
            Decimal pct = (cfg != null && cfg.Increment_Percent__c != null) ? cfg.Increment_Percent__c : 0;
            Boolean onActual = cfg != null && 'Actual'.equalsIgnoreCase(cfg.Basis__c);

            Decimal baseValue = onActual && src.Achievement_Value__c != null
                ? src.Achievement_Value__c
                : (src.Target_Value__c == null ? 0 : src.Target_Value__c);
            Decimal newValue = (baseValue * (1 + (pct / 100))).setScale(2);

            Target__c next = new Target__c(
                Tier__c = 'Outlet',
                Account__c = src.Account__c,
                Product__c = src.Product__c,
                Brand__c = src.Brand__c,
                State__c = src.State__c,
                Outlet_Type__c = src.Outlet_Type__c,
                Target_Type__c = src.Target_Type__c,
                Target_Value__c = newValue,
                Set_By__c = UserInfo.getUserId()
            );
            if (src.Period_Start__c != null) {
                next.Period_Start__c = src.Period_Start__c.addDays(JC_DAYS);
            }
            if (src.Period_End__c != null) {
                next.Period_End__c = src.Period_End__c.addDays(JC_DAYS);
            }
            result.add(next);
        }
        return result;
    }

    private static String buildKey(String state, String outletType) {
        return (state == null ? '' : state.trim().toLowerCase())
            + '|' + (outletType == null ? '' : outletType.trim().toLowerCase());
    }
}
