import { LightningElement, api } from 'lwc';

/** A single KPI tile used on the Home dashboard. */
export default class DmsKpiCard extends LightningElement {
    @api label;
    @api value;
    @api delta;
    @api icon = 'utility:chart';
    @api positive = false;

    get deltaClass() {
        return this.positive ? 'dms-kpi__delta dms-kpi__delta_up' : 'dms-kpi__delta dms-kpi__delta_down';
    }
}
