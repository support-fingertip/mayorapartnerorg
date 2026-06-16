import { createElement } from 'lwc';
import DmsProducts from 'c/dmsProducts';

const flush = () => Promise.resolve();

describe('c-dms-products', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders a card per product by default', () => {
        const element = createElement('c-dms-products', { is: DmsProducts });
        document.body.appendChild(element);

        const cards = element.shadowRoot.querySelectorAll('.dms-card');
        expect(cards.length).toBeGreaterThan(0);
    });

    it('filters products by the search key', async () => {
        const element = createElement('c-dms-products', { is: DmsProducts });
        document.body.appendChild(element);

        const before = element.shadowRoot.querySelectorAll('.dms-card').length;

        const search = element.shadowRoot.querySelector('lightning-input');
        search.value = 'Kopiko';
        search.dispatchEvent(new CustomEvent('change'));

        await flush();

        const after = element.shadowRoot.querySelectorAll('.dms-card').length;
        expect(after).toBeLessThanOrEqual(before);
        expect(after).toBeGreaterThan(0);
    });
});
