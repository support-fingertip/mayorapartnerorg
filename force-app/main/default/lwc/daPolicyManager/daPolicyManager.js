import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParents from '@salesforce/apex/SFA_MasterAdmin_Controller.getDaPolicies';
import saveParents from '@salesforce/apex/SFA_MasterAdmin_Controller.saveDaPolicies';
import getChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.getDaPolicyKpis';
import saveChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.saveDaPolicyKpis';
import getLookupOptions from '@salesforce/apex/SFA_MasterAdmin_Controller.getLookupOptions';

const PARENT_COLUMNS = [{"label": "Policy Name", "field": "Name", "type": "text"}, {"label": "Description", "field": "Description__c", "type": "text"}, {"label": "Active", "field": "Is_Active__c", "type": "checkbox"}];
const CHILD_COLUMNS = [{"label": "KPI", "field": "KPI_Metric__c", "type": "lookup", "lookup": "KPI_Metric__c"}, {"label": "Half Day Target", "field": "Half_Day_Target__c", "type": "number"}, {"label": "Full Day Target", "field": "Full_Day_Target__c", "type": "number"}];

export default class DaPolicyManager extends LightningElement {
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

    @wire(getChildren, { policyId: '$selectedParentId' })
    wiredChildren(result) {
        this._wiredChildren = result;
        if (result.data) { this.childRows = result.data; }
    }

    connectedCallback() { this.loadLookups(); }
    async loadLookups() {
        try {
            const results = await Promise.all([getLookupOptions({ objectApiName: 'KPI_Metric__c' })]);
            const opt0 = (results[0] || []).map(o => ({ label: o.label, value: o.value }));
            this.childColumns = this.childColumns.map(col => col.field === 'KPI_Metric__c' ? { ...col, options: opt0 } : col);
        } catch (e) {
            this.toast('Error', this.msg(e), 'error');
        }
    }
    get hasParentSelected() { return !!this.selectedParentId; }

    handleParentSelect(event) { this.selectedParentId = event.detail.value; }

    async handleSaveParents(event) {
        try {
            await saveParents({ records: event.detail.rows });
            this.toast('Saved', 'DA Policy records saved.', 'success');
            await refreshApex(this._wiredParents);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        }
    }

    async handleSaveChildren(event) {
        if (!this.selectedParentId) {
            this.toast('Select first', 'Choose a DA Policy above.', 'warning');
            return;
        }
        const rows = event.detail.rows.map(r => ({ ...r, DA_Policy__c: this.selectedParentId }));
        try {
            await saveChildren({ records: rows });
            this.toast('Saved', 'KPI Target records saved.', 'success');
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
