import { LightningElement } from 'lwc';
import { getCollections, getCollectionCustomers, formatCurrency } from 'c/dmsData';

const ALL = 'All';
const MODE_THEME = { Cash: 'success', Cheque: 'info', NEFT: 'info', UPI: 'purple' };
const MODES = ['Cash', 'Cheque', 'NEFT', 'UPI'];
const REF_FIELD = {
    Cheque: { label: 'Cheque Number', placeholder: 'e.g. CHQ-SBI-012345' },
    NEFT: { label: 'Reference No.', placeholder: 'e.g. NEFT2606010012' },
    UPI: { label: 'UPI Reference', placeholder: 'e.g. name@bank' }
};

export default class DmsSecondaryCollection extends LightningElement {
    dateFilter = ALL;
    dateOptions = [
        { label: 'All Dates', value: ALL },
        { label: 'This JC', value: 'this-jc' },
        { label: 'Last JC', value: 'last-jc' },
        { label: 'This Week', value: 'this-week' },
        { label: 'Last Week', value: 'last-week' },
        { label: 'This Quarter', value: 'this-quarter' },
        { label: 'This Year', value: 'this-year' }
    ];
    search = '';

    collections = [];
    customers = {};
    nextSeq = 22;

    // modal
    modalOpen = false;
    formCustomer = '';
    formInvoice = '';
    formAmount = '';
    formMode = 'Cash';
    formRef = '';
    formNotes = '';

    connectedCallback() {
        this.collections = getCollections();
        this.customers = getCollectionCustomers();
    }

    get rows() {
        const key = this.search.toLowerCase();
        return this.collections
            .filter((c) => !key || c.id.toLowerCase().includes(key) || c.customer.toLowerCase().includes(key))
            .map((c) => ({
                ...c,
                key: c.id,
                amountLabel: formatCurrency(c.amount),
                modeTheme: MODE_THEME[c.mode] || 'neutral'
            }));
    }

    get summary() {
        const total = this.collections.reduce((s, c) => s + c.amount, 0);
        const retailers = this.collections.filter((c) => c.type === 'Retailer').length;
        return [
            { id: 'e', label: 'Total Entries', value: String(this.collections.length) },
            { id: 'a', label: 'Total Amount', value: formatCurrency(total) },
            { id: 'r', label: 'Retailers', value: String(retailers) },
            { id: 's', label: 'Sub-Distributors', value: String(this.collections.length - retailers) }
        ];
    }

    handleDate(e) {
        this.dateFilter = e.detail.value;
    }
    handleSearch(e) {
        this.search = e.target.value;
    }

    /* --------------------------- record modal ----------------------------- */
    get retailerOpts() {
        return (this.customers.Retailer || []).map((c) => ({
            code: c.code,
            label: `${c.name} (${c.code})`,
            selected: c.code === this.formCustomer
        }));
    }
    get subDistOpts() {
        return (this.customers['Sub-Distributor'] || []).map((c) => ({
            code: c.code,
            label: `${c.name} (${c.code})`,
            selected: c.code === this.formCustomer
        }));
    }
    get modeButtons() {
        return MODES.map((m) => ({
            mode: m,
            class: m === this.formMode ? `dms-seg dms-seg_active dms-seg_${m.toLowerCase()}` : 'dms-seg'
        }));
    }
    get showRefField() {
        return this.formMode !== 'Cash';
    }
    get refLabel() {
        return (REF_FIELD[this.formMode] || {}).label;
    }
    get refPlaceholder() {
        return (REF_FIELD[this.formMode] || {}).placeholder;
    }
    get saveDisabled() {
        return !this.formCustomer || !(parseInt(this.formAmount, 10) > 0);
    }

    openModal() {
        this.modalOpen = true;
        this.formCustomer = '';
        this.formInvoice = '';
        this.formAmount = '';
        this.formMode = 'Cash';
        this.formRef = '';
        this.formNotes = '';
    }
    closeModal() {
        this.modalOpen = false;
    }
    handleCustomer(e) {
        this.formCustomer = e.target.value;
    }
    handleInvoice(e) {
        this.formInvoice = e.target.value;
    }
    handleAmount(e) {
        this.formAmount = e.target.value;
    }
    setMode(e) {
        this.formMode = e.currentTarget.dataset.mode;
        this.formRef = '';
    }
    handleRef(e) {
        this.formRef = e.target.value;
    }
    handleNotes(e) {
        this.formNotes = e.target.value;
    }

    findCustomer(code) {
        const all = [...(this.customers.Retailer || []).map((c) => ({ ...c, type: 'Retailer' })),
            ...(this.customers['Sub-Distributor'] || []).map((c) => ({ ...c, type: 'Sub-Distributor' }))];
        return all.find((c) => c.code === code);
    }

    save() {
        if (this.saveDisabled) {
            return;
        }
        const cust = this.findCustomer(this.formCustomer);
        const id = `COL-00${this.nextSeq}`;
        this.nextSeq += 1;
        this.collections = [
            {
                id,
                date: '17 Jun 2026',
                customer: cust ? cust.name : this.formCustomer,
                type: cust ? cust.type : 'Retailer',
                code: this.formCustomer,
                invoiceRef: this.formInvoice || '—',
                amount: parseInt(this.formAmount, 10),
                mode: this.formMode,
                reference: this.formMode === 'Cash' ? '—' : this.formRef || '—',
                by: 'You',
                notes: this.formNotes || '—'
            },
            ...this.collections
        ];
        this.modalOpen = false;
    }
}