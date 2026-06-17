import { LightningElement } from 'lwc';
import { getInventory, getStockAdjustments, formatNumber, formatLakh } from 'c/dmsData';

const ALL = 'All';

const BRAND_COLORS = {
    Malkist: ['#fdebc8', '#8a5a00'],
    'Coffee Joy': ['#fdf0cf', '#8a6d00'],
    Roma: ['#e0e7ff', '#3730a3'],
    "Slai O'lai": ['#fde0ec', '#9d174d'],
    Kopiko: ['#e7dcc8', '#6b4f2a'],
    'Beng-Beng': ['#ead9cf', '#7b4a2d'],
    JoyMee: ['#d7f0dd', '#1f7a3d'],
    Danisa: ['#f5eccf', '#846a1a'],
    'Choki-Choki': ['#ffe3cf', '#9a4a12'],
    KIS: ['#dbeafe', '#1e40af'],
    JuizyMilk: ['#e0f2fe', '#075985']
};

const REASON_THEME = {
    Damaged: 'danger',
    Expiry: 'warning',
    Missing: 'warning',
    'Non-saleable': 'purple',
    Other: 'neutral'
};
const REASONS = ['Damaged', 'Missing', 'Expiry', 'Non-saleable', 'Other'];

export default class DmsInventory extends LightningElement {
    activeTab = 'stock';

    // stock filters
    brand = ALL;
    subBrand = ALL;
    alias = ALL;
    statusFilter = ALL;
    stockSearch = '';

    // adjustments filters
    adjFilter = ALL;
    reasonFilter = ALL;
    adjSearch = '';

    inventory = [];
    adjustments = [];

    // new adjustment modal
    modalOpen = false;
    formProduct = '';
    formType = 'Remove';
    formReason = 'Damaged';
    formQty = '';
    formNotes = '';

    connectedCallback() {
        this.inventory = getInventory();
        this.adjustments = getStockAdjustments();
    }

    /* -------------------------------- tabs -------------------------------- */
    get stockTabClass() {
        return this.activeTab === 'stock' ? 'dms-subtab dms-subtab_active' : 'dms-subtab';
    }
    get adjTabClass() {
        return this.activeTab === 'adjust' ? 'dms-subtab dms-subtab_active' : 'dms-subtab';
    }
    get isStock() {
        return this.activeTab === 'stock';
    }
    get isAdjust() {
        return this.activeTab === 'adjust';
    }
    handleTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    /* ------------------------------ stock view ---------------------------- */
    optionsFrom(field, allLabel) {
        const vals = [...new Set(this.inventory.map((p) => p[field]))];
        return [{ label: allLabel, value: ALL }, ...vals.map((v) => ({ label: v, value: v }))];
    }
    get brandOptions() {
        return this.optionsFrom('brand', 'All Brands');
    }
    get subBrandOptions() {
        return this.optionsFrom('subBrand', 'All Sub-Brands');
    }
    get aliasOptions() {
        return [{ label: 'All Aliases', value: ALL }];
    }
    get statusOptions() {
        return [
            { label: 'All Status', value: ALL },
            { label: 'In Stock', value: 'In Stock' },
            { label: 'Low Stock', value: 'Low Stock' },
            { label: 'Out of Stock', value: 'Out of Stock' }
        ];
    }

    get stockRows() {
        const key = this.stockSearch.toLowerCase();
        return this.inventory
            .filter((p) => this.brand === ALL || p.brand === this.brand)
            .filter((p) => this.subBrand === ALL || p.subBrand === this.subBrand)
            .filter((p) => this.statusFilter === ALL || p.status === this.statusFilter)
            .filter((p) => !key || p.name.toLowerCase().includes(key) || p.sku.toLowerCase().includes(key))
            .map((p) => {
                const [bg, color] = BRAND_COLORS[p.brand] || ['#eceff3', '#5c6b7a'];
                return {
                    ...p,
                    key: p.sku,
                    brandStyle: `background-color:${bg};color:${color};`,
                    casesLabel: formatNumber(p.cases),
                    unitsLabel: formatNumber(p.units),
                    valueLabel: `₹${Math.round(p.value / 1000)}k`,
                    expiredLabel: p.expired ? p.expired : '—',
                    statusTheme: p.status === 'In Stock' ? 'success' : p.status === 'Low Stock' ? 'warning' : 'danger'
                };
            });
    }

    get stockCount() {
        return this.stockRows.length;
    }
    get totalCasesLabel() {
        return formatNumber(this.stockRows.reduce((s, p) => s + p.cases, 0));
    }
    get stockValueLabel() {
        return formatLakh(this.stockRows.reduce((s, p) => s + p.value, 0));
    }
    get outOfStockCount() {
        return this.stockRows.filter((p) => p.status === 'Out of Stock').length;
    }

