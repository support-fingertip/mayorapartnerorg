import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParents from '@salesforce/apex/SFA_MasterAdmin_Controller.getSchemeBaskets';
import saveParents from '@salesforce/apex/SFA_MasterAdmin_Controller.saveSchemeBaskets';
import getChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.getBasketProducts';
import saveChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.saveBasketProducts';
import getLookupOptions from '@salesforce/apex/SFA_MasterAdmin_Controller.getLookupOptions';

const PARENT_COLUMNS = [{"label": "Basket Name", "field": "Name", "type": "text"}, {"label": "Code", "field": "Basket_Code__c", "type": "text"}, {"label": "Channel", "field": "Channel__c", "type": "picklist", "options": [{"label": "GT", "value": "GT"}, {"label": "MT", "value": "MT"}, {"label": "Both", "value": "Both"}]}, {"label": "Active", "field": "Is_Active__c", "type": "checkbox"}];
const CHILD_COLUMNS = [{"label": "Product", "field": "Product_Ext__c", "type": "lookup", "lookup": "Product_Extension__c"}, {"label": "Min Qty", "field": "Min_Qty__c", "type": "number"}];

export default class SchemeBasketManager extends LightningElement {
    parentColumns = PARENT_COLUMNS;
    @track childColumns = CHILD_COLUMNS;
    @track parentRows = [];
    @track childRows = [];
    @track parentOptions = [];
    @track selectedParentId;
    _wiredParents;
    _wiredChildren;

    @wire(getParents)
    wiredParents(result) {
        this._wiredParents = result;
        if (result.data) {
            this.parentRows = result.data;
            this.parentOptions = result.data.map(p => ({ label: p.Name, value: p.Id }));
        }
    }

    @wire(getChildren, { basketId: '$selectedParentId' })
    wiredChildren(result) {
        this._wiredChildren = result;
        if (result.data) { this.childRows = result.data; }
    }

    connectedCallback() { this.loadLookups(); }
    async loadLookups() {
        try {
            const results = await Promise.all([getLookupOptions({ objectApiName: 'Product_Extension__c' })]);
            const opt0 = (results[0] || []).map(o => ({ label: o.label, value: o.value }));
            this.childColumns = this.childColumns.map(col => col.field === 'Product_Ext__c' ? { ...col, options: opt0 } : col);
        } catch (e) {
            this.toast('Error', this.msg(e), 'error');
        }
    }
    get hasParentSelected() { return !!this.selectedParentId; }

    handleParentSelect(event) { this.selectedParentId = event.detail.value; }

    async handleSaveParents(event) {
        try {
            await saveParents({ records: event.detail.rows });
            this.toast('Saved', 'Scheme Basket records saved.', 'success');
            await refreshApex(this._wiredParents);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        }
    }

    async handleSaveChildren(event) {
        if (!this.selectedParentId) {
            this.toast('Select first', 'Choose a Scheme Basket above.', 'warning');
            return;
        }
        const rows = event.detail.rows.map(r => ({ ...r, Scheme_Basket__c: this.selectedParentId }));
        try {
            await saveChildren({ records: rows });
            this.toast('Saved', 'Basket Product records saved.', 'success');
            await refreshApex(this._wiredChildren);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    msg(e) {
        if (e && e.body && e.body.message) { return e.body.message; }
        if (e && e.message) { return e.message; }
        return 'Unknown error';
    }
}
