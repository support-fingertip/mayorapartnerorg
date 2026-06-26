import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParents from '@salesforce/apex/SFA_MasterAdmin_Controller.getMapBudgets';
import getChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.getMapOrders';

const PARENT_COLUMNS = [{"label": "Budget", "fieldName": "Name"}, {"label": "Brand", "fieldName": "Brand_Name__c"}, {"label": "Amount", "fieldName": "Amount__c", "type": "currency"}, {"label": "Spent", "fieldName": "Spent_Amount__c", "type": "currency"}, {"label": "Remaining", "fieldName": "Remaining_Amount__c", "type": "currency"}, {"label": "Status", "fieldName": "Status__c"}, {"type": "action", "typeAttributes": {"rowActions": [{"label": "Manage Lines", "name": "lines"}, {"label": "Edit", "name": "edit"}]}}];
const CHILD_COLUMNS = [{"label": "Order", "fieldName": "Name"}, {"label": "Amount", "fieldName": "Amount__c", "type": "currency"}, {"label": "Actuals", "fieldName": "Actuals__c", "type": "currency"}, {"label": "Remaining", "fieldName": "Remaining_Amount__c", "type": "currency"}, {"label": "Status", "fieldName": "Status__c"}];

export default class mapManager extends LightningElement {
    parentObject = 'MAP_Budget__c';
    childObject = 'MAP_Order__c';
    parentFields = ["Brand_Name__c", "Budget_Date__c", "Amount__c", "Status__c", "Description__c", "Is_Active__c"];
    childParentField = 'MAP_Budget__c';
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

    @wire(getChildren, { budgetId: '$selectedId' })
    wiredChildren(result) { this._wiredChildren = result; if (result.data) { this.children = result.data; } }

    get hasSelection() { return !!this.selectedId; }
    get parentFormTitle() { return this.recordId ? 'Edit MAP Budget' : 'New MAP Budget'; }
    get childPanelTitle() { return this.selectedName ? 'MAP Orders \u2014 ' + this.selectedName : 'MAP Orders'; }

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
        this.toast('Saved', 'MAP Budget saved.', 'success');
        return refreshApex(this._wiredParents);
    }
    handleNewChild() {
        if (!this.selectedId) { this.toast('Select first', 'Pick a MAP Budget row first.', 'warning'); return; }
        this.showChildForm = true;
    }
    closeChildForm() { this.showChildForm = false; }
    handleChildSuccess() {
        this.showChildForm = false;
        this.toast('Saved', 'MAP Order saved.', 'success');
        return refreshApex(this._wiredChildren);
    }
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
