import { createElement } from 'lwc';
import DmsGrn from 'c/dmsGrn';

const flush = () => Promise.resolve();

describe('c-dms-grn', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the GRN list and summary chips', () => {
        const element = createElement('c-dms-grn', { is: DmsGrn });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_grn .dms-trow').length).toBe(4);
        // Total + Completed + Pending chips
        expect(element.shadowRoot.querySelectorAll('.dms-chip').length).toBe(3);
    });

    it('runs the Create GRN wizard and auto-creates a return for damaged qty', async () => {
        const element = createElement('c-dms-grn', { is: DmsGrn });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-btn').click(); // New GRN
        await flush();
        expect(element.shadowRoot.querySelector('.dms-wizard')).not.toBeNull();

        // both invoices pre-selected -> Next builds the item list (8 SKUs)
        element.shadowRoot.querySelectorAll('.dms-wizard__foot .dms-btn')[1].click();
        await flush();
        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_items .dms-trow');
        expect(rows.length).toBe(8);

        // enter damage qty 2 on first item
        const input = element.shadowRoot.querySelector('.dms-qtyinput');
        input.value = 2;
        input.dispatchEvent(new CustomEvent('change'));
        await flush();

        // Save GRN
        element.shadowRoot.querySelectorAll('.dms-wizard__foot .dms-btn')[1].click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-modal__title').textContent).toBe('GRN Saved');
        expect(element.shadowRoot.querySelector('.dms-returnbox')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.dms-returnbox__line').textContent).toContain(
            'Damaged'
        );
    });
});
