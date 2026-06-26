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
}
