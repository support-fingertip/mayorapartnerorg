import { createElement } from 'lwc';
import DmsOrders from 'c/dmsOrders';

const flush = () => Promise.resolve();

describe('c-dms-orders', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders all orders initially', () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        const rows = element.shadowRoot.querySelectorAll('.dms-table__row');
        expect(rows.length).toBeGreaterThan(0);
    });

    it('filters rows when a status tab is clicked', async () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        const allCount = element.shadowRoot.querySelectorAll('.dms-table__row').length;

        const tabs = element.shadowRoot.querySelectorAll('.dms-tab');
        const confirmedTab = [...tabs].find((t) => t.dataset.status === 'Confirmed');
        confirmedTab.click();

        await flush();

        const filtered = element.shadowRoot.querySelectorAll('.dms-table__row').length;
        expect(filtered).toBeGreaterThan(0);
        expect(filtered).toBeLessThanOrEqual(allCount);
    });
});
