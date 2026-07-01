import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTargets from '@salesforce/apex/TAM_TargetVsActuals_Controller.getTargets';
import getOptions from '@salesforce/apex/TAM_TargetVsActuals_Controller.getOptions';
import saveTarget from '@salesforce/apex/TAM_TargetVsActuals_Controller.saveTarget';
import recalc from '@salesforce/apex/TAM_TargetVsActuals_Controller.recalc';
import recalcAll from '@salesforce/apex/TAM_TargetVsActuals_Controller.recalcAll';

const P = (...v) => v.map(x => ({ label: x, value: x }));

// Tier -> Account Customer_Type filter (SS/SB/DB are Accounts; Secondary = user)
const TIER_ACCTYPE = {
    P1: 'Distributor',
    P2: 'Sub Distributor',
    Outlet: 'Outlet'
};

const COLUMNS = [
    { label: 'Tier', fieldName: 'Tier__c', fixedWidth: 90 },
    { label: 'Target For', fieldName: 'targetFor' },
    { label: 'Product', fieldName: 'productLabel' },
    { label: 'KPI', fieldName: 'kpiName' },
    { label: 'Type', fieldName: 'Target_Type__c', fixedWidth: 100 },
    { label: 'Target', fieldName: 'Target_Value__c', type: 'number', fixedWidth: 100 },
    { label: 'Actual', fieldName: 'Achievement_Value__c', type: 'number', fixedWidth: 100 },
    { label: '%', fieldName: 'Achievement_Percent__c', type: 'number', fixedWidth: 80 },
    { label: 'Status', fieldName: 'Status__c', fixedWidth: 100 },
    { type: 'action', typeAttributes: { rowActions: [
        { label: 'Edit', name: 'edit' },
        { label: 'Recalculate', name: 'recalc' }
    ] } }
];

const EMPTY = {
    Id: null, Tier__c: 'P1', Target_Type__c: 'Revenue', Target_Product_Level__c: 'Brand',
    Customer__c: '', User__c: '', Product_Ext__c: '', KPI__c: '', JC__c: '',
    Brand__c: '', Sub_Brand__c: '', Brand_Alias__c: '',
    Target_Value__c: null, Status__c: 'Active', Period_Start__c: null, Period_End__c: null
};

export default class TargetVsActuals extends LightningElement {
    columns = COLUMNS;
    @track rows = [];
    @track view = 'list';
    @track form = { ...EMPTY };
    @track saving = false;
    _wired;

    @track customerOptions = [];
    @track userOptions = [];
    @track kpiOptions = [];
    @track productOptions = [];
    @track periodOptions = [];

    @wire(getTargets)
    wiredTargets(result) {
        this._wired = result;
        if (result.data) {
            this.rows = result.data.map(t => ({
                ...t,
                targetFor: t.Customer__r ? t.Customer__r.Name : (t.User__r ? t.User__r.Name : ''),
                productLabel: t.Product_Ext__r ? t.Product_Ext__r.Name
                    : (t.Brand_Alias__c || t.Sub_Brand__c || t.Brand__c || t.Target_Product_Level__c || ''),
                kpiName: t.KPI__r ? t.KPI__r.Name : ''
            }));
        }
    }

    // ----- options -----
    get tierOptions() { return P('P1', 'P2', 'Secondary', 'Outlet'); }
    get targetTypeOptions() { return P('Revenue', 'Volume', 'Collection', 'Productive Calls', 'New Outlets'); }
    get levelOptions() { return P('Brand', 'Sub Brand', 'Brand Alias', 'SKU'); }
    get statusOptions() { return P('Draft', 'Published', 'Active', 'Closed'); }

    // ----- view flags -----
    get isList() { return this.view === 'list'; }
    get isForm() { return this.view === 'form'; }
    get hasRows() { return this.rows && this.rows.length > 0; }
    get formTitle() { return this.form.Id ? 'Edit Target' : 'New Target'; }
    get saveLabel() { return this.saving ? 'Saving...' : 'Save Target'; }

    // tier-driven conditional fields
    get isSecondary() { return this.form.Tier__c === 'Secondary'; }
    get isCustomerTier() { return this.form.Tier__c !== 'Secondary'; }
    get customerLabel() {
        return { P1: 'Distributor (SS/DB)', P2: 'Sub Distributor', Outlet: 'Outlet' }[this.form.Tier__c] || 'Customer';
    }
    get isBrandLevel() { return this.form.Target_Product_Level__c === 'Brand'; }
    get isSubBrandLevel() { return this.form.Target_Product_Level__c === 'Sub Brand'; }
    get isAliasLevel() { return this.form.Target_Product_Level__c === 'Brand Alias'; }
    get isSkuLevel() { return this.form.Target_Product_Level__c === 'SKU'; }

