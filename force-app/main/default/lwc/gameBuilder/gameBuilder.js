import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTeams from '@salesforce/apex/GAM_Battleground_Controller.getTeams';
import saveTeams from '@salesforce/apex/GAM_Battleground_Controller.saveTeams';
import getTeamMembers from '@salesforce/apex/GAM_Battleground_Controller.getTeamMembers';
import saveTeamMembers from '@salesforce/apex/GAM_Battleground_Controller.saveTeamMembers';
import getKpis from '@salesforce/apex/GAM_Battleground_Controller.getKpis';
import saveKpis from '@salesforce/apex/GAM_Battleground_Controller.saveKpis';
import getGames from '@salesforce/apex/GAM_Battleground_Controller.getGames';
import saveGames from '@salesforce/apex/GAM_Battleground_Controller.saveGames';
import getGameTeams from '@salesforce/apex/GAM_Battleground_Controller.getGameTeams';
import saveGameTeams from '@salesforce/apex/GAM_Battleground_Controller.saveGameTeams';
import getGameKpis from '@salesforce/apex/GAM_Battleground_Controller.getGameKpis';
import saveGameKpis from '@salesforce/apex/GAM_Battleground_Controller.saveGameKpis';
import getAwards from '@salesforce/apex/GAM_Battleground_Controller.getAwards';
import saveAwards from '@salesforce/apex/GAM_Battleground_Controller.saveAwards';
import getLookupOptions from '@salesforce/apex/GAM_Battleground_Controller.getLookupOptions';

const P = (...vals) => vals.map(v => ({ label: v, value: v }));
const LVL = P('L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9');
const CAT = P('Qualifier', 'Discipline', 'Coverage', 'Sales');
const FREQ = P('Daily', 'Weekly', 'Monthly', 'Journey Cycle');
const OBJ = P('Sales', 'Coverage', 'Discipline', 'Quality', 'Other');
const CALC = P('App', 'Query');
const MEAS = P('Number', 'Decimal', 'Percent', 'Currency', 'Duration');
const KTYPE = P('Positive', 'Negative');
const TIER = P('Basic', 'Advanced');
const GKTYPE = P('Qualifier', 'Coverage', 'Sales', 'Other');

export default class GameBuilder extends LightningElement {
    @track teamColumns = [];
    @track kpiColumns = [];
    @track gameColumns = [];
    @track gameTeamColumns = [];
    @track gameKpiColumns = [];
    @track awardColumns = [];
    @track memberColumns = [];

    @track teamRows = [];
    @track kpiRows = [];
    @track gameRows = [];
    @track awardRows = [];
    @track gameTeamRows = [];
    @track gameKpiRows = [];
    @track memberRows = [];

    @track gameOptions = [];
    @track teamOptions = [];
    @track selectedGameId;
    @track selectedTeamId;

    userOptions = [];
    kpiOptions = [];
    metricOptions = [];

    _wiredTeams; _wiredKpis; _wiredGames; _wiredAwards; _wiredGameTeams; _wiredGameKpis; _wiredMembers;

    @wire(getTeams) wiredTeams(r) { this._wiredTeams = r; if (r.data) { this.teamRows = r.data; this.teamOptions = r.data.map(t => ({ label: t.Name, value: t.Id })); } }
    @wire(getKpis) wiredKpis(r) { this._wiredKpis = r; if (r.data) { this.kpiRows = r.data; this.kpiOptions = r.data.map(k => ({ label: k.Name, value: k.Id })); } }
    @wire(getGames) wiredGames(r) { this._wiredGames = r; if (r.data) { this.gameRows = r.data; this.gameOptions = r.data.map(g => ({ label: g.Name, value: g.Id })); } }
    @wire(getAwards) wiredAwards(r) { this._wiredAwards = r; if (r.data) { this.awardRows = r.data; } }
    @wire(getGameTeams, { gameId: '$selectedGameId' }) wiredGameTeams(r) { this._wiredGameTeams = r; if (r.data) { this.gameTeamRows = r.data; } }
    @wire(getGameKpis, { gameId: '$selectedGameId' }) wiredGameKpis(r) { this._wiredGameKpis = r; if (r.data) { this.gameKpiRows = r.data; } }
    @wire(getTeamMembers, { teamId: '$selectedTeamId' }) wiredMembers(r) { this._wiredMembers = r; if (r.data) { this.memberRows = r.data; } }

    connectedCallback() { this.loadOptions(); this.buildColumns(); }

    async loadOptions() {
        try {
            const [users, kpis, metrics] = await Promise.all([
                getLookupOptions({ objectApiName: 'User' }),
                getLookupOptions({ objectApiName: 'Battleground_KPI__c' }),
                getLookupOptions({ objectApiName: 'KPI_Metric__c' })
            ]);
            this.userOptions = (users || []).map(o => ({ label: o.label, value: o.value }));
            this.kpiOptions = (kpis || []).map(o => ({ label: o.label, value: o.value }));
            this.metricOptions = (metrics || []).map(o => ({ label: o.label, value: o.value }));
        } catch (e) {
            this.toast('Error', this.msg(e), 'error');
        }
        this.buildColumns();
    }

