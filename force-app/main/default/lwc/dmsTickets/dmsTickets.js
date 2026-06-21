import { LightningElement } from 'lwc';
import { getTickets, getTicketCategories } from 'c/dmsData';

const ALL = 'All';
const CATEGORY_THEME = {
    'Delivery Delay': 'purple',
    'Product Quality': 'danger',
    'Invoice Dispute': 'warning',
    'Order Issue': 'neutral',
    'Scheme / Pricing': 'warning',
    Feedback: 'success',
    Other: 'neutral'
};
const PRIORITY_THEME = { High: 'danger', Medium: 'warning', Low: 'info' };
const STATUS_THEME = { Open: 'danger', 'In Progress': 'warning', Resolved: 'success', Closed: 'neutral' };

export default class DmsTickets extends LightningElement {
    categoryFilter = ALL;
    statusFilter = ALL;
    search = '';

    tickets = [];
    categories = [];
    nextSeq = 86;

    // detail
    detailOpen = false;
    selected = null;

    // new ticket
    modalOpen = false;
    formCategory = '';
    formPriority = 'Medium';
    formSubject = '';
    formRef = '';
    formDesc = '';

    connectedCallback() {
        this.tickets = getTickets();
        this.categories = getTicketCategories();
    }

    get categoryOptions() {
        return [{ label: 'All Categories', value: ALL }, ...this.categories.map((c) => ({ label: c, value: c }))];
    }
    get statusOptions() {
        return [
            { label: 'All Status', value: ALL },
            { label: 'Open', value: 'Open' },
            { label: 'In Progress', value: 'In Progress' },
            { label: 'Resolved', value: 'Resolved' },
            { label: 'Closed', value: 'Closed' }
        ];
    }

    decorate(t) {
        return {
            ...t,
            key: t.id,
            categoryTheme: CATEGORY_THEME[t.category] || 'neutral',
            priorityTheme: PRIORITY_THEME[t.priority] || 'neutral',
            statusTheme: STATUS_THEME[t.status] || 'neutral',
            statusClass: `dms-status dms-status_${STATUS_THEME[t.status] || 'neutral'}`,
            isOpen: t.status === 'Open',
            isProgress: t.status === 'In Progress',
            isDone: t.status === 'Resolved' || t.status === 'Closed',
            refLabel: t.reference || '—'
        };
    }

    get rows() {
        const key = this.search.toLowerCase();
        return this.tickets
            .filter((t) => this.categoryFilter === ALL || t.category === this.categoryFilter)
            .filter((t) => this.statusFilter === ALL || t.status === this.statusFilter)
            .filter((t) => !key || t.subject.toLowerCase().includes(key) || t.id.toLowerCase().includes(key))
            .map((t) => this.decorate(t));
    }

    get summary() {
        const count = (s) => this.tickets.filter((t) => t.status === s).length;
        return [
            { id: 't', label: 'Total', value: this.tickets.length, cls: 'dms-card__value' },
            { id: 'o', label: 'Open', value: count('Open'), cls: 'dms-card__value dms-card__value_red' },
            { id: 'p', label: 'In Progress', value: count('In Progress'), cls: 'dms-card__value dms-card__value_amber' },
            { id: 'r', label: 'Resolved', value: count('Resolved'), cls: 'dms-card__value dms-card__value_green' }
        ];
    }

    handleCategory(e) {
        this.categoryFilter = e.detail.value;
    }
    handleStatus(e) {
        this.statusFilter = e.detail.value;
    }
    handleSearch(e) {
        this.search = e.target.value;
    }

    /* ---------------------------- detail modal ---------------------------- */
    viewTicket(event) {
        const id = event.currentTarget.dataset.id;
        const t = this.tickets.find((x) => x.id === id);
        if (!t) {
            return;
        }
        this.selected = {
            ...this.decorate(t),
            messages: t.messages.map((m, i) => ({
                ...m,
                key: i,
                initials: m.type === 'mayora' ? 'M' : 'SD',
                avatarClass: m.type === 'mayora' ? 'dms-msg__av dms-msg__av_m' : 'dms-msg__av dms-msg__av_sd',
                cardClass: m.type === 'mayora' ? 'dms-msg dms-msg_mayora' : 'dms-msg dms-msg_sd'
            }))
        };
        this.detailOpen = true;
    }
    closeDetail() {
        this.detailOpen = false;
    }

    /* ----------------------------- new ticket ----------------------------- */
    get newCategoryOptions() {
        return this.categories.map((c) => ({ value: c, label: c, selected: c === this.formCategory }));
    }
    get priorityButtons() {
        return ['High', 'Medium', 'Low'].map((p) => ({
            p,
            class: p === this.formPriority ? 'dms-seg dms-seg_active' : 'dms-seg'
        }));
    }
    get submitDisabled() {
        return !this.formCategory || !this.formSubject;
    }

    openModal() {
        this.modalOpen = true;
        this.formCategory = '';
        this.formPriority = 'Medium';
        this.formSubject = '';
        this.formRef = '';
        this.formDesc = '';
    }
    closeModal() {
        this.modalOpen = false;
    }
    handleFormCategory(e) {
        this.formCategory = e.target.value;
    }
    setPriority(e) {
        this.formPriority = e.currentTarget.dataset.p;
    }
    handleSubject(e) {
        this.formSubject = e.target.value;
    }
    handleRef(e) {
        this.formRef = e.target.value;
    }
    handleDesc(e) {
        this.formDesc = e.target.value;
    }

    submitTicket() {
        if (this.submitDisabled) {
            return;
        }
        const id = `TKT-00${this.nextSeq}`;
        this.nextSeq += 1;
        this.tickets = [
            {
                id,
                date: '17 Jun 2026',
                category: this.formCategory,
                subject: this.formSubject,
                reference: this.formRef || '—',
                priority: this.formPriority,
                status: 'Open',
                lastUpdate: '17 Jun 2026',
                messages: [{ from: 'Sharma Distributors', type: 'sd', date: '17 Jun 2026', text: this.formDesc || this.formSubject }]
            },
            ...this.tickets
        ];
        this.modalOpen = false;
    }
}