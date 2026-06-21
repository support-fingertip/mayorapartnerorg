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
    static void assigningUserSyncsManagerAndRole() {
        User managerUser = makeUser('mgr');
        User repUser = makeUser('rep');
        UserRole posRole = new UserRole(Name = 'RSM Role', DeveloperName = 'POS_RSM_ROLE_01');
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new List<User>{ managerUser, repUser };
            insert posRole; // setup-object DML inside runAs avoids MIXED_DML
        }

        // Position whose POS_<code> matches the pre-created role.
        Position__c pos = new Position__c(Name = 'RSM Role', Position_Code__c = 'RSM-ROLE-01');
        insert pos;

        Test.startTest();
        Employee__c managerEmp = new Employee__c(
            Channels__c = 'GT',
            User__c = managerUser.Id
        );
        insert managerEmp;

        Employee__c repEmp = new Employee__c(
            Channels__c = 'GT',
            User__c = repUser.Id,
            Reporting_Manager__c = managerEmp.Id,
            Position__c = pos.Id
        );
        insert repEmp;
        Test.stopTest();

        User refreshed = [SELECT ManagerId, UserRoleId FROM User WHERE Id = :repUser.Id];
        System.assertEquals(
            managerUser.Id, refreshed.ManagerId,
            'Rep user ManagerId should sync from the reporting manager employee.'
        );
        System.assertEquals(
            posRole.Id, refreshed.UserRoleId,
            'Rep user Role should sync from the employee position.'
        );
    }
}