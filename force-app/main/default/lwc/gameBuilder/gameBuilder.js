import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParents from '@salesforce/apex/SFA_MasterAdmin_Controller.getGames';
import getChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.getGameKpis';

const PARENT_COLUMNS = [{"label": "Game", "fieldName": "Name"}, {"label": "Team", "fieldName": "Team_Name__c"}, {"label": "Start", "fieldName": "Start_Date__c", "type": "date-local"}, {"label": "End", "fieldName": "End_Date__c", "type": "date-local"}, {"label": "Active", "fieldName": "Is_Active__c", "type": "boolean"}, {"type": "action", "typeAttributes": {"rowActions": [{"label": "Manage Lines", "name": "lines"}, {"label": "Edit", "name": "edit"}]}}];
const CHILD_COLUMNS = [{"label": "Slab", "fieldName": "Slab_Number__c", "type": "number"}, {"label": "Role", "fieldName": "Role__c"}, {"label": "KPI", "fieldName": "KPI_Name__c"}, {"label": "Type", "fieldName": "KPI_Type__c"}, {"label": "Cutoff", "fieldName": "Cutoff_Value__c", "type": "number"}, {"label": "Coins", "fieldName": "Reward_Coins__c", "type": "number"}];

export default class gameBuilder extends LightningElement {
    parentObject = 'Game__c';
    childObject = 'Game_KPI__c';
    parentFields = ["Name", "Team_Name__c", "Game_Code__c", "Start_Date__c", "End_Date__c", "Filter_Level__c", "Filter_State__c", "Description__c", "Is_Active__c"];
    childParentField = 'Game__c';
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

    @wire(getChildren, { gameId: '$selectedId' })
    wiredChildren(result) { this._wiredChildren = result; if (result.data) { this.children = result.data; } }

    get hasSelection() { return !!this.selectedId; }
    get parentFormTitle() { return this.recordId ? 'Edit Game' : 'New Game'; }
    get childPanelTitle() { return this.selectedName ? 'KPI Slabs \u2014 ' + this.selectedName : 'KPI Slabs'; }

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
        this.toast('Saved', 'Game saved.', 'success');
        return refreshApex(this._wiredParents);
    }
    handleNewChild() {
        if (!this.selectedId) { this.toast('Select first', 'Pick a Game row first.', 'warning'); return; }
        this.showChildForm = true;
    }
    closeChildForm() { this.showChildForm = false; }
    handleChildSuccess() {
        this.showChildForm = false;
        this.toast('Saved', 'KPI Slab saved.', 'success');
        return refreshApex(this._wiredChildren);
    }
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
