import { LightningElement } from 'lwc';
import {
    getP1Orders,
    getP2Orders,
    getSecondaryOrders,
    getOrderProducts,
    getOrderBrands,
    formatCurrency,
    formatNumber,
    ORDER_CREDIT_LIMIT,
    ORDER_ACTIVE_SCHEMES
} from 'c/dmsData';

const ALL = 'All';
const P1_STATUSES = ['All', 'Draft', 'Pending Approval', 'Approved', 'Rejected', 'Invoiced', 'GRN Given'];
const STATUS_THEME = {
    Draft: 'neutral',
    'Pending Approval': 'warning',
    Approved: 'success',
    Rejected: 'danger',
    Invoiced: 'info',
    'GRN Given': 'success'
};
const TYPE_THEME = { Retailer: 'info', 'Sub-Dist.': 'purple' };

export default class DmsOrders extends LightningElement {
    activeTab = 'p1';
    showNewOrder = false;

    p1Status = ALL;
    p1Search = '';
    p2Search = '';
    secondarySearch = '';

    // New order entry
    orderBrand = ALL;
    orderSubBrand = ALL;
    orderSearch = '';
    cartOpen = false;
    showConfirm = false;
    confirmTitle = '';
    detailOpen = false;
    selected = null;
    creditLimit = ORDER_CREDIT_LIMIT;
    activeSchemes = ORDER_ACTIVE_SCHEMES;

    p1 = [];
    p2 = [];
    secondaryOrders = [];
    orderProducts = [];
    brands = [];

    connectedCallback() {
        this.p1 = getP1Orders();
        this.p2 = getP2Orders();
        this.secondaryOrders = getSecondaryOrders();
        this.orderProducts = getOrderProducts().map((p) => ({ ...p, qty: 0 }));
        this.brands = [ALL, ...getOrderBrands()];
    }

    /* -------------------------------- tabs -------------------------------- */
    get subTabs() {
        return [
            { id: 'p1', label: 'P1 Orders' },
            { id: 'p2', label: 'P2 Orders' },
            { id: 'secondary', label: 'Secondary Orders' }
        ].map((t) => ({
            ...t,
            class: t.id === this.activeTab ? 'dms-subtab dms-subtab_active' : 'dms-subtab'
        }));
    }

    get isP1() {
        return this.activeTab === 'p1';
    }
    get isP2() {
        return this.activeTab === 'p2';
    }
    get isSecondary() {
        return this.activeTab === 'secondary';
    }

    get showList() {
        return !this.showNewOrder;
    }

    handleTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    /* ----------------------------- P1 orders ------------------------------ */
    get p1StatusTabs() {
        return P1_STATUSES.map((status) => ({
            status,
            class: status === this.p1Status ? 'dms-chipbtn dms-chipbtn_active' : 'dms-chipbtn'
        }));
    }

    get p1Orders() {
        const key = this.p1Search.toLowerCase();
        return this.p1
            .filter((o) => this.p1Status === ALL || o.status === this.p1Status)
            .filter((o) => !key || o.id.toLowerCase().includes(key))
            .map((o) => this.decorate(o));
    }

    handleP1Status(event) {
        this.p1Status = event.currentTarget.dataset.status;
    }
    handleP1Search(event) {
        this.p1Search = event.target.value;
    }

    /* ----------------------------- P2 orders ------------------------------ */
    get p2Orders() {
        const key = this.p2Search.toLowerCase();
        return this.p2
            .filter((o) => !key || o.id.toLowerCase().includes(key))
            .map((o) => this.decorate(o));
    }
    handleP2Search(event) {
        this.p2Search = event.target.value;
    }

    /* -------------------------- Secondary orders -------------------------- */
    get secondaryRows() {
        const key = this.secondarySearch.toLowerCase();
        return this.secondaryOrders
            .filter(
                (o) =>
                    !key ||
                    o.id.toLowerCase().includes(key) ||
                    o.customer.toLowerCase().includes(key)
            )
            .map((o) => ({
                ...o,
                key: o.id,
                unitsLabel: formatNumber(o.units),
                valueLabel: formatCurrency(o.value),
                typeTheme: TYPE_THEME[o.type] || 'neutral'
            }));
    }
    handleSecondarySearch(event) {
        this.secondarySearch = event.target.value;
    }

    decorate(o) {
        return {
            ...o,
            key: o.id,
            unitsLabel: formatNumber(o.units),
            valueLabel: formatCurrency(o.value),
            statusTheme: STATUS_THEME[o.status] || 'neutral'
        };
    }

    /* --------------------------- order detail ----------------------------- */
    viewOrder(event) {
        const id = event.currentTarget.dataset.id;
        const order = [...this.p1, ...this.p2, ...this.secondaryOrders].find((o) => o.id === id);
        if (!order) {
            return;
        }
        this.selected = {
            id: order.id,
            subtitle: order.customer ? `${order.date} · ${order.customer}` : order.date,
            lines: order.lines.map((l) => ({
                ...l,
                key: l.sku,
                unitsLabel: formatNumber(l.units),
                rateLabel: formatCurrency(l.rate),
                amountLabel: formatCurrency(l.amount)
            })),
            totalCases: order.cases,
            totalUnitsLabel: formatNumber(order.units),
            orderValueLabel: formatCurrency(order.value)
        };
        this.detailOpen = true;
    }

