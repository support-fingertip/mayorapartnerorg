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
        Decimal bestCoins = -1;
        for (Game_KPI__c slab : slabs) {
            Decimal cutoff = slab.Cutoff_Value__c == null ? 0 : slab.Cutoff_Value__c;
            if (meetsCriteria(achievement, cutoff, slab.Eligibility_Criteria__c)) {
                Decimal coins = slab.Reward_Coins__c == null ? 0 : slab.Reward_Coins__c;
                if (best == null || coins > bestCoins) {
                    best = slab;
                    bestCoins = coins;
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
            SELECT Id, KPI_Type__c, Cutoff_Value__c, Reward_Coins__c, Eligibility_Criteria__c
            FROM Game_KPI__c
            WHERE Id IN :kpiIds
        ]);

        for (Game_Score__c score : scores) {
            Game_KPI__c kpi = kpiById.get(score.Game_KPI__c);
            if (kpi == null) {
                continue;
            }
            Decimal cutoff = kpi.Cutoff_Value__c == null ? 0 : kpi.Cutoff_Value__c;
            Boolean qualified = score.Achievement__c != null
                && meetsCriteria(score.Achievement__c, cutoff, kpi.Eligibility_Criteria__c);

            score.Is_Qualified__c = qualified;
            score.Target__c = kpi.Cutoff_Value__c;
            score.Target_Coins__c = kpi.Reward_Coins__c;
            score.Coins_Awarded__c =
                (qualified && kpi.KPI_Type__c != 'Qualifier' && kpi.Reward_Coins__c != null)
                    ? kpi.Reward_Coins__c
                    : 0;
        }
    }

    /**
     * Computes actuals + coins for every user in each active game's team(s), for
     * each game KPI, and upserts Game Score keyed by (game KPI, user, today).
     * Pass null to score all users, or a set of user Ids to score just those.
     */
    /** Calculate scores for every team member in every active game. */
    public static void runForAll() {
        calculateScores(null);
    }

    /** Calculate scores for a single salesperson across the active games they're in. */
    public static void runForUser(Id userId) {
        calculateScores(userId == null ? null : new Set<Id>{ userId });
    }

    public static void calculateScores(Set<Id> userIds) {
        Map<Id, Game__c> gameById = new Map<Id, Game__c>([
            SELECT Id, Type__c, Start_Date__c, End_Date__c FROM Game__c WHERE Is_Active__c = true
        ]);
        if (gameById.isEmpty()) { return; }

        Map<Id, Set<Id>> gameTeams = new Map<Id, Set<Id>>();
        for (Game_Team__c gt : [SELECT Game__c, Battleground_Team__c FROM Game_Team__c WHERE Game__c IN :gameById.keySet()]) {
            if (gt.Battleground_Team__c == null) { continue; }
            if (!gameTeams.containsKey(gt.Game__c)) { gameTeams.put(gt.Game__c, new Set<Id>()); }
            gameTeams.get(gt.Game__c).add(gt.Battleground_Team__c);
        }
        Set<Id> teamIds = new Set<Id>();
        for (Set<Id> s : gameTeams.values()) { teamIds.addAll(s); }
        Map<Id, Set<Id>> teamMembers = new Map<Id, Set<Id>>();
        for (Team_Member__c tm : [SELECT Battleground_Team__c, Member__c FROM Team_Member__c WHERE Battleground_Team__c IN :teamIds]) {
            if (tm.Member__c == null) { continue; }
            if (userIds != null && !userIds.contains(tm.Member__c)) { continue; }
            if (!teamMembers.containsKey(tm.Battleground_Team__c)) { teamMembers.put(tm.Battleground_Team__c, new Set<Id>()); }
            teamMembers.get(tm.Battleground_Team__c).add(tm.Member__c);
        }

        Map<Id, Map<Id, List<Game_KPI__c>>> gameKpiSlabs = new Map<Id, Map<Id, List<Game_KPI__c>>>();
        Set<Id> bgKpiIds = new Set<Id>();
        for (Game_KPI__c gk : [
            SELECT Id, Game__c, Battleground_KPI__c, Is_Qualifier__c, Slab_Number__c,
                   Cutoff_Value__c, Reward_Coins__c, Eligibility_Criteria__c
            FROM Game_KPI__c WHERE Game__c IN :gameById.keySet()
            ORDER BY Battleground_KPI__c, Slab_Number__c NULLS FIRST
        ]) {
            if (gk.Battleground_KPI__c == null) { continue; }
            if (!gameKpiSlabs.containsKey(gk.Game__c)) { gameKpiSlabs.put(gk.Game__c, new Map<Id, List<Game_KPI__c>>()); }
            Map<Id, List<Game_KPI__c>> byKpi = gameKpiSlabs.get(gk.Game__c);
            if (!byKpi.containsKey(gk.Battleground_KPI__c)) { byKpi.put(gk.Battleground_KPI__c, new List<Game_KPI__c>()); }
            byKpi.get(gk.Battleground_KPI__c).add(gk);
            bgKpiIds.add(gk.Battleground_KPI__c);
        }

        // Per-KPI calculation mapping: prefer the KPI's own Source Object / fields,
        // fall back to the linked KPI_Metric for any legacy KPIs.
        Map<Id, Src> kpiSource = new Map<Id, Src>();
        for (Battleground_KPI__c bk : [
            SELECT Id, Source_Object__c, Aggregation__c, Aggregate_Field__c, Date_Field__c, User_Field__c,
                   KPI_Metric__r.Source_Object__c, KPI_Metric__r.Aggregation__c, KPI_Metric__r.Aggregate_Field__c,
                   KPI_Metric__r.Date_Field__c, KPI_Metric__r.User_Field__c
            FROM Battleground_KPI__c WHERE Id IN :bgKpiIds
        ]) {
            Src s = new Src();
            if (String.isNotBlank(bk.Source_Object__c)) {
                s.obj = bk.Source_Object__c; s.agg = bk.Aggregation__c; s.aggField = bk.Aggregate_Field__c;
                s.dateField = bk.Date_Field__c; s.userField = bk.User_Field__c;
            } else if (bk.KPI_Metric__r != null) {
                s.obj = bk.KPI_Metric__r.Source_Object__c; s.agg = bk.KPI_Metric__r.Aggregation__c;
                s.aggField = bk.KPI_Metric__r.Aggregate_Field__c; s.dateField = bk.KPI_Metric__r.Date_Field__c;
                s.userField = bk.KPI_Metric__r.User_Field__c;
            }
            kpiSource.put(bk.Id, s);
        }

        Date scoreDate = Date.today();
        Map<String, Game_Score__c> existing = new Map<String, Game_Score__c>();
        for (Game_Score__c sc : [
            SELECT Id, Game_KPI__c, Salesperson__c, Score_Date__c
            FROM Game_Score__c WHERE Game__c IN :gameById.keySet() AND Score_Date__c = :scoreDate
        ]) {
            existing.put(scoreKey(sc.Game_KPI__c, sc.Salesperson__c, sc.Score_Date__c), sc);
        }

        List<Game_Score__c> toUpsert = new List<Game_Score__c>();
        for (Id gameId : gameById.keySet()) {
            Game__c game = gameById.get(gameId);
            Set<Id> teamsForGame = gameTeams.get(gameId);
            Map<Id, List<Game_KPI__c>> kpiMap = gameKpiSlabs.get(gameId);
            if (teamsForGame == null || kpiMap == null) { continue; }
            Set<Id> users = new Set<Id>();
            for (Id tId : teamsForGame) {
                if (teamMembers.containsKey(tId)) { users.addAll(teamMembers.get(tId)); }
            }
            for (Id userId : users) {
                for (Id bgKpiId : kpiMap.keySet()) {
                    List<Game_KPI__c> slabs = kpiMap.get(bgKpiId);
                    Decimal actual = computeActual(kpiSource.get(bgKpiId), userId, game.Start_Date__c, game.End_Date__c);
                    Game_KPI__c best;
                    Decimal bestCoins = -1;
                    Boolean qualified = false;
                    for (Game_KPI__c slab : slabs) {
                        Decimal cut = slab.Cutoff_Value__c == null ? 0 : slab.Cutoff_Value__c;
                        if (meetsCriteria(actual, cut, slab.Eligibility_Criteria__c)) {
                            qualified = true;
                            Decimal coins = slab.Reward_Coins__c == null ? 0 : slab.Reward_Coins__c;
                            if (best == null || coins > bestCoins) { best = slab; bestCoins = coins; }
                        }
                    }
                    Game_KPI__c ref = best != null ? best : slabs[0];
                    Decimal coins = (best != null && best.Is_Qualifier__c != true && best.Reward_Coins__c != null) ? best.Reward_Coins__c : 0;
                    String k = scoreKey(ref.Id, userId, scoreDate);
                    Game_Score__c sc = existing.containsKey(k)
                        ? existing.get(k)
                        : new Game_Score__c(Game__c = gameId, Game_KPI__c = ref.Id, Salesperson__c = userId, Score_Date__c = scoreDate);
                    sc.Achievement__c = actual;
                    sc.Target__c = ref.Cutoff_Value__c;
                    sc.Target_Coins__c = ref.Reward_Coins__c;
                    sc.Is_Qualified__c = qualified;
                    sc.Coins_Awarded__c = coins;
                    toUpsert.add(sc);
                }
            }
        }
        if (!toUpsert.isEmpty()) { upsert toUpsert; }
    }

    private static String scoreKey(Id kpiId, Id userId, Date d) {
        return String.valueOf(kpiId) + '|' + String.valueOf(userId) + '|' + String.valueOf(d);
    }

    /**
     * Applies the slab's Eligibility Criteria operator. Defaults to "At least"
     * (>=) when no criteria is set, preserving existing behaviour.
     */
    public static Boolean meetsCriteria(Decimal actual, Decimal target, String criteria) {
        if (actual == null) { return false; }
        Decimal t = target == null ? 0 : target;
        String c = String.isBlank(criteria) ? 'At least' : criteria;
        if (c == 'At least')     { return actual >= t; }
        if (c == 'Greater than') { return actual >  t; }
        if (c == 'At most')      { return actual <= t; }
        if (c == 'Less than')    { return actual <  t; }
        if (c == 'Equal to')     { return actual == t; }
        return actual >= t;
    }

    /** Calculation mapping for a KPI's actual (object + aggregation + filter fields). */
    public class Src {
        public String obj;
        public String agg;
        public String aggField;
        public String dateField;
        public String userField;
    }

    private static Decimal computeActual(Src s, Id userId, Date fromDate, Date toDate) {
        if (s == null || String.isBlank(s.obj)
            || String.isBlank(s.userField) || String.isBlank(s.dateField)) {
            return 0;
        }
        try {
            String agg = String.isBlank(s.agg) ? 'COUNT' : s.agg.toUpperCase();
            String sel = (agg == 'COUNT' || String.isBlank(s.aggField))
                ? 'COUNT(Id) val'
                : agg + '(' + s.aggField + ') val';
            Date fromD = fromDate == null ? Date.today() : fromDate;
            Date toD = toDate == null ? Date.today() : toDate;
            String q = 'SELECT ' + sel + ' FROM ' + s.obj
                + ' WHERE ' + s.userField + ' = :userId'
                + ' AND ' + s.dateField + ' >= :fromD'
                + ' AND ' + s.dateField + ' <= :toD';
            List<AggregateResult> rs = Database.query(q);
            if (rs.isEmpty() || rs[0].get('val') == null) { return 0; }
            return (Decimal) rs[0].get('val');
        } catch (Exception e) {
            return 0;
        }
    }
}
