/**
 * @description Scheduled batch (BRD §20.1) that recomputes Game Score coins and
 *              qualification for all active games. Schedule daily (end of day):
 *              System.schedule('GAM Game Score', '0 0 23 * * ?',
 *                  new GAM_GameScore_Batch());
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class GAM_GameScore_Batch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Achievement__c, Game_KPI__c, Is_Qualified__c,
                   Target__c, Target_Coins__c, Coins_Awarded__c
            FROM Game_Score__c
            WHERE Game__r.Is_Active__c = true
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Game_Score__c> scope) {
        GAM_GameScore_Service.recomputeScores(scope);
        if (!scope.isEmpty()) {
            update scope;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // No post-processing required.
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }
}