    closeDetail() {
        this.detailOpen = false;
    }

    /* --------------------------- New P1 Order ----------------------------- */
    openNewOrder() {
        this.showNewOrder = true;
    }
    closeNewOrder() {
        this.showNewOrder = false;
    }

    get brandChips() {
        return this.brands.map((b) => ({
            brand: b,
            label: b === ALL ? 'All' : b,
            class: b === this.orderBrand ? 'dms-chipbtn dms-chipbtn_active' : 'dms-chipbtn'
        }));
    }

    get subBrandChips() {
        const pool = this.orderProducts.filter(
            (p) => this.orderBrand === ALL || p.brand === this.orderBrand
        );
        const subs = [ALL, ...new Set(pool.map((p) => p.subBrand))];
        return subs.map((s) => ({
            sub: s,
            label: s === ALL ? 'All' : s,
            class: s === this.orderSubBrand ? 'dms-chipbtn dms-chipbtn_active' : 'dms-chipbtn'
        }));
    }

    get orderCards() {
        const key = this.orderSearch.toLowerCase();
        return this.orderProducts
            .filter((p) => this.orderBrand === ALL || p.brand === this.orderBrand)
            .filter((p) => this.orderSubBrand === ALL || p.subBrand === this.orderSubBrand)
            .filter((p) => !key || p.name.toLowerCase().includes(key))
            .map((p) => ({
                ...p,
                caseLabel: `${formatCurrency(p.casePrice)}/case`,
                mrpLabel: `MRP ${formatCurrency(p.mrp)}/pc`,
                packLabel: `${p.packSize} · ${p.pcs} pcs/case`
            }));
    }

    get currentOrderValue() {
        return this.orderProducts.reduce((sum, p) => sum + p.qty * p.casePrice, 0);
    }
    get currentOrderLabel() {
        return formatCurrency(this.currentOrderValue);
    }
    get creditLimitLabel() {
        return formatCurrency(this.creditLimit);
    }
    get creditBarStyle() {
        const pct = Math.min(100, (this.currentOrderValue / this.creditLimit) * 100);
        return `width:${pct}%;`;
    }
    get cartCount() {
        return this.orderProducts.filter((p) => p.qty > 0).length;
    }
    get cartLabel() {
        const k = Math.round(this.currentOrderValue / 1000);
        return this.currentOrderValue > 0 ? `View Cart (${this.cartCount})  ₹${k}k` : 'View Cart (0)';
    }

    handleStep(event) {
        const { id, dir } = event.currentTarget.dataset;
        this.orderProducts = this.orderProducts.map((p) => {
            if (p.id !== id) {
                return p;
            }
            const qty = Math.max(0, p.qty + (dir === 'up' ? 1 : -1));
            return { ...p, qty };
        });
    }

    /* ------------------------------ cart ------------------------------ */
    openCart() {
        this.cartOpen = true;
    }
    closeCart() {
        this.cartOpen = false;
    }

    get cartTitle() {
        return `Cart (${this.cartCount} products)`;
    }

    get cartItems() {
        return this.orderProducts
            .filter((p) => p.qty > 0)
            .map((p) => ({
                ...p,
                key: p.id,
                packCaseLabel: `${p.packSize} · ${formatCurrency(p.casePrice)}/case`,
                lineLabel: formatCurrency(p.qty * p.casePrice),
                unitsLabel: `${formatNumber(p.qty * p.pcs)} units`
            }));
    }

    get totalCases() {
        return this.orderProducts.reduce((sum, p) => sum + p.qty, 0);
    }
    get totalUnitsLabel() {
        return formatNumber(this.orderProducts.reduce((sum, p) => sum + p.qty * p.pcs, 0));
    }
    get subtotalLabel() {
        return formatCurrency(this.currentOrderValue);
    }
    get orderTotalLabel() {
        return formatCurrency(this.currentOrderValue);
    }

    get confirmSummary() {
        return `${this.cartCount} products · ${this.totalCases} cases · ${this.orderTotalLabel}`;
    }

    saveDraft() {
        this.confirmTitle = 'Saved as Draft';
        this.showConfirm = true;
    }

    submitOrder() {
        this.confirmTitle = 'Submitted for Approval';
        this.showConfirm = true;
    }

    // Done -> reset the cart and return to the order list view.
    handleDone() {
        this.showConfirm = false;
        this.cartOpen = false;
        this.showNewOrder = false;
        this.orderProducts = this.orderProducts.map((p) => ({ ...p, qty: 0 }));
        this.orderBrand = ALL;
        this.orderSubBrand = ALL;
        this.orderSearch = '';
    }

    handleOrderBrand(event) {
        this.orderBrand = event.currentTarget.dataset.brand;
        this.orderSubBrand = ALL;
    }
    handleOrderSubBrand(event) {
        this.orderSubBrand = event.currentTarget.dataset.sub;
    }
    handleOrderSearch(event) {
        this.orderSearch = event.target.value;
    }
}
