import { createElement } from 'lwc';
import DmsTickets from 'c/dmsTickets';

const flush = () => Promise.resolve();

describe('c-dms-tickets', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders tickets with summary cards', () => {
        const element = createElement('c-dms-tickets', { is: DmsTickets });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_tk .dms-trow').length).toBe(6);
        const cards = [...element.shadowRoot.querySelectorAll('.dms-card__value')].map((c) =>
            c.textContent
        );
        expect(cards).toEqual(['6', '1', '2', '2']); // total / open / in progress / resolved
    });

    it('opens the ticket detail modal with the conversation', async () => {
        const element = createElement('c-dms-tickets', { is: DmsTickets });
        document.body.appendChild(element);

        const view = [...element.shadowRoot.querySelectorAll('.dms-viewlink')].find(
            (v) => v.dataset.id === 'TKT-0082'
        );
        view.click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-detail__id').textContent).toBe('TKT-0082');
        expect(element.shadowRoot.querySelectorAll('.dms-msg').length).toBe(2);
    });

    it('submits a new ticket and prepends it', async () => {
        const element = createElement('c-dms-tickets', { is: DmsTickets });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-toolbar__right .dms-btn').click();
        await flush();

        const sel = element.shadowRoot.querySelector('.dms-select');
        sel.value = 'Order Issue';
        sel.dispatchEvent(new CustomEvent('change'));
        const subject = element.shadowRoot.querySelector('.dms-modal__body lightning-input');
        subject.value = 'Test issue';
        subject.dispatchEvent(new CustomEvent('change'));
        await flush();

        element.shadowRoot.querySelectorAll('.dms-modal__foot .dms-btn')[1].click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_tk .dms-trow').length).toBe(7);
    });
});
