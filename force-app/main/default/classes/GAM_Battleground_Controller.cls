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
                       Is_Qualifier__c, Is_Incentive__c, KPI_Metric__c, Is_Active__c
                FROM Battleground_KPI__c ORDER BY Category__c, Sequence__c NULLS FIRST];
    }
    @AuraEnabled public static void saveKpis(List<Battleground_KPI__c> records) { upsert records; }

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
    public class KpiAward {
        @AuraEnabled public Id kpiId { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public Decimal target { get; set; }
        @AuraEnabled public Decimal points { get; set; }
        @AuraEnabled public String reward { get; set; }
    }
    public class GameWizard {
        @AuraEnabled public Id gameId { get; set; }
        @AuraEnabled public String gameName { get; set; }
        @AuraEnabled public Date startDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public Boolean isActive { get; set; }
        @AuraEnabled public String teamName { get; set; }
        @AuraEnabled public Id teamId { get; set; }
        @AuraEnabled public List<Id> userIds { get; set; }
        @AuraEnabled public List<KpiAward> kpis { get; set; }
    }

    @AuraEnabled
    public static Id saveGameWizard(GameWizard wiz) {
        // 1) Game header
        Game__c game = new Game__c();
        if (wiz.gameId != null) { game.Id = wiz.gameId; }
        game.Name = wiz.gameName;
        game.Start_Date__c = wiz.startDate;
        game.End_Date__c = wiz.endDate;
        game.Is_Active__c = wiz.isActive == true;
        upsert game;

        // On edit, clear prior teams/KPIs/awards so the wizard is the source of truth.
        if (wiz.gameId != null) {
            delete [SELECT Id FROM Game_Team__c WHERE Game__c = :game.Id];
            delete [SELECT Id FROM Game_KPI__c WHERE Game__c = :game.Id];
            delete [SELECT Id FROM Award__c WHERE Game__c = :game.Id];
        }

        // 2) Team (reuse selected team or create a new one) + members
        Id teamId = wiz.teamId;
        if (teamId == null && String.isNotBlank(wiz.teamName)) {
            Battleground_Team__c team = new Battleground_Team__c(Name = wiz.teamName, Is_Active__c = true);
            insert team;
            teamId = team.Id;
        }
        if (teamId != null) {
            if (wiz.userIds != null && !wiz.userIds.isEmpty()) {
                Set<Id> existing = new Set<Id>();
                for (Team_Member__c m : [SELECT Member__c FROM Team_Member__c WHERE Battleground_Team__c = :teamId]) {
                    existing.add(m.Member__c);
                }
                List<Team_Member__c> members = new List<Team_Member__c>();
                for (Id uid : wiz.userIds) {
                    if (!existing.contains(uid)) {
                        members.add(new Team_Member__c(Battleground_Team__c = teamId, Member__c = uid));
                    }
                }
                if (!members.isEmpty()) { insert members; }
            }
            insert new Game_Team__c(Game__c = game.Id, Battleground_Team__c = teamId);
        }

        // 3) KPIs the game focuses on + Awards (points & reward per KPI)
        if (wiz.kpis != null && !wiz.kpis.isEmpty()) {
            List<Game_KPI__c> gks = new List<Game_KPI__c>();
            List<Award__c> awards = new List<Award__c>();
            for (KpiAward k : wiz.kpis) {
                gks.add(new Game_KPI__c(
                    Game__c = game.Id, Battleground_KPI__c = k.kpiId, Category__c = k.category,
                    Cutoff_Value__c = k.target, Reward_Coins__c = k.points
                ));
                awards.add(new Award__c(
                    Game__c = game.Id, Battleground_KPI__c = k.kpiId,
                    Coins__c = k.points, Description__c = k.reward, Is_Active__c = true
                ));
            }
            insert gks;
            insert awards;
        }
        return game.Id;
    }
}
