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

    @isTest
    static void wizardCreatesWholeGame() {
        Battleground_Team__c team = new Battleground_Team__c(Name = 'Mayora Stars', Is_Active__c = true);
        insert team;
        insert new Team_Member__c(Battleground_Team__c = team.Id, Member__c = UserInfo.getUserId());

        Battleground_KPI__c kpi = new Battleground_KPI__c(Name = 'PC', Category__c = 'Coverage', Is_Active__c = true);
        insert kpi;

        GAM_Battleground_Controller.Slab s1 = new GAM_Battleground_Controller.Slab();
        s1.target = 10; s1.coins = 50;
        GAM_Battleground_Controller.Slab s2 = new GAM_Battleground_Controller.Slab();
        s2.target = 20; s2.coins = 100;

        GAM_Battleground_Controller.KpiAward line = new GAM_Battleground_Controller.KpiAward();
        line.kpiId = kpi.Id; line.category = 'Coverage'; line.measure = 'Number';
        line.isQualifier = false; line.useSlabs = true; line.isContinuous = false;
        line.reward = 'Gift voucher';
        line.slabs = new List<GAM_Battleground_Controller.Slab>{ s1, s2 };

        GAM_Battleground_Controller.GameWizard wiz = new GAM_Battleground_Controller.GameWizard();
        wiz.gameName = 'MI Challenge'; wiz.startDate = Date.today(); wiz.endDate = Date.today().addDays(28);
        wiz.isActive = true; wiz.gameType = 'Daily';
        wiz.teamIds = new List<Id>{ team.Id };
        wiz.kpis = new List<GAM_Battleground_Controller.KpiAward>{ line };

        Test.startTest();
        Id gameId = GAM_Battleground_Controller.saveGameWizard(wiz);
        Test.stopTest();

        System.assertNotEquals(null, gameId);
        System.assertEquals(1, [SELECT COUNT() FROM Game_Team__c WHERE Game__c = :gameId]);
        System.assertEquals(2, [SELECT COUNT() FROM Game_KPI__c WHERE Game__c = :gameId]);
        System.assertEquals(1, [SELECT COUNT() FROM Award__c WHERE Game__c = :gameId]);
        System.assertEquals('Daily', [SELECT Type__c FROM Game__c WHERE Id = :gameId].Type__c);
    }

    @isTest
    static void describeMetadataHelpers() {
        System.assert(GAM_Battleground_Controller.getSourceObjects().size() >= 1,
            'Should list at least one selectable source object');
        System.assert(GAM_Battleground_Controller.getObjectFields('Task', 'date').size() >= 1,
            'Task should expose at least one date field');
        System.assert(GAM_Battleground_Controller.getObjectFields('Task', 'user').size() >= 1,
            'Task should expose at least one user lookup field');
        System.assertEquals(0, GAM_Battleground_Controller.getObjectFields('', 'number').size());
        System.assertEquals(0, GAM_Battleground_Controller.getObjectFields('No_Such_Object__x', 'number').size());
    }

    @isTest
    static void kpiWithSourceMappingScores() {
        Battleground_Team__c team = new Battleground_Team__c(Name = 'Map Team', Is_Active__c = true);
        insert team;
        insert new Team_Member__c(Battleground_Team__c = team.Id, Member__c = UserInfo.getUserId());
        Employee__c emp = new Employee__c(User__c = UserInfo.getUserId(), Channels__c = 'GT', Is_Active__c = false);
        insert emp;

        // KPI whose actual = count of the user's Tasks in the game window
        Battleground_KPI__c kpi = new Battleground_KPI__c(
            Name = 'Task Count', Category__c = 'Coverage', Is_Active__c = true,
            Source_Object__c = 'Task', Aggregation__c = 'COUNT',
            Date_Field__c = 'ActivityDate', User_Field__c = 'OwnerId'
        );
        insert kpi;
        insert new Task(Subject = 'Call', OwnerId = UserInfo.getUserId(), ActivityDate = Date.today());

        Game__c game = new Game__c(Name = 'Map Game', Type__c = 'Daily', Is_Active__c = true,
            Start_Date__c = Date.today().addDays(-1), End_Date__c = Date.today().addDays(1));
        insert game;
        insert new Game_Team__c(Game__c = game.Id, Battleground_Team__c = team.Id);
        insert new Game_KPI__c(Game__c = game.Id, Battleground_KPI__c = kpi.Id, Category__c = 'Coverage',
            Slab_Number__c = 1, Cutoff_Value__c = 1, Reward_Coins__c = 30);

        Test.startTest();
        // recalc=true scores this one user live, then reads current coins
        GAM_Battleground_Controller.CoinSummary summary =
            GAM_Battleground_Controller.getUserCoins(UserInfo.getUserId(), true);
        Test.stopTest();

        List<Game_Score__c> scores = [SELECT Achievement__c, Coins_Awarded__c, Employee__c FROM Game_Score__c WHERE Game__c = :game.Id];
        System.assertEquals(1, scores.size(), 'One score expected');
        System.assert(scores[0].Achievement__c >= 1, 'Actual should count the seeded task');
        System.assertEquals(emp.Id, scores[0].Employee__c, 'Score should carry the resolved Employee');

        System.assertEquals(30, summary.totalCoins, 'Live coins read should total the awarded coins');
        System.assertEquals(emp.Id, summary.employeeId, 'Summary should resolve the Employee');
        System.assertEquals(1, summary.games.size(), 'One active game in the summary');
        System.assertEquals(0, GAM_Battleground_Controller.getUserCoins(null, false).totalCoins);

        // set-of-users read (recalc=false, reads stored scores)
        List<GAM_Battleground_Controller.CoinSummary> many =
            GAM_Battleground_Controller.getUsersCoins(new List<Id>{ UserInfo.getUserId() }, false);
        System.assertEquals(1, many.size(), 'One summary per requested user');
        System.assertEquals(30, many[0].totalCoins, 'Stored coins total for the user');
        System.assertEquals(0, GAM_Battleground_Controller.getUsersCoins(new List<Id>(), true).size());
    }

    @isTest
    static void schedulerScoresUsers() {
        Battleground_Team__c team = new Battleground_Team__c(Name = 'Scorers', Is_Active__c = true);
        insert team;
        insert new Team_Member__c(Battleground_Team__c = team.Id, Member__c = UserInfo.getUserId());

        Battleground_KPI__c kpi = new Battleground_KPI__c(Name = 'Calls', Category__c = 'Coverage', Is_Active__c = true);
        insert kpi;

        Game__c game = new Game__c(Name = 'Score Game', Type__c = 'Daily', Is_Active__c = true,
            Start_Date__c = Date.today().addDays(-1), End_Date__c = Date.today().addDays(1));
        insert game;
        insert new Game_Team__c(Game__c = game.Id, Battleground_Team__c = team.Id);
        insert new Game_KPI__c(Game__c = game.Id, Battleground_KPI__c = kpi.Id, Category__c = 'Coverage',
            Slab_Number__c = 1, Cutoff_Value__c = 0, Reward_Coins__c = 25);

        Test.startTest();
        GAM_Battleground_Controller.recalculate(UserInfo.getUserId());
        new GAM_GameScore_Scheduler().execute(null);
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Game_Score__c WHERE Game__c = :game.Id] >= 1,
            'Scoring should have created at least one Game Score');
    }
}
