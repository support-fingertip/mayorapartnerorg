/**
 * @description Tests for MDM_Employee_TriggerHandler — verifies that assigning
 *              a user to an employee with a reporting manager syncs the
 *              corresponding User.ManagerId (BRD §5.2 / §6).
 */
@isTest
private class MDM_Employee_TriggerHandler_Test {

    private static User makeUser(String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniq = alias + System.now().getTime();
        return new User(
            LastName = alias,
            Username = uniq + '@mayora.test.invalid',
            Email = uniq + '@mayora.test',
            Alias = alias.left(8),
            CommunityNickname = uniq.left(40),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
    }

    @isTest
    static void assigningUserSyncsManagerId() {
        User managerUser = makeUser('mgr');
        User repUser = makeUser('rep');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new List<User>{ managerUser, repUser };
        }

        Test.startTest();
        Employee__c managerEmp = new Employee__c(
            Channels__c = 'GT',
            User__c = managerUser.Id
        );
        insert managerEmp;

        Employee__c repEmp = new Employee__c(
            Channels__c = 'GT',
            User__c = repUser.Id,
            Reporting_Manager__c = managerEmp.Id
        );
        insert repEmp;
        Test.stopTest();

        User refreshed = [SELECT ManagerId FROM User WHERE Id = :repUser.Id];
        System.assertEquals(
            managerUser.Id, refreshed.ManagerId,
            'Rep user ManagerId should sync from the reporting manager employee.'
        );
    }
}
