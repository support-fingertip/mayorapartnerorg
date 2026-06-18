import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTickets from '@salesforce/apex/DMS_PortalController.getTickets';
import raiseTicket from '@salesforce/apex/DMS_PortalController.raiseTicket';

const COLUMNS = [
    { label: 'Subject', fieldName: 'Subject__c' },
    { label: 'Category', fieldName: 'Category__c' },
    { label: 'Priority', fieldName: 'Priority__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Date', fieldName: 'Ticket_Date__c', type: 'date' }
];

const CATEGORY_OPTIONS = ['Product Quality', 'Delivery Issue', 'Pricing Dispute', 'Service Request', 'Scheme Claim', 'Other']
    .map((c) => ({ label: c, value: c }));
const PRIORITY_OPTIONS = ['Low', 'Medium', 'High', 'Critical'].map((p) => ({ label: p, value: p }));

export default class DistributorTickets extends LightningElement {
    columns = COLUMNS;
    rows = [];
    wiredTickets;
    categoryOptions = CATEGORY_OPTIONS;
    priorityOptions = PRIORITY_OPTIONS;
    subject;
    description;
    category = 'Service Request';
    priority = 'Medium';
    submitting = false;
    error;

    @wire(getTickets)
    wired(result) {
        this.wiredTickets = result;
        if (result.data) { this.rows = result.data; }
        else if (result.error) { this.error = this.msg(result.error); }
    }

    handleSubject(e) { this.subject = e.detail.value; }
    handleDescription(e) { this.description = e.detail.value; }
    handleCategory(e) { this.category = e.detail.value; }
    handlePriority(e) { this.priority = e.detail.value; }

    get hasRows() { return this.rows && this.rows.length > 0; }
    get isSubmitDisabled() { return !this.subject || this.submitting; }

    async submit() {
        this.submitting = true;
        try {
            await raiseTicket({ subject: this.subject, description: this.description, category: this.category, priority: this.priority });
            this.toast('Ticket raised', 'Your support ticket was created.', 'success');
            this.subject = undefined; this.description = undefined;
            await refreshApex(this.wiredTickets);
        } catch (e) {
            this.toast('Could not raise ticket', this.msg(e), 'error');
        } finally {
            this.submitting = false;
        }
    }

    msg(e) { return (e && e.body && e.body.message) || 'Unexpected error.'; }
    toast(title, message, variant) { this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
}