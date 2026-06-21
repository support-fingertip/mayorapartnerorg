/**
 * @description Trigger handler for Position__c. Each position is mirrored as a
 *              Salesforce Role (UserRole), and the position self-hierarchy
 *              (Parent_Position__c) drives the role hierarchy (ParentRoleId).
 *
 *              UserRole is a setup object, so the actual role DML is performed
 *              in an asynchronous Queueable (MDM_PositionRoleProvisioner) to
 *              avoid MIXED_DML_OPERATION with the Position__c (non-setup)
 *              transaction.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class MDM_Position_TriggerHandler extends TriggerHandler {

    protected override void afterInsert() {
        enqueue(Trigger.newMap.keySet());
    }

    protected override void afterUpdate() {
        Map<Id, Position__c> oldMap = (Map<Id, Position__c>) Trigger.oldMap;
        Set<Id> changed = new Set<Id>();
        for (Position__c pos : (List<Position__c>) Trigger.new) {
            Position__c prior = oldMap.get(pos.Id);
            if (pos.Name != prior.Name
                    || pos.Position_Code__c != prior.Position_Code__c
                    || pos.Parent_Position__c != prior.Parent_Position__c) {
                changed.add(pos.Id);
            }
        }
        enqueue(changed);
    }

    private void enqueue(Set<Id> positionIds) {
        if (positionIds == null || positionIds.isEmpty()) {
            return;
        }
        // Cannot enqueue another async job from within an async context.
        if (System.isQueueable() || System.isFuture() || System.isBatch()) {
            return;
        }
        System.enqueueJob(new MDM_PositionRoleProvisioner(positionIds));
    }
}