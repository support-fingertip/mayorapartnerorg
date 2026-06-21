/**
 * @description Tests for Position -> Role automation. Verifies that creating
 *              positions auto-creates the linked Salesforce Roles and that the
 *              position self-hierarchy drives the role hierarchy.
 */
@isTest
private class MDM_Position_TriggerHandler_Test {

    @isTest
    static void createsRoleHierarchyFromPositions() {
        Test.startTest();
        Position__c parent = new Position__c(
            Name = 'Regional Sales Manager',
            Position_Code__c = 'RSM-01'
        );
        insert parent;

        Position__c child = new Position__c(
            Name = 'Area Sales Manager',
            Position_Code__c = 'ASM-01',
            Parent_Position__c = parent.Id
        );
        insert child;
        Test.stopTest(); // flushes the async role provisioning

        UserRole parentRole = [
            SELECT Id, Name, DeveloperName, ParentRoleId
            FROM UserRole WHERE DeveloperName = 'POS_RSM_01' LIMIT 1
        ];
        UserRole childRole = [
            SELECT Id, Name, DeveloperName, ParentRoleId
            FROM UserRole WHERE DeveloperName = 'POS_ASM_01' LIMIT 1
        ];

        System.assertEquals('Regional Sales Manager', parentRole.Name, 'Role label mirrors position name.');
        System.assertEquals('Area Sales Manager', childRole.Name, 'Role label mirrors position name.');
        System.assertEquals(
            parentRole.Id, childRole.ParentRoleId,
            'Child role parent should mirror the parent position.'
        );
    }

    @isTest
    static void developerNameIsSanitized() {
        System.assertEquals('POS_RSM_01', MDM_PositionRoleProvisioner.devName('rsm/01'));
        System.assertEquals('POS_ASM_01', MDM_PositionRoleProvisioner.devName('ASM-01'));
        System.assertEquals(null, MDM_PositionRoleProvisioner.devName('   '));
    }
}