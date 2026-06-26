/**
 * @description Tests for DFO_DayAttendance_AutoClose_Batch (BRD §18 auto-end-day).
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class DFO_DayAttendance_AutoClose_Batch_Test {

    @isTest
    static void openDayIsAutoClosed() {
        Day_Attendance__c day = new Day_Attendance__c(
            User__c = UserInfo.getUserId(),
            Salesperson__c = UserInfo.getUserId(),
            Attendance_Date__c = Date.today(),
            Status__c = 'Started',
            Day_Start_Time__c = System.now().addHours(-8)
        );
        insert day;

        Test.startTest();
        Database.executeBatch(new DFO_DayAttendance_AutoClose_Batch());
        Test.stopTest();

        day = [
            SELECT Status__c, Auto_Closed__c, Day_End_Time__c
            FROM Day_Attendance__c WHERE Id = :day.Id
        ];
        System.assertEquals('Auto-Closed', day.Status__c, 'Open day should be auto-closed');
        System.assertEquals(true, day.Auto_Closed__c, 'Auto_Closed flag should be set');
        System.assertNotEquals(null, day.Day_End_Time__c, 'Day end time should be stamped');
    }

    @isTest
    static void schedulableSchedules() {
        Test.startTest();
        String jobId = System.schedule('DFO AutoClose Test', '0 55 23 * * ?', new DFO_DayAttendance_AutoClose_Batch());
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}
