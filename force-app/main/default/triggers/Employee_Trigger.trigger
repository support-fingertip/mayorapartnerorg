/**
 * @description Single trigger for Employee__c. Delegates to
 *              MDM_Employee_TriggerHandler via the TriggerHandler framework.
 */
trigger Employee_Trigger on Employee__c (after insert, after update) {
    new MDM_Employee_TriggerHandler().run();
}
