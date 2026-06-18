import { createElement } from 'lwc';
import Positions from 'c/positions';

const flush = () => Promise.resolve();

describe('c-positions', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders all positions as rows by default', () => {
        const element = createElement('c-positions', { is: Positions });
        document.body.appendChild(element);

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_positions .dms-trow');
        expect(rows.length).toBe(9);
        expect(element.shadowRoot.querySelector('.dms-count').textContent).toBe(
            '9 of 9 positions'
        );
    });

    it('filters positions by vacant status', async () => {
        const element = createElement('c-positions', { is: Positions });
        document.body.appendChild(element);

        const statusCombo = element.shadowRoot.querySelectorAll('lightning-combobox')[1];
        statusCombo.dispatchEvent(new CustomEvent('change', { detail: { value: 'Vacant' } }));
        await flush();

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_positions .dms-trow');
        expect(rows.length).toBe(2);
    });

    it('switches to the Temporary Assignments tab', async () => {
        const element = createElement('c-positions', { is: Positions });
        document.body.appendChild(element);

        const tempTab = [...element.shadowRoot.querySelectorAll('.dms-subtab')].find(
            (t) => t.dataset.tab === 'temp'
        );
        tempTab.click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_temp .dms-trow').length).toBe(3);
    });
});
