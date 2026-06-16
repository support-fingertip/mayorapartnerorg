import { LightningElement } from 'lwc';
import { getOrders, formatCurrency } from 'c/dmsData';

const STATUS_FILTERS = ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];

/** Sales order list screen for the Experience Cloud Orders tab. */
export default class DmsOrders extends LightningElement {
    allOrders = [];
    activeStatus = 'All';

    connectedCallback() {
        this.allOrders = getOrders();
    }

    get statusTabs() {
        return STATUS_FILTERS.map((status) => ({
            status,
            class: status === this.activeStatus ? 'dms-tab dms-tab_active' : 'dms-tab'
        }));
    }

    get filteredOrders() {
        return this.allOrders
            .filter((o) => this.activeStatus === 'All' || o.status === this.activeStatus)
            .map((o) => ({ ...o, amountLabel: formatCurrency(o.amount) }));
    }

    get isEmpty() {
        return this.filteredOrders.length === 0;
    }

    handleTab(event) {
        this.activeStatus = event.currentTarget.dataset.status;
    }
}