    // ----- lifecycle -----
    async connectedCallback() {
        await Promise.all([this.loadUsers(), this.loadKpis(), this.loadProducts(), this.loadPeriods()]);
    }
    async loadUsers() { this.userOptions = await this.opts('User', null); }
    async loadKpis() { this.kpiOptions = await this.opts('KPI', null); }
    async loadProducts() { this.productOptions = await this.opts('Product', null); }
    async loadPeriods() {
        this.periodOptions = [{ label: '-- None --', value: '' }].concat(await this.opts('Period', null));
    }
    async loadCustomers() {
        const accType = TIER_ACCTYPE[this.form.Tier__c] || '';
        this.customerOptions = await this.opts('Account', accType);
    }
    async opts(kind, accType) {
        try {
            const r = await getOptions({ kind, accType, search: '' });
            return (r || []).map(o => ({ label: o.label, value: o.value }));
        } catch (e) { return []; }
    }

    // ----- actions -----
    handleNew() { this.form = { ...EMPTY }; this.loadCustomers(); this.view = 'form'; }
    handleBack() { this.view = 'list'; }

    async handleRowAction(event) {
        const action = event.detail.action.name;
        const row = event.detail.row;
        if (action === 'edit') {
            this.form = {
                ...EMPTY, ...row,
                Customer__c: row.Customer__c || '', User__c: row.User__c || '',
                Product_Ext__c: row.Product_Ext__c || '', KPI__c: row.KPI__c || '', JC__c: row.JC__c || ''
            };
            await this.loadCustomers();
            this.view = 'form';
        } else if (action === 'recalc') {
            await this.doRecalc(row.Id, row.Name || 'target');
        }
    }

    handleField(event) {
        const f = event.target.dataset.field;
        const v = event.target.type === 'checkbox' ? event.target.checked : event.detail.value;
        this.form = { ...this.form, [f]: v };
        if (f === 'Tier__c') { this.loadCustomers(); }
    }

    async handleSave() {
        if (!this.form.Tier__c) { this.toast('Required', 'Select a tier.', 'warning'); return; }
        if (this.isCustomerTier && !this.form.Customer__c) { this.toast('Required', 'Select a customer.', 'warning'); return; }
        if (this.isSecondary && !this.form.User__c) { this.toast('Required', 'Select a user.', 'warning'); return; }
        if (!this.form.Target_Value__c) { this.toast('Required', 'Enter a target value.', 'warning'); return; }

        const rec = { Tier__c: this.form.Tier__c, Target_Type__c: this.form.Target_Type__c,
            Target_Product_Level__c: this.form.Target_Product_Level__c, Status__c: this.form.Status__c,
            Target_Value__c: Number(this.form.Target_Value__c) };
        if (this.form.Id) { rec.Id = this.form.Id; }
        if (this.isCustomerTier) { rec.Customer__c = this.form.Customer__c; }
        if (this.isSecondary) { rec.User__c = this.form.User__c; }
        if (this.form.KPI__c) { rec.KPI__c = this.form.KPI__c; }
        if (this.form.JC__c) { rec.JC__c = this.form.JC__c; }
        if (this.form.Period_Start__c) { rec.Period_Start__c = this.form.Period_Start__c; }
        if (this.form.Period_End__c) { rec.Period_End__c = this.form.Period_End__c; }
        if (this.isBrandLevel) { rec.Brand__c = this.form.Brand__c; }
        if (this.isSubBrandLevel) { rec.Sub_Brand__c = this.form.Sub_Brand__c; }
        if (this.isAliasLevel) { rec.Brand_Alias__c = this.form.Brand_Alias__c; }
        if (this.isSkuLevel && this.form.Product_Ext__c) { rec.Product_Ext__c = this.form.Product_Ext__c; }

        this.saving = true;
        try {
            await saveTarget({ record: rec });
            this.toast('Saved', 'Target saved.', 'success');
            this.view = 'list';
            await refreshApex(this._wired);
        } catch (e) {
            this.toast('Save failed', this.msg(e), 'error');
        } finally {
            this.saving = false;
        }
    }

    async doRecalc(targetId, name) {
        try {
            await recalc({ targetId });
            this.toast('Recalculated', 'Actuals updated for ' + name + '.', 'success');
            await refreshApex(this._wired);
        } catch (e) {
            this.toast('Failed', this.msg(e), 'error');
        }
    }

    async handleRecalcAll() {
        try {
            await recalcAll();
            this.toast('Started', 'Recalculating all active targets in the background.', 'success');
        } catch (e) {
            this.toast('Failed', this.msg(e), 'error');
        }
    }

    toast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
    msg(e) {
        if (e && e.body && e.body.message) { return e.body.message; }
        if (e && e.message) { return e.message; }
        return 'Unknown error';
    }
}
