import { LightningElement } from 'lwc';
import { getManagedSchemes, getSchemeClaims, formatCurrency } from 'c/dmsData';

const ALL = 'All';

const STATUS_THEME = {
    Active: 'success',
    Draft: 'neutral',
    'Pending IT Review': 'warning',
    'Pending Director': 'info',
    Expired: 'neutral',
    Deactivated: 'danger'
};
const CLAIM_THEME = { Draft: 'neutral', Approved: 'info', Settled: 'success' };

/**
 * Scheme Management (BRD §13 + Schemes Architecture).
 * One Header (Scheme) joined to its Children — Slabs, Eligibility, Bundle
 * Lines and Tiers — with a Claim settlement record for cumulative schemes.
 */
export default class DmsSchemes extends LightningElement {
    activeTab = 'schemes';

    schemes = [];
    claims = [];
    selectedId = null;

    type = ALL;
    status = ALL;
    searchKey = '';

    connectedCallback() {
        this.schemes = getManagedSchemes();
        this.claims = getSchemeClaims();
    }

    /* -------------------------------- tabs -------------------------------- */
    get schemesTabClass() {
        return this.isSchemes ? 'dms-subtab dms-subtab_active' : 'dms-subtab';
    }
    get claimsTabClass() {
        return this.isClaims ? 'dms-subtab dms-subtab_active' : 'dms-subtab';
    }
    get isSchemes() {
        return this.activeTab === 'schemes';
    }
    get isClaims() {
        return this.activeTab === 'claims';
    }
    handleTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        this.selectedId = null;
    }

    /* ------------------------------- KPIs --------------------------------- */
    get kpis() {
        const active = this.schemes.filter((s) => s.status === 'Active');
        const pending = this.schemes.filter((s) => s.status.startsWith('Pending')).length;
        const budget = active.reduce((sum, s) => sum + s.budget, 0);
        const used = active.reduce((sum, s) => sum + s.utilized, 0);
        const pct = budget ? Math.round((used / budget) * 100) : 0;
        return [
            { id: 'total', label: 'Total Schemes', value: `${this.schemes.length}`, variant: 'default' },
            { id: 'active', label: 'Active', value: `${active.length}`, variant: 'accent' },
            { id: 'pending', label: 'Pending Approval', value: `${pending}`, variant: 'warning' },
            { id: 'budget', label: 'Active Budget Utilized', value: `${pct}%`, variant: 'default' }
        ];
    }

    /* ------------------------------ filters ------------------------------- */
    get typeOptions() {
        const values = [...new Set(this.schemes.map((s) => s.type))];
        return [{ label: 'All Types', value: ALL }, ...values.map((v) => ({ label: v, value: v }))];
    }
    get statusOptions() {
        const values = [...new Set(this.schemes.map((s) => s.status))];
        return [{ label: 'All Status', value: ALL }, ...values.map((v) => ({ label: v, value: v }))];
    }

    get filteredSchemes() {
        const key = this.searchKey.toLowerCase();
        return this.schemes
            .filter((s) => this.type === ALL || s.type === this.type)
            .filter((s) => this.status === ALL || s.status === this.status)
            .filter(
                (s) =>
                    !key ||
                    s.name.toLowerCase().includes(key) ||
                    s.id.toLowerCase().includes(key)
            )
            .map((s) => {
                const pct = s.budget ? Math.round((s.utilized / s.budget) * 100) : 0;
                const color = pct >= 90 ? '#e2231a' : pct >= 70 ? '#c47d00' : '#6d28d9';
                return {
                    ...s,
                    key: s.id,
                    statusTheme: STATUS_THEME[s.status] || 'neutral',
                    passLabel: s.passThrough ? 'Pass-Through' : 'Single-Level',
                    utilPct: pct,
                    utilLabel: `${pct}%`,
                    barStyle: `width:${pct}%;background-color:${color};`,
                    rowClass: s.id === this.selectedId ? 'dms-trow dms-trow_selected' : 'dms-trow'
                };
            });
    }

    get schemeCountLabel() {
        return `${this.filteredSchemes.length} of ${this.schemes.length} schemes`;
    }

    /* --------------------------- detail (children) ------------------------ */
    get selected() {
        const s = this.schemes.find((x) => x.id === this.selectedId);
        if (!s) {
            return null;
        }
        return {
            ...s,
            budgetLabel: formatCurrency(s.budget),
            utilizedLabel: formatCurrency(s.utilized),
            passLabel: s.passThrough ? 'Yes' : 'No',
            claimableLabel: s.claimable ? 'Yes' : 'No',
            hasSlabs: s.slabs.length > 0,
            hasEligibility: s.eligibilityRows.length > 0,
            hasTiers: s.tiers.length > 0,
            hasBundle: s.bundleLines.length > 0,
            slabRows: s.slabs.map((r, i) => ({ ...r, key: `slab-${i}` })),
            eligRows: s.eligibilityRows.map((r, i) => ({ ...r, key: `elig-${i}` })),
            tierRows: s.tiers.map((r, i) => ({ ...r, key: `tier-${i}` })),
            bundleRows: s.bundleLines.map((r, i) => ({ ...r, key: `bun-${i}` }))
        };
    }

    /* ------------------------------- claims ------------------------------- */
    get claimRows() {
        return this.claims.map((c) => ({
            ...c,
            key: c.id,
            amountLabel: formatCurrency(c.amount),
            statusTheme: CLAIM_THEME[c.status] || 'neutral'
        }));
    }

    /* ------------------------------ handlers ------------------------------ */
    handleType(e) {
        this.type = e.detail.value;
    }
    handleStatus(e) {
        this.status = e.detail.value;
    }
    handleSearch(e) {
        this.searchKey = e.target.value;
    }
    handleSelect(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedId = this.selectedId === id ? null : id;
    }
    handleCloseDetail() {
        this.selectedId = null;
    }
}
