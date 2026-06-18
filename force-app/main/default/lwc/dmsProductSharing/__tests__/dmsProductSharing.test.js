import { createElement } from 'lwc';
import DmsProductSharing from 'c/dmsProductSharing';

const flush = () => Promise.resolve();

describe('c-dms-product-sharing', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders all visibility rules by default', () => {
        const element = createElement('c-dms-product-sharing', { is: DmsProductSharing });
        document.body.appendChild(element);

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_sharing .dms-trow');
        expect(rows.length).toBe(12);
        expect(element.shadowRoot.querySelector('.dms-count').textContent).toBe(
            '12 of 12 rules'
        );
    });

    it('filters rules by Distributor level', async () => {
        const element = createElement('c-dms-product-sharing', { is: DmsProductSharing });
        document.body.appendChild(element);

        const levelCombo = element.shadowRoot.querySelectorAll('lightning-combobox')[0];
        levelCombo.dispatchEvent(new CustomEvent('change', { detail: { value: 'Distributor' } }));
        await flush();

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_sharing .dms-trow');
        expect(rows.length).toBe(2);
    });
});
