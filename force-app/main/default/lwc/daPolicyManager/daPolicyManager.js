import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParents from '@salesforce/apex/SFA_MasterAdmin_Controller.getDaPolicies';
import getChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.getDaPolicyKpis';

const PARENT_COLUMNS = [{"label": "Policy", "fieldName": "Name"}, {"label": "Active", "fieldName": "Is_Active__c", "type": "boolean"}, {"type": "action", "typeAttributes": {"rowActions": [{"label": "Manage Lines", "name": "lines"}, {"label": "Edit", "name": "edit"}]}}];
const CHILD_COLUMNS = [{"label": "KPI Target", "fieldName": "Name"}, {"label": "Half Day", "fieldName": "Half_Day_Target__c", "type": "number"}, {"label": "Full Day", "fieldName": "Full_Day_Target__c", "type": "number"}];

export default class daPolicyManager extends LightningElement {
    parentObject = 'DA_Policy__c';
    childObject = 'DA_Policy_KPI__c';
    parentFields = ["Name", "Expense_Eligibility__c", "Description__c", "Is_Active__c"];
    childParentField = 'DA_Policy__c';
    parentColumns = PARENT_COLUMNS;
    childColumns = CHILD_COLUMNS;

    parents;
    children;
    _wiredParents;
    _wiredChildren;
    @track selectedId;
    @track selectedName;
    @track recordId;
    @track showParentForm = false;
    @track showChildForm = false;

    @wire(getParents)
    wiredParents(result) { this._wiredParents = result; if (result.data) { this.parents = result.data; } }

    @wire(getChildren, { policyId: '$selectedId' })
    wiredChildren(result) { this._wiredChildren = result; if (result.data) { this.children = result.data; } }

    get hasSelection() { return !!this.selectedId; }
    get parentFormTitle() { return this.recordId ? 'Edit DA Policy' : 'New DA Policy'; }
    get childPanelTitle() { return this.selectedName ? 'KPI Targets \u2014 ' + this.selectedName : 'KPI Targets'; }

    handleNewParent() { this.recordId = null; this.showParentForm = true; }
    handleParentRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === 'edit') { this.recordId = row.Id; this.showParentForm = true; }
        else if (action === 'lines') { this.selectedId = row.Id; this.selectedName = row.Name; }
    }
    closeParentForm() { this.showParentForm = false; }
    handleParentSuccess() {
        this.showParentForm = false;
        this.toast('Saved', 'DA Policy saved.', 'success');
        return refreshApex(this._wiredParents);
    }
    handleNewChild() {
        if (!this.selectedId) { this.toast('Select first', 'Pick a DA Policy row first.', 'warning'); return; }
        this.showChildForm = true;
    }
    closeChildForm() { this.showChildForm = false; }
    handleChildSuccess() {
        this.showChildForm = false;
        this.toast('Saved', 'KPI Target saved.', 'success');
        return refreshApex(this._wiredChildren);
    }
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
