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
