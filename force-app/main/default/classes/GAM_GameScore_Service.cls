/**
 * @description Gamification scoring service (BRD §20.1). Evaluates a user's
 *              achievement against the slabs of a Game KPI and computes the
 *              coins awarded / qualification. Deterministic and side-effect free
 *              so it can be unit-tested and reused by the batch and the API layer.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public without sharing class GAM_GameScore_Service {

    /** Result of evaluating an achievement against a set of slabs. */
    public class SlabResult {
        public Integer coins = 0;
        public Boolean qualified = false;
        public Game_KPI__c matchedSlab;
    }

    /**
     * Returns the highest slab whose cutoff the achievement meets, the coins it
     * awards (zero for Qualifier KPIs), and whether the user qualified.
     */
    public static SlabResult evaluate(Decimal achievement, List<Game_KPI__c> slabs) {
        SlabResult result = new SlabResult();
        if (achievement == null || slabs == null || slabs.isEmpty()) {
            return result;
        }
        Game_KPI__c best;
        for (Game_KPI__c slab : slabs) {
            Decimal cutoff = slab.Cutoff_Value__c == null ? 0 : slab.Cutoff_Value__c;
            if (achievement >= cutoff) {
                Decimal bestCutoff = (best == null || best.Cutoff_Value__c == null) ? -1 : best.Cutoff_Value__c;
                if (best == null || cutoff > bestCutoff) {
                    best = slab;
                }
            }
        }
        if (best != null) {
            result.matchedSlab = best;
            result.qualified = true;
            if (best.KPI_Type__c != 'Qualifier' && best.Reward_Coins__c != null) {
                result.coins = (Integer) best.Reward_Coins__c;
            }
        }
        return result;
    }

    /**
     * Recomputes Is_Qualified / Target / Target Coins / Coins Awarded on each
     * Game Score from its linked Game KPI slab and captured Achievement.
     * Mutates the records in place (caller performs the DML).
     */
    public static void recomputeScores(List<Game_Score__c> scores) {
        if (scores == null || scores.isEmpty()) {
            return;
        }
        Set<Id> kpiIds = new Set<Id>();
        for (Game_Score__c score : scores) {
            if (score.Game_KPI__c != null) {
                kpiIds.add(score.Game_KPI__c);
            }
        }
        Map<Id, Game_KPI__c> kpiById = new Map<Id, Game_KPI__c>([
            SELECT Id, KPI_Type__c, Cutoff_Value__c, Reward_Coins__c
            FROM Game_KPI__c
            WHERE Id IN :kpiIds
        ]);

        for (Game_Score__c score : scores) {
            Game_KPI__c kpi = kpiById.get(score.Game_KPI__c);
            if (kpi == null) {
                continue;
            }
            Decimal cutoff = kpi.Cutoff_Value__c == null ? 0 : kpi.Cutoff_Value__c;
            Boolean qualified = score.Achievement__c != null && score.Achievement__c >= cutoff;

            score.Is_Qualified__c = qualified;
            score.Target__c = kpi.Cutoff_Value__c;
            score.Target_Coins__c = kpi.Reward_Coins__c;
            score.Coins_Awarded__c =
                (qualified && kpi.KPI_Type__c != 'Qualifier' && kpi.Reward_Coins__c != null)
                    ? kpi.Reward_Coins__c
                    : 0;
        }
    }
}
