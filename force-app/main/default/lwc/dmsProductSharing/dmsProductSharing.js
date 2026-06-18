import { LightningElement } from 'lwc';
import { getProductSharing } from 'c/dmsData';

const ALL = 'All';

const LEVEL_THEME = {
    Nation: 'info',
    Branch: 'neutral',
    State: 'warning',
    Channel: 'success',
    Distributor: 'purple'
};
const STATUS_THEME = { Active: 'success', Inactive: 'neutral' };

/**
 * Product Sharing / Visibility (BRD §9.3).
 * Admin assigns each SKU's visibility scope — Nation, Branch, State, Channel
 * (GT / MT / Both) or Distributor-specific. The most specific rule wins.
 */
export default class DmsProductSharing extends LightningElement {
    rules = [];

    level = ALL;
    channel = ALL;
    searchKey = '';

    connectedCallback() {
        this.rules = getProductSharing();
    }

    /* ------------------------------- KPIs --------------------------------- */
    get kpis() {
        const by = (lvl) => this.rules.filter((r) => r.level === lvl).length;
        return [
            { id: 'total', label: 'Visibility Rules', value: `${this.rules.length}`, variant: 'default' },
            { id: 'nation', label: 'Nation-wide', value: `${by('Nation')}`, variant: 'accent' },
            { id: 'state', label: 'State-specific', value: `${by('State')}`, variant: 'default' },
            { id: 'dist', label: 'Distributor-specific', value: `${by('Distributor')}`, variant: 'warning' }
        ];
    }

    /* ------------------------------ filters ------------------------------- */
    get levelOptions() {
        return [
            { label: 'All Levels', value: ALL },
            { label: 'Nation', value: 'Nation' },
            { label: 'Branch', value: 'Branch' },
            { label: 'State', value: 'State' },
            { label: 'Channel', value: 'Channel' },
            { label: 'Distributor', value: 'Distributor' }
        ];
    }
    get channelOptions() {
        return [
            { label: 'All Channels', value: ALL },
            { label: 'GT', value: 'GT' },
            { label: 'MT', value: 'MT' },
            { label: 'Both', value: 'Both' }
        ];
    }

    get filteredRules() {
        const key = this.searchKey.toLowerCase();
        return this.rules
            .filter((r) => this.level === ALL || r.level === this.level)
            .filter((r) => this.channel === ALL || r.channel === this.channel)
            .filter(
                (r) =>
                    !key ||
                    r.sku.toLowerCase().includes(key) ||
                    r.skuName.toLowerCase().includes(key) ||
                    r.scope.toLowerCase().includes(key)
            )
            .map((r) => ({
                ...r,
                key: r.id,
                levelTheme: LEVEL_THEME[r.level] || 'neutral',
                statusTheme: STATUS_THEME[r.status] || 'neutral'
            }));
    }

    get ruleCountLabel() {
        return `${this.filteredRules.length} of ${this.rules.length} rules`;
    }

    /* ------------------------------ handlers ------------------------------ */
    handleLevel(e) {
        this.level = e.detail.value;
    }
    handleChannel(e) {
        this.channel = e.detail.value;
    }
    handleSearch(e) {
        this.searchKey = e.target.value;
    }
}
