@isTest
private class SchemeControllerTest {
    @testSetup
    static void setup() {
        Scheme__c scheme = new Scheme__c(
            Name = 'Test Buy 4 Get 1',
            Scheme_Class__c = 'Secondary',
            Type__c = 'Slab',
            Evaluation_Basis__c = 'Single-Invoice',
            Benefit_Type__c = 'Free goods',
            Is_Pass_Through__c = false,
            Claimable__c = true,
            Budget__c = 100000,
            Utilized_Amount__c = 25000,
            Approval_Status__c = 'Active',
            Active__c = true,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(28)
        );
        insert scheme;

        insert new Scheme_Slab__c(
            Scheme__c = scheme.Id,
            Buy_Quantity__c = 4,
            Get_Quantity__c = 1,
            Sort_Order__c = 1
        );

        Account distributor = new Account(Name = 'Test Super Stockiest');
        insert distributor;

        insert new Scheme_Claim__c(
            Scheme__c = scheme.Id,
            Distributor__c = distributor.Id,
            Claim_Amount__c = 4820,
            Status__c = 'Draft'
        );
    }

    @isTest
    static void getSchemesReturnsHeaderWithChildren() {
        Test.startTest();
        List<Scheme__c> schemes = SchemeController.getSchemes();
        Test.stopTest();

        System.assertEquals(1, schemes.size(), 'One scheme expected');
        System.assertEquals('Slab', schemes[0].Type__c, 'Type should round-trip');
        System.assertEquals(1, schemes[0].Slabs__r.size(), 'Slab child expected');
        System.assertEquals(4, schemes[0].Slabs__r[0].Buy_Quantity__c, 'Buy qty');
    }

    @isTest
    static void getSchemeClaimsReturnsClaims() {
        Test.startTest();
        List<Scheme_Claim__c> claims = SchemeController.getSchemeClaims();
        Test.stopTest();

        System.assertEquals(1, claims.size(), 'One claim expected');
        System.assertEquals('Draft', claims[0].Status__c, 'Status should round-trip');
    }
}
