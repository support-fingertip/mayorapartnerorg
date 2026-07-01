/**
 * @description Controller for the Target vs Actuals admin UI (BRD §13). Manages
 *              the tiered Target__c records (P1 / P2 / Secondary / Outlet) — where
 *              SS / SB / DB / Outlet are all Accounts — lets the admin pick the
 *              customer (or user for Secondary), the product-hierarchy level, the
 *              KPI and target value, and triggers the tier-aware actuals engine.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public with sharing class TAM_TargetVsActuals_Controller {

    @AuraEnabled(cacheable=true)
    public static List<Target__c> getTargets() {
        return [
            SELECT Id, Name, Tier__c, Target_Type__c, Target_Product_Level__c,
                   Brand__c, Sub_Brand__c, Brand_Alias__c,
                   Customer__c, Customer__r.Name, User__c, User__r.Name,
                   Product_Ext__c, Product_Ext__r.Name, KPI__c, KPI__r.Name,
                   Target_Value__c, Achievement_Value__c, Achievement_Percent__c,
                   Period_Start__c, Period_End__c, JC__c, JC__r.Name, Status__c
            FROM Target__c
            WHERE Tier__c != null
            ORDER BY CreatedDate DESC
            LIMIT 500
        ];
    }

    /**
     * Option lists for the pickers. kind:
     *   'Account'  (accType filters Customer_Type__c), 'User', 'KPI',
     *   'Product', 'Period'. search filters by Name.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOptions(String kind, String accType, String search) {
        List<Map<String, String>> out = new List<Map<String, String>>();
        String like = '%' + (search == null ? '' : String.escapeSingleQuotes(search)) + '%';
        List<SObject> rows;
        if (kind == 'Account') {
            if (String.isNotBlank(accType)) {
                rows = [SELECT Id, Name FROM Account
                        WHERE Customer_Type__c = :accType AND Name LIKE :like ORDER BY Name LIMIT 200];
            } else {
                rows = [SELECT Id, Name FROM Account WHERE Name LIKE :like ORDER BY Name LIMIT 200];
            }
        } else if (kind == 'User') {
            rows = [SELECT Id, Name FROM User WHERE IsActive = true AND Name LIKE :like ORDER BY Name LIMIT 200];
        } else if (kind == 'KPI') {
            rows = [SELECT Id, Name FROM Target_Criteria__c WHERE Active__c = true AND Name LIKE :like ORDER BY Name LIMIT 200];
        } else if (kind == 'Product') {
            rows = [SELECT Id, Name FROM Product_Extension__c WHERE Is_Active__c = true AND Name LIKE :like ORDER BY Name LIMIT 200];
        } else if (kind == 'Period') {
            rows = [SELECT Id, Name FROM Target_Period__c ORDER BY Name LIMIT 200];
        } else {
            return out;
        }
        for (SObject r : rows) {
            out.add(new Map<String, String>{
                'label' => String.valueOf(r.get('Name')),
                'value' => String.valueOf(r.get('Id'))
            });
        }
        return out;
    }

    @AuraEnabled
    public static Id saveTarget(Target__c record) {
        upsert record;
        return record.Id;
    }

    /** Recompute one target's actuals (tier-aware, BRD §13). */
    @AuraEnabled
    public static Target__c recalc(Id targetId) {
        TAM_TargetActuals_Service.calculateForTarget(targetId);
        return [
            SELECT Id, Achievement_Value__c, Achievement_Percent__c, Last_Calculated__c
            FROM Target__c WHERE Id = :targetId LIMIT 1
        ];
    }

    /** Kick the batch to recompute all active tiered targets covering today. */
    @AuraEnabled
    public static Id recalcAll() {
        return Database.executeBatch(new TAM_TargetActuals_Batch(), 50);
    }
}
