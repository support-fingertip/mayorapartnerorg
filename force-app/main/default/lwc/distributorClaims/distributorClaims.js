import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getClaims from '@salesforce/apex/DMS_PortalController.getClaims';
import submitClaim from '@salesforce/apex/DMS_PortalController.submitClaim';

const COLUMNS = [
    { label: 'Claim #', fieldName: 'Name' },
    { label: 'Type', fieldName: 'Claim_Type__c' },
    { label: 'Date', fieldName: 'Claim_Date__c', type: 'date' },
    { label: 'Amount', fieldName: 'Total_Amount__c', type: 'currency' },
    { label: 'Approved', fieldName: 'Approved_Amount__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Credit Note', fieldName: 'Credit_Note_Number__c' }
];

const TYPE_OPTIONS = ['Scheme Claim', 'Damage Claim', 'Expiry Claim', 'Rate Difference', 'Other']
    .map((t) => ({ label: t, value: t }));

export default class DistributorClaims extends LightningElement {
    columns = COLUMNS;
    rows = [];
    wiredClaims;
    typeOptions = TYPE_OPTIONS;
    claimType = 'Scheme Claim';
    amount;
    notes;
    submitting = false;
    error;

    @wire(getClaims)
    wired(result) {
        this.wiredClaims = result;
        if (result.data) { this.rows = result.data; }
        else if (result.error) { this.error = this.msg(result.error); }
    }

    handleType(e) { this.claimType = e.detail.value; }
    handleAmount(e) { this.amount = e.detail.value; }
    handleNotes(e) { this.notes = e.detail.value; }

    get hasRows() { return this.rows && this.rows.length > 0; }
    get isSubmitDisabled() { return !this.amount || Number(this.amount) <= 0 || this.submitting; }

    async submit() {
        this.submitting = true;
        try {
            await submitClaim({ claimType: this.claimType, amount: Number(this.amount), notes: this.notes });
            this.toast('Claim submitted', 'Your claim was submitted for review.', 'success');
            this.amount = undefined; this.notes = undefined;
            await refreshApex(this.wiredClaims);
        } catch (e) {
            this.toast('Could not submit claim', this.msg(e), 'error');
        } finally {
            this.submitting = false;
        }
    }

    msg(e) { return (e && e.body && e.body.message) || 'Unexpected error.'; }
    toast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
}