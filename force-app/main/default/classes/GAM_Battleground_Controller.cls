/**
 * @description Controller for the unified Battleground Console (BRD 20.1) — the
 *              single admin UI that replaces FieldAssist's separate Teams / Games /
 *              Awards / Battleground KPIs / User-Team Mapping screens. Cacheable
 *              list getters, bulk upsert savers, and lookup option lists for the
 *              grid comboboxes.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public with sharing class GAM_Battleground_Controller {

    // ----- Teams -----
    @AuraEnabled(cacheable=true)
    public static List<Battleground_Team__c> getTeams() {
        return [SELECT Id, Name, Team_Code__c, Level__c, State__c, Manager__c, Is_Active__c
                FROM Battleground_Team__c ORDER BY Name];
    }
    @AuraEnabled public static void saveTeams(List<Battleground_Team__c> records) { upsert records; }

    /**
     * Creates / updates a team and replaces its membership in one transaction so the
     * Teams area can save a team and its selected users together.
     */
    @AuraEnabled
    public static Id saveTeamWithMembers(Battleground_Team__c team, List<Id> memberIds) {
        upsert team;
        delete [SELECT Id FROM Team_Member__c WHERE Battleground_Team__c = :team.Id];
        if (memberIds != null && !memberIds.isEmpty()) {
            List<Team_Member__c> members = new List<Team_Member__c>();
            for (Id uid : memberIds) {
                members.add(new Team_Member__c(Battleground_Team__c = team.Id, Member__c = uid));
            }
            insert members;
        }
        return team.Id;
    }

    /** Member user Ids for a team (used to pre-select the multi-select on edit). */
    @AuraEnabled(cacheable=true)
    public static List<Id> getTeamMemberIds(Id teamId) {
        List<Id> ids = new List<Id>();
        for (Team_Member__c tm : [SELECT Member__c FROM Team_Member__c WHERE Battleground_Team__c = :teamId]) {
            if (tm.Member__c != null) { ids.add(tm.Member__c); }
        }
        return ids;
    }

    // ----- User-Team Mapping -----
    @AuraEnabled(cacheable=true)
    public static List<Team_Member__c> getTeamMembers(Id teamId) {
        return [SELECT Id, Name, Member__c FROM Team_Member__c
                WHERE Battleground_Team__c = :teamId ORDER BY Name];
    }
    @AuraEnabled public static void saveTeamMembers(List<Team_Member__c> records) { upsert records; }

    // ----- Battleground KPIs -----
    @AuraEnabled(cacheable=true)
    public static List<Battleground_KPI__c> getKpis() {
        return [SELECT Id, Name, UI_Name__c, Category__c, Frequency__c, Objective__c,
                       Calculation__c, Measure__c, KPI_Type__c, Tier__c, Sequence__c,
                       Is_Qualifier__c, Is_Incentive__c, KPI_Metric__c, Is_Active__c,
                       Source_Object__c, Aggregation__c, Aggregate_Field__c, Date_Field__c, User_Field__c
                FROM Battleground_KPI__c ORDER BY Category__c, Sequence__c NULLS FIRST];
    }
    @AuraEnabled public static void saveKpis(List<Battleground_KPI__c> records) { upsert records; }

    /** Selectable source objects (custom objects + common standard objects). */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSourceObjects() {
        Set<String> standardAllow = new Set<String>{
            'Account', 'Contact', 'Lead', 'Task', 'Event', 'Opportunity',
            'OpportunityLineItem', 'Order', 'OrderItem', 'Case'
        };
        Map<String, String> byLabel = new Map<String, String>();
        for (Schema.SObjectType t : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult d = t.getDescribe();
            String api = d.getName();
            if (!d.isQueryable() || !d.isAccessible()) { continue; }
            Boolean isCustom = d.isCustom() && api.endsWith('__c');
            if (isCustom || standardAllow.contains(api)) {
                byLabel.put(d.getLabel() + ' (' + api + ')', api);
            }
        }
        return sortedOptions(byLabel);
    }

    /**
     * Fields of an object filtered by kind: 'number' (numeric), 'date'
     * (date/datetime), 'user' (User lookups), or anything else for all fields.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getObjectFields(String objectApiName, String kind) {
        Map<String, String> byLabel = new Map<String, String>();
        if (String.isBlank(objectApiName)) { return new List<Map<String, String>>(); }
        Schema.SObjectType t = Schema.getGlobalDescribe().get(objectApiName);
        if (t == null) { return new List<Map<String, String>>(); }
        for (Schema.SObjectField f : t.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fd = f.getDescribe();
            if (!fd.isAccessible()) { continue; }
            Schema.DisplayType ty = fd.getType();
            Boolean ok;
            if (kind == 'number') {
                ok = ty == Schema.DisplayType.INTEGER || ty == Schema.DisplayType.DOUBLE
                    || ty == Schema.DisplayType.CURRENCY || ty == Schema.DisplayType.PERCENT
                    || ty == Schema.DisplayType.LONG;
            } else if (kind == 'date') {
                ok = ty == Schema.DisplayType.DATE || ty == Schema.DisplayType.DATETIME;
            } else if (kind == 'user') {
                ok = ty == Schema.DisplayType.REFERENCE && fd.getReferenceTo().contains(User.SObjectType);
            } else {
                ok = true;
            }
            if (ok) { byLabel.put(fd.getLabel() + ' (' + fd.getName() + ')', fd.getName()); }
        }
        return sortedOptions(byLabel);
    }

    private static List<Map<String, String>> sortedOptions(Map<String, String> byLabel) {
        List<String> labels = new List<String>(byLabel.keySet());
        labels.sort();
        List<Map<String, String>> opts = new List<Map<String, String>>();
        for (String l : labels) {
            opts.add(new Map<String, String>{ 'label' => l, 'value' => byLabel.get(l) });
        }
        return opts;
    }

    // ----- Games -----
    @AuraEnabled(cacheable=true)
    public static List<Game__c> getGames() {
        return [SELECT Id, Name, Team_Name__c, Start_Date__c, End_Date__c, Is_Active__c
                FROM Game__c ORDER BY Name];
    }
    @AuraEnabled public static void saveGames(List<Game__c> records) { upsert records; }

    // ----- Game ↔ Team -----
    @AuraEnabled(cacheable=true)
    public static List<Game_Team__c> getGameTeams(Id gameId) {
        return [SELECT Id, Name, Battleground_Team__c FROM Game_Team__c
                WHERE Game__c = :gameId ORDER BY Name];
    }
    @AuraEnabled public static void saveGameTeams(List<Game_Team__c> records) { upsert records; }

    // ----- Game ↔ KPI -----
    @AuraEnabled(cacheable=true)
    public static List<Game_KPI__c> getGameKpis(Id gameId) {
        return [SELECT Id, Name, Battleground_KPI__c, Category__c, KPI_Type__c,
                       Slab_Number__c, Cutoff_Value__c, Reward_Coins__c
                FROM Game_KPI__c WHERE Game__c = :gameId ORDER BY Slab_Number__c NULLS FIRST];
    }
    @AuraEnabled public static void saveGameKpis(List<Game_KPI__c> records) { upsert records; }

    // ----- Awards -----
    @AuraEnabled(cacheable=true)
    public static List<Award__c> getAwards() {
        return [SELECT Id, Name, Game__c, Battleground_KPI__c, Coins__c, Description__c, Is_Active__c
                FROM Award__c ORDER BY CreatedDate DESC];
    }
    @AuraEnabled public static void saveAwards(List<Award__c> records) { upsert records; }

    // ----- Lookup options -----
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getLookupOptions(String objectApiName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Set<String> allowed = new Set<String>{
            'User', 'Battleground_Team__c', 'Battleground_KPI__c', 'Game__c', 'KPI_Metric__c'
        };
        if (String.isBlank(objectApiName) || !allowed.contains(objectApiName)) {
            return options;
        }
        String filter = objectApiName == 'User' ? ' WHERE IsActive = true' : '';
        for (SObject rec : Database.query(
                'SELECT Id, Name FROM ' + String.escapeSingleQuotes(objectApiName)
                + filter + ' ORDER BY Name LIMIT 2000')) {
            options.add(new Map<String, String>{
                'label' => String.valueOf(rec.get('Name')),
                'value' => String.valueOf(rec.get('Id'))
            });
        }
        return options;
    }

    // ===== Guided game wizard (create/update a whole game in one transaction) =====
    public class Slab {
        @AuraEnabled public Decimal target { get; set; }
        @AuraEnabled public Decimal coins { get; set; }
    }
    public class KpiAward {
        @AuraEnabled public Id kpiId { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String measure { get; set; }
        @AuraEnabled public Boolean isQualifier { get; set; }
        @AuraEnabled public Boolean useSlabs { get; set; }
        @AuraEnabled public Boolean isContinuous { get; set; }
        @AuraEnabled public String criteria { get; set; }   // eligibility operator
        @AuraEnabled public String reward { get; set; }
        @AuraEnabled public List<Slab> slabs { get; set; }
    }
    public class GameWizard {
        @AuraEnabled public Id gameId { get; set; }
        @AuraEnabled public String gameName { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String gameType { get; set; }   // Daily / Monthly
        @AuraEnabled public Boolean isActive { get; set; }
        @AuraEnabled public List<Id> teamIds { get; set; }  // teams the game applies to
        @AuraEnabled public List<KpiAward> kpis { get; set; }
    }

    /** Loads a whole game back into the wizard structure for editing. */
    @AuraEnabled
    public static GameWizard getGameForEdit(Id gameId) {
        Game__c g = [SELECT Id, Name, Type__c, Start_Date__c, End_Date__c, Is_Active__c
                     FROM Game__c WHERE Id = :gameId LIMIT 1];
        GameWizard w = new GameWizard();
        w.gameId = g.Id; w.gameName = g.Name; w.gameType = g.Type__c;
        w.startDate = g.Start_Date__c; w.endDate = g.End_Date__c; w.isActive = g.Is_Active__c;
        w.teamIds = new List<Id>();
        for (Game_Team__c gt : [SELECT Battleground_Team__c FROM Game_Team__c WHERE Game__c = :gameId]) {
            if (gt.Battleground_Team__c != null) { w.teamIds.add(gt.Battleground_Team__c); }
        }
        Map<Id, String> rewardByKpi = new Map<Id, String>();
        for (Award__c a : [SELECT Battleground_KPI__c, Description__c FROM Award__c WHERE Game__c = :gameId]) {
            rewardByKpi.put(a.Battleground_KPI__c, a.Description__c);
        }
        Map<Id, KpiAward> byKpi = new Map<Id, KpiAward>();
        List<Id> order = new List<Id>();
        for (Game_KPI__c gk : [
            SELECT Battleground_KPI__c, Category__c, Measure__c, Is_Qualifier__c,
                   Use_Slabs__c, Is_Continuous__c, Eligibility_Criteria__c,
                   Slab_Number__c, Cutoff_Value__c, Reward_Coins__c
            FROM Game_KPI__c WHERE Game__c = :gameId
            ORDER BY Battleground_KPI__c, Slab_Number__c NULLS FIRST
        ]) {
            if (gk.Battleground_KPI__c == null) { continue; }
            KpiAward ka = byKpi.get(gk.Battleground_KPI__c);
            if (ka == null) {
                ka = new KpiAward();
                ka.kpiId = gk.Battleground_KPI__c; ka.category = gk.Category__c; ka.measure = gk.Measure__c;
                ka.isQualifier = gk.Is_Qualifier__c == true; ka.useSlabs = gk.Use_Slabs__c == true;
                ka.isContinuous = gk.Is_Continuous__c == true; ka.criteria = gk.Eligibility_Criteria__c;
                ka.reward = rewardByKpi.get(gk.Battleground_KPI__c);
                ka.slabs = new List<Slab>();
                byKpi.put(gk.Battleground_KPI__c, ka);
                order.add(gk.Battleground_KPI__c);
            }
            Slab s = new Slab(); s.target = gk.Cutoff_Value__c; s.coins = gk.Reward_Coins__c;
            ka.slabs.add(s);
        }
        w.kpis = new List<KpiAward>();
        for (Id kid : order) { w.kpis.add(byKpi.get(kid)); }
        return w;
    }

    @AuraEnabled
    public static Id saveGameWizard(GameWizard wiz) {
        Game__c game = new Game__c();
        if (wiz.gameId != null) { game.Id = wiz.gameId; }
        game.Name = wiz.gameName;
        game.Start_Date__c = wiz.startDate;
        game.End_Date__c = wiz.endDate;
        game.Type__c = wiz.gameType;
        game.Is_Active__c = wiz.isActive == true;
        upsert game;

        if (wiz.gameId != null) {
            delete [SELECT Id FROM Game_Team__c WHERE Game__c = :game.Id];
            delete [SELECT Id FROM Game_KPI__c WHERE Game__c = :game.Id];
            delete [SELECT Id FROM Award__c WHERE Game__c = :game.Id];
        }

        // Teams the game applies to
        if (wiz.teamIds != null && !wiz.teamIds.isEmpty()) {
            List<Game_Team__c> gts = new List<Game_Team__c>();
            for (Id tId : wiz.teamIds) {
                gts.add(new Game_Team__c(Game__c = game.Id, Battleground_Team__c = tId));
            }
            insert gts;
        }

        // KPIs + slab rows + a summary Award per KPI
        if (wiz.kpis != null && !wiz.kpis.isEmpty()) {
            List<Game_KPI__c> gks = new List<Game_KPI__c>();
            List<Award__c> awards = new List<Award__c>();
            for (KpiAward k : wiz.kpis) {
                List<Slab> slabs = (k.slabs != null && !k.slabs.isEmpty()) ? k.slabs : new List<Slab>{ new Slab() };
                Decimal totalCoins = 0;
                Integer slabNo = 0;
                for (Slab s : slabs) {
                    slabNo++;
                    gks.add(new Game_KPI__c(
                        Game__c = game.Id, Battleground_KPI__c = k.kpiId, Category__c = k.category,
                        Measure__c = k.measure, Is_Qualifier__c = k.isQualifier == true,
                        Use_Slabs__c = k.useSlabs == true, Is_Continuous__c = k.isContinuous == true,
                        Eligibility_Criteria__c = k.criteria,
                        Slab_Number__c = slabNo, Cutoff_Value__c = s.target, Reward_Coins__c = s.coins
                    ));
                    if (s.coins != null) { totalCoins += s.coins; }
                }
                awards.add(new Award__c(
                    Game__c = game.Id, Battleground_KPI__c = k.kpiId,
                    Coins__c = totalCoins, Description__c = k.reward, Is_Active__c = true
                ));
            }
            insert gks;
            insert awards;
        }
        return game.Id;
    }

    /**
     * UI-triggered scoring. Pass a user Id to recompute that one salesperson's
     * scores across every active game they belong to, or null to score everyone.
     */
    @AuraEnabled
    public static void recalculate(Id userId) {
        Set<Id> ids = userId == null ? null : new Set<Id>{ userId };
        GAM_GameScore_Service.calculateScores(ids);
    }

    // ===== On-demand coins read (for a real-time API/app call) =====
    public class GameCoins {
        @AuraEnabled public Id gameId;
        @AuraEnabled public String gameName;
        @AuraEnabled public Integer coins;
    }
    public class CoinSummary {
        @AuraEnabled public Id userId;
        @AuraEnabled public Id employeeId;
        @AuraEnabled public Date asOf;
        @AuraEnabled public Integer totalCoins;
        @AuraEnabled public List<GameCoins> games;
    }

    /**
     * Returns CURRENT coins for today for a SET of users, optionally recomputing
     * first. Lightweight read meant for a real-time API/app call — NOT the batch.
     * Pass recalc=true to score those users live before reading. Every requested
     * user gets a summary back (totalCoins = 0 if they have no scores yet).
     */
    @AuraEnabled
    public static List<CoinSummary> getUsersCoins(List<Id> userIds, Boolean recalc) {
        List<CoinSummary> results = new List<CoinSummary>();
        if (userIds == null || userIds.isEmpty()) { return results; }
        Set<Id> idSet = new Set<Id>(userIds);
        idSet.remove(null);
        if (idSet.isEmpty()) { return results; }

        if (recalc == true) {
            GAM_GameScore_Service.calculateScores(idSet);
        }

        // One summary per requested user, pre-seeded so zero-score users return too.
        Map<Id, CoinSummary> byUser = new Map<Id, CoinSummary>();
        for (Id uid : idSet) {
            CoinSummary s = new CoinSummary();
            s.userId = uid; s.asOf = Date.today(); s.totalCoins = 0; s.games = new List<GameCoins>();
            byUser.put(uid, s);
        }

        for (AggregateResult ar : [
            SELECT Salesperson__c uid, Game__c gid, MAX(Game__r.Name) gname, SUM(Coins_Awarded__c) coins
            FROM Game_Score__c
            WHERE Salesperson__c IN :idSet AND Score_Date__c = :Date.today()
                  AND Game__r.Is_Active__c = true
            GROUP BY Salesperson__c, Game__c
        ]) {
            CoinSummary s = byUser.get((Id) ar.get('uid'));
            if (s == null) { continue; }
            GameCoins gc = new GameCoins();
            gc.gameId = (Id) ar.get('gid');
            gc.gameName = (String) ar.get('gname');
            Decimal c = (Decimal) ar.get('coins');
            gc.coins = c == null ? 0 : (Integer) c;
            s.totalCoins += gc.coins;
            s.games.add(gc);
        }

        for (Employee__c emp : [SELECT Id, User__c FROM Employee__c WHERE User__c IN :idSet]) {
            CoinSummary s = byUser.get(emp.User__c);
            if (s != null && s.employeeId == null) { s.employeeId = emp.Id; }
        }

        results.addAll(byUser.values());
        return results;
    }

    /** Single-user convenience over getUsersCoins (real-time API/app call). */
    @AuraEnabled
    public static CoinSummary getUserCoins(Id userId, Boolean recalc) {
        if (userId == null) {
            CoinSummary empty = new CoinSummary();
            empty.asOf = Date.today(); empty.totalCoins = 0; empty.games = new List<GameCoins>();
            return empty;
        }
        List<CoinSummary> list = getUsersCoins(new List<Id>{ userId }, recalc);
        return list.isEmpty() ? null : list[0];
    }
}
