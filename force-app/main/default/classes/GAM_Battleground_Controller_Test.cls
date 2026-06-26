/**
 * @description Tests for GAM_Battleground_Controller.
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class GAM_Battleground_Controller_Test {

    @isTest
    static void endToEnd() {
        Test.startTest();
        GAM_Battleground_Controller.saveTeams(new List<Battleground_Team__c>{
            new Battleground_Team__c(Name = 'Mayora Stars', Level__c = 'L1', Is_Active__c = true)
        });
        Id teamId = [SELECT Id FROM Battleground_Team__c LIMIT 1].Id;
        GAM_Battleground_Controller.saveTeamMembers(new List<Team_Member__c>{
            new Team_Member__c(Battleground_Team__c = teamId, Member__c = UserInfo.getUserId())
        });
        GAM_Battleground_Controller.saveKpis(new List<Battleground_KPI__c>{
            new Battleground_KPI__c(Name = 'PC', Category__c = 'Coverage', Is_Qualifier__c = false, Is_Active__c = true)
        });
        GAM_Battleground_Controller.saveGames(new List<Game__c>{
            new Game__c(Name = 'MI Challenge', Is_Active__c = true)
        });
        Id gameId = [SELECT Id FROM Game__c LIMIT 1].Id;
        Id kpiId = [SELECT Id FROM Battleground_KPI__c LIMIT 1].Id;
        GAM_Battleground_Controller.saveGameTeams(new List<Game_Team__c>{
            new Game_Team__c(Game__c = gameId, Battleground_Team__c = teamId)
        });
        GAM_Battleground_Controller.saveGameKpis(new List<Game_KPI__c>{
            new Game_KPI__c(Game__c = gameId, Battleground_KPI__c = kpiId, Category__c = 'Coverage',
                Slab_Number__c = 1, Cutoff_Value__c = 10, Reward_Coins__c = 50)
        });
        GAM_Battleground_Controller.saveAwards(new List<Award__c>{
            new Award__c(Game__c = gameId, Battleground_KPI__c = kpiId, Coins__c = 50, Is_Active__c = true)
        });
        Test.stopTest();

        System.assertEquals(1, GAM_Battleground_Controller.getTeams().size());
        System.assertEquals(1, GAM_Battleground_Controller.getTeamMembers(teamId).size());
        System.assertEquals(1, GAM_Battleground_Controller.getKpis().size());
        System.assertEquals(1, GAM_Battleground_Controller.getGames().size());
        System.assertEquals(1, GAM_Battleground_Controller.getGameTeams(gameId).size());
        System.assertEquals(1, GAM_Battleground_Controller.getGameKpis(gameId).size());
        System.assertEquals(1, GAM_Battleground_Controller.getAwards().size());
        System.assert(GAM_Battleground_Controller.getLookupOptions('User').size() >= 1);
        System.assertEquals(0, GAM_Battleground_Controller.getLookupOptions('Bad__c').size());
    }
}
