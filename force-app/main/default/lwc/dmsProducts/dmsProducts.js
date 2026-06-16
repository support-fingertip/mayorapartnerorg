import { LightningElement } from 'lwc';
import { getCatalog, getSchemes, formatCurrency } from 'c/dmsData';

const ALL = 'All';

// Per-brand badge colors (approximated from the prototype).
const BRAND_COLORS = {
    Malkist: ['#fdebc8', '#8a5a00'],
    'Coffee Joy': ['#fdf0cf', '#8a6d00'],
    Roma: ['#e0e7ff', '#3730a3'],
    "Slai O'lai": ['#fde0ec', '#9d174d'],
    Kopiko: ['#e7dcc8', '#6b4f2a'],
    'Beng-Beng': ['#ead9cf', '#7b4a2d'],
    JoyMee: ['#d7f0dd', '#1f7a3d'],
    Danisa: ['#f5eccf', '#846a1a'],
    'Choki-Choki': ['#ffe3cf', '#9a4a12']
};

const SCHEME_TYPE_THEME = { 'Buy X Get Y': 'purple', 'Slab Discount': 'info' };
const SCHEME_STATUS_THEME = { Active: 'success', 'Expiring Soon': 'warning', Upcoming: 'info' };

export default class DmsProducts extends LightningElement {
    activeTab = 'products';

    catalog = [];
    schemes = [];

    // product filters
    brand = ALL;
    subBrand = ALL;
    alias = ALL;
    searchKey = '';

    // scheme filters
    schemeType = ALL;
    schemeStatus = ALL;
    schemeSearch = '';

    connectedCallback() {
        this.catalog = getCatalog();
        this.schemes = getSchemes();
    }

    /* -------------------------------- tabs -------------------------------- */
    get subTabs() {
        return [
            { id: 'products', label: 'Products', icon: 'utility:product_item' },
            { id: 'schemes', label: 'Schemes & Offers', icon: 'utility:tags' }
        ].map((t) => ({
            ...t,
            class: t.id === this.activeTab ? 'dms-subtab dms-subtab_active' : 'dms-subtab'
        }));
    }

    get isProducts() {
        return this.activeTab === 'products';
    }
    get isSchemes() {
        return this.activeTab === 'schemes';
    }

    handleTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    /* ------------------------- product filter options -------------------- */
    optionsFrom(field, allLabel) {
        const values = [...new Set(this.catalog.map((p) => p[field]))];
        return [{ label: allLabel, value: ALL }, ...values.map((v) => ({ label: v, value: v }))];
    }

    get brandOptions() {
        return this.optionsFrom('brand', 'All Brands');
    }
    get subBrandOptions() {
        return this.optionsFrom('subBrand', 'All Sub-Brands');
    }
    get aliasOptions() {
        return this.optionsFrom('alias', 'All Aliases');
    }

    /* ----------------------------- product rows --------------------------- */
    get products() {
        const key = this.searchKey.toLowerCase();
        return this.catalog
            .filter((p) => this.brand === ALL || p.brand === this.brand)
            .filter((p) => this.subBrand === ALL || p.subBrand === this.subBrand)
            .filter((p) => this.alias === ALL || p.alias === this.alias)
            .filter(
                (p) =>
                    !key ||
                    p.name.toLowerCase().includes(key) ||
                    p.sku.toLowerCase().includes(key)
            )
            .map((p) => {
                const [bg, color] = BRAND_COLORS[p.brand] || ['#eceff3', '#5c6b7a'];
                const ppu = Math.round(p.dist / p.units);
                return {
                    ...p,
                    key: p.sku,
                    brandStyle: `background-color:${bg};color:${color};`,
                    mrpLabel: formatCurrency(p.mrp),
                    distLabel: formatCurrency(p.dist),
                    ppuLabel: `${formatCurrency(ppu)} / unit`
                };
            });
    }

    get productCountLabel() {
        return `${this.products.length} of ${this.catalog.length} products`;
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
    handleSearch(e) {
        this.searchKey = e.target.value;
    }

    /* ------------------------------- schemes ------------------------------ */
    get schemeTypeOptions() {
        return [
            { label: 'All Schemes', value: ALL },
            { label: 'Buy X Get Y', value: 'Buy X Get Y' },
            { label: 'Slab Discount', value: 'Slab Discount' }
        ];
    }

    get schemeStatusOptions() {
        return [
            { label: 'All Status', value: ALL },
            { label: 'Active', value: 'Active' },
            { label: 'Expiring Soon', value: 'Expiring Soon' },
            { label: 'Upcoming', value: 'Upcoming' }
        ];
    }

    get filteredSchemes() {
        const key = this.schemeSearch.toLowerCase();
        return this.schemes
            .filter((s) => this.schemeType === ALL || s.type === this.schemeType)
            .filter((s) => this.schemeStatus === ALL || s.status === this.schemeStatus)
            .filter(
                (s) =>
                    !key ||
                    s.name.toLowerCase().includes(key) ||
                    s.desc.toLowerCase().includes(key)
            )
            .map((s) => ({
                ...s,
                typeTheme: SCHEME_TYPE_THEME[s.type] || 'neutral',
                statusTheme: SCHEME_STATUS_THEME[s.status] || 'neutral'
            }));
    }

    get schemeSummary() {
        const count = (status) => this.schemes.filter((s) => s.status === status).length;
        return [
            { id: 'total', label: 'Total Schemes', value: this.schemes.length, theme: 'default' },
            { id: 'active', label: 'Active', value: count('Active'), theme: 'success' },
            { id: 'expiring', label: 'Expiring Soon', value: count('Expiring Soon'), theme: 'warning' },
            { id: 'upcoming', label: 'Upcoming', value: count('Upcoming'), theme: 'info' }
        ].map((c) => ({ ...c, valueClass: `dms-chip__value dms-chip__value_${c.theme}` }));
    }

    handleSchemeType(e) {
        this.schemeType = e.detail.value;
    }
    handleSchemeStatus(e) {
        this.schemeStatus = e.detail.value;
    }
    handleSchemeSearch(e) {
        this.schemeSearch = e.target.value;
    }
}
