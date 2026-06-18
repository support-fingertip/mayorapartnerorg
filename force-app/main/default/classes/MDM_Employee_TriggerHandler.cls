/**
 * @description Trigger handler for Employee__c. Keeps the Salesforce user
 *              hierarchy (User.ManagerId) in sync with the employee reporting
 *              structure (Employee__c.Reporting_Manager__c) so that the
 *              ManagerId-based visibility used across the app
 *              (e.g. TAM_RoleHierarchy_Service) reflects position changes —
 *              BRD §5.2 / §6 (assign user => manager flows; position move =>
 *              hierarchy updates).
 *
 *              User is a setup object, so the actual User DML is performed
 *              asynchronously (@future) to avoid MIXED_DML_OPERATION with the
 *              Employee__c (non-setup) transaction.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class MDM_Employee_TriggerHandler extends TriggerHandler {

    // ── After Insert ──────────────────────────────────────────────────────────

    protected override void afterInsert() {
        Set<Id> empIds = collectChanged((List<Employee__c>) Trigger.new, null);
        if (!empIds.isEmpty()) {
            syncUserManagers(empIds);
        }
    }

    // ── After Update ──────────────────────────────────────────────────────────

    protected override void afterUpdate() {
        Map<Id, Employee__c> oldMap = (Map<Id, Employee__c>) Trigger.oldMap;
        Set<Id> empIds = collectChanged((List<Employee__c>) Trigger.new, oldMap);
        if (!empIds.isEmpty()) {
            syncUserManagers(empIds);
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * @description Returns the Ids of employees whose User__c or
     *              Reporting_Manager__c changed (or new records) and that have a
     *              user assigned — these are the ones whose User.ManagerId may
     *              need to be re-synced. Returns empty when already running
     *              asynchronously, since a @future cannot be enqueued from a
     *              future/batch/queueable context.
     */
    private Set<Id> collectChanged(List<Employee__c> records, Map<Id, Employee__c> oldMap) {
        Set<Id> ids = new Set<Id>();
        if (System.isFuture() || System.isBatch() || System.isQueueable()) {
            return ids;
        }
        for (Employee__c emp : records) {
            if (emp.User__c == null) {
                continue;
            }
            Boolean changed = (oldMap == null)
                || emp.User__c != oldMap.get(emp.Id).User__c
                || emp.Reporting_Manager__c != oldMap.get(emp.Id).Reporting_Manager__c
                || emp.Position__c != oldMap.get(emp.Id).Position__c;
            if (changed) {
                ids.add(emp.Id);
            }
        }
        return ids;
    }

    /**
     * @description Asynchronously aligns each assigned user with their employee
     *              record: sets User.ManagerId from the reporting manager's user,
     *              and User.UserRoleId from the employee's Position (the role
     *              auto-created by MDM_PositionRoleProvisioner, matched by the
     *              POS_<code> DeveloperName). Re-queries for fresh data and only
     *              updates users whose Manager or Role actually differs.
     */
    @future
    public static void syncUserManagers(Set<Id> employeeIds) {
        List<Employee__c> emps = [
            SELECT Id, User__c, Reporting_Manager__r.User__c, Position__r.Position_Code__c
            FROM Employee__c
            WHERE Id IN :employeeIds AND User__c != null
        ];
        if (emps.isEmpty()) {
            return;
        }

        Map<Id, Id> userToManagerUser = new Map<Id, Id>();
        Map<Id, String> userToRoleDevName = new Map<Id, String>();
        Set<String> roleDevNames = new Set<String>();
        for (Employee__c emp : emps) {
            userToManagerUser.put(
                emp.User__c,
                emp.Reporting_Manager__r != null ? emp.Reporting_Manager__r.User__c : null
            );
            String roleDev = (emp.Position__r != null)
                ? MDM_PositionRoleProvisioner.devName(emp.Position__r.Position_Code__c)
                : null;
            userToRoleDevName.put(emp.User__c, roleDev);
            if (roleDev != null) {
                roleDevNames.add(roleDev);
            }
        }

        // Resolve the position roles to their Ids.
        Map<String, Id> roleIdByDevName = new Map<String, Id>();
        if (!roleDevNames.isEmpty()) {
            for (UserRole role : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName IN :roleDevNames]) {
                roleIdByDevName.put(role.DeveloperName, role.Id);
            }
        }

        Map<Id, User> users = new Map<Id, User>([
            SELECT Id, ManagerId, UserRoleId FROM User WHERE Id IN :userToManagerUser.keySet()
        ]);

        List<User> toUpdate = new List<User>();
        for (Id userId : users.keySet()) {
            User usr = users.get(userId);
            Boolean dirty = false;

            Id newManager = userToManagerUser.get(userId);
            if (usr.ManagerId != newManager) {
                usr.ManagerId = newManager;
                dirty = true;
            }

            String roleDev = userToRoleDevName.get(userId);
            if (roleDev != null && roleIdByDevName.containsKey(roleDev)) {
                Id newRole = roleIdByDevName.get(roleDev);
                if (usr.UserRoleId != newRole) {
                    usr.UserRoleId = newRole;
                    dirty = true;
                }
            }

            if (dirty) {
                toUpdate.add(usr);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}
