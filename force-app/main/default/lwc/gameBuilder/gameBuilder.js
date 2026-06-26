import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGames from '@salesforce/apex/GAM_Battleground_Controller.getGames';
import getKpis from '@salesforce/apex/GAM_Battleground_Controller.getKpis';
import saveKpis from '@salesforce/apex/GAM_Battleground_Controller.saveKpis';
import getLookupOptions from '@salesforce/apex/GAM_Battleground_Controller.getLookupOptions';
import saveGameWizard from '@salesforce/apex/GAM_Battleground_Controller.saveGameWizard';

const P = (...v) => v.map(x => ({ label: x, value: x }));

const GAME_COLUMNS = [
    { label: 'Game', fieldName: 'Name' },
    { label: 'Start', fieldName: 'Start_Date__c', type: 'date-local' },
    { label: 'End', fieldName: 'End_Date__c', type: 'date-local' },
    { label: 'Status', fieldName: 'statusLabel' }
];

const KPI_LIST_COLUMNS = [
    { label: 'KPI Name', fieldName: 'Name' },
    { label: 'Category', fieldName: 'Category__c' },
    { label: 'Frequency', fieldName: 'Frequency__c' },
    { label: 'KPI Type', fieldName: 'KPI_Type__c' },
    { label: 'Tier', fieldName: 'Tier__c' },
    { label: 'Qualifier', fieldName: 'Is_Qualifier__c', type: 'boolean' },
    { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean' },
    { type: 'action', typeAttributes: { rowActions: [{ label: 'Edit', name: 'edit' }] } }
];

const EMPTY_KPI = {
    Id: null, Name: '', UI_Name__c: '', Category__c: '', Frequency__c: '', Objective__c: '',
    Calculation__c: '', Measure__c: '', KPI_Type__c: '', Tier__c: '', Sequence__c: null,
    KPI_Metric__c: '', Description__c: '', Is_Qualifier__c: false, Is_Incentive__c: false, Is_Active__c: true
};

export default class GameBuilder extends LightningElement {
    gameColumns = GAME_COLUMNS;
    kpiListColumns = KPI_LIST_COLUMNS;

    @track games = [];
    @track kpiRows = [];
    @track userOptions = [];
    @track kpiOptions = [];
    @track metricOptions = [];
    kpiMeta = {};
    _wiredGames;
    _wiredKpis;

    @track view = 'list';
    @track kpiSubView = 'list';
    @track kpiForm = { ...EMPTY_KPI };
    @track savingKpi = false;

    // wizard state
    @track step = 1;
    @track gameName = '';
    @track startDate;
    @track endDate;
    @track isActive = true;
    @track teamName = '';
    @track selectedUserIds = [];
    @track selectedKpiIds = [];
    @track awardRows = [];

    @wire(getGames)
    wiredGames(result) {
        this._wiredGames = result;
        if (result.data) {
            this.games = result.data.map(g => ({ ...g, statusLabel: g.Is_Active__c ? 'Active' : 'Inactive' }));
        }
    }

    @wire(getKpis)
    wiredKpis(result) {
        this._wiredKpis = result;
        if (result.data) {
            this.kpiRows = result.data;
            this.kpiOptions = result.data.map(k => ({
                label: (k.Category__c ? k.Category__c + ' — ' : '') + k.Name,
                value: k.Id
            }));
            this.kpiMeta = {};
            result.data.forEach(k => { this.kpiMeta[k.Id] = { name: k.Name, category: k.Category__c }; });
        }
    }

    connectedCallback() { this.loadLookups(); }

    async loadLookups() {
        try {
            const [users, metrics] = await Promise.all([
                getLookupOptions({ objectApiName: 'User' }),
                getLookupOptions({ objectApiName: 'KPI_Metric__c' })
            ]);
            this.userOptions = (users || []).map(u => ({ label: u.label, value: u.value }));
            this.metricOptions = [{ label: '-- None --', value: '' }]
                .concat((metrics || []).map(m => ({ label: m.label, value: m.value })));
        } catch (e) {
            this.toast('Error', this.msg(e), 'error');
        }
    }

    // ----- views -----
    get isList() { return this.view === 'list'; }
    get isWizard() { return this.view === 'wizard'; }
    get isKpis() { return this.view === 'kpis'; }
    get hasGames() { return this.games && this.games.length > 0; }
    get hasKpis() { return this.kpiRows && this.kpiRows.length > 0; }

    handleManageKpis() { this.view = 'kpis'; this.kpiSubView = 'list'; }
    handleBackToList() { this.view = 'list'; }

    // ----- KPI form -----
    get isKpiList() { return this.kpiSubView === 'list'; }
    get isKpiForm() { return this.kpiSubView === 'form'; }
    get kpiFormTitle() { return this.kpiForm.Id ? 'Edit Battleground KPI' : 'New Battleground KPI'; }
    get categoryOptions() { return P('Qualifier', 'Discipline', 'Coverage', 'Sales'); }
    get frequencyOptions() { return P('Daily', 'Weekly', 'Monthly', 'Journey Cycle'); }
    get objectiveOptions() { return P('Sales', 'Coverage', 'Discipline', 'Quality', 'Other'); }
    get calculationOptions() { return P('App', 'Query'); }
    get measureOptions() { return P('Number', 'Decimal', 'Percent', 'Currency', 'Duration'); }
    get kpiTypeOptions() { return P('Positive', 'Negative'); }
    get tierOptions() { return P('Basic', 'Advanced'); }
    get kpiSaveLabel() { return this.savingKpi ? 'Saving...' : 'Save KPI'; }

    handleNewKpi() { this.kpiForm = { ...EMPTY_KPI }; this.kpiSubView = 'form'; }
    handleKpiRowAction(event) {
        if (event.detail.action.name === 'edit') {
            const r = event.detail.row;
            this.kpiForm = { ...EMPTY_KPI, ...r };
            this.kpiSubView = 'form';
        }
    }
    handleKpiCancel() { this.kpiSubView = 'list'; }
    handleKpiField(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.detail.value;
        this.kpiForm = { ...this.kpiForm, [field]: value };
    }

    async handleKpiSave() {
        if (!this.kpiForm.Name) { this.toast('Required', 'Enter a KPI name.', 'warning'); return; }
        if (!this.kpiForm.Category__c) { this.toast('Required', 'Select a category.', 'warning'); return; }
        const rec = { ...this.kpiForm };
        if (!rec.Id) { delete rec.Id; }
        if (rec.Sequence__c === '' || rec.Sequence__c === null) { delete rec.Sequence__c; }
        else { rec.Sequence__c = Number(rec.Sequence__c); }
        if (!rec.KPI_Metric__c) { delete rec.KPI_Metric__c; }
        this.savingKpi = true;
        try {
            await saveKpis({ records: [rec] });
            this.toast('Saved', 'KPI "' + this.kpiForm.Name + '" saved.', 'success');
            this.kpiSubView = 'list';
            await refreshApex(this._wiredKpis);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        } finally {
            this.savingKpi = false;
        }
    }

    // ----- game wizard -----
    handleNewGame() { this.resetWizard(); this.view = 'wizard'; }
    handleCancel() { this.view = 'list'; }

    resetWizard() {
        this.step = 1;
        this.gameName = '';
        this.startDate = null;
        this.endDate = null;
        this.isActive = true;
        this.teamName = '';
        this.selectedUserIds = [];
        this.selectedKpiIds = [];
        this.awardRows = [];
    }

    get isStep1() { return this.step === 1; }
    get isStep2() { return this.step === 2; }
    get isStep3() { return this.step === 3; }
    get isStep4() { return this.step === 4; }
    get showBack() { return this.step > 1; }
    get isLastStep() { return this.step === 4; }
    get stepLabel() { return ['Game & Team', 'Select KPIs', 'Awards', 'Review & Save'][this.step - 1]; }

    handleField(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    }
    handleUsers(event) { this.selectedUserIds = event.detail.value; }
    handleKpis(event) { this.selectedKpiIds = event.detail.value; }
    handleAward(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const row = this.awardRows.find(r => r.kpiId === id);
        if (row) { row[field] = event.target.value; }
    }

    handleBack() { if (this.step > 1) { this.step -= 1; } }
    handleNext() {
        if (this.step === 1 && !this.gameName) { this.toast('Required', 'Enter a game name.', 'warning'); return; }
        if (this.step === 2) {
            if (!this.selectedKpiIds.length) { this.toast('Required', 'Select at least one KPI.', 'warning'); return; }
            this.buildAwardRows();
        }
        if (this.step < 4) { this.step += 1; }
    }

    buildAwardRows() {
        const existing = {};
        this.awardRows.forEach(r => { existing[r.kpiId] = r; });
        this.awardRows = this.selectedKpiIds.map(id => {
            const prev = existing[id] || {};
            const meta = this.kpiMeta[id] || {};
            return {
                kpiId: id,
                kpiName: meta.name || id,
                category: meta.category || '',
                target: prev.target || null,
                points: prev.points || null,
                reward: prev.reward || ''
            };
        });
    }

    get reviewSummary() { return { users: this.selectedUserIds.length, kpis: this.selectedKpiIds.length }; }

    async handleSave() {
        const payload = {
            gameName: this.gameName,
            startDate: this.startDate || null,
            endDate: this.endDate || null,
            isActive: this.isActive,
            teamName: this.teamName,
            userIds: this.selectedUserIds,
            kpis: this.awardRows.map(r => ({
                kpiId: r.kpiId,
                category: r.category,
                target: r.target ? Number(r.target) : null,
                points: r.points ? Number(r.points) : null,
                reward: r.reward
            }))
        };
        try {
            await saveGameWizard({ wiz: payload });
            this.toast('Saved', 'Game "' + this.gameName + '" created.', 'success');
            this.view = 'list';
            await refreshApex(this._wiredGames);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        }
    }

    toast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
    msg(e) {
        if (e && e.body && e.body.message) { return e.body.message; }
        if (e && e.message) { return e.message; }
        return 'Unknown error';
    }
}
