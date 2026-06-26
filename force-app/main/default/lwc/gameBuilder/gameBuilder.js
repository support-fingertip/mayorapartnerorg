import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGames from '@salesforce/apex/GAM_Battleground_Controller.getGames';
import getKpis from '@salesforce/apex/GAM_Battleground_Controller.getKpis';
import getLookupOptions from '@salesforce/apex/GAM_Battleground_Controller.getLookupOptions';
import saveGameWizard from '@salesforce/apex/GAM_Battleground_Controller.saveGameWizard';

const GAME_COLUMNS = [
    { label: 'Game', fieldName: 'Name' },
    { label: 'Start', fieldName: 'Start_Date__c', type: 'date-local' },
    { label: 'End', fieldName: 'End_Date__c', type: 'date-local' },
    { label: 'Status', fieldName: 'statusLabel' }
];

export default class GameBuilder extends LightningElement {
    gameColumns = GAME_COLUMNS;
    @track games = [];
    @track userOptions = [];
    @track kpiOptions = [];
    kpiMeta = {};
    _wiredGames;

    // wizard state
    @track view = 'list';
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
            this.games = result.data.map(g => ({
                ...g,
                statusLabel: g.Is_Active__c ? 'Active' : 'Inactive'
            }));
        }
    }

    connectedCallback() { this.loadOptions(); }

    async loadOptions() {
        try {
            const [users, kpis] = await Promise.all([
                getLookupOptions({ objectApiName: 'User' }),
                getKpis()
            ]);
            this.userOptions = (users || []).map(u => ({ label: u.label, value: u.value }));
            this.kpiOptions = (kpis || []).map(k => ({
                label: (k.Category__c ? k.Category__c + ' — ' : '') + k.Name,
                value: k.Id
            }));
            this.kpiMeta = {};
            (kpis || []).forEach(k => { this.kpiMeta[k.Id] = { name: k.Name, category: k.Category__c }; });
        } catch (e) {
            this.toast('Error', this.msg(e), 'error');
        }
    }

    // ----- list view -----
    get isList() { return this.view === 'list'; }
    get isWizard() { return this.view === 'wizard'; }
    get hasGames() { return this.games && this.games.length > 0; }

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

    // ----- step state -----
    get isStep1() { return this.step === 1; }
    get isStep2() { return this.step === 2; }
    get isStep3() { return this.step === 3; }
    get isStep4() { return this.step === 4; }
    get showBack() { return this.step > 1; }
    get isLastStep() { return this.step === 4; }
    get stepLabel() {
        return ['Game & Team', 'Select KPIs', 'Awards', 'Review & Save'][this.step - 1];
    }

    // ----- field handlers -----
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

    // ----- navigation -----
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

    get reviewSummary() {
        return {
            users: this.selectedUserIds.length,
            kpis: this.selectedKpiIds.length
        };
    }

    // ----- save -----
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
