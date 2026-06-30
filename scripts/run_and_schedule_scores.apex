/*
 * Execute Anonymous — the three ways to run gamification scoring (BRD 20.1).
 * Uncomment the one you need.
 */

// 1) RUN NOW for ALL team members in every active game
GAM_GameScore_Service.runForAll();

// 2) RUN NOW for a SINGLE user (replace the Id with the salesperson's User Id)
// GAM_GameScore_Service.runForUser('005XXXXXXXXXXXXXXX');

// 3) SCHEDULE every day at a specified time (24h clock). Runs daily at 23:00 here.
//    Returns the scheduled job Id. Change 23, 0 to your hour, minute.
// String jobId = GAM_GameScore_Scheduler.scheduleDaily('Game Score Daily', 23, 0);
// System.debug('Scheduled job: ' + jobId);

// To stop a previously scheduled run, find it in Setup > Scheduled Jobs, or:
// for (CronTrigger ct : [SELECT Id, CronJobDetail.Name FROM CronTrigger
//         WHERE CronJobDetail.Name = 'Game Score Daily']) { System.abortJob(ct.Id); }
