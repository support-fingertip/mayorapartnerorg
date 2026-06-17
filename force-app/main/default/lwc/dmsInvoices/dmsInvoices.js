import { LightningElement } from 'lwc';
import {
    getPrimaryInvoices,
    getSecondaryInvoices,
    getInvoiceCustomers,
    getCustomerOrders,
    formatCurrency
} from 'c/dmsData';

const ALL = 'All';
const GRN_OPTIONS = [
    { label: 'All GRN Status', value: ALL },
    { label: 'GRN Done', value: 'done' },
    { label: 'GRN Not Done', value: 'notdone' }
];
const DATE_OPTIONS = [{ label: 'All Dates', value: ALL }];
const TYPE_THEME = { Retailer: 'info', 'Sub-Dist.': 'purple' };
const STEP_LABELS = { 1: 'Select Customer', 2: 'Select Orders', 3: 'Review & Create' };

export default class DmsInvoices extends LightningElement {
    activeTab = 'primary';

    grnFilter = ALL;
    grnOptions = GRN_OPTIONS;
    dateOptions = DATE_OPTIONS;
    dateFilter = ALL;

    primary = [];
    secondary = [];

    // Create Invoice wizard
    wizardOpen = false;
    step = 1;
    custType = 'Retailer';
    selectedCustomer = null;
    selectedOrderIds = [];
    customers = {};

    connectedCallback() {
        this.primary = getPrimaryInvoices();
        this.secondary = getSecondaryInvoices();
        this.customers = getInvoiceCustomers();
    }

    /* -------------------------------- tabs -------------------------------- */
    get subTabs() {
        return [
            { id: 'primary', label: 'Primary Invoices' },
            { id: 'secondary', label: 'Secondary Invoices' }
        ].map((t) => ({
            ...t,
            class: t.id === this.activeTab ? 'dms-subtab dms-subtab_active' : 'dms-subtab'
        }));
    }

    get isPrimary() {
        return this.activeTab === 'primary';
    }
    get isSecondary() {
        return this.activeTab === 'secondary';
    }

    handleTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
    }

    handleGrnFilter(e) {
        this.grnFilter = e.detail.value;
    }
    handleDateFilter(e) {
        this.dateFilter = e.detail.value;
    }

    /* --------------------------- primary invoices ------------------------- */
    get primaryInvoices() {
        return this.primary
            .filter(
                (i) =>
                    this.grnFilter === ALL ||
                    (this.grnFilter === 'done' ? i.grnDone : !i.grnDone)
            )
            .map((i) => ({
                ...i,
                key: i.id,
                amountLabel: formatCurrency(i.amount),
                grnLabel: i.grnDone ? 'GRN Done' : 'GRN Not Done',
                grnClass: i.grnDone ? 'dms-grn dms-grn_done' : 'dms-grn dms-grn_pending'
            }));
    }

    get primarySummary() {
        const done = this.primary.filter((i) => i.grnDone).length;
        return [
            { id: 'total', label: 'Total Primary Invoices', value: this.primary.length, cls: 'dms-chip__value' },
            { id: 'done', label: 'GRN Done', value: done, cls: 'dms-chip__value dms-chip__value_done' },
            { id: 'notdone', label: 'GRN Not Done', value: this.primary.length - done, cls: 'dms-chip__value dms-chip__value_pending' }
        ];
    }

    /* -------------------------- secondary invoices ------------------------ */
    get secondaryInvoices() {
        return this.secondary.map((i) => ({
            ...i,
            key: i.id,
            amountLabel: formatCurrency(i.amount),
            typeTheme: TYPE_THEME[i.type] || 'neutral'
        }));
    }

    get secondarySummary() {
        const total = this.secondary.reduce((s, i) => s + i.amount, 0);
        const retailers = this.secondary.filter((i) => i.type === 'Retailer').length;
        return [
            { id: 'total', label: 'Total Invoices', value: String(this.secondary.length), cls: 'dms-chip__value' },
            { id: 'value', label: 'Total Value', value: formatCurrency(total), cls: 'dms-chip__value' },
            { id: 'ret', label: 'Retailers', value: String(retailers), cls: 'dms-chip__value dms-chip__value_info' },
            { id: 'sub', label: 'Sub-Distributors', value: String(this.secondary.length - retailers), cls: 'dms-chip__value dms-chip__value_purple' }
        ];
    }

    /* --------------------------- create wizard ---------------------------- */
    openWizard() {
        this.wizardOpen = true;
        this.step = 1;
        this.custType = 'Retailer';
        this.selectedCustomer = null;
        this.selectedOrderIds = [];
    }
    closeWizard() {
        this.wizardOpen = false;
    }

    get stepLabel() {
        return STEP_LABELS[this.step];
    }
    get isStep1() {
        return this.step === 1;
    }
    get isStep2() {
        return this.step === 2;
    }
    get isStep3() {
        return this.step === 3;
    }

    get stepDots() {
        return [1, 2, 3].map((n) => ({
            n,
            class: n === this.step ? 'dms-step__dot dms-step__dot_active' : 'dms-step__dot'
        }));
    }

    get custTypeButtons() {
        return ['Retailer', 'Sub-Distributor'].map((t) => ({
            type: t,
            class: t === this.custType ? 'dms-seg dms-seg_active' : 'dms-seg'
        }));
    }

    get customerList() {
        const list = this.customers[this.custType] || [];
        return list.map((c) => ({
            ...c,
            typeTheme: TYPE_THEME[c.type] || 'neutral',
            class:
                this.selectedCustomer === c.name
                    ? 'dms-custrow dms-custrow_selected'
                    : 'dms-custrow'
        }));
    }

    get orderList() {
        const orders = this.selectedCustomer ? getCustomerOrders(this.selectedCustomer) : [];
        return orders.map((o) => {
            const selected = this.selectedOrderIds.includes(o.id);
            return {
                ...o,
                key: o.id,
                amountLabel: formatCurrency(o.amount),
                metaLabel: `${o.date} · ${o.products.length} products`,
                productsLabel: o.products.join(', '),
                selected,
                rowClass: selected ? 'dms-ordrow dms-ordrow_selected' : 'dms-ordrow',
                boxClass: selected ? 'dms-check dms-check_on' : 'dms-check'
            };
        });
    }

    get selectedCountLabel() {
        return `${this.selectedOrderIds.length} selected`;
    }

    get reviewOrders() {
        const orders = this.selectedCustomer ? getCustomerOrders(this.selectedCustomer) : [];
        return orders
            .filter((o) => this.selectedOrderIds.includes(o.id))
            .map((o) => ({ ...o, key: o.id, amountLabel: formatCurrency(o.amount) }));
    }

    get reviewTotalLabel() {
        const orders = this.selectedCustomer ? getCustomerOrders(this.selectedCustomer) : [];
        const total = orders
            .filter((o) => this.selectedOrderIds.includes(o.id))
            .reduce((s, o) => s + o.amount, 0);
        return formatCurrency(total);
    }

    get nextDisabled() {
        if (this.step === 1) {
            return !this.selectedCustomer;
        }
        if (this.step === 2) {
            return this.selectedOrderIds.length === 0;
        }
        return false;
    }

    setCustType(event) {
        this.custType = event.currentTarget.dataset.type;
        this.selectedCustomer = null;
        this.selectedOrderIds = [];
    }

    selectCustomer(event) {
        this.selectedCustomer = event.currentTarget.dataset.name;
        this.selectedOrderIds = [];
    }

    toggleOrder(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedOrderIds = this.selectedOrderIds.includes(id)
            ? this.selectedOrderIds.filter((x) => x !== id)
            : [...this.selectedOrderIds, id];
    }

    nextStep() {
        if (this.nextDisabled) {
            return;
        }
        if (this.step < 3) {
            this.step += 1;
        } else {
            this.closeWizard();
        }
    }

    backStep() {
        if (this.step > 1) {
            this.step -= 1;
        } else {
            this.closeWizard();
        }
    }
}
