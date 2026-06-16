import { createElement } from 'lwc';
import DmsStatusBadge from 'c/dmsStatusBadge';

describe('c-dms-status-badge', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    const create = (props) => {
        const element = createElement('c-dms-status-badge', { is: DmsStatusBadge });
        Object.assign(element, props);
        document.body.appendChild(element);
        return element;
    };

    it('renders the status text', () => {
        const element = create({ status: 'Paid' });
        const span = element.shadowRoot.querySelector('span');
        expect(span.textContent).toBe('Paid');
    });

    it('maps a known status to its semantic theme class', () => {
        const element = create({ status: 'Overdue' });
        const span = element.shadowRoot.querySelector('span');
        expect(span.className).toContain('dms-badge_danger');
    });

    it('falls back to the neutral theme for unknown statuses', () => {
        const element = create({ status: 'Whatever' });
        const span = element.shadowRoot.querySelector('span');
        expect(span.className).toContain('dms-badge_neutral');
    });
});
