/**
 * @description Single trigger for Retail_Asset__c. Delegates to
 *              DFO_RetailAsset_TriggerHandler via the TriggerHandler framework.
 */
trigger Retail_Asset_Trigger on Retail_Asset__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new DFO_RetailAsset_TriggerHandler().run();
}
