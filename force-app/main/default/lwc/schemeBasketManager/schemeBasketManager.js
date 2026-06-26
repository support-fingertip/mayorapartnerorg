import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParents from '@salesforce/apex/SFA_MasterAdmin_Controller.getSchemeBaskets';
import getChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.getBasketProducts';

const PARENT_COLUMNS = [{"label": "Basket", "fieldName": "Name"}, {"label": "Code", "fieldName": "Basket_Code__c"}, {"label": "Channel", "fieldName": "Channel__c"}, {"label": "Active", "fieldName": "Is_Active__c", "type": "boolean"}, {"type": "action", "typeAttributes": {"rowActions": [{"label": "Manage Lines", "name": "lines"}, {"label": "Edit", "name": "edit"}]}}];
const CHILD_COLUMNS = [{"label": "Line", "fieldName": "Name"}, {"label": "Min Qty", "fieldName": "Min_Qty__c", "type": "number"}];

export default class schemeBasketManager extends LightningElement {
    parentObject = 'Scheme_Basket__c';
    childObject = 'Scheme_Basket_Product__c';
    parentFields = ["Name", "Basket_Code__c", "Channel__c", "Description__c", "Is_Active__c"];
    childParentField = 'Scheme_Basket__c';
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

    @wire(getChildren, { basketId: '$selectedId' })
    wiredChildren(result) { this._wiredChildren = result; if (result.data) { this.children = result.data; } }

    get hasSelection() { return !!this.selectedId; }
    get parentFormTitle() { return this.recordId ? 'Edit Scheme Basket' : 'New Scheme Basket'; }
    get childPanelTitle() { return this.selectedName ? 'Basket Products \u2014 ' + this.selectedName : 'Basket Products'; }

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
        this.toast('Saved', 'Scheme Basket saved.', 'success');
        return refreshApex(this._wiredParents);
    }
    handleNewChild() {
        if (!this.selectedId) { this.toast('Select first', 'Pick a Scheme Basket row first.', 'warning'); return; }
        this.showChildForm = true;
    }
    closeChildForm() { this.showChildForm = false; }
    handleChildSuccess() {
        this.showChildForm = false;
        this.toast('Saved', 'Basket Product saved.', 'success');
        return refreshApex(this._wiredChildren);
    }
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
