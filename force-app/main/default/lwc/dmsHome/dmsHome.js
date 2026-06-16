import { LightningElement } from 'lwc';
import { getKpis, getOrders, getInvoices } from 'c/dmsData';

/** DMS landing / dashboard screen for the Experience Cloud Home tab. */
export default class DmsHome extends LightningElement {
    kpis = [];
    recentOrders = [];
    recentInvoices = [];

    connectedCallback() {
        this.kpis = getKpis();
        this.recentOrders = getOrders().slice(0, 5);
        this.recentInvoices = getInvoices()
            .filter((i) => i.status !== 'Paid')
            .slice(0, 5);
    }
}
