import { LightningElement } from 'lwc';
import { getTargets, formatCurrency, formatNumber } from 'c/dmsData';

const ALL = 'All';

/**
 * Targets vs Actual (BRD §13 Targets).
 * Targets are managed by tier (P1 / P2 / Secondary / Outlet) and always
 * broken down by Product Hierarchy. Actuals roll up on a JC basis.
 */
export default class Targets extends LightningElement {
    targets = [];

    tier = ALL;
    brand = ALL;
    searchKey = '';

    connectedCallback() {
        this.targets = getTargets();
    }

    /* ----------------------------- formatting ----------------------------- */
    formatMetric(kpi, value) {
        return kpi === 'Sales Value' ? formatCurrency(value) : formatNumber(value);
    }

    /* ------------------------------- KPIs --------------------------------- */
    get jcLabel() {
        return this.targets.length ? this.targets[0].jc : '—';
    }

    get kpis() {
        const rows = this.targets;
        const achieved = rows.filter((t) => t.actual >= t.target).length;
        const atRisk = rows.filter((t) => t.target > 0 && t.actual / t.target < 0.8).length;
        const avg = rows.length
            ? Math.round(
                  rows.reduce((sum, t) => sum + (t.target ? (t.actual / t.target) * 100 : 0), 0) /
                      rows.length
              )
            : 0;
        return [
            { id: 'avg', label: `Avg Achievement (${this.jcLabel})`, value: `${avg}%`, variant: 'accent' },
            { id: 'lines', label: 'Target Lines', value: `${rows.length}`, variant: 'default' },
            { id: 'achieved', label: 'Achieved', value: `${achieved}`, variant: 'default' },
            { id: 'risk', label: 'At Risk (<80%)', value: `${atRisk}`, variant: 'warning' }
        ];
    }

    /* ------------------------------ filters ------------------------------- */
    get tierOptions() {
        return [
            { label: 'All Tiers', value: ALL },
            { label: 'P1 (SS / DB)', value: 'P1' },
            { label: 'P2 (SD)', value: 'P2' },
            { label: 'Secondary (User)', value: 'Secondary' },
            { label: 'Outlet', value: 'Outlet' }
        ];
    }
    get brandOptions() {
        const values = [...new Set(this.targets.map((t) => t.brand))];
        return [{ label: 'All Brands', value: ALL }, ...values.map((v) => ({ label: v, value: v }))];
    }

    get filteredTargets() {
        const key = this.searchKey.toLowerCase();
        return this.targets
            .filter((t) => this.tier === ALL || t.tier === this.tier)
            .filter((t) => this.brand === ALL || t.brand === this.brand)
            .filter(
                (t) =>
                    !key ||
                    t.entity.toLowerCase().includes(key) ||
                    t.brand.toLowerCase().includes(key)
            )
            .map((t) => {
                const pct = t.target ? Math.round((t.actual / t.target) * 100) : 0;
                let status = 'At Risk';
                let statusTheme = 'danger';
                let color = '#e2231a';
                if (pct >= 100) {
                    status = 'Achieved';
                    statusTheme = 'success';
                    color = '#2e844a';
                } else if (pct >= 80) {
                    status = 'On Track';
                    statusTheme = 'warning';
                    color = '#c47d00';
                }
                return {
                    ...t,
                    key: t.id,
                    targetLabel: this.formatMetric(t.kpi, t.target),
                    actualLabel: this.formatMetric(t.kpi, t.actual),
                    pctLabel: `${pct}%`,
                    barStyle: `width:${Math.min(pct, 100)}%;background-color:${color};`,
                    status,
                    statusTheme
                };
            });
    }

    get targetCountLabel() {
        return `${this.filteredTargets.length} of ${this.targets.length} target lines`;
    }

    /* ------------------------------ handlers ------------------------------ */
    handleTier(e) {
        this.tier = e.detail.value;
    }
    handleBrand(e) {
        this.brand = e.detail.value;
    }
    handleSearch(e) {
        this.searchKey = e.target.value;
    }
}
