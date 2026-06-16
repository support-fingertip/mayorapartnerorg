import { createElement } from 'lwc';
import DmsHome from 'c/dmsHome';

describe('c-dms-home', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders four KPI cards from the mock data', () => {
        const element = createElement('c-dms-home', { is: DmsHome });
        document.body.appendChild(element);

        const kpis = element.shadowRoot.querySelectorAll('c-dms-kpi-card');
        expect(kpis.length).toBe(4);
    });

    it('renders recent orders and outstanding invoice panels', () => {
        const element = createElement('c-dms-home', { is: DmsHome });
        document.body.appendChild(element);

        const titles = [...element.shadowRoot.querySelectorAll('.dms-panel__title')].map(
            (el) => el.textContent
        );
        expect(titles).toContain('Recent Orders');
        expect(titles).toContain('Outstanding Invoices');
    });
});
