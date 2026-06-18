import { createElement } from 'lwc';
import DmsCustomers from 'c/dmsCustomers';

const flush = () => Promise.resolve();

describe('c-dms-customers', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders 6 retailers with total chip', () => {
        const element = createElement('c-dms-customers', { is: DmsCustomers });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_cust .dms-trow').length).toBe(6);
        expect(element.shadowRoot.querySelector('.dms-chip__value').textContent).toBe('6');
    });

    it('switches to sub-distributors (3)', async () => {
        const element = createElement('c-dms-customers', { is: DmsCustomers });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('[data-tab="subdist"]').click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_cust .dms-trow').length).toBe(3);
        expect(element.shadowRoot.querySelector('.dms-chip__value').textContent).toBe('3');
    });

    it('opens the customer detail modal with inner tabs', async () => {
        const element = createElement('c-dms-customers', { is: DmsCustomers });
        document.body.appendChild(element);

        const view = [...element.shadowRoot.querySelectorAll('.dms-viewbtn')].find(
            (b) => b.dataset.code === 'RET-001'
        );
        view.click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-detail__id h2').textContent).toBe('ABC Mart');
        // Last 10 Orders default tab -> 5 rows for ABC Mart
        expect(element.shadowRoot.querySelectorAll('.dms-detail__body .dms-trow').length).toBe(5);

        // switch to Target vs Actual
        [...element.shadowRoot.querySelectorAll('.dms-itab')]
            .find((t) => t.dataset.id === 'target')
            .click();
        await flush();
        expect(element.shadowRoot.querySelectorAll('.dms-pct').length).toBe(3);
    });

    it('filters retailers by search', async () => {
        const element = createElement('c-dms-customers', { is: DmsCustomers });
        document.body.appendChild(element);

        const search = element.shadowRoot.querySelector('.dms-search');
        search.value = 'Andheri';
        search.dispatchEvent(new CustomEvent('change'));
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_cust .dms-trow').length).toBe(1);
    });
});
