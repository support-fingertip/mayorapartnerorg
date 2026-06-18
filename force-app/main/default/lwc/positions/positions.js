import { LightningElement } from 'lwc';
import { getPositions, getTempAssignments } from 'c/dmsData';

const ALL = 'All';

const STATUS_THEME = { Filled: 'success', Vacant: 'warning' };
const TEMP_STATUS_THEME = { Active: 'success', Expired: 'neutral' };

/**
 * Position & Role Management (BRD §5–6).
 * A Position auto-creates a matching Role; assigning a User flows the Role,
 * Profile and Manager to that user, who then owns the Position's records.
 * A vacant Position falls back to the System Admin as owner.
 */
export default class Positions extends LightningElement {
    activeTab = 'positions';

    positions = [];
    tempAssignments = [];

    level = ALL;
    status = ALL;
    searchKey = '';

    connectedCallback() {
        this.positions = getPositions();
        this.tempAssignments = getTempAssignments();
    }

    /* -------------------------------- tabs -------------------------------- */
    get positionsTabClass() {
        return this.isPositions ? 'dms-subtab dms-subtab_active' : 'dms-subtab';
    }
    get tempTabClass() {
        return this.isTemp ? 'dms-subtab dms-subtab_active' : 'dms-subtab';
    }
    get isPositions() {
        return this.activeTab === 'positions';
    }
    get isTemp() {
        return this.activeTab === 'temp';
    }
    handleTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    /* ------------------------------- KPIs --------------------------------- */
    get kpis() {
        const filled = this.positions.filter((p) => p.status === 'Filled').length;
        const vacant = this.positions.length - filled;
        return [
            { id: 'total', label: 'Total Positions', value: `${this.positions.length}`, variant: 'default' },
            { id: 'filled', label: 'Filled', value: `${filled}`, variant: 'accent' },
            { id: 'vacant', label: 'Vacant (owned by Admin)', value: `${vacant}`, variant: 'warning' },
            { id: 'roles', label: 'Roles Auto-Created', value: `${this.positions.length}`, variant: 'default' }
        ];
    }

    /* ------------------------------ filters ------------------------------- */
    get levelOptions() {
        const values = [...new Set(this.positions.map((p) => p.level))];
        return [{ label: 'All Levels', value: ALL }, ...values.map((v) => ({ label: v, value: v }))];
    }
    get statusOptions() {
        return [
            { label: 'All Status', value: ALL },
            { label: 'Filled', value: 'Filled' },
            { label: 'Vacant', value: 'Vacant' }
        ];
    }

    get filteredPositions() {
        const key = this.searchKey.toLowerCase();
        return this.positions
            .filter((p) => this.level === ALL || p.level === this.level)
            .filter((p) => this.status === ALL || p.status === this.status)
            .filter(
                (p) =>
                    !key ||
                    p.code.toLowerCase().includes(key) ||
                    p.user.toLowerCase().includes(key) ||
                    p.area.toLowerCase().includes(key)
            )
            .map((p) => ({
                ...p,
                key: p.code,
                statusTheme: STATUS_THEME[p.status] || 'neutral',
                owner: p.status === 'Filled' ? p.user : 'System Admin (vacant)',
                ownerClass: p.status === 'Filled' ? 'dms-strong' : 'dms-muted'
            }));
    }

    get positionCountLabel() {
        return `${this.filteredPositions.length} of ${this.positions.length} positions`;
    }

    get tempRows() {
        return this.tempAssignments.map((t) => ({
            ...t,
            key: `${t.beat}-${t.fromPosition}`,
            statusTheme: TEMP_STATUS_THEME[t.status] || 'neutral'
        }));
    }

    handleLevel(e) {
        this.level = e.detail.value;
    }
    handleStatus(e) {
        this.status = e.detail.value;
    }
    handleSearch(e) {
        this.searchKey = e.target.value;
    }
}
