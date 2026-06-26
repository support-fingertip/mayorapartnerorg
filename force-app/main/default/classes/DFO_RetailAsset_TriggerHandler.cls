/**
 * @description Trigger handler for Retail_Asset__c (BRD §21.15). Defaults the
 *              status to Active and the given date to today on creation.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class DFO_RetailAsset_TriggerHandler extends TriggerHandler {

    protected override void beforeInsert() {
        for (Retail_Asset__c asset : (List<Retail_Asset__c>) Trigger.new) {
            if (String.isBlank(asset.Status__c)) {
                asset.Status__c = 'Active';
            }
            if (asset.Given_Date__c == null) {
                asset.Given_Date__c = Date.today();
            }
        }
    }
}
