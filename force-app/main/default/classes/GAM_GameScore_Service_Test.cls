/**
 * @description Tests for GAM_GameScore_Service and GAM_GameScore_Batch (BRD §20.1).
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class GAM_GameScore_Service_Test {

    @isTest
    static void evaluatePicksHighestMetSlab() {
        List<Game_KPI__c> slabs = new List<Game_KPI__c>{
            new Game_KPI__c(KPI_Type__c = 'Sales', Cutoff_Value__c = 10, Reward_Coins__c = 50),
            new Game_KPI__c(KPI_Type__c = 'Sales', Cutoff_Value__c = 20, Reward_Coins__c = 100)
        };
        GAM_GameScore_Service.SlabResult r = GAM_GameScore_Service.evaluate(25, slabs);
        System.assertEquals(true, r.qualified, 'Should qualify above the top slab');
        System.assertEquals(100, r.coins, 'Should award the highest met slab coins');
    }

    @isTest
    static void qualifierAwardsNoCoins() {
        List<Game_KPI__c> slabs = new List<Game_KPI__c>{
            new Game_KPI__c(KPI_Type__c = 'Qualifier', Cutoff_Value__c = 5, Reward_Coins__c = 99)
        };
        GAM_GameScore_Service.SlabResult r = GAM_GameScore_Service.evaluate(8, slabs);
        System.assertEquals(true, r.qualified, 'Qualifier threshold met');
        System.assertEquals(0, r.coins, 'Qualifier KPIs award no coins (BRD 20.1)');
    }

    @isTest
    static void criteriaOperatorsEvaluate() {
        System.assertEquals(true,  GAM_GameScore_Service.meetsCriteria(10, 10, 'At least'));
        System.assertEquals(false, GAM_GameScore_Service.meetsCriteria(9,  10, 'At least'));
        System.assertEquals(true,  GAM_GameScore_Service.meetsCriteria(11, 10, 'Greater than'));
        System.assertEquals(false, GAM_GameScore_Service.meetsCriteria(10, 10, 'Greater than'));
        System.assertEquals(true,  GAM_GameScore_Service.meetsCriteria(10, 10, 'At most'));
        System.assertEquals(false, GAM_GameScore_Service.meetsCriteria(11, 10, 'At most'));
        System.assertEquals(true,  GAM_GameScore_Service.meetsCriteria(9,  10, 'Less than'));
        System.assertEquals(true,  GAM_GameScore_Service.meetsCriteria(10, 10, 'Equal to'));
        System.assertEquals(true,  GAM_GameScore_Service.meetsCriteria(10, 10, null), 'Null criteria defaults to At least');
    }

    @isTest
    static void atMostQualifierEvaluate() {
        List<Game_KPI__c> slabs = new List<Game_KPI__c>{
            new Game_KPI__c(KPI_Type__c = 'Qualifier', Cutoff_Value__c = 9,
                Reward_Coins__c = 0, Eligibility_Criteria__c = 'At most')
        };
        GAM_GameScore_Service.SlabResult r = GAM_GameScore_Service.evaluate(8, slabs);
        System.assertEquals(true, r.qualified, '8 is at most 9 — should qualify');
    }

    @isTest
    static void belowAllSlabsNoCoins() {
        List<Game_KPI__c> slabs = new List<Game_KPI__c>{
            new Game_KPI__c(KPI_Type__c = 'Sales', Cutoff_Value__c = 10, Reward_Coins__c = 50)
        };
        GAM_GameScore_Service.SlabResult r = GAM_GameScore_Service.evaluate(3, slabs);
        System.assertEquals(false, r.qualified, 'Below all slabs should not qualify');
        System.assertEquals(0, r.coins);
    }

    @isTest
    static void batchRecomputesScores() {
        Game__c g = new Game__c(Name = 'Test Game', Is_Active__c = true);
        insert g;
        Game_KPI__c kpi = new Game_KPI__c(
            Game__c = g.Id, KPI_Type__c = 'Sales', KPI_Name__c = 'PC',
            Cutoff_Value__c = 10, Reward_Coins__c = 50
        );
        insert kpi;
        Game_Score__c sc = new Game_Score__c(
            Game__c = g.Id, Salesperson__c = UserInfo.getUserId(),
            Game_KPI__c = kpi.Id, Achievement__c = 15, Score_Date__c = Date.today()
        );
        insert sc;

        Test.startTest();
        Database.executeBatch(new GAM_GameScore_Batch());
        Test.stopTest();

        sc = [
            SELECT Coins_Awarded__c, Is_Qualified__c, Target__c, Target_Coins__c
            FROM Game_Score__c WHERE Id = :sc.Id
        ];
        System.assertEquals(50, (Integer) sc.Coins_Awarded__c, 'Coins should be awarded for the met slab');
        System.assertEquals(true, sc.Is_Qualified__c, 'Score should be qualified');
    }

    @isTest
    static void schedulableSchedules() {
        Test.startTest();
        String jobId = System.schedule('GAM Test Job', '0 0 23 * * ?', new GAM_GameScore_Batch());
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Schedulable should return a job id');
    }
}
