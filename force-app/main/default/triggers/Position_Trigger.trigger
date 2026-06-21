/**
 * @description Single trigger for Position__c. Delegates to
 *              MDM_Position_TriggerHandler via the TriggerHandler framework.
 */
trigger Position_Trigger on Position__c (after insert, after update) {
    new MDM_Position_TriggerHandler().run();
}