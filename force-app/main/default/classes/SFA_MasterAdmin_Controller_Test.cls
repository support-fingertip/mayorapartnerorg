/**
 * @description Tests for SFA_MasterAdmin_Controller (getters, bulk savers, lookups).
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class SFA_MasterAdmin_Controller_Test {

    @isTest
    static void bulkSaveAndGet() {
        Test.startTest();

        // Gamification
        SFA_MasterAdmin_Controller.saveGames(new List<Game__c>{
            new Game__c(Name = 'G1', Is_Active__c = true)
        });
        Id gameId = [SELECT Id FROM Game__c LIMIT 1].Id;
        SFA_MasterAdmin_Controller.saveGameKpis(new List<Game_KPI__c>{
            new Game_KPI__c(Game__c = gameId, KPI_Type__c = 'Sales', KPI_Name__c = 'PC',
                Slab_Number__c = 1, Cutoff_Value__c = 10, Reward_Coins__c = 50)
        });

        // MAP
        SFA_MasterAdmin_Controller.saveMapBudgets(new List<MAP_Budget__c>{
            new MAP_Budget__c(Brand_Name__c = 'Kopiko', Amount__c = 1000, Status__c = 'Draft')
        });
        Id budgetId = [SELECT Id FROM MAP_Budget__c LIMIT 1].Id;
        SFA_MasterAdmin_Controller.saveMapOrders(new List<MAP_Order__c>{
            new MAP_Order__c(MAP_Budget__c = budgetId, Amount__c = 100, Status__c = 'Draft')
        });

        // DA Policy
        SFA_MasterAdmin_Controller.saveDaPolicies(new List<DA_Policy__c>{
            new DA_Policy__c(Name = 'Std DA', Is_Active__c = true)
        });
        Id policyId = [SELECT Id FROM DA_Policy__c LIMIT 1].Id;
        SFA_MasterAdmin_Controller.saveDaPolicyKpis(new List<DA_Policy_KPI__c>{
            new DA_Policy_KPI__c(DA_Policy__c = policyId, Half_Day_Target__c = 5, Full_Day_Target__c = 10)
        });

        // Scheme Basket
        SFA_MasterAdmin_Controller.saveSchemeBaskets(new List<Scheme_Basket__c>{
            new Scheme_Basket__c(Name = 'Combo', Channel__c = 'GT', Is_Active__c = true)
        });
        Id basketId = [SELECT Id FROM Scheme_Basket__c LIMIT 1].Id;
        SFA_MasterAdmin_Controller.saveBasketProducts(new List<Scheme_Basket_Product__c>{
            new Scheme_Basket_Product__c(Scheme_Basket__c = basketId, Min_Qty__c = 2)
        });

        Test.stopTest();

        System.assertEquals(1, SFA_MasterAdmin_Controller.getGames().size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getGameKpis(gameId).size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getMapBudgets().size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getMapOrders(budgetId).size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getDaPolicies().size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getDaPolicyKpis(policyId).size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getSchemeBaskets().size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getBasketProducts(basketId).size());
        System.assertEquals(0, SFA_MasterAdmin_Controller.getLookupOptions('Bad_Object__c').size());
        // Allowed lookup object returns (possibly empty) without error
        SFA_MasterAdmin_Controller.getLookupOptions('KPI_Metric__c');
    }
}
