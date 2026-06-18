public with sharing class SchemeController {
    /**
     * Returns active/configured schemes with their child rows (Slabs,
     * Eligibilities, Bundle Lines, Tiers) for the Scheme Management screen.
     * Read-only and cacheable so the LWC can @wire it.
     */
    @AuraEnabled(cacheable=true)
    public static List<Scheme__c> getSchemes() {
        return [
            SELECT Id, Name, Description__c, Scheme_Class__c, Type__c,
                   Evaluation_Basis__c, Benefit_Type__c, Buy_Quantity__c,
                   Get_Quantity__c, Is_Pass_Through__c, Start_Date__c, End_Date__c,
                   Budget__c, Utilized_Amount__c, Budget_Behaviour__c, Claimable__c,
                   Approval_Status__c, Active__c,
                   (SELECT Id, Name, Buy_Quantity__c, Get_Quantity__c,
                           Discount_Percent__c, Discount_Value__c, Free_Product__c,
                           Sort_Order__c
                    FROM Slabs__r ORDER BY Sort_Order__c),
                   (SELECT Id, Name, Region__c, Channel__c, Outlet_Type__c,
                           Outlet_Tag__c, Distributor_Type__c
                    FROM Eligibilities__r),
                   (SELECT Id, Name, Product__c, Quantity__c, Line_Role__c
                    FROM Bundle_Lines__r),
                   (SELECT Id, Name, Tier__c, Buy_Quantity__c, Get_Quantity__c,
                           Discount_Percent__c, Discount_Value__c, Active__c
                    FROM Tiers__r)
            FROM Scheme__c
            ORDER BY CreatedDate DESC
        ];
    }

    /** Settlement records (cumulative schemes) for the Claims tab. */
    @AuraEnabled(cacheable=true)
    public static List<Scheme_Claim__c> getSchemeClaims() {
        return [
            SELECT Id, Name, Scheme__c, Scheme__r.Name, Distributor__c,
                   Distributor__r.Name, Claim_Amount__c, Status__c
            FROM Scheme_Claim__c
            ORDER BY CreatedDate DESC
        ];
    }
}
