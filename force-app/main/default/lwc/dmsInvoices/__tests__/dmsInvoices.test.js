import { createElement } from 'lwc';
import DmsInvoices from 'c/dmsInvoices';

const flush = () => Promise.resolve();

describe('c-dms-invoices', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders primary invoices with GRN summary chips', () => {
        const element = createElement('c-dms-invoices', { is: DmsInvoices });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_primary .dms-trow').length).toBe(5);
        expect(element.shadowRoot.querySelectorAll('.dms-chip').length).toBe(3);
    });

    it('switches to secondary invoices and shows the New Invoice button', async () => {
        const element = createElement('c-dms-invoices', { is: DmsInvoices });
        document.body.appendChild(element);

        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.tab === 'secondary')
            .click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_secondary .dms-trow').length).toBe(4);
        expect(element.shadowRoot.querySelector('.dms-btn')).not.toBeNull();
    });

    it('runs the Create Invoice wizard through customer and order selection', async () => {
        const element = createElement('c-dms-invoices', { is: DmsInvoices });
        document.body.appendChild(element);

        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.tab === 'secondary')
            .click();
        await flush();

        element.shadowRoot.querySelector('.dms-btn').click(); // New Invoice
        await flush();

        expect(element.shadowRoot.querySelector('.dms-wizard')).not.toBeNull();

        // step 1: pick a customer, then Next (2nd footer button)
        element.shadowRoot.querySelector('.dms-custrow[data-name="ABC Mart"]').click();
        await flush();
        element.shadowRoot.querySelectorAll('.dms-wizard__foot .dms-btn')[1].click();
        await flush();

        // step 2: ABC Mart has 2 orders
        const orders = element.shadowRoot.querySelectorAll('.dms-ordrow');
        expect(orders.length).toBe(2);

        orders[0].click(); // select SO-6432
        orders[1].click(); // select SO-6418
        await flush();
        expect(element.shadowRoot.querySelector('.dms-wizard__count').textContent).toBe('2 selected');

        // step 3: review aggregated lines (5 distinct products) + total
        element.shadowRoot.querySelectorAll('.dms-wizard__foot .dms-btn')[1].click();
        await flush();
        expect(element.shadowRoot.querySelectorAll('.dms-tbl_review .dms-trow').length).toBe(5);
        expect(element.shadowRoot.querySelector('.dms-invtotal__value').textContent).toContain(
            '15,456'
        );

        // Generate Invoice -> success modal
        element.shadowRoot.querySelectorAll('.dms-wizard__foot .dms-btn')[1].click();
        await flush();
        expect(element.shadowRoot.querySelector('.dms-modal__title').textContent).toBe(
            'Invoice Generated'
        );
    });

    it('disables Next until a customer is selected', async () => {
        const element = createElement('c-dms-invoices', { is: DmsInvoices });
        document.body.appendChild(element);

        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.tab === 'secondary')
            .click();
        await flush();
        element.shadowRoot.querySelector('.dms-btn').click();
        await flush();

        const next = element.shadowRoot.querySelectorAll('.dms-wizard__foot .dms-btn')[1];
        expect(next.disabled).toBe(true);
    });
});
