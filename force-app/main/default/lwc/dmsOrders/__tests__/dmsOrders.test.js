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

    it('opens the order detail modal from a View link', async () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        // Secondary tab -> SO-6416 has the known 4-line breakdown
        [...element.shadowRoot.querySelectorAll('.dms-subtab')]
            .find((t) => t.dataset.tab === 'secondary')
            .click();
        await flush();

        const view = [...element.shadowRoot.querySelectorAll('.dms-view')].find(
            (v) => v.dataset.id === 'SO-6416'
        );
        view.click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-detail__head h2').textContent).toBe('SO-6416');
        expect(element.shadowRoot.querySelectorAll('.dms-tbl_detail .dms-trow').length).toBe(4);
        const totals = [...element.shadowRoot.querySelectorAll('.dms-detail__tv')].map((t) =>
            t.textContent
        );
        expect(totals[0]).toBe('88'); // total cases
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

    it('opens the cart drawer with line items and totals', async () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-btn').click();
        await flush();

        // add two cases of the first product
        const plus = element.shadowRoot.querySelector('.dms-stepper__btn[data-dir="up"]');
        plus.click();
        await flush();
        plus.click();
        await flush();

        element.shadowRoot.querySelector('.dms-no__cart').click();
        await flush();

        expect(element.shadowRoot.querySelector('.dms-cart')).not.toBeNull();
        expect(element.shadowRoot.querySelectorAll('.dms-cart__item').length).toBe(1);
        expect(element.shadowRoot.querySelector('.dms-cart__head h2').textContent).toBe(
            'Cart (1 products)'
        );
    });

    it('shows the confirmation modal and returns to the list on Done', async () => {
        const element = createElement('c-dms-orders', { is: DmsOrders });
        document.body.appendChild(element);

        element.shadowRoot.querySelector('.dms-btn').click();
        await flush();
        element.shadowRoot.querySelector('.dms-stepper__btn[data-dir="up"]').click();
        await flush();
        element.shadowRoot.querySelector('.dms-no__cart').click();
        await flush();

        element.shadowRoot.querySelector('.dms-btn_outline').click(); // Save as Draft
        await flush();

        expect(element.shadowRoot.querySelector('.dms-modal__title').textContent).toBe(
            'Saved as Draft'
        );

        element.shadowRoot.querySelector('.dms-modal__done').click();
        await flush();

        // back on the list view
        expect(element.shadowRoot.querySelector('.dms-neworder')).toBeNull();
        expect(element.shadowRoot.querySelector('.dms-tbl_p1')).not.toBeNull();
    });
});
