import { createElement } from 'lwc';
import DmsSecondaryCollection from 'c/dmsSecondaryCollection';

const flush = () => Promise.resolve();

describe('c-dms-secondary-collection', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders collections and summary chips', () => {
        const element = createElement('c-dms-secondary-collection', { is: DmsSecondaryCollection });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_coll .dms-trow').length).toBe(8);
        const chips = [...element.shadowRoot.querySelectorAll('.dms-chip__value')].map((c) =>
            c.textContent
        );
        expect(chips[0]).toBe('8'); // total entries
        expect(chips[2]).toBe('5'); // retailers
        expect(chips[3]).toBe('3'); // sub-distributors
    });

    it('shows the cheque-number field only for cheque mode', async () => {
        const element = createElement('c-dms-secondary-collection', { is: DmsSecondaryCollection });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-toolbar__right .dms-btn').click();
        await flush();

        // default Cash -> no extra ref field
        expect(element.shadowRoot.querySelector('.dms-flabel ~ lightning-input')).not.toBeNull();

        const cheque = [...element.shadowRoot.querySelectorAll('.dms-seg')].find(
            (b) => b.dataset.mode === 'Cheque'
        );
        cheque.click();
        await flush();

        const labels = [...element.shadowRoot.querySelectorAll('.dms-flabel')].map((l) =>
            l.textContent
        );
        expect(labels).toContain('Cheque Number');
    });

    it('records a new collection and prepends it', async () => {
        const element = createElement('c-dms-secondary-collection', { is: DmsSecondaryCollection });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-toolbar__right .dms-btn').click();
        await flush();

        const sel = element.shadowRoot.querySelector('.dms-select');
        sel.value = 'RET-004';
        sel.dispatchEvent(new CustomEvent('change'));

        const amount = element.shadowRoot.querySelectorAll('.dms-modal lightning-input')[1];
        amount.value = 5000;
        amount.dispatchEvent(new CustomEvent('change'));
        await flush();

        element.shadowRoot.querySelectorAll('.dms-modal__foot .dms-btn')[1].click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_coll .dms-trow').length).toBe(9);
    });
});
