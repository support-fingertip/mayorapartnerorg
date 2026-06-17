import { createElement } from 'lwc';
import DmsInventory from 'c/dmsInventory';

const flush = () => Promise.resolve();

describe('c-dms-inventory', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the stock view with 14 SKUs and summary cards', () => {
        const element = createElement('c-dms-inventory', { is: DmsInventory });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_stock .dms-trow').length).toBe(14);
        const cards = [...element.shadowRoot.querySelectorAll('.dms-card__value')].map((c) =>
            c.textContent
        );
        expect(cards[0]).toBe('14'); // total SKUs
        expect(cards[1]).toBe('5,100'); // total cases
    });

    it('switches to stock adjustments and shows entries + summary', async () => {
        const element = createElement('c-dms-inventory', { is: DmsInventory });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('[data-tab="adjust"]').click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_adj .dms-trow').length).toBe(7);
        const chips = [...element.shadowRoot.querySelectorAll('.dms-chip__value')].map((c) =>
            c.textContent
        );
        expect(chips).toEqual(['7', '11', '4', '7']); // total / removed / added / month
    });

    it('adds a new adjustment via the modal', async () => {
        const element = createElement('c-dms-inventory', { is: DmsInventory });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('[data-tab="adjust"]').click();
        await flush();
        element.shadowRoot.querySelector('.dms-toolbar__right .dms-btn').click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-modal')).not.toBeNull();

        const combo = element.shadowRoot.querySelector('.dms-modal lightning-combobox');
        combo.dispatchEvent(new CustomEvent('change', { detail: { value: 'MLK-CHE-130' } }));
        const qty = element.shadowRoot.querySelector('.dms-qtyfield');
        qty.value = 5;
        qty.dispatchEvent(new CustomEvent('change'));
        await flush();

        element.shadowRoot.querySelectorAll('.dms-modal__foot .dms-btn')[1].click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_adj .dms-trow').length).toBe(8);
    });
});
