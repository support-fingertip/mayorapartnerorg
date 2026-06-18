/**
 * @description Asynchronously provisions / maintains the Salesforce Role
 *              (UserRole) for each Position__c. The role is linked to its
 *              position by a deterministic DeveloperName (POS_<code>), so no
 *              role Id needs to be written back to the position (which would
 *              cause MIXED_DML against the setup UserRole object).
 *
 *              Behaviour:
 *                - Creates a UserRole for any position that does not yet have
 *                  one (matched by DeveloperName).
 *                - Keeps the role label in sync with the position name.
 *                - Sets the role's ParentRoleId from the parent position's role,
 *                  so the role hierarchy mirrors the position hierarchy.
 *
 * @author  SFA Development Team
 * @date    2026
 */
public class MDM_PositionRoleProvisioner implements Queueable {

    private final Set<Id> positionIds;

    public MDM_PositionRoleProvisioner(Set<Id> positionIds) {
        this.positionIds = positionIds;
    }

    public void execute(QueueableContext ctx) {
        List<Position__c> positions = [
            SELECT Id, Name, Position_Code__c, Parent_Position__r.Position_Code__c
            FROM Position__c
            WHERE Id IN :positionIds
        ];
        if (positions.isEmpty()) {
            return;
        }

        // Collect every developer name we care about (positions + their parents).
        Set<String> devNames = new Set<String>();
        for (Position__c pos : positions) {
            addDevName(devNames, pos.Position_Code__c);
            if (pos.Parent_Position__r != null) {
                addDevName(devNames, pos.Parent_Position__r.Position_Code__c);
            }
        }
        if (devNames.isEmpty()) {
            return;
        }

        Map<String, UserRole> roleByDevName = loadRoles(devNames);

        // Phase 1 — create roles that don't exist yet.
        List<UserRole> toInsert = new List<UserRole>();
        for (Position__c pos : positions) {
            String dev = devName(pos.Position_Code__c);
            if (dev != null && !roleByDevName.containsKey(dev)) {
                toInsert.add(new UserRole(Name = roleLabel(pos), DeveloperName = dev));
                roleByDevName.put(dev, null); // reserve so duplicates in batch don't double-insert
            }
        }
        if (!toInsert.isEmpty()) {
            insert toInsert;
            roleByDevName = loadRoles(devNames); // refresh with the new Ids
        }

        // Phase 2 — sync label + parent link now that all roles exist.
        List<UserRole> toUpdate = new List<UserRole>();
        for (Position__c pos : positions) {
            UserRole role = roleByDevName.get(devName(pos.Position_Code__c));
            if (role == null) {
                continue;
            }
            Id parentRoleId = (pos.Parent_Position__r != null)
                ? roleIdFor(roleByDevName, pos.Parent_Position__r.Position_Code__c)
                : null;

            Boolean dirty = false;
            if (role.Name != roleLabel(pos)) {
                role.Name = roleLabel(pos);
                dirty = true;
            }
            if (role.ParentRoleId != parentRoleId) {
                role.ParentRoleId = parentRoleId;
                dirty = true;
            }
            if (dirty) {
                toUpdate.add(role);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Map<String, UserRole> loadRoles(Set<String> devNames) {
        Map<String, UserRole> byDev = new Map<String, UserRole>();
        for (UserRole role : [
            SELECT Id, Name, DeveloperName, ParentRoleId
            FROM UserRole
            WHERE DeveloperName IN :devNames
        ]) {
            byDev.put(role.DeveloperName, role);
        }
        return byDev;
    }

    private Id roleIdFor(Map<String, UserRole> roleByDevName, String positionCode) {
        UserRole role = roleByDevName.get(devName(positionCode));
        return role == null ? null : role.Id;
    }

    private void addDevName(Set<String> acc, String positionCode) {
        String dev = devName(positionCode);
        if (dev != null) {
            acc.add(dev);
        }
    }

    private String roleLabel(Position__c pos) {
        return String.isNotBlank(pos.Name) ? pos.Name : pos.Position_Code__c;
    }

    /**
     * @description Deterministic, API-safe role DeveloperName for a position
     *              code: uppercased, non-alphanumerics collapsed to single
     *              underscores, prefixed with POS_ (guarantees a letter start),
     *              capped at 80 chars.
     */
    @TestVisible
    private static String devName(String positionCode) {
        if (String.isBlank(positionCode)) {
            return null;
        }
        String cleaned = positionCode.trim().toUpperCase().replaceAll('[^A-Z0-9]', '_');
        cleaned = cleaned.replaceAll('_+', '_');
        cleaned = cleaned.replaceFirst('^_', '').replaceFirst('_$', '');
        if (String.isBlank(cleaned)) {
            return null;
        }
        String dev = 'POS_' + cleaned;
        return dev.length() > 80 ? dev.substring(0, 80) : dev;
    }
}
