import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGames from '@salesforce/apex/GAM_Battleground_Controller.getGames';
import getKpis from '@salesforce/apex/GAM_Battleground_Controller.getKpis';
import saveKpis from '@salesforce/apex/GAM_Battleground_Controller.saveKpis';
import getTeams from '@salesforce/apex/GAM_Battleground_Controller.getTeams';
import getTeamMemberIds from '@salesforce/apex/GAM_Battleground_Controller.getTeamMemberIds';
import saveTeamWithMembers from '@salesforce/apex/GAM_Battleground_Controller.saveTeamWithMembers';
import getLookupOptions from '@salesforce/apex/GAM_Battleground_Controller.getLookupOptions';
import saveGameWizard from '@salesforce/apex/GAM_Battleground_Controller.saveGameWizard';
import getGameForEdit from '@salesforce/apex/GAM_Battleground_Controller.getGameForEdit';
import recalculate from '@salesforce/apex/GAM_Battleground_Controller.recalculate';

const P = (...v) => v.map(x => ({ label: x, value: x }));

const CATEGORIES = [
    { key: 'Qualifier', label: 'Qualifiers' },
    { key: 'Discipline', label: 'Discipline' },
    { key: 'Coverage', label: 'Coverage' },
    { key: 'Sales', label: 'Sales' }
];

const GAME_COLUMNS = [
    { label: 'Game', fieldName: 'Name' },
    { label: 'Type', fieldName: 'Type__c' },
    { label: 'Start', fieldName: 'Start_Date__c', type: 'date-local' },
    { label: 'End', fieldName: 'End_Date__c', type: 'date-local' },
    { label: 'Status', fieldName: 'statusLabel' },
    { type: 'action', typeAttributes: { rowActions: [{ label: 'Edit', name: 'edit' }] } }
];

