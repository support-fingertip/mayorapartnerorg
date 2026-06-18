/**
 * @description Tests for MDM_MTArticleCode_Service (BRD §9.5 MT article-code
 *              mapping). Verifies active-only resolution and blank handling.
 */
@isTest
private class MDM_MTArticleCode_Service_Test {

    @isTest
    static void resolvesActiveProductByArticleCode() {
        Product_Extension__c active = new Product_Extension__c(
            Name = 'Malkist Cheese Crackers',
            SKU_Code__c = 'MLK-CHE-130',
            MT_Article_Code__c = 'REL-1001',
            Is_Active__c = true
        );
        Product_Extension__c inactive = new Product_Extension__c(
            Name = 'Discontinued SKU',
            SKU_Code__c = 'OLD-1',
            MT_Article_Code__c = 'REL-9999',
            Is_Active__c = false
        );
        insert new List<Product_Extension__c>{ active, inactive };

        Test.startTest();
        Map<String, Product_Extension__c> resolved =
            MDM_MTArticleCode_Service.resolveByArticleCode(
                new Set<String>{ 'REL-1001', 'REL-9999', '  ' }
            );
        Test.stopTest();

        System.assertEquals(1, resolved.size(), 'Only the active product should resolve.');
        System.assertEquals(active.Id, resolved.get('REL-1001').Id, 'Article code maps to its SKU.');
        System.assertEquals(active.Id, MDM_MTArticleCode_Service.skuIdForArticleCode('REL-1001'));
        System.assertEquals(null, MDM_MTArticleCode_Service.skuIdForArticleCode('NO-SUCH-CODE'));
    }

    @isTest
    static void blankInputReturnsEmpty() {
        System.assert(
            MDM_MTArticleCode_Service.resolveByArticleCode(null).isEmpty(),
            'Null input returns empty map.'
        );
        System.assertEquals(null, MDM_MTArticleCode_Service.skuIdForArticleCode(null));
    }
}
