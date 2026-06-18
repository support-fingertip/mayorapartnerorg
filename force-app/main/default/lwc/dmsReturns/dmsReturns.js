import { LightningElement } from 'lwc';
import { getReturns, getReturnableInvoices } from 'c/dmsData';

const ALL = 'All';
const STATUS_THEME = { Approved: 'success', Pending: 'warning', Rejected: 'danger' };
const TYPE_THEME = { Retailer: 'purple', 'Sub-Dist.': 'purple' };
const RETURN_REASONS = [
    { label: 'Damaged goods', value: 'Damaged goods' },
    { label: 'Expired', value: 'Expired' },
    { label: 'Short received', value: 'Short received' },
    { label: 'Other', value: 'Other' }
];

export default class DmsReturns extends LightningElement {
    activeTab = 'p1';
    statusFilter = ALL;
    statusOptions = [
        { label: 'All Status', value: ALL },
        { label: 'Approved', value: 'Approved' },
        { label: 'Pending', value: 'Pending' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    p1 = [];
    p2 = [];
    secondary = [];

    // wizard
    wizardOpen = false;
    step = 1;
    selectedInvoiceId = null;
    items = [];
    invoices = [];
    reasonOptions = RETURN_REASONS;

    connectedCallback() {
        const r = getReturns();
        this.p1 = r.p1;
        this.p2 = r.p2;
        this.secondary = r.secondary;
        this.invoices = getReturnableInvoices();
    }

    /* -------------------------------- tabs -------------------------------- */
    get subTabs() {
        return [
            { id: 'p1', label: 'P1 Returns' },
            { id: 'p2', label: 'P2 Returns' },
            { id: 'secondary', label: 'Secondary Returns' }
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
    handleTab(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        this.statusFilter = ALL;
    }
    handleStatus(e) {
        this.statusFilter = e.detail.value;
    }

    byStatus(list) {
        return list
            .filter((r) => this.statusFilter === ALL || r.status === this.statusFilter)
            .map((r) => ({
                ...r,
                key: r.id,
                statusTheme: STATUS_THEME[r.status] || 'neutral',
                typeTheme: TYPE_THEME[r.type] || 'purple'
            }));
    }

    get p1Rows() {
        return this.byStatus(this.p1);
    }
    get p2Rows() {
        return this.byStatus(this.p2);
    }
    get secondaryRows() {
        return this.byStatus(this.secondary);
    }

    summaryOf(list) {
        const count = (s) => list.filter((r) => r.status === s).length;
        return { total: list.length, approved: count('Approved'), pending: count('Pending'), rejected: count('Rejected') };
    }
    get p1Summary() {
        const s = this.summaryOf(this.p1);
        return [
            { id: 't', label: 'Total Returns', value: s.total, cls: 'dms-card__value' },
            { id: 'a', label: 'Approved', value: s.approved, cls: 'dms-card__value dms-card__value_green' },
            { id: 'p', label: 'Pending', value: s.pending, cls: 'dms-card__value dms-card__value_amber' },
            { id: 'r', label: 'Rejected', value: s.rejected, cls: 'dms-card__value dms-card__value_red' }
        ];
    }
    get p2Summary() {
        const s = this.summaryOf(this.p2);
        return [
            { id: 't', label: 'Total Returns', value: s.total, cls: 'dms-card__value' },
            { id: 'a', label: 'Approved', value: s.approved, cls: 'dms-card__value dms-card__value_green' },
            { id: 'p', label: 'Pending', value: s.pending, cls: 'dms-card__value dms-card__value_amber' },
            { id: 'r', label: 'Rejected', value: s.rejected, cls: 'dms-card__value dms-card__value_red' }
        ];
    }
    get secondarySummary() {
        const s = this.summaryOf(this.secondary);
        return [
            { id: 't', label: 'Total Secondary Returns', value: s.total, cls: 'dms-card__value' },
            { id: 'a', label: 'Approved', value: s.approved, cls: 'dms-card__value dms-card__value_green' },
            { id: 'p', label: 'Pending', value: s.pending, cls: 'dms-card__value dms-card__value_amber' }
        ];
    }

    /* ------------------------- Create Primary Return ---------------------- */
    openWizard() {
        this.wizardOpen = true;
        this.step = 1;
        this.selectedInvoiceId = null;
        this.items = [];
    }
    closeWizard() {
        this.wizardOpen = false;
    }
    get isStep1() {
        return this.step === 1;
    }
    get isStep2() {
        return this.step === 2;
    }
    get stepLabel() {
        return this.step === 1 ? 'Select Invoice' : 'Enter Return Qty & Reason';
    }
    get stepDots() {
        return [1, 2].map((n) => ({
            n,
            class: n === this.step ? 'dms-step__dot dms-step__dot_active' : 'dms-step__dot'
        }));
    }

    get invoiceCards() {
        return this.invoices.map((inv) => {
            const selected = inv.id === this.selectedInvoiceId;
            return {
                ...inv,
                key: inv.id,
                metaLabel: `${inv.date} · ${inv.lines.length} products`,
                productsLabel: inv.lines.map((l) => l.name).join(', '),
                rowClass: selected ? 'dms-pick dms-pick_on' : 'dms-pick',
                radioClass: selected ? 'dms-radio dms-radio_on' : 'dms-radio'
            };
        });
    }

    get itemRows() {
        return this.items.map((it) => ({ ...it }));
    }
    get totalReturnQty() {
        return this.items.reduce((s, it) => s + it.returnQty, 0);
    }
    get nextDisabled() {
        if (this.step === 1) {
            return !this.selectedInvoiceId;
        }
        return this.totalReturnQty === 0;
    }

    selectInvoice(event) {
        this.selectedInvoiceId = event.currentTarget.dataset.id;
    }

    buildItems() {
        const inv = this.invoices.find((i) => i.id === this.selectedInvoiceId);
        this.items = (inv ? inv.lines : []).map((l, i) => ({
            id: `i${i}`,
            name: l.name,
            delivered: l.delivered,
            returnQty: 0,
            reason: 'Damaged goods'
        }));
    }

    handleReturnQty(event) {
        const id = event.currentTarget.dataset.id;
        let val = parseInt(event.target.value, 10);
        this.items = this.items.map((it) => {
            if (it.id !== id) {
                return it;
            }
            if (Number.isNaN(val) || val < 0) {
                val = 0;
            }
            return { ...it, returnQty: Math.min(val, it.delivered) };
        });
    }
    handleReason(event) {
        const id = event.currentTarget.dataset.id;
        const reason = event.detail.value;
        this.items = this.items.map((it) => (it.id === id ? { ...it, reason } : it));
    }

    nextStep() {
        if (this.nextDisabled) {
            return;
        }
        if (this.step === 1) {
            this.buildItems();
            this.step = 2;
        } else {
            this.saveReturn();
        }
    }
    backStep() {
        if (this.step === 2) {
            this.step = 1;
        } else {
            this.closeWizard();
        }
    }
    saveReturn() {
        this.p1 = [
            { id: 'RET-046', date: '17 Jun 2026', qty: this.totalReturnQty, status: 'Pending' },
            ...this.p1
        ];
        this.wizardOpen = false;
    }
}