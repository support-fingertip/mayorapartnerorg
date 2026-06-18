import { createElement } from 'lwc';
import Schemes from 'c/schemes';

const flush = () => Promise.resolve();

describe('c-schemes', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders all managed schemes by default', () => {
        const element = createElement('c-schemes', { is: Schemes });
        document.body.appendChild(element);

        const rows = element.shadowRoot.querySelectorAll('.dms-tbl_schemes .dms-trow');
        expect(rows.length).toBe(8);
        expect(element.shadowRoot.querySelector('.dms-count').textContent).toBe(
            '8 of 8 schemes'
        );
    });

    it('opens the detail panel with children when a scheme row is clicked', async () => {
        const element = createElement('c-schemes', { is: Schemes });
        document.body.appendChild(element);

        // SCH-0005 is the pass-through scheme with Tier child rows.
        const row = element.shadowRoot.querySelector('.dms-tbl_schemes .dms-trow[data-id="SCH-0005"]');
        row.click();
        await flush();

        const detail = element.shadowRoot.querySelector('.dms-detail');
        expect(detail).not.toBeNull();
        // Header + at least the Tier child table rendered.
        expect(element.shadowRoot.querySelectorAll('.dms-tbl_child').length).toBeGreaterThan(0);
    });

    it('switches to the Scheme Claims tab', async () => {
        const element = createElement('c-schemes', { is: Schemes });
        document.body.appendChild(element);

        const claimsTab = [...element.shadowRoot.querySelectorAll('.dms-subtab')].find(
            (t) => t.dataset.tab === 'claims'
        );
        claimsTab.click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_claims .dms-trow').length).toBe(3);
    });
});
