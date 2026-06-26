import { LightningElement, api, track } from 'lwc';

/**
 * Reusable bulk data-entry grid. Renders an editable table from a column config,
 * lets the user add/remove rows and edit cells inline (text/number/date/checkbox/
 * picklist/lookup), and emits a `save` event with all rows for a bulk upsert.
 */
export default class BulkEntryGrid extends LightningElement {
    @api title = 'Records';
    @track rows = [];

    _columns = [];
    @api
    get columns() { return this._columns; }
    set columns(value) { this._columns = value || []; this.rebuild(); }

    _records = [];
    @api
    get records() { return this._records; }
    set records(value) { this._records = value || []; this.rebuild(); }

    rebuild() {
        if (!this._columns || this._columns.length === 0) { return; }
        this.rows = (this._records || []).map((r, i) => this.decorate({ ...r }, i));
    }

    decorate(row, index) {
        if (!row._key) {
            row._key = row.Id || ('new-' + index + '-' + Math.floor(Math.random() * 1000000));
        }
        row._cells = this._columns.map(c => ({
            field: c.field,
            value: row[c.field],
            checked: c.type === 'checkbox' ? !!row[c.field] : false,
            options: c.options || [],
            isText: !c.type || c.type === 'text',
            isNumber: c.type === 'number',
            isDate: c.type === 'date',
            isCheckbox: c.type === 'checkbox',
            isPicklist: c.type === 'picklist' || c.type === 'lookup'
        }));
        return row;
    }

    get headerCells() { return (this._columns || []).map(c => ({ key: c.field, label: c.label })); }
    get hasColumns() { return this._columns && this._columns.length > 0; }

    handleChange(event) {
        const key = event.target.dataset.key;
        const field = event.target.dataset.field;
        const type = event.target.dataset.type;
        const value = type === 'checkbox' ? event.target.checked : event.target.value;
        const row = this.rows.find(r => r._key === key);
        if (!row) { return; }
        row[field] = value;
        const cell = row._cells.find(c => c.field === field);
        if (cell) {
            cell.value = value;
            if (type === 'checkbox') { cell.checked = value; }
        }
    }

    handleAddRow() {
        this.rows = [...this.rows, this.decorate({}, this.rows.length)];
    }

    handleRemoveRow(event) {
        const key = event.target.dataset.key;
        this.rows = this.rows.filter(r => r._key !== key);
    }

    handleSave() {
        const clean = this.rows.map(r => {
            const out = {};
            this._columns.forEach(c => {
                let v = r[c.field];
                if (v === undefined || v === null || v === '') { return; }
                if (c.type === 'number') { v = Number(v); }
                if (c.type === 'checkbox') { v = !!v; }
                out[c.field] = v;
            });
            if (r.Id) { out.Id = r.Id; }
            return out;
        }).filter(o => Object.keys(o).length > 0);
        this.dispatchEvent(new CustomEvent('save', { detail: { rows: clean } }));
    }
}
