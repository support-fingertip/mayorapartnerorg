import { createElement } from 'lwc';
import DmsHome from 'c/dmsHome';

const flush = () => Promise.resolve();

describe('c-dms-home', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the three dashboard sub-tabs', () => {
        const element = createElement('c-dms-home', { is: DmsHome });
        document.body.appendChild(element);

        const tabs = [...element.shadowRoot.querySelectorAll('.dms-subtab')].map((t) =>
            t.textContent.trim()
        );
        expect(tabs).toEqual(['P1 Dashboard', 'P2 Dashboard', 'Secondary Dashboard']);
    });

    it('shows the 6 P1 KPI cards and two order-analysis charts by default', () => {
        const element = createElement('c-dms-home', { is: DmsHome });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('c-dms-kpi-card').length).toBe(6);
        expect(element.shadowRoot.querySelectorAll('c-dms-bar-chart').length).toBe(2);
    });

    it('switches to the P2 dashboard and renders 7 KPIs and the SD table', async () => {
        const element = createElement('c-dms-home', { is: DmsHome });
        document.body.appendChild(element);

        const p2Tab = [...element.shadowRoot.querySelectorAll('.dms-subtab')].find(
            (t) => t.dataset.dash === 'p2'
        );
        p2Tab.click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('c-dms-kpi-card').length).toBe(7);
        expect(element.shadowRoot.querySelector('.dms-tbl_sd')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.dms-tbl_range')).not.toBeNull();
    });

    it('renders P2 tickets', async () => {
        const element = createElement('c-dms-home', { is: DmsHome });
        document.body.appendChild(element);

        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.dash === 'p2')
            .click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-tbl_tickets')).not.toBeNull();
    });

    it('renders the Secondary dashboard with KPIs, charts and tables', async () => {
        const element = createElement('c-dms-home', { is: DmsHome });
        document.body.appendChild(element);

        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.dash === 'secondary')
            .click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('c-dms-kpi-card').length).toBe(9);
        expect(element.shadowRoot.querySelector('c-dms-column-chart')).not.toBeNull();
        expect(element.shadowRoot.querySelector('c-dms-pie-chart')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.dms-tbl_collection')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.dms-tbl_outlets')).not.toBeNull();
    });

    it('changes the Range Selling dimension when a toggle is clicked', async () => {
        const element = createElement('c-dms-home', { is: DmsHome });
        document.body.appendChild(element);

        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.dash === 'p2')
            .click();
        await flush();

        const before = element.shadowRoot.querySelectorAll('.dms-tbl_range .dms-trow').length;
        const sku = [...element.shadowRoot.querySelectorAll('.dms-toggle__btn')].find(
            (b) => b.dataset.dim === 'sku'
        );
        sku.click();
        await flush();

        const after = element.shadowRoot.querySelectorAll('.dms-tbl_range .dms-trow').length;
        expect(after).toBeGreaterThan(0);
        expect(after).not.toBe(before);
    });
});
