import { LightningElement } from 'lwc';
import { getCustomersData, getCustomerDetail, formatCurrency } from 'c/dmsData';

const ALL = 'All';
const DETAIL_TABS = [
    { id: 'orders', label: 'Last 10 Orders' },
    { id: 'skus', label: 'SKUs Covered' },
    { id: 'aliases', label: 'Brand Aliases' },
    { id: 'subbrands', label: 'Sub-Brands' },
    { id: 'brands', label: 'Brands' },
    { id: 'target', label: 'Target vs Actual' }
];

export default class DmsCustomers extends LightningElement {
    activeTab = 'retailers';
    outletFilter = ALL;
    beatFilter = ALL;
    search = '';

    retailers = [];
    subDistributors = [];

    connectedCallback() {
        const d = getCustomersData();
        this.retailers = d.retailers;
        this.subDistributors = d.subDistributors;
    }

    /* -------------------------------- tabs -------------------------------- */
    get retailerTabClass() {
        return this.activeTab === 'retailers' ? 'dms-subtab dms-subtab_active' : 'dms-subtab';
    }
    get subDistTabClass() {
        return this.activeTab === 'subdist' ? 'dms-subtab dms-subtab_active' : 'dms-subtab';
    }
    get isRetailers() {
        return this.activeTab === 'retailers';
    }
    handleTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        this.outletFilter = ALL;
        this.beatFilter = ALL;
        this.search = '';
    }

    get activeList() {
        return this.isRetailers ? this.retailers : this.subDistributors;
    }

    get outletOptions() {
        const vals = [...new Set(this.activeList.map((c) => c.outletType))];
        return [{ label: 'All Outlet Types', value: ALL }, ...vals.map((v) => ({ label: v, value: v }))];
    }
    get beatOptions() {
        const vals = [...new Set(this.activeList.map((c) => c.beat))];
        return [{ label: 'All Beats', value: ALL }, ...vals.map((v) => ({ label: v, value: v }))];
    }

    get rows() {
        const key = this.search.toLowerCase();
        return this.activeList
            .filter((c) => this.outletFilter === ALL || c.outletType === this.outletFilter)
            .filter((c) => this.beatFilter === ALL || c.beat === this.beatFilter)
            .filter(
                (c) =>
                    !key ||
                    c.name.toLowerCase().includes(key) ||
                    c.area.toLowerCase().includes(key) ||
                    c.beat.toLowerCase().includes(key)
            )
            .map((c) => ({
                ...c,
                key: c.code,
                typeTheme: c.type === 'Retailer' ? 'info' : 'purple',
                monthlyLabel: `₹${Math.round(c.monthly / 1000)}k`
            }));
    }

    get totalLabel() {
        return this.isRetailers ? 'Total Retailers' : 'Total Sub-Distributors';
    }
    get totalCount() {
        return this.activeList.length;
    }

    handleOutlet(e) {
        this.outletFilter = e.detail.value;
    }
    handleBeat(e) {
        this.beatFilter = e.detail.value;
    }
    handleSearch(e) {
        this.search = e.target.value;
    }

    /* --------------------------- detail modal ----------------------------- */
    detailOpen = false;
    detailTab = 'orders';
    selected = null;

    viewCustomer(event) {
        const code = event.currentTarget.dataset.code;
        const c = this.activeList.find((x) => x.code === code);
        if (!c) {
            return;
        }
        const d = getCustomerDetail(c);
        this.selected = {
            ...c,
            monthlyLabel: `₹${Math.round(c.monthly / 1000)}k`,
            subtitle: `${c.code} · ${c.area}`,
            orders: d.orders.map((o) => ({ ...o, key: o.id, amountLabel: formatCurrency(o.amount) })),
            skus: d.skus.map((s) => ({ ...s, key: s.code })),
            aliases: d.aliases.map((a) => ({ key: a, label: a })),
            subBrands: d.subBrands.map((a) => ({ key: a, label: a })),
            brands: d.brands.map((a) => ({ key: a, label: a })),
            targets: d.targets.map((t) => ({
                ...t,
                key: t.code,
                pctLabel: `${t.pct}%`,
                pctClass: t.pct >= 85 ? 'dms-pct dms-pct_good' : 'dms-pct dms-pct_warn'
            }))
        };
        this.detailTab = 'orders';
        this.detailOpen = true;
    }
    closeDetail() {
        this.detailOpen = false;
    }
    setDetailTab(event) {
        this.detailTab = event.currentTarget.dataset.id;
    }
    get detailTabs() {
        return DETAIL_TABS.map((t) => ({
            ...t,
            class: t.id === this.detailTab ? 'dms-itab dms-itab_active' : 'dms-itab'
        }));
    }
    get isOrders() {
        return this.detailTab === 'orders';
    }
    get isSkus() {
        return this.detailTab === 'skus';
    }
    get isAliases() {
        return this.detailTab === 'aliases';
    }
    get isSubBrands() {
        return this.detailTab === 'subbrands';
    }
    get isBrands() {
        return this.detailTab === 'brands';
    }
    get isTarget() {
        return this.detailTab === 'target';
    }
    get chipList() {
        if (this.detailTab === 'aliases') {
            return this.selected.aliases;
        }
        if (this.detailTab === 'subbrands') {
            return this.selected.subBrands;
        }
        return this.selected.brands;
    }
    get isChipsTab() {
        return this.isAliases || this.isSubBrands || this.isBrands;
    }
}
