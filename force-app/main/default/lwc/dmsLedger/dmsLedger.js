import { LightningElement } from 'lwc';
import { getLedger, formatCurrency } from 'c/dmsData';

const TYPE_THEME = {
    'Opening Bal.': 'neutral',
    'Primary Invoice': 'info',
    'Payment Received': 'success',
    'Return Credit': 'purple',
    'Scheme Claim': 'warning'
};

export default class DmsLedger extends LightningElement {
    fromDate = '2026-05-01';
    toDate = '2026-05-31';
    generated = false;
    tx = [];

    get rows() {
        return this.tx.map((t) => ({
            ...t,
            key: t.date + t.ref + t.narration,
            typeTheme: TYPE_THEME[t.type] || 'neutral',
            refLabel: t.ref || '—',
            hasRef: Boolean(t.ref),
            debitLabel: t.debit ? formatCurrency(t.debit) : '—',
            creditLabel: t.credit ? formatCurrency(t.credit) : '—',
            balanceLabel: t.balance === 0 ? '₹0 NIL' : `${formatCurrency(t.balance)} Dr`,
            balanceClass: t.balance === 0 ? 'dms-num dms-bal dms-bal_nil' : 'dms-num dms-bal dms-bal_dr'
        }));
    }

    get rangeLabel() {
        return `${this.fromDate} to ${this.toDate} · ${this.tx.length} transactions`;
    }

    get closingLabel() {
        if (!this.tx.length) {
            return '';
        }
        const bal = this.tx[this.tx.length - 1].balance;
        return bal === 0 ? '₹0 NIL' : `${formatCurrency(bal)} Dr`;
    }

    handleFrom(e) {
        this.fromDate = e.target.value;
    }
    handleTo(e) {
        this.toDate = e.target.value;
    }

    generate() {
        this.tx = getLedger();
        this.generated = true;
    }
}