const TEAM_COLUMNS = [
    { label: 'Team', fieldName: 'Name' },
    { label: 'Code', fieldName: 'Team_Code__c' },
    { label: 'Level', fieldName: 'Level__c' },
    { label: 'State', fieldName: 'State__c' },
    { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean' },
    { type: 'action', typeAttributes: { rowActions: [{ label: 'Edit', name: 'edit' }] } }
];

const KPI_LIST_COLUMNS = [
    { label: 'KPI Name', fieldName: 'Name' },
    { label: 'Category', fieldName: 'Category__c' },
    { label: 'Frequency', fieldName: 'Frequency__c' },
    { label: 'Measure', fieldName: 'Measure__c' },
    { label: 'Qualifier', fieldName: 'Is_Qualifier__c', type: 'boolean' },
    { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean' },
    { type: 'action', typeAttributes: { rowActions: [{ label: 'Edit', name: 'edit' }] } }
];

const EMPTY_KPI = {
    Id: null, Name: '', UI_Name__c: '', Category__c: '', Frequency__c: '', Objective__c: '',
    Calculation__c: '', Measure__c: '', KPI_Type__c: '', Tier__c: '', Sequence__c: null,
    KPI_Metric__c: '', Description__c: '', Is_Qualifier__c: false, Is_Incentive__c: false, Is_Active__c: true
};

const EMPTY_TEAM = {
    Id: null, Name: '', Team_Code__c: '', Level__c: '', State__c: '', Is_Active__c: true
};

export default class GameBuilder extends LightningElement {
    gameColumns = GAME_COLUMNS;
    teamColumns = TEAM_COLUMNS;
    kpiListColumns = KPI_LIST_COLUMNS;

    @track games = [];
    @track kpiRows = [];
    @track teamRows = [];
    @track userOptions = [];
    @track metricOptions = [];
    kpiById = {};
    _wiredGames;
    _wiredKpis;
    _wiredTeams;

    @track view = 'list';

    // ----- KPI management -----
    @track kpiSubView = 'list';
    @track kpiForm = { ...EMPTY_KPI };
    @track savingKpi = false;

    // ----- Team management -----
    @track teamSubView = 'list';
    @track teamForm = { ...EMPTY_TEAM };
    @track teamMemberIds = [];
    @track savingTeam = false;

    // ----- Game wizard -----
    @track editGameId = null;
    @track step = 1;
    @track gameName = '';
    @track gameType = 'Daily';
    @track startDate;
    @track endDate;
    @track isActive = true;
    @track selectedTeamIds = [];
    @track selectedKpiIds = [];
    @track kpiParams = {};
    @track catSearch = {};
    @track saving = false;

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
            this.kpiById = {};
            result.data.forEach(k => { this.kpiById[k.Id] = k; });
        }
    }

    @wire(getTeams)
    wiredTeams(result) {
        this._wiredTeams = result;
        if (result.data) { this.teamRows = result.data; }
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

    // ===== top-level views =====
    get isList() { return this.view === 'list'; }
    get isTeams() { return this.view === 'teams'; }
    get isKpis() { return this.view === 'kpis'; }
    get isWizard() { return this.view === 'wizard'; }
    get hasGames() { return this.games && this.games.length > 0; }
    get hasKpis() { return this.kpiRows && this.kpiRows.length > 0; }
    get hasTeams() { return this.teamRows && this.teamRows.length > 0; }

    handleManageTeams() { this.view = 'teams'; this.teamSubView = 'list'; }
    handleManageKpis() { this.view = 'kpis'; this.kpiSubView = 'list'; }
    handleBackToList() { this.view = 'list'; }

    async handleRecalcAll() {
        try {
            await recalculate({ userId: null });
            this.toast('Scoring started', 'Scores recalculated for all team members.', 'success');
        } catch (e) {
            this.toast('Failed', this.msg(e), 'error');
        }
    }

    // ===== Teams area =====
    get isTeamList() { return this.teamSubView === 'list'; }
    get isTeamForm() { return this.teamSubView === 'form'; }
    get teamFormTitle() { return this.teamForm.Id ? 'Edit Team' : 'New Team'; }
    get levelOptions() { return P('L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8'); }
    get teamSaveLabel() { return this.savingTeam ? 'Saving...' : 'Save Team'; }

    handleNewTeam() { this.teamForm = { ...EMPTY_TEAM }; this.teamMemberIds = []; this.teamSubView = 'form'; }
    async handleTeamRowAction(event) {
        if (event.detail.action.name === 'edit') {
            const r = event.detail.row;
            this.teamForm = { ...EMPTY_TEAM, ...r };
            this.teamSubView = 'form';
            try {
                this.teamMemberIds = await getTeamMemberIds({ teamId: r.Id });
            } catch (e) {
                this.teamMemberIds = [];
            }
        }
    }
    handleTeamCancel() { this.teamSubView = 'list'; }
    handleTeamField(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.detail.value;
        this.teamForm = { ...this.teamForm, [field]: value };
    }
    handleTeamUsers(event) { this.teamMemberIds = event.detail.value; }

    async handleTeamSave() {
        if (!this.teamForm.Name) { this.toast('Required', 'Enter a team name.', 'warning'); return; }
        const rec = { ...this.teamForm };
        if (!rec.Id) { delete rec.Id; }
        if (!rec.Level__c) { delete rec.Level__c; }
        this.savingTeam = true;
        try {
            await saveTeamWithMembers({ team: rec, memberIds: this.teamMemberIds });
            this.toast('Saved', 'Team "' + this.teamForm.Name + '" saved.', 'success');
            this.teamSubView = 'list';
            await refreshApex(this._wiredTeams);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        } finally {
            this.savingTeam = false;
        }
    }

    // ===== KPI management =====
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

    // ===== Game wizard =====
    handleNewGame() { this.resetWizard(); this.view = 'wizard'; }
    handleCancel() { this.view = 'list'; }

    get wizardTitle() { return this.editGameId ? 'Edit Game' : 'Create Game'; }

    async handleGameRowAction(event) {
        if (event.detail.action.name !== 'edit') { return; }
        this.resetWizard();
        try {
            const w = await getGameForEdit({ gameId: event.detail.row.Id });
            this.editGameId = w.gameId;
            this.gameName = w.gameName || '';
            this.gameType = w.gameType || 'Daily';
            this.startDate = w.startDate || null;
            this.endDate = w.endDate || null;
            this.isActive = w.isActive !== false;
            this.selectedTeamIds = (w.teamIds || []).slice();
            const ids = [];
            const params = {};
            (w.kpis || []).forEach(ka => {
                ids.push(ka.kpiId);
                const slabs = (ka.slabs && ka.slabs.length)
                    ? ka.slabs.map(s => ({ target: s.target, coins: s.coins }))
                    : [{ target: null, coins: null }];
                params[ka.kpiId] = {
                    isQualifier: ka.isQualifier === true,
                    useSlabs: ka.useSlabs === true,
                    isContinuous: ka.isContinuous === true,
                    criteria: ka.criteria || 'At least',
                    measure: ka.measure || '',
                    reward: ka.reward || '',
                    slabs
                };
            });
            this.selectedKpiIds = ids;
            this.kpiParams = params;
            this.view = 'wizard';
        } catch (e) {
            this.toast('Could not open game', this.msg(e), 'error');
        }
    }

    resetWizard() {
        this.editGameId = null;
        this.step = 1;
        this.gameName = '';
        this.gameType = 'Daily';
        this.startDate = null;
        this.endDate = null;
        this.isActive = true;
        this.selectedTeamIds = [];
        this.selectedKpiIds = [];
        this.kpiParams = {};
        this.catSearch = {};
    }

    get gameTypeOptions() { return P('Daily', 'Monthly'); }
    get isStep1() { return this.step === 1; }
    get isStep2() { return this.step === 2; }
    get isStep3() { return this.step === 3; }
    get isStep4() { return this.step === 4; }
    get isStep5() { return this.step === 5; }
    get showBack() { return this.step > 1; }
    get isLastStep() { return this.step === 5; }
    get saveLabel() { return this.saving ? 'Saving...' : 'Save Game'; }
    get stepLabel() {
        return ['Game', 'Teams', 'KPIs', 'Parameters', 'Review'][this.step - 1];
    }

    handleField(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
    }
    handleGameType(event) { this.gameType = event.detail.value; }

    // ----- step 2: teams (checkbox list) -----
    get teamChecks() {
        return (this.teamRows || []).map(t => ({
            id: t.Id,
            name: t.Name,
            sub: [t.Team_Code__c, t.Level__c, t.State__c].filter(Boolean).join(' · '),
            checked: this.selectedTeamIds.includes(t.Id)
        }));
    }
    handleTeamCheck(event) {
        const id = event.target.dataset.id;
        const set = new Set(this.selectedTeamIds);
        if (event.target.checked) { set.add(id); } else { set.delete(id); }
        this.selectedTeamIds = [...set];
    }

    // ----- step 3: KPI category columns -----
    get kpiColumns() {
        return CATEGORIES.map(c => {
            const q = (this.catSearch[c.key] || '').toLowerCase();
            const items = (this.kpiRows || [])
                .filter(k => (k.Category__c || 'Sales') === c.key && k.Is_Active__c !== false)
                .filter(k => !q
                    || (k.Name || '').toLowerCase().includes(q)
                    || (k.UI_Name__c || '').toLowerCase().includes(q))
                .map(k => ({
                    id: k.Id,
                    name: k.UI_Name__c || k.Name,
                    sub: k.Frequency__c || '',
                    checked: this.selectedKpiIds.includes(k.Id)
                }));
            return { key: c.key, label: c.label, items, count: items.length, hasItems: items.length > 0 };
        });
    }
    handleCatSearch(event) {
        const cat = event.target.dataset.cat;
        this.catSearch = { ...this.catSearch, [cat]: event.target.value };
    }
    handleKpiCheck(event) {
        const id = event.target.dataset.id;
        const set = new Set(this.selectedKpiIds);
        if (event.target.checked) {
            set.add(id);
            this.ensureParam(id);
        } else {
            set.delete(id);
            delete this.kpiParams[id];
            this.kpiParams = { ...this.kpiParams };
        }
        this.selectedKpiIds = [...set];
    }

    get criteriaOptions() {
        return [
            { label: 'At least (>=)', value: 'At least' },
            { label: 'Greater than (>)', value: 'Greater than' },
            { label: 'At most (<=)', value: 'At most' },
            { label: 'Less than (<)', value: 'Less than' },
            { label: 'Equal to (=)', value: 'Equal to' }
        ];
    }

    ensureParam(id) {
        if (this.kpiParams[id]) { return; }
        const k = this.kpiById[id] || {};
        const isQual = (k.Category__c === 'Qualifier') || k.Is_Qualifier__c === true;
        this.kpiParams = {
            ...this.kpiParams,
            [id]: {
                isQualifier: isQual,
                useSlabs: false,
                isContinuous: false,
                criteria: 'At least',
                measure: k.Measure__c || '',
                reward: '',
                slabs: [{ target: null, coins: null }]
            }
        };
    }

    // ----- step 4: parameter cards -----
    get kpiParamCards() {
        return this.selectedKpiIds.map(id => {
            const k = this.kpiById[id] || {};
            const p = this.kpiParams[id] || { slabs: [{}] };
            const slabList = p.useSlabs ? p.slabs : p.slabs.slice(0, 1);
            return {
                id,
                name: k.UI_Name__c || k.Name || id,
                category: k.Category__c || '',
                isQualifier: p.isQualifier,
                notQualifier: !p.isQualifier,
                useSlabs: p.useSlabs,
                isContinuous: p.isContinuous,
                criteria: p.criteria || 'At least',
                measure: p.measure,
                reward: p.reward,
                showAddSlab: p.useSlabs,
                slabs: slabList.map((s, i) => ({
                    idx: String(i),
                    key: id + '-' + i,
                    label: p.useSlabs ? ('Slab ' + (i + 1)) : 'Target',
                    target: s.target,
                    coins: s.coins,
                    canRemove: p.useSlabs && p.slabs.length > 1
                }))
            };
        });
    }

    handleParamToggle(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const p = this.kpiParams[id];
        if (!p) { return; }
        p[field] = event.target.checked;
        if (field === 'useSlabs' && event.target.checked && p.slabs.length < 2) {
            p.slabs.push({ target: null, coins: null });
        }
        this.kpiParams = { ...this.kpiParams };
    }
    handleParamField(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const p = this.kpiParams[id];
        if (!p) { return; }
        p[field] = event.detail ? event.detail.value : event.target.value;
        this.kpiParams = { ...this.kpiParams };
    }
    handleSlabField(event) {
        const id = event.target.dataset.id;
        const idx = Number(event.target.dataset.idx);
        const field = event.target.dataset.field;
        const p = this.kpiParams[id];
        if (!p || !p.slabs[idx]) { return; }
        p.slabs[idx][field] = event.target.value;
        this.kpiParams = { ...this.kpiParams };
    }
    handleAddSlab(event) {
        const id = event.target.dataset.id;
        const p = this.kpiParams[id];
        if (!p) { return; }
        p.slabs.push({ target: null, coins: null });
        this.kpiParams = { ...this.kpiParams };
    }
    handleRemoveSlab(event) {
        const id = event.target.dataset.id;
        const idx = Number(event.target.dataset.idx);
        const p = this.kpiParams[id];
        if (!p || p.slabs.length <= 1) { return; }
        p.slabs.splice(idx, 1);
        this.kpiParams = { ...this.kpiParams };
    }

    // ----- navigation -----
    handleBack() { if (this.step > 1) { this.step -= 1; } }
    handleNext() {
        if (this.step === 1 && !this.gameName) { this.toast('Required', 'Enter a game name.', 'warning'); return; }
        if (this.step === 2 && !this.selectedTeamIds.length) { this.toast('Required', 'Select at least one team.', 'warning'); return; }
        if (this.step === 3 && !this.selectedKpiIds.length) { this.toast('Required', 'Select at least one KPI.', 'warning'); return; }
        if (this.step < 5) { this.step += 1; }
    }

    get reviewSummary() {
        return {
            type: this.gameType,
            teams: this.selectedTeamIds.length,
            kpis: this.selectedKpiIds.length
        };
    }

    async handleSave() {
        const num = v => (v !== null && v !== undefined && v !== '' ? Number(v) : null);
        const payload = {
            gameId: this.editGameId || null,
            gameName: this.gameName,
            startDate: this.startDate || null,
            endDate: this.endDate || null,
            gameType: this.gameType,
            isActive: this.isActive,
            teamIds: this.selectedTeamIds,
            kpis: this.selectedKpiIds.map(id => {
                const k = this.kpiById[id] || {};
                const p = this.kpiParams[id];
                const rawSlabs = p.useSlabs ? p.slabs : p.slabs.slice(0, 1);
                return {
                    kpiId: id,
                    category: k.Category__c,
                    measure: p.measure,
                    isQualifier: p.isQualifier,
                    useSlabs: p.useSlabs,
                    isContinuous: p.isContinuous,
                    criteria: p.criteria || 'At least',
                    reward: p.reward,
                    slabs: rawSlabs.map(s => ({
                        target: num(s.target),
                        coins: p.isQualifier ? null : num(s.coins)
                    }))
                };
            })
        };
        this.saving = true;
        try {
            await saveGameWizard({ wiz: payload });
            this.toast('Saved', 'Game "' + this.gameName + '" ' + (this.editGameId ? 'updated.' : 'created.'), 'success');
            this.view = 'list';
            await refreshApex(this._wiredGames);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        } finally {
            this.saving = false;
        }
    }

    toast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
    msg(e) {
        if (e && e.body && e.body.message) { return e.body.message; }
        if (e && e.message) { return e.message; }
        return 'Unknown error';
    }
}