    handleBrand(e) {
        this.brand = e.detail.value;
    }
    handleSubBrand(e) {
        this.subBrand = e.detail.value;
    }
    handleAlias(e) {
        this.alias = e.detail.value;
    }
    handleStatus(e) {
        this.statusFilter = e.detail.value;
    }
    handleStockSearch(e) {
        this.stockSearch = e.target.value;
    }

    /* --------------------------- adjustments ------------------------------ */
    get adjListOptions() {
        return [
            { label: 'All Adjustments', value: ALL },
            { label: 'Remove', value: 'Remove' },
            { label: 'Add', value: 'Add' }
        ];
    }
    get reasonFilterOptions() {
        return [{ label: 'All Reasons', value: ALL }, ...REASONS.map((r) => ({ label: r, value: r }))];
    }

    get adjRows() {
        const key = this.adjSearch.toLowerCase();
        return this.adjustments
            .filter((a) => this.adjFilter === ALL || a.type === this.adjFilter)
            .filter((a) => this.reasonFilter === ALL || a.reason === this.reasonFilter)
            .filter((a) => !key || a.product.toLowerCase().includes(key) || a.reason.toLowerCase().includes(key))
            .map((a) => ({
                ...a,
                key: a.id,
                typeTheme: a.type === 'Add' ? 'success' : 'danger',
                reasonTheme: REASON_THEME[a.reason] || 'neutral',
                qtyLabel: a.qty > 0 ? `+${a.qty}` : `${a.qty}`,
                qtyClass: a.qty > 0 ? 'dms-qty dms-qty_add' : 'dms-qty dms-qty_rem'
            }));
    }

    get adjSummary() {
        const rows = this.adjRows;
        const removed = rows.filter((a) => a.qty < 0).reduce((s, a) => s + Math.abs(a.qty), 0);
        const added = rows.filter((a) => a.qty > 0).reduce((s, a) => s + a.qty, 0);
        return [
            { id: 'total', label: 'Total Entries', value: rows.length, cls: 'dms-chip__value' },
            { id: 'rem', label: 'Ctns Removed', value: removed, cls: 'dms-chip__value dms-chip__value_rem' },
            { id: 'add', label: 'Ctns Added', value: added, cls: 'dms-chip__value dms-chip__value_add' },
            { id: 'month', label: 'This Month', value: rows.length, cls: 'dms-chip__value' }
        ];
    }

    handleAdjFilter(e) {
        this.adjFilter = e.detail.value;
    }
    handleReasonFilter(e) {
        this.reasonFilter = e.detail.value;
    }
    handleAdjSearch(e) {
        this.adjSearch = e.target.value;
    }

    /* ------------------------- new adjustment modal ----------------------- */
    get productOptions() {
        return this.inventory.map((p) => ({ label: `${p.name} (${p.sku})`, value: p.sku }));
    }
    get typeButtons() {
        return [
            { type: 'Remove', label: 'Remove Stock' },
            { type: 'Add', label: 'Add Stock' }
        ].map((t) => ({
            ...t,
            class:
                t.type === this.formType
                    ? `dms-seg dms-seg_active dms-seg_${t.type === 'Add' ? 'add' : 'rem'}`
                    : 'dms-seg'
        }));
    }
    get reasonChips() {
        return REASONS.map((r) => ({
            reason: r,
            class: r === this.formReason ? 'dms-rchip dms-rchip_active' : 'dms-rchip'
        }));
    }
    get saveDisabled() {
        return !this.formProduct || !(parseInt(this.formQty, 10) > 0);
    }

    openModal() {
        this.modalOpen = true;
        this.formProduct = '';
        this.formType = 'Remove';
        this.formReason = 'Damaged';
        this.formQty = '';
        this.formNotes = '';
    }
    closeModal() {
        this.modalOpen = false;
    }
    handleFormProduct(e) {
        this.formProduct = e.detail.value;
    }
    setFormType(e) {
        this.formType = e.currentTarget.dataset.type;
    }
    setFormReason(e) {
        this.formReason = e.currentTarget.dataset.reason;
    }
    handleFormQty(e) {
        this.formQty = e.target.value;
    }
    handleFormNotes(e) {
        this.formNotes = e.target.value;
    }

    saveAdjustment() {
        if (this.saveDisabled) {
            return;
        }
        const prod = this.inventory.find((p) => p.sku === this.formProduct);
        const qty = parseInt(this.formQty, 10);
        const nextId = `ADJ-${String(12 + (this.adjustments.length - 7)).padStart(4, '0')}`;
        const entry = {
            id: nextId,
            date: '17 Jun 2026',
            product: prod ? prod.name : this.formProduct,
            sku: this.formProduct,
            type: this.formType,
            reason: this.formReason,
            qty: this.formType === 'Add' ? qty : -qty,
            notes: this.formNotes || '—',
            by: 'You'
        };
        this.adjustments = [entry, ...this.adjustments];
        this.modalOpen = false;
    }
}
