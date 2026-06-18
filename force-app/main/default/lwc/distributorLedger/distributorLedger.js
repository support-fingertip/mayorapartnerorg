import { LightningElement, wire } from 'lwc';
import getLedger from '@salesforce/apex/DMS_PortalController.getLedger';
import getAging from '@salesforce/apex/DMS_PortalController.getAging';

const COLUMNS = [
    { label: 'Date', fieldName: 'Entry_Date__c', type: 'date' },
    { label: 'Type', fieldName: 'Entry_Type__c' },
    { label: 'Amount', fieldName: 'Amount__c', type: 'currency' },
    { label: 'Reference', fieldName: 'Reference_Number__c' },
    { label: 'Description', fieldName: 'Description__c' }
];

const BUCKET_KEYS = ['Current', '1-30', '31-60', '61-90', '90+'];

export default class DistributorLedger extends LightningElement {
    columns = COLUMNS;
    rows = [];
    buckets = [];
    error;

    @wire(getLedger)
    wiredLedger({ data, error }) {
        if (data) { this.rows = data; }
        else if (error) { this.error = (error.body && error.body.message) || 'Unable to load ledger.'; }
    }

    @wire(getAging)
    wiredAging({ data, error }) {
        if (data) {
            this.buckets = BUCKET_KEYS.map((k) => ({ label: k, value: data[k] || 0 }));
        } else if (error) {
            this.error = (error.body && error.body.message) || 'Unable to load aging.';
        }
    }

    get hasRows() { return this.rows && this.rows.length > 0; }
}