/**
 * @description Controller for the admin bulk-entry manager LWCs that define the
 *              net-new BRD masters (gamification games + KPI slabs, MAP budgets +
 *              orders, DA policies + KPI targets, scheme baskets + products).
 *              Provides cacheable list getters, bulk upsert savers, and lookup
 *              option lists for the grid comboboxes.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public with sharing class SFA_MasterAdmin_Controller {

    // ===== Gamification =====
    @AuraEnabled(cacheable=true)
    public static List<Game__c> getGames() {
        return [
            SELECT Id, Name, Team_Name__c, Game_Code__c, Start_Date__c, End_Date__c, Is_Active__c
            FROM Game__c ORDER BY Name
        ];
    }
    @AuraEnabled(cacheable=true)
    public static List<Game_KPI__c> getGameKpis(Id gameId) {
        return [
            SELECT Id, Name, Role__c, KPI_Name__c, KPI_Type__c, Slab_Number__c,
                   Cutoff_Value__c, Reward_Coins__c, KPI_Metric__c
            FROM Game_KPI__c WHERE Game__c = :gameId ORDER BY Slab_Number__c NULLS FIRST
        ];
    }
    @AuraEnabled
    public static void saveGames(List<Game__c> records) { upsert records; }
    @AuraEnabled
    public static void saveGameKpis(List<Game_KPI__c> records) { upsert records; }

    // ===== MAP =====
    @AuraEnabled(cacheable=true)
    public static List<MAP_Budget__c> getMapBudgets() {
        return [
            SELECT Id, Name, Brand_Name__c, Budget_Date__c, Amount__c, Spent_Amount__c,
                   Remaining_Amount__c, Status__c, Description__c, Is_Active__c
            FROM MAP_Budget__c ORDER BY CreatedDate DESC
        ];
    }
    @AuraEnabled(cacheable=true)
    public static List<MAP_Order__c> getMapOrders(Id budgetId) {
        return [
            SELECT Id, Name, Amount__c, Actuals__c, Remaining_Amount__c, Status__c, Description__c
            FROM MAP_Order__c WHERE MAP_Budget__c = :budgetId ORDER BY CreatedDate DESC
        ];
    }
    @AuraEnabled
    public static void saveMapBudgets(List<MAP_Budget__c> records) { upsert records; }
    @AuraEnabled
    public static void saveMapOrders(List<MAP_Order__c> records) { upsert records; }

    // ===== DA Policy =====
    @AuraEnabled(cacheable=true)
    public static List<DA_Policy__c> getDaPolicies() {
        return [SELECT Id, Name, Description__c, Is_Active__c FROM DA_Policy__c ORDER BY Name];
    }
    @AuraEnabled(cacheable=true)
    public static List<DA_Policy_KPI__c> getDaPolicyKpis(Id policyId) {
        return [
            SELECT Id, Name, KPI_Metric__c, Half_Day_Target__c, Full_Day_Target__c
            FROM DA_Policy_KPI__c WHERE DA_Policy__c = :policyId ORDER BY Name
        ];
    }
    @AuraEnabled
    public static void saveDaPolicies(List<DA_Policy__c> records) { upsert records; }
    @AuraEnabled
    public static void saveDaPolicyKpis(List<DA_Policy_KPI__c> records) { upsert records; }

    // ===== Scheme Basket =====
    @AuraEnabled(cacheable=true)
    public static List<Scheme_Basket__c> getSchemeBaskets() {
        return [
            SELECT Id, Name, Basket_Code__c, Channel__c, Description__c, Is_Active__c
            FROM Scheme_Basket__c ORDER BY Name
        ];
    }
    @AuraEnabled(cacheable=true)
    public static List<Scheme_Basket_Product__c> getBasketProducts(Id basketId) {
        return [
            SELECT Id, Name, Product_Ext__c, Min_Qty__c
            FROM Scheme_Basket_Product__c WHERE Scheme_Basket__c = :basketId ORDER BY Name
        ];
    }
    @AuraEnabled
    public static void saveSchemeBaskets(List<Scheme_Basket__c> records) { upsert records; }
    @AuraEnabled
    public static void saveBasketProducts(List<Scheme_Basket_Product__c> records) { upsert records; }

    // ===== Lookup options for grid comboboxes =====
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getLookupOptions(String objectApiName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Set<String> allowed = new Set<String>{
            'KPI_Metric__c', 'Product_Extension__c', 'Expense_Eligibility__c'
        };
        if (String.isBlank(objectApiName) || !allowed.contains(objectApiName)) {
            return options;
        }
        for (SObject rec : Database.query(
                'SELECT Id, Name FROM ' + String.escapeSingleQuotes(objectApiName)
                + ' ORDER BY Name LIMIT 1000')) {
            options.add(new Map<String, String>{
                'label' => String.valueOf(rec.get('Name')),
                'value' => String.valueOf(rec.get('Id'))
            });
        }
        return options;
    }
}
