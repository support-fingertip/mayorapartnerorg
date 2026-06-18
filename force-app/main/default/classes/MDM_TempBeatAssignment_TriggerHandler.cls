/**
 * @description Trigger handler for Temporary_Beat_Assignment__c (BRD §5.3).
 *              Defaults Start_Date to today and Status to Active on creation,
 *              and auto-expires an assignment once its End_Date has passed.
 *              Because all custom objects in this org use a ReadWrite OWD,
 *              access to the lent beat/outlets is already open — this handler
 *              governs the assignment lifecycle, not row sharing.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class MDM_TempBeatAssignment_TriggerHandler extends TriggerHandler {

    private static final String STATUS_ACTIVE = 'Active';
    private static final String STATUS_EXPIRED = 'Expired';

    protected override void beforeInsert() {
        for (Temporary_Beat_Assignment__c rec : (List<Temporary_Beat_Assignment__c>) Trigger.new) {
            if (rec.Start_Date__c == null) {
                rec.Start_Date__c = Date.today();
            }
            if (String.isBlank(rec.Status__c)) {
                rec.Status__c = STATUS_ACTIVE;
            }
            expireIfPast(rec);
        }
    }

    protected override void beforeUpdate() {
        for (Temporary_Beat_Assignment__c rec : (List<Temporary_Beat_Assignment__c>) Trigger.new) {
            expireIfPast(rec);
        }
    }

    /** Flips an active assignment to Expired once its End_Date is in the past. */
    private void expireIfPast(Temporary_Beat_Assignment__c rec) {
        if (rec.Status__c == STATUS_ACTIVE
                && rec.End_Date__c != null
                && rec.End_Date__c < Date.today()) {
            rec.Status__c = STATUS_EXPIRED;
        }
    }
}
