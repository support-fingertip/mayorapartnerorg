import { LightningElement } from 'lwc';
import { getGrnList, getPendingGrnInvoices, formatCurrency } from 'c/dmsData';

const ALL = 'All';
const REASONS = [
    { label: 'Damaged', value: 'Damaged' },
    { label: 'Missed', value: 'Missed' },
    { label: 'Expired', value: 'Expired' }
];

export default class DmsGrn extends LightningElement {
    listFilter = ALL;
    listOptions = [{ label: 'All GRNs', value: ALL }];
    reasonOptions = REASONS;

    grns = [];
    pendingInvoices = [];

    // wizard
    wizardOpen = false;
    step = 1;
    selectedInvoiceIds = [];
    items = [];
    showSuccess = false;
    successInfo = {};

    connectedCallback() {
        this.grns = getGrnList();
        this.pendingInvoices = getPendingGrnInvoices();
        // pre-select all pending invoices (matches the prototype)
        this.selectedInvoiceIds = this.pendingInvoices.map((i) => i.id);
    }

    /* ------------------------------- list -------------------------------- */
    get grnRows() {
        return this.grns.map((g) => ({ ...g, key: g.id }));
    }

    get summary() {
        return [
            { id: 'total', label: 'Total GRNs', value: this.grns.length, cls: 'dms-chip__value' },
            { id: 'done', label: 'Completed (May 2026)', value: this.grns.length, cls: 'dms-chip__value dms-chip__value_done' }
        ];
    }

    get pendingCount() {
        return this.pendingInvoices.length;
    }

    handleListFilter(e) {
        this.listFilter = e.detail.value;
    }

    /* ------------------------------ wizard ------------------------------- */
    openWizard() {
        this.wizardOpen = true;
        this.step = 1;
        this.selectedInvoiceIds = this.pendingInvoices.map((i) => i.id);
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
        return this.step === 1 ? 'Select SAP Invoices' : 'Review Items & Enter Damage/Missing Qty';
    }
    get stepDots() {
        return [1, 2].map((n) => ({
            n,
            class: n === this.step ? 'dms-step__dot dms-step__dot_active' : 'dms-step__dot'
        }));
    }

    get invoiceCards() {
        return this.pendingInvoices.map((inv) => {
            const selected = this.selectedInvoiceIds.includes(inv.id);
            return {
                ...inv,
                key: inv.id,
                amountLabel: formatCurrency(inv.amount),
                metaLabel: `${inv.date} · ${inv.lines.length} SKUs`,
                productsLabel: inv.lines.map((l) => l.name).join(', '),
                rowClass: selected ? 'dms-pick dms-pick_on' : 'dms-pick',
                boxClass: selected ? 'dms-check dms-check_on' : 'dms-check'
            };
        });
    }

    get itemRows() {
        return this.items.map((it) => ({
            ...it,
            reasonDisabled: it.damage === 0
        }));
    }

    get nextDisabled() {
        return this.step === 1 && this.selectedInvoiceIds.length === 0;
    }

    toggleInvoice(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedInvoiceIds = this.selectedInvoiceIds.includes(id)
            ? this.selectedInvoiceIds.filter((x) => x !== id)
            : [...this.selectedInvoiceIds, id];
    }

    buildItems() {
        const items = [];
        this.pendingInvoices
            .filter((inv) => this.selectedInvoiceIds.includes(inv.id))
            .forEach((inv) => {
                inv.lines.forEach((l, i) => {
                    items.push({
                        id: `${inv.id}-${i}`,
                        sku: l.sku,
                        name: l.name,
                        shelf: l.shelf,
                        skuMeta: `${l.sku} · ${l.shelf}`,
                        qty: l.qty,
                        mfg: l.mfg,
                        expiry: l.expiry,
                        damage: 0,
                        reason: 'Damaged'
                    });
                });
            });
        this.items = items;
    }

    handleDamage(event) {
        const id = event.currentTarget.dataset.id;
        let val = parseInt(event.target.value, 10);
        this.items = this.items.map((it) => {
            if (it.id !== id) {
                return it;
            }
            if (Number.isNaN(val) || val < 0) {
                val = 0;
            }
            return { ...it, damage: Math.min(val, it.qty) };
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
            this.saveGrn();
        }
    }

    backStep() {
        if (this.step === 2) {
            this.step = 1;
        } else {
            this.closeWizard();
        }
    }

    saveGrn() {
        const selected = this.pendingInvoices.filter((inv) =>
            this.selectedInvoiceIds.includes(inv.id)
        );
        const total = selected.reduce((s, inv) => s + inv.amount, 0);
        const returns = this.items
            .filter((it) => it.damage > 0)
            .map((it) => ({
                key: it.id,
                label: `${it.name} — ${it.damage} ctns (${it.reason})`
            }));
        this.successInfo = {
            grnId: 'GRN-0392',
            refs: selected.map((i) => i.id).join(', '),
            totalLabel: formatCurrency(total),
            hasReturns: returns.length > 0,
            returnId: 'RET-046',
            returns
        };
        this.wizardOpen = false;
        this.showSuccess = true;
    }

    closeSuccess() {
        this.showSuccess = false;
    }
}
