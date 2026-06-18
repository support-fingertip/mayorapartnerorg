import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getIndents from '@salesforce/apex/DMS_PortalController.getIndents';
import getProducts from '@salesforce/apex/DMS_PortalController.getProducts';
import placeIndent from '@salesforce/apex/DMS_PortalController.placeIndent';

const INDENT_COLUMNS = [
    { label: 'Indent #', fieldName: 'Name' },
    { label: 'Date', fieldName: 'Indent_Date__c', type: 'date' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Total', fieldName: 'Total_Amount__c', type: 'currency' },
    { label: 'Requested Delivery', fieldName: 'Requested_Delivery_Date__c', type: 'date' }
];

const LINE_COLUMNS = [
    { label: 'Product', fieldName: 'productName' },
    { label: 'Quantity', fieldName: 'quantity', type: 'number' },
    { type: 'button-icon', fixedWidth: 50,
      typeAttributes: { iconName: 'utility:delete', name: 'remove', variant: 'bare', alternativeText: 'Remove' } }
];

export default class DistributorOrders extends LightningElement {
    indentColumns = INDENT_COLUMNS;
    lineColumns = LINE_COLUMNS;
    indents = [];
    wiredIndents;
    productOptions = [];
    productNameById = {};
    productId;
    quantity;
    @track lines = [];
    submitting = false;
    error;

    @wire(getIndents)
    wired(result) {
        this.wiredIndents = result;
        if (result.data) { this.indents = result.data; }
        else if (result.error) { this.error = this.msg(result.error); }
    }

    @wire(getProducts)
    wiredProducts({ data }) {
        if (data) {
            this.productOptions = data.map((p) => ({ label: p.Name, value: p.Id }));
            data.forEach((p) => { this.productNameById[p.Id] = p.Name; });
        }
    }

    handleProduct(e) { this.productId = e.detail.value; }
    handleQty(e) { this.quantity = e.detail.value; }

    addLine() {
        if (!this.productId || !this.quantity || Number(this.quantity) <= 0) {
            this.toast('Incomplete', 'Pick a product and a positive quantity.', 'warning');
            return;
        }
        const existing = this.lines.find((l) => l.productId === this.productId);
        if (existing) { existing.quantity = Number(this.quantity); this.lines = [...this.lines]; }
        else {
            this.lines = [...this.lines,
                { productId: this.productId, productName: this.productNameById[this.productId], quantity: Number(this.quantity) }];
        }
        this.productId = undefined; this.quantity = undefined;
    }

    handleRowAction(e) {
        if (e.detail.action.name === 'remove') {
            const id = e.detail.row.productId;
            this.lines = this.lines.filter((l) => l.productId !== id);
        }
    }

    get hasIndents() { return this.indents && this.indents.length > 0; }
    get isSubmitDisabled() { return this.lines.length === 0 || this.submitting; }

    async submit() {
        this.submitting = true;
        try {
            await placeIndent({ lines: this.lines.map((l) => ({ productId: l.productId, quantity: l.quantity })) });
            this.toast('Indent placed', 'Your replenishment indent was created as Draft.', 'success');
            this.lines = [];
            await refreshApex(this.wiredIndents);
        } catch (e) {
            this.toast('Could not place indent', this.msg(e), 'error');
        } finally {
            this.submitting = false;
        }
    }

    msg(e) { return (e && e.body && e.body.message) || 'Unexpected error.'; }
    toast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
}