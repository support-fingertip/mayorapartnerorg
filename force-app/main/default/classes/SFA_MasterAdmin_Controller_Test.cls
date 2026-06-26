/**
 * @description Tests for SFA_MasterAdmin_Controller getters.
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class SFA_MasterAdmin_Controller_Test {

    @isTest
    static void allGettersReturnData() {
        Game__c g = new Game__c(Name = 'G1', Is_Active__c = true);
        insert g;
        insert new Game_KPI__c(Game__c = g.Id, KPI_Type__c = 'Sales', KPI_Name__c = 'PC',
            Slab_Number__c = 1, Cutoff_Value__c = 10, Reward_Coins__c = 50);

        MAP_Budget__c b = new MAP_Budget__c(Brand_Name__c = 'Kopiko', Amount__c = 1000, Status__c = 'Draft');
        insert b;
        insert new MAP_Order__c(MAP_Budget__c = b.Id, Amount__c = 100, Status__c = 'Draft');

        DA_Policy__c p = new DA_Policy__c(Name = 'Std DA', Is_Active__c = true);
        insert p;
        insert new DA_Policy_KPI__c(DA_Policy__c = p.Id, Half_Day_Target__c = 5, Full_Day_Target__c = 10);

        Scheme_Basket__c sb = new Scheme_Basket__c(Name = 'Combo', Channel__c = 'GT', Is_Active__c = true);
        insert sb;
        insert new Scheme_Basket_Product__c(Scheme_Basket__c = sb.Id, Min_Qty__c = 2);

        Test.startTest();
        System.assertEquals(1, SFA_MasterAdmin_Controller.getGames().size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getGameKpis(g.Id).size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getMapBudgets().size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getMapOrders(b.Id).size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getDaPolicies().size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getDaPolicyKpis(p.Id).size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getSchemeBaskets().size());
        System.assertEquals(1, SFA_MasterAdmin_Controller.getBasketProducts(sb.Id).size());
        Test.stopTest();
    }
}
