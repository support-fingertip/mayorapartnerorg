import { createElement } from 'lwc';
import DmsTargets from 'c/dmsTargets';

const flush = () => Promise.resolve();

describe('c-dms-targets', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders all target lines by default', () => {
        const element = createElement('c-dms-targets', { is: DmsTargets });
        document.body.appendChild(element);

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_targets .dms-trow');
        expect(rows.length).toBe(10);
        expect(element.shadowRoot.querySelector('.dms-count').textContent).toBe(
            '10 of 10 target lines'
        );
    });

    it('filters target lines by the Outlet tier', async () => {
        const element = createElement('c-dms-targets', { is: DmsTargets });
        document.body.appendChild(element);

        const tierCombo = element.shadowRoot.querySelectorAll('lightning-combobox')[0];
        tierCombo.dispatchEvent(new CustomEvent('change', { detail: { value: 'Outlet' } }));
        await flush();

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_targets .dms-trow');
        expect(rows.length).toBe(3);
    });
});
