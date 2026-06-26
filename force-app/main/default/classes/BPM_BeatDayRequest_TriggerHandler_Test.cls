/**
 * @description Tests for BPM_BeatDayRequest_TriggerHandler (BRD 7.4):
 *              defaulting and the 3-approvals-per-JC No-PJP-Day cap.
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class BPM_BeatDayRequest_TriggerHandler_Test {

    private static Target_Period__c makeJourneyCycle() {
        Target_Period__c jc = new Target_Period__c(
            Name = 'JC Test',
            Type__c = 'Journey Cycle',
            Start_Date__c = Date.today().addDays(-5),
            End_Date__c = Date.today().addDays(22)
        );
        insert jc;
        return jc;
    }

    private static Beat_Day_Request__c newRequest(Id jcId) {
        return new Beat_Day_Request__c(
            Salesperson__c = UserInfo.getUserId(),
            Journey_Cycle__c = jcId,
            Request_Type__c = 'No-PJP Day',
            Reason__c = 'Other'
        );
    }

    @isTest
    static void defaultsAreApplied() {
        Target_Period__c jc = makeJourneyCycle();
        Beat_Day_Request__c r = newRequest(jc.Id);

        Test.startTest();
        insert r;
        Test.stopTest();

        r = [SELECT Status__c, Request_Date__c FROM Beat_Day_Request__c WHERE Id = :r.Id];
        System.assertEquals('Pending', r.Status__c, 'Status should default to Pending');
        System.assertEquals(Date.today(), r.Request_Date__c, 'Request Date should default to today');
    }

    @isTest
    static void firstThreeApprovalsSucceed() {
        Target_Period__c jc = makeJourneyCycle();
        List<Beat_Day_Request__c> reqs = new List<Beat_Day_Request__c>{
            newRequest(jc.Id), newRequest(jc.Id), newRequest(jc.Id)
        };
        insert reqs;

        Test.startTest();
        for (Beat_Day_Request__c r : reqs) {
            r.Status__c = 'Approved';
        }
        update reqs;
        Test.stopTest();

        Integer approved = [
            SELECT COUNT() FROM Beat_Day_Request__c
            WHERE Status__c = 'Approved' AND Journey_Cycle__c = :jc.Id
        ];
        System.assertEquals(3, approved, 'All three No-PJP approvals within a JC should succeed');
    }

    @isTest
    static void fourthApprovalIsBlocked() {
        Target_Period__c jc = makeJourneyCycle();
        List<Beat_Day_Request__c> first = new List<Beat_Day_Request__c>{
            newRequest(jc.Id), newRequest(jc.Id), newRequest(jc.Id)
        };
        insert first;
        for (Beat_Day_Request__c r : first) {
            r.Status__c = 'Approved';
        }
        update first;

        Beat_Day_Request__c fourth = newRequest(jc.Id);
        insert fourth;
        fourth.Status__c = 'Approved';

        Test.startTest();
        Boolean blocked = false;
        try {
            update fourth;
        } catch (DmlException e) {
            blocked = true;
            System.assert(
                e.getMessage().contains('maximum of 3'),
                'Expected the BRD 7.4 cap message, got: ' + e.getMessage()
            );
        }
        Test.stopTest();

        System.assert(blocked, 'The 4th No-PJP approval in a JC must be blocked (BRD 7.4)');
    }
}
