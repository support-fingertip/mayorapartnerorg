import { LightningElement } from 'lwc';
import { getInvoices, formatCurrency } from 'c/dmsData';

const STATUS_FILTERS = ['All', 'Paid', 'Pending', 'Overdue'];

/** Invoice list screen for the Experience Cloud Invoices tab. */
export default class DmsInvoices extends LightningElement {
    allInvoices = [];
    activeStatus = 'All';

    connectedCallback() {
        this.allInvoices = getInvoices();
    }

    get statusTabs() {
        return STATUS_FILTERS.map((status) => ({
            status,
            class: status === this.activeStatus ? 'dms-tab dms-tab_active' : 'dms-tab'
        }));
    }

    get filteredInvoices() {
        return this.allInvoices
            .filter((i) => this.activeStatus === 'All' || i.status === this.activeStatus)
            .map((i) => ({ ...i, amountLabel: formatCurrency(i.amount) }));
    }

    get isEmpty() {
        return this.filteredInvoices.length === 0;
    }

    get totalLabel() {
        return formatCurrency(this.allInvoices.reduce((sum, i) => sum + i.amount, 0));
    }

    get paidLabel() {
        return formatCurrency(
            this.allInvoices.filter((i) => i.status === 'Paid').reduce((sum, i) => sum + i.amount, 0)
        );
    }

    get outstandingLabel() {
        return formatCurrency(
            this.allInvoices.filter((i) => i.status !== 'Paid').reduce((sum, i) => sum + i.amount, 0)
        );
    }

    handleTab(event) {
        this.activeStatus = event.currentTarget.dataset.status;
    }
}
