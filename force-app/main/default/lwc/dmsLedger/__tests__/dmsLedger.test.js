import { createElement } from 'lwc';
import DmsLedger from 'c/dmsLedger';

const flush = () => Promise.resolve();

describe('c-dms-ledger', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('shows the empty state before generating', () => {
        const element = createElement('c-dms-ledger', { is: DmsLedger });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelector('.dms-empty')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.dms-tbl_ledger')).toBeNull();
    });

    it('renders 13 transactions and the closing balance after Generate', async () => {
        const element = createElement('c-dms-ledger', { is: DmsLedger });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-btn').click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_ledger .dms-trow').length).toBe(13);
        expect(element.shadowRoot.querySelector('.dms-ledger__closing').textContent).toContain(
            '1,51,680'
        );
    });
});
