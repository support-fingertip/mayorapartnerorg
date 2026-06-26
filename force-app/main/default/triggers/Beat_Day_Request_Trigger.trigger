/**
 * @description Single trigger for Beat_Day_Request__c. Delegates all logic to
 *              BPM_BeatDayRequest_TriggerHandler via the TriggerHandler framework.
 */
trigger Beat_Day_Request_Trigger on Beat_Day_Request__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new BPM_BeatDayRequest_TriggerHandler().run();
}
