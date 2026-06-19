import { LightningElement } from 'lwc';
import {
    getP1Dashboard,
    getP2Dashboard,
    getSecondaryDashboard,
    getPeriodOptions
} from 'c/dmsData';

const DASH_TABS = [
    { id: 'p1', label: 'P1 Dashboard' },
    { id: 'p2', label: 'P2 Dashboard' },
    { id: 'secondary', label: 'Secondary Dashboard' }
];

const ORDER_DIMS = [
    { dim: 'brand', label: 'Brand' },
    { dim: 'subBrand', label: 'Sub-Brand' },
    { dim: 'brandAlias', label: 'Brand Alias' }
];

const RANGE_DIMS = [...ORDER_DIMS, { dim: 'sku', label: 'SKU' }];

const ORDERS_TICKS = ['0', '5', '10', '15', '20'];
const VALUE_TICKS = ['₹0L', '₹0.5L', '₹1L', '₹1.5L', '₹2L'];
const BEAT_TICKS = ['₹1.6L', '₹1.2L', '₹0.8L', '₹0.4L', '₹0L'];
const CUSTOMER_TICKS = ['₹0L', '₹0.25L', '₹0.5L', '₹0.75L', '₹1L'];
const RANGE_ACCENT_COLOR = { purple: '#6d28d9', brand: '#a20417' };

/** DMS landing screen — hosts the P1, P2 and Secondary dashboards as sub-tabs. */
export default class DmsHome extends LightningElement {
    activeDash = 'p1';
    period = 'this-jc';
    orderDim = 'brand';
    rangeDim = 'brand';

    p1 = {};
    p2 = {};
    secondary = {};
    periodOptions = [];

    // chart axis config
    ordersTicks = ORDERS_TICKS;
    valueTicks = VALUE_TICKS;
    beatTicks = BEAT_TICKS;
    customerTicks = CUSTOMER_TICKS;
    ordersMax = 20;
    valueMax = 2;
    beatMax = 1.6;
    customerMax = 1;

    connectedCallback() {
        this.p1 = getP1Dashboard();
        this.p2 = getP2Dashboard();
        this.secondary = getSecondaryDashboard();
        this.periodOptions = getPeriodOptions();
    }

    /* -------------------------------- tabs -------------------------------- */
    get subTabs() {
        return DASH_TABS.map((tab) => ({
            ...tab,
            class:
                tab.id === this.activeDash
                    ? `dms-subtab dms-subtab_active dms-subtab_${tab.id}`
                    : 'dms-subtab'
        }));
    }

    get isP1() {
        return this.activeDash === 'p1';
    }
    get isP2() {
        return this.activeDash === 'p2';
    }
    get isSecondary() {
        return this.activeDash === 'secondary';
    }

    /* ------------------------------- P1 data ------------------------------ */
    get p1Kpis() {
        return this.p1.kpis || [];
    }

    get orderDimButtons() {
        return ORDER_DIMS.map((opt) => ({
            ...opt,
            class:
                opt.dim === this.orderDim
                    ? 'dms-toggle__btn dms-toggle__btn_navy'
                    : 'dms-toggle__btn'
        }));
    }

    get ordersChartItems() {
        return this.p1.orderAnalysis ? this.p1.orderAnalysis[this.orderDim].orders : [];
    }

    get valueChartItems() {
        return this.p1.orderAnalysis ? this.p1.orderAnalysis[this.orderDim].value : [];
    }

    get skuReturns() {
        return (this.p1.skuReturns || []).map((r) => ({ ...r, key: r.code }));
    }

    get schemeClaims() {
        return (this.p1.schemeClaims || []).map((c) => ({ ...c, key: c.name }));
    }

    /* ------------------------------- P2 data ------------------------------ */
    get p2Kpis() {
        return this.p2.kpis || [];
    }

    get topSDs() {
        return this.p2.topSDs || [];
    }

    get allSDs() {
        return (this.p2.allSDs || []).map((s) => ({
            ...s,
            key: s.name,
            rowClass: s.noSales ? 'dms-trow dms-trow_nosales' : 'dms-trow'
        }));
    }

    get p2Tickets() {
        return this.p2.tickets || [];
    }

    /* ------- Range Selling (shared by P2 + Secondary, themed per dash) ----- */
    get rangeAccent() {
        return this.isSecondary ? 'brand' : 'purple';
    }

    get rangeDimButtons() {
        const active = `dms-toggle__btn dms-toggle__btn_${this.rangeAccent}`;
        return RANGE_DIMS.map((opt) => ({
            ...opt,
            class: opt.dim === this.rangeDim ? active : 'dms-toggle__btn'
        }));
    }

    get rangeRows() {
        const source = this.isSecondary ? this.secondary.rangeSelling : this.p2.rangeSelling;
        const color = RANGE_ACCENT_COLOR[this.rangeAccent];
        const rows = source ? source[this.rangeDim] : [];
        return rows.map((r) => ({
            ...r,
            key: r.name,
            pctLabel: `${r.pct}%`,
            barStyle: `width:${r.pct}%;background-color:${color};`
        }));
    }

    /* ---------------------------- Secondary data --------------------------- */
    get secondaryKpisTop() {
        return this.secondary.kpisTop || [];
    }
    get secondaryKpisMain() {
        return this.secondary.kpisMain || [];
    }
    get beatSales() {
        return this.secondary.beatSales || [];
    }
    get outletTypes() {
        return this.secondary.outletTypes || [];
    }
    get topCustomers() {
        return this.secondary.topCustomers || [];
    }
    get secondaryCollection() {
        return (this.secondary.secondaryCollection || []).map((c) => ({ ...c, key: c.inv }));
    }
    get newOutlets() {
        return (this.secondary.newOutlets || []).map((o) => ({ ...o, key: o.name }));
    }
    get newOutletsLabel() {
        return this.secondary.newOutletsLabel;
    }
    get secondaryTickets() {
        return this.secondary.tickets || [];
    }

    /* ------------------------------ handlers ------------------------------ */
    handleDashTab(event) {
        this.activeDash = event.currentTarget.dataset.dash;
    }

    handlePeriod(event) {
        this.period = event.detail.value;
    }

    handleOrderDim(event) {
        this.orderDim = event.currentTarget.dataset.dim;
    }

    handleRangeDim(event) {
        this.rangeDim = event.currentTarget.dataset.dim;
    }
}
