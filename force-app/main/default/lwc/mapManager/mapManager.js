import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParents from '@salesforce/apex/SFA_MasterAdmin_Controller.getMapBudgets';
import saveParents from '@salesforce/apex/SFA_MasterAdmin_Controller.saveMapBudgets';
import getChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.getMapOrders';
import saveChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.saveMapOrders';

const PARENT_COLUMNS = [{"label": "Brand", "field": "Brand_Name__c", "type": "text"}, {"label": "Date", "field": "Budget_Date__c", "type": "date"}, {"label": "Amount", "field": "Amount__c", "type": "number"}, {"label": "Status", "field": "Status__c", "type": "picklist", "options": [{"label": "Draft", "value": "Draft"}, {"label": "Pending Approval", "value": "Pending Approval"}, {"label": "Approved", "value": "Approved"}, {"label": "Rejected", "value": "Rejected"}]}, {"label": "Active", "field": "Is_Active__c", "type": "checkbox"}];
const CHILD_COLUMNS = [{"label": "Amount", "field": "Amount__c", "type": "number"}, {"label": "Actuals", "field": "Actuals__c", "type": "number"}, {"label": "Description", "field": "Description__c", "type": "text"}, {"label": "Status", "field": "Status__c", "type": "picklist", "options": [{"label": "Draft", "value": "Draft"}, {"label": "Pending Approval", "value": "Pending Approval"}, {"label": "Approved", "value": "Approved"}, {"label": "Rejected", "value": "Rejected"}]}];

export default class MapManager extends LightningElement {
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

    @wire(getChildren, { budgetId: '$selectedParentId' })
    wiredChildren(result) {
        this._wiredChildren = result;
        if (result.data) { this.childRows = result.data; }
    }

    get hasParentSelected() { return !!this.selectedParentId; }

    handleParentSelect(event) { this.selectedParentId = event.detail.value; }

    async handleSaveParents(event) {
        try {
            await saveParents({ records: event.detail.rows });
            this.toast('Saved', 'MAP Budget records saved.', 'success');
            await refreshApex(this._wiredParents);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        }
    }

    async handleSaveChildren(event) {
        if (!this.selectedParentId) {
            this.toast('Select first', 'Choose a MAP Budget above.', 'warning');
            return;
        }
        const rows = event.detail.rows.map(r => ({ ...r, MAP_Budget__c: this.selectedParentId }));
        try {
            await saveChildren({ records: rows });
            this.toast('Saved', 'MAP Order records saved.', 'success');
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
