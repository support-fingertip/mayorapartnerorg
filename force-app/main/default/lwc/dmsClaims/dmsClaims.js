import { LightningElement } from 'lwc';
import { getClaims, getClaimSchemes, formatCurrency } from 'c/dmsData';

const ALL = 'All';
const STATUS_THEME = { Approved: 'success', Pending: 'warning', Rejected: 'danger' };

export default class DmsClaims extends LightningElement {
    statusFilter = ALL;
    dateFilter = ALL;
    statusOptions = [
        { label: 'All Status', value: ALL },
        { label: 'Approved', value: 'Approved' },
        { label: 'Pending', value: 'Pending' },
        { label: 'Rejected', value: 'Rejected' }
    ];
    dateOptions = [{ label: 'All Dates', value: ALL }];

    claims = [];
    schemes = [];
    nextSeq = 42;

    // modal
    modalOpen = false;
    formScheme = '';
    formProducts = '';
    formAmount = '';
    formDesc = '';

    // success
    showSuccess = false;
    successInfo = {};

    connectedCallback() {
        this.claims = getClaims();
        this.schemes = getClaimSchemes();
    }

    get rows() {
        return this.claims
            .filter((c) => this.statusFilter === ALL || c.status === this.statusFilter)
            .map((c) => ({
                ...c,
                key: c.id,
                amountLabel: formatCurrency(c.amount),
                statusTheme: STATUS_THEME[c.status] || 'neutral'
            }));
    }

    get summary() {
        const count = (s) => this.claims.filter((c) => c.status === s).length;
        const total = this.claims.reduce((s, c) => s + c.amount, 0);
        return [
            { id: 't', label: 'Total Claims', value: this.claims.length, cls: 'dms-card__value' },
            { id: 'v', label: 'Total Value', value: formatCurrency(total), cls: 'dms-card__value' },
            { id: 'a', label: 'Approved', value: count('Approved'), cls: 'dms-card__value dms-card__value_green' },
            { id: 'p', label: 'Pending', value: count('Pending'), cls: 'dms-card__value dms-card__value_amber' },
            { id: 'r', label: 'Rejected', value: count('Rejected'), cls: 'dms-card__value dms-card__value_red' }
        ];
    }

    handleStatus(e) {
        this.statusFilter = e.detail.value;
    }
    handleDate(e) {
        this.dateFilter = e.detail.value;
    }

    /* ------------------------------ new claim ----------------------------- */
    get schemeOptions() {
        return this.schemes.map((s) => ({ value: s, label: s, selected: s === this.formScheme }));
    }
    get submitDisabled() {
        return !this.formScheme || !(parseInt(this.formProducts, 10) > 0) || !(parseInt(this.formAmount, 10) > 0);
    }

    openModal() {
        this.modalOpen = true;
        this.formScheme = '';
        this.formProducts = '';
        this.formAmount = '';
        this.formDesc = '';
    }
    closeModal() {
        this.modalOpen = false;
    }
    handleScheme(e) {
        this.formScheme = e.target.value;
    }
    handleProducts(e) {
        this.formProducts = e.target.value;
    }
    handleAmount(e) {
        this.formAmount = e.target.value;
    }
    handleDesc(e) {
        this.formDesc = e.target.value;
    }

    submitClaim() {
        if (this.submitDisabled) {
            return;
        }
        const amount = parseInt(this.formAmount, 10);
        const id = `SCH-00${this.nextSeq}`;
        this.nextSeq += 1;
        this.claims = [
            {
                id,
                date: '17 Jun 2026',
                scheme: this.formScheme,
                products: parseInt(this.formProducts, 10),
                amount,
                desc: this.formDesc || '—',
                status: 'Pending'
            },
            ...this.claims
        ];
        this.successInfo = {
            id,
            scheme: this.formScheme,
            amountLabel: formatCurrency(amount)
        };
        this.modalOpen = false;
        this.showSuccess = true;
    }
    closeSuccess() {
        this.showSuccess = false;
    }
}
