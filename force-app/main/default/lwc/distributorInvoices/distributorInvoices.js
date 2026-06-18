import { LightningElement, wire } from 'lwc';
import getInvoices from '@salesforce/apex/DMS_PortalController.getInvoices';

const COLUMNS = [
    { label: 'Invoice #', fieldName: 'Invoice_Number__c' },
    { label: 'Date', fieldName: 'Invoice_Date__c', type: 'date' },
    { label: 'Type', fieldName: 'Order_Type__c' },
    { label: 'Total', fieldName: 'Total_Amount__c', type: 'currency' },
    { label: 'Balance Due', fieldName: 'Balance_Due__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c' }
];

export default class DistributorInvoices extends LightningElement {
    columns = COLUMNS;
    rows = [];
    error;

    @wire(getInvoices)
    wired({ data, error }) {
        if (data) { this.rows = data; this.error = undefined; }
        else if (error) { this.error = (error.body && error.body.message) || 'Unable to load invoices.'; }
    }

    get hasRows() { return this.rows && this.rows.length > 0; }
}