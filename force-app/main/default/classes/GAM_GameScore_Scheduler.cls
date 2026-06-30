/**
 * @description Schedulable wrapper that recomputes gamification scores (BRD 20.1)
 *              for every user in each active game's team(s). Delegates to
 *              GAM_GameScore_Service.calculateScores(null) so the same logic the
 *              UI uses for a single user runs across all users on a schedule.
 *
 * Usage (Execute Anonymous):
 *   // Score every active game's team members daily at 11 PM
 *   System.schedule('Game Score Nightly', '0 0 23 * * ?', new GAM_GameScore_Scheduler());
 *
 * @author  SFA Development Team
 * @date    2026
 */
public without sharing class GAM_GameScore_Scheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        GAM_GameScore_Service.calculateScores(null);
    }

    /**
     * Schedules this job to run every day at the given hour/minute (24h).
     * Returns the CronTrigger Id. Example: scheduleDaily('Game Score Daily', 23, 0)
     * runs nightly at 23:00.
     */
    public static String scheduleDaily(String jobName, Integer hour, Integer minute) {
        Integer h = (hour == null) ? 23 : Math.max(0, Math.min(23, hour));
        Integer m = (minute == null) ? 0 : Math.max(0, Math.min(59, minute));
        String cron = '0 ' + m + ' ' + h + ' * * ?';
        return System.schedule(jobName, cron, new GAM_GameScore_Scheduler());
    }
}
