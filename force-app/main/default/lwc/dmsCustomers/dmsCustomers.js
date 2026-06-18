import { LightningElement } from 'lwc';
import { getCustomersData } from 'c/dmsData';

const ALL = 'All';

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
}
