import { createElement } from 'lwc';
import DmsProducts from 'c/dmsProducts';

const flush = () => Promise.resolve();

describe('c-dms-products', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the full catalog as table rows by default', () => {
        const element = createElement('c-dms-products', { is: DmsProducts });
        document.body.appendChild(element);

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_products .dms-trow');
        expect(rows.length).toBe(14);
        expect(element.shadowRoot.querySelector('.dms-count').textContent).toBe(
            '14 of 14 products'
        );
    });

    it('filters products by search key', async () => {
        const element = createElement('c-dms-products', { is: DmsProducts });
        document.body.appendChild(element);

        const search = element.shadowRoot.querySelector('lightning-input');
        search.value = 'Malkist';
        search.dispatchEvent(new CustomEvent('change'));
        await flush();

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_products .dms-trow');
        expect(rows.length).toBe(4); // 3 Malkist crackers + cereal
    });

    it('switches to Schemes & Offers and shows summary + scheme cards', async () => {
        const element = createElement('c-dms-products', { is: DmsProducts });
        document.body.appendChild(element);

        const schemesTab = [...element.shadowRoot.querySelectorAll('.dms-subtab')].find(
            (t) => t.dataset.tab === 'schemes'
        );
        schemesTab.click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-chip').length).toBe(4);
        expect(element.shadowRoot.querySelectorAll('.dms-scheme').length).toBe(8);
    });
});
