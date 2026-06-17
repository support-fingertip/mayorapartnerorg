import { createElement } from 'lwc';
import DmsReturns from 'c/dmsReturns';

const flush = () => Promise.resolve();

describe('c-dms-returns', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders P1 returns with New Return and summary cards', () => {
        const element = createElement('c-dms-returns', { is: DmsReturns });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_pr .dms-trow').length).toBe(4);
        expect(element.shadowRoot.querySelector('.dms-btn')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.dms-viewonly')).toBeNull();
    });

    it('shows View only (no create) on Secondary returns', async () => {
        const element = createElement('c-dms-returns', { is: DmsReturns });
        document.body.appendChild(element);

        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.tab === 'secondary')
            .click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_sr .dms-trow').length).toBe(5);
        expect(element.shadowRoot.querySelector('.dms-viewonly')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.dms-btn')).toBeNull();
    });

    it('creates a primary return via the wizard and prepends it to P1', async () => {
        const element = createElement('c-dms-returns', { is: DmsReturns });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-btn').click(); // New Return
        await flush();

        // step 1: select first invoice, Next
        element.shadowRoot.querySelector('.dms-pick').click();
        await flush();
        element.shadowRoot.querySelectorAll('.dms-wizard__foot .dms-btn')[1].click();
        await flush();

        // step 2: enter return qty 2 on first product
        const input = element.shadowRoot.querySelector('.dms-qtyinput');
        input.value = 2;
        input.dispatchEvent(new CustomEvent('change'));
        await flush();
        expect(element.shadowRoot.querySelector('.dms-rtotal__value').textContent).toBe('2 cartons');

        // Save Return
        element.shadowRoot.querySelectorAll('.dms-wizard__foot .dms-btn')[1].click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_pr .dms-trow').length).toBe(5);
    });
});
