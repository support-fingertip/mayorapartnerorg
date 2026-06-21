/**
 * @description Maps Modern-Trade chain article codes to Mayora SKUs during MT
 *              order upload (BRD §9.5). Each MT chain uses its own article code,
 *              stored on Product_Extension__c.MT_Article_Code__c; this service
 *              resolves those codes back to active products so an uploaded MT PO
 *              can be converted to Salesforce order lines.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public with sharing class MDM_MTArticleCode_Service {

    /**
     * @description Resolves a set of MT article codes to active products,
     *              keyed by the stored MT_Article_Code__c value.
     */
    public static Map<String, Product_Extension__c> resolveByArticleCode(Set<String> articleCodes) {
        Map<String, Product_Extension__c> resolved = new Map<String, Product_Extension__c>();
        if (articleCodes == null || articleCodes.isEmpty()) {
            return resolved;
        }

        Set<String> codes = new Set<String>();
        for (String code : articleCodes) {
            if (String.isNotBlank(code)) {
                codes.add(code.trim());
            }
        }
        if (codes.isEmpty()) {
            return resolved;
        }

        for (Product_Extension__c prod : [
            SELECT Id, Name, SKU_Code__c, MT_Article_Code__c
            FROM Product_Extension__c
            WHERE MT_Article_Code__c IN :codes AND Is_Active__c = true
        ]) {
            if (String.isNotBlank(prod.MT_Article_Code__c)) {
                resolved.put(prod.MT_Article_Code__c.trim(), prod);
            }
        }
        return resolved;
    }

    /**
     * @description Convenience single-code lookup; returns the product Id or null.
     */
    public static Id skuIdForArticleCode(String articleCode) {
        if (String.isBlank(articleCode)) {
            return null;
        }
        Product_Extension__c prod =
            resolveByArticleCode(new Set<String>{ articleCode }).get(articleCode.trim());
        return prod == null ? null : prod.Id;
    }
}