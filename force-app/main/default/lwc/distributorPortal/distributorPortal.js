import { LightningElement } from 'lwc';

const TABS = [
    { label: 'Home', name: 'home' },
    { label: 'Orders', name: 'orders' },
    { label: 'Invoices', name: 'invoices' },
    { label: 'Ledger', name: 'ledger' },
    { label: 'Claims', name: 'claims' },
    { label: 'Secondary Sale', name: 'sale' },
    { label: 'Support', name: 'support' }
];

export default class DistributorPortal extends LightningElement {
    active = 'home';

    get tabs() {
        return TABS.map((t) => ({
            ...t,
            css: 'nav-item' + (t.name === this.active ? ' nav-item_active' : '')
        }));
    }

    select(e) {
        this.active = e.currentTarget.dataset.name;
    }

    get isHome() { return this.active === 'home'; }
    get isOrders() { return this.active === 'orders'; }
    get isInvoices() { return this.active === 'invoices'; }
    get isLedger() { return this.active === 'ledger'; }
    get isClaims() { return this.active === 'claims'; }
    get isSale() { return this.active === 'sale'; }
    get isSupport() { return this.active === 'support'; }
}