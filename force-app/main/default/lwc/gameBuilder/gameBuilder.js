import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParents from '@salesforce/apex/SFA_MasterAdmin_Controller.getGames';
import saveParents from '@salesforce/apex/SFA_MasterAdmin_Controller.saveGames';
import getChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.getGameKpis';
import saveChildren from '@salesforce/apex/SFA_MasterAdmin_Controller.saveGameKpis';
import getLookupOptions from '@salesforce/apex/SFA_MasterAdmin_Controller.getLookupOptions';

const PARENT_COLUMNS = [{"label": "Game Name", "field": "Name", "type": "text"}, {"label": "Team", "field": "Team_Name__c", "type": "text"}, {"label": "Code", "field": "Game_Code__c", "type": "text"}, {"label": "Start", "field": "Start_Date__c", "type": "date"}, {"label": "End", "field": "End_Date__c", "type": "date"}, {"label": "Level", "field": "Filter_Level__c", "type": "picklist", "options": [{"label": "L1", "value": "L1"}, {"label": "L2", "value": "L2"}, {"label": "L3", "value": "L3"}, {"label": "L4", "value": "L4"}, {"label": "L5", "value": "L5"}, {"label": "L6", "value": "L6"}, {"label": "L7", "value": "L7"}, {"label": "L8", "value": "L8"}, {"label": "L9", "value": "L9"}]}, {"label": "State", "field": "Filter_State__c", "type": "text"}, {"label": "Active", "field": "Is_Active__c", "type": "checkbox"}];
const CHILD_COLUMNS = [{"label": "Slab", "field": "Slab_Number__c", "type": "number"}, {"label": "Role", "field": "Role__c", "type": "picklist", "options": [{"label": "SR", "value": "SR"}, {"label": "MES", "value": "MES"}, {"label": "DBSM", "value": "DBSM"}, {"label": "DO", "value": "DO"}, {"label": "ASE", "value": "ASE"}, {"label": "ASM", "value": "ASM"}, {"label": "Manager", "value": "Manager"}, {"label": "All", "value": "All"}]}, {"label": "KPI Name", "field": "KPI_Name__c", "type": "text"}, {"label": "Type", "field": "KPI_Type__c", "type": "picklist", "options": [{"label": "Qualifier", "value": "Qualifier"}, {"label": "Coverage", "value": "Coverage"}, {"label": "Sales", "value": "Sales"}, {"label": "Other", "value": "Other"}]}, {"label": "KPI Metric", "field": "KPI_Metric__c", "type": "lookup", "lookup": "KPI_Metric__c"}, {"label": "Cutoff", "field": "Cutoff_Value__c", "type": "number"}, {"label": "Coins", "field": "Reward_Coins__c", "type": "number"}];

export default class GameBuilder extends LightningElement {
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

    @wire(getChildren, { gameId: '$selectedParentId' })
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
            this.toast('Saved', 'Game records saved.', 'success');
            await refreshApex(this._wiredParents);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        }
    }

    async handleSaveChildren(event) {
        if (!this.selectedParentId) {
            this.toast('Select first', 'Choose a Game above.', 'warning');
            return;
        }
        const rows = event.detail.rows.map(r => ({ ...r, Game__c: this.selectedParentId }));
        try {
            await saveChildren({ records: rows });
            this.toast('Saved', 'KPI Slab records saved.', 'success');
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
