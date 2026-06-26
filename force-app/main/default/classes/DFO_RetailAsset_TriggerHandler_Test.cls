/**
 * @description Tests for DFO_RetailAsset_TriggerHandler (BRD §21.15).
 *
 * @author  SFA Development Team
 * @date    2026
 */
@isTest
private class DFO_RetailAsset_TriggerHandler_Test {

    @isTest
    static void defaultsAreApplied() {
        Retail_Asset__c asset = new Retail_Asset__c(Name = 'Cooler 001');

        Test.startTest();
        insert asset;
        Test.stopTest();

        asset = [SELECT Status__c, Given_Date__c FROM Retail_Asset__c WHERE Id = :asset.Id];
        System.assertEquals('Active', asset.Status__c, 'Status should default to Active');
        System.assertEquals(Date.today(), asset.Given_Date__c, 'Given Date should default to today');
    }

    @isTest
    static void explicitStatusPreserved() {
        Retail_Asset__c asset = new Retail_Asset__c(Name = 'Rack 002', Status__c = 'Returned');

        Test.startTest();
        insert asset;
        Test.stopTest();

        asset = [SELECT Status__c FROM Retail_Asset__c WHERE Id = :asset.Id];
        System.assertEquals('Returned', asset.Status__c, 'Explicit status should be preserved');
    }
}
