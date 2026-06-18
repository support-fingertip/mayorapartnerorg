import { createElement } from 'lwc';
import DmsClaims from 'c/dmsClaims';

const flush = () => Promise.resolve();

describe('c-dms-claims', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders claims with summary cards', () => {
        const element = createElement('c-dms-claims', { is: DmsClaims });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_claims .dms-trow').length).toBe(4);
        const cards = [...element.shadowRoot.querySelectorAll('.dms-card__value')].map((c) =>
            c.textContent
        );
        expect(cards[0]).toBe('4'); // total claims
        expect(cards[1]).toContain('13,280'); // total value
    });

    it('submits a new claim and shows the confirmation', async () => {
        const element = createElement('c-dms-claims', { is: DmsClaims });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-btn').click();
        await flush();

        const sel = element.shadowRoot.querySelector('.dms-select');
        sel.value = 'Choki-Choki Q4 2025 Scheme';
        sel.dispatchEvent(new CustomEvent('change'));

        const nums = element.shadowRoot.querySelectorAll('lightning-input');
        nums[0].value = 3;
        nums[0].dispatchEvent(new CustomEvent('change'));
        nums[1].value = 3;
        nums[1].dispatchEvent(new CustomEvent('change'));
        await flush();

        element.shadowRoot.querySelectorAll('.dms-modal__foot .dms-btn')[1].click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-success__title').textContent).toBe(
            'Scheme Claim Submitted'
        );
        expect(element.shadowRoot.querySelector('.dms-success__line').textContent).toContain(
            'SCH-0042'
        );
    });
});
