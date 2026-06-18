/**
 * @description Single trigger for Temporary_Beat_Assignment__c. Delegates to
 *              MDM_TempBeatAssignment_TriggerHandler via the TriggerHandler framework.
 */
trigger Temporary_Beat_Assignment_Trigger on Temporary_Beat_Assignment__c (before insert, before update) {
    new MDM_TempBeatAssignment_TriggerHandler().run();
}