    buildColumns() {
        this.teamColumns = [
            { label: 'Team Name', field: 'Name', type: 'text' },
            { label: 'Code', field: 'Team_Code__c', type: 'text' },
            { label: 'Level', field: 'Level__c', type: 'picklist', options: LVL },
            { label: 'State', field: 'State__c', type: 'text' },
            { label: 'Manager', field: 'Manager__c', type: 'lookup', options: this.userOptions },
            { label: 'Active', field: 'Is_Active__c', type: 'checkbox' }
        ];
        this.kpiColumns = [
            { label: 'KPI Name', field: 'Name', type: 'text' },
            { label: 'UI Name', field: 'UI_Name__c', type: 'text' },
            { label: 'Category', field: 'Category__c', type: 'picklist', options: CAT },
            { label: 'Frequency', field: 'Frequency__c', type: 'picklist', options: FREQ },
            { label: 'Objective', field: 'Objective__c', type: 'picklist', options: OBJ },
            { label: 'Calculation', field: 'Calculation__c', type: 'picklist', options: CALC },
            { label: 'Measure', field: 'Measure__c', type: 'picklist', options: MEAS },
            { label: 'KPI Type', field: 'KPI_Type__c', type: 'picklist', options: KTYPE },
            { label: 'Tier', field: 'Tier__c', type: 'picklist', options: TIER },
            { label: 'Seq', field: 'Sequence__c', type: 'number' },
            { label: 'Qualifier', field: 'Is_Qualifier__c', type: 'checkbox' },
            { label: 'Incentive', field: 'Is_Incentive__c', type: 'checkbox' },
            { label: 'KPI Metric', field: 'KPI_Metric__c', type: 'lookup', options: this.metricOptions },
            { label: 'Active', field: 'Is_Active__c', type: 'checkbox' }
        ];
        this.gameColumns = [
            { label: 'Game Name', field: 'Name', type: 'text' },
            { label: 'Team Label', field: 'Team_Name__c', type: 'text' },
            { label: 'Start', field: 'Start_Date__c', type: 'date' },
            { label: 'End', field: 'End_Date__c', type: 'date' },
            { label: 'Active', field: 'Is_Active__c', type: 'checkbox' }
        ];
        this.gameTeamColumns = [
            { label: 'Team', field: 'Battleground_Team__c', type: 'lookup', options: this.teamOptions }
        ];
        this.gameKpiColumns = [
            { label: 'Battleground KPI', field: 'Battleground_KPI__c', type: 'lookup', options: this.kpiOptions },
            { label: 'Category', field: 'Category__c', type: 'picklist', options: CAT },
            { label: 'KPI Type', field: 'KPI_Type__c', type: 'picklist', options: GKTYPE },
            { label: 'Slab', field: 'Slab_Number__c', type: 'number' },
            { label: 'Cutoff', field: 'Cutoff_Value__c', type: 'number' },
            { label: 'Coins', field: 'Reward_Coins__c', type: 'number' }
        ];
        this.awardColumns = [
            { label: 'Game', field: 'Game__c', type: 'lookup', options: this.gameOptions },
            { label: 'KPI', field: 'Battleground_KPI__c', type: 'lookup', options: this.kpiOptions },
            { label: 'Coins', field: 'Coins__c', type: 'number' },
            { label: 'Description', field: 'Description__c', type: 'text' },
            { label: 'Active', field: 'Is_Active__c', type: 'checkbox' }
        ];
        this.memberColumns = [
            { label: 'User', field: 'Member__c', type: 'lookup', options: this.userOptions }
        ];
    }

    get hasGameSelected() { return !!this.selectedGameId; }
    get hasTeamSelected() { return !!this.selectedTeamId; }

    handleGameSelect(e) { this.selectedGameId = e.detail.value; }
    handleTeamSelect(e) { this.selectedTeamId = e.detail.value; }

    saver(fn, rows, wired, label) {
        return fn({ records: rows })
            .then(() => { this.toast('Saved', label + ' saved.', 'success'); return refreshApex(wired); })
            .catch(e => this.toast('Save failed', this.msg(e), 'error'));
    }

    handleSaveTeams(e) { this.saver(saveTeams, e.detail.rows, this._wiredTeams, 'Teams'); }
    handleSaveKpis(e) { this.saver(saveKpis, e.detail.rows, this._wiredKpis, 'KPIs'); }
    handleSaveGames(e) { this.saver(saveGames, e.detail.rows, this._wiredGames, 'Games'); }
    handleSaveAwards(e) { this.saver(saveAwards, e.detail.rows, this._wiredAwards, 'Awards'); }

    handleSaveGameTeams(e) {
        if (!this.selectedGameId) { this.toast('Select first', 'Choose a Game.', 'warning'); return; }
        const rows = e.detail.rows.map(r => ({ ...r, Game__c: this.selectedGameId }));
        this.saver(saveGameTeams, rows, this._wiredGameTeams, 'Game teams');
    }
    handleSaveGameKpis(e) {
        if (!this.selectedGameId) { this.toast('Select first', 'Choose a Game.', 'warning'); return; }
        const rows = e.detail.rows.map(r => ({ ...r, Game__c: this.selectedGameId }));
        this.saver(saveGameKpis, rows, this._wiredGameKpis, 'Game KPIs');
    }
    handleSaveMembers(e) {
        if (!this.selectedTeamId) { this.toast('Select first', 'Choose a Team.', 'warning'); return; }
        const rows = e.detail.rows.map(r => ({ ...r, Battleground_Team__c: this.selectedTeamId }));
        this.saver(saveTeamMembers, rows, this._wiredMembers, 'Team members');
    }

    toast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
    msg(e) {
        if (e && e.body && e.body.message) { return e.body.message; }
        if (e && e.message) { return e.message; }
        return 'Unknown error';
    }
}
