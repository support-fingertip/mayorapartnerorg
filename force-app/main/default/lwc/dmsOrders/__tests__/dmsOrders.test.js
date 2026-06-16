import { createElement } from 'lwc';
import DmsOrders from 'c/dmsOrders';

const flush = () => Promise.resolve();

describe('c-dms-orders', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders P1 orders with status filter chips', () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_p1 .dms-trow').length).toBe(5);
        expect(element.shadowRoot.querySelectorAll('.dms-chiprow .dms-chipbtn').length).toBe(7);
    });

    it('filters P1 orders by status chip', async () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        const grn = [...element.shadowRoot.querySelectorAll('.dms-chipbtn')].find(
            (b) => b.dataset.status === 'GRN Given'
        );
        grn.click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_p1 .dms-trow').length).toBe(2);
    });

    it('switches to Secondary orders', async () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.tab === 'secondary')
            .click();
        await flush();

        expect(element.shadowRoot.querySelectorAll('.dms-tbl_secondary .dms-trow').length).toBe(7);
    });

    it('opens the New Order screen and updates the cart total via the stepper', async () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-btn').click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-neworder')).not.toBeNull();

        // first product = Malkist Cheese @ ₹576/case
        const plus = element.shadowRoot.querySelector('.dms-stepper__btn[data-dir="up"]');
        plus.click();
        await flush();

        const qty = element.shadowRoot.querySelector('.dms-stepper__qty');
        expect(qty.textContent).toBe('1');
        expect(element.shadowRoot.querySelector('.dms-no__cart').textContent).toContain('1');
    });
});
