/**
 * @description Scheduled batch (BRD §18) that auto-closes day-attendance records
 *              the user left open. Run nightly at 23:55:
 *              System.schedule('DFO Day Auto-Close','0 55 23 * * ?',
 *                  new DFO_DayAttendance_AutoClose_Batch());
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class DFO_DayAttendance_AutoClose_Batch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, Day_Start_Time__c, Day_End_Time__c, End_Time__c, Auto_Closed__c
            FROM Day_Attendance__c
            WHERE Status__c IN ('Started', 'In Progress')
              AND Day_Start_Time__c != null
              AND Day_End_Time__c = null
              AND Attendance_Date__c <= TODAY
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Day_Attendance__c> scope) {
        if (scope.isEmpty()) {
            return;
        }
        DateTime nowDt = System.now();
        for (Day_Attendance__c day : scope) {
            day.Status__c = 'Auto-Closed';
            day.Day_End_Time__c = nowDt;
            day.End_Time__c = nowDt;
            day.Auto_Closed__c = true;
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        // No post-processing required.
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }
}
