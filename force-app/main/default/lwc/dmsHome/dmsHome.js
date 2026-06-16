import { LightningElement } from 'lwc';
import { getP1Dashboard, getP2Dashboard, getPeriodOptions } from 'c/dmsData';

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

/** DMS landing screen — hosts the P1, P2 and Secondary dashboards as sub-tabs. */
export default class DmsHome extends LightningElement {
    activeDash = 'p1';
    period = 'this-jc';
    orderDim = 'brand';
    rangeDim = 'brand';

    p1 = {};
    p2 = {};
    periodOptions = [];

    // chart axis config
    ordersTicks = ORDERS_TICKS;
    valueTicks = VALUE_TICKS;
    ordersMax = 20;
    valueMax = 2;

    connectedCallback() {
        this.p1 = getP1Dashboard();
        this.p2 = getP2Dashboard();
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

    get rangeDimButtons() {
        return RANGE_DIMS.map((opt) => ({
            ...opt,
            class:
                opt.dim === this.rangeDim
                    ? 'dms-toggle__btn dms-toggle__btn_purple'
                    : 'dms-toggle__btn'
        }));
    }

    get rangeRows() {
        const rows = this.p2.rangeSelling ? this.p2.rangeSelling[this.rangeDim] : [];
        return rows.map((r) => ({
            ...r,
            key: r.name,
            pctLabel: `${r.pct}%`,
            barStyle: `width:${r.pct}%;`
        }));
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
