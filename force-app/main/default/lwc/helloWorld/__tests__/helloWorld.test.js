import { createElement } from 'lwc';
import HelloWorld from 'c/helloWorld';

describe('c-hello-world', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('displays default greeting when no name is entered', () => {
        const element = createElement('c-hello-world', { is: HelloWorld });
        document.body.appendChild(element);

        const p = element.shadowRoot.querySelector('p');
        expect(p.textContent).toBe('Hello, World!');
    });

    it('displays personalised greeting when name is entered', async () => {
        const element = createElement('c-hello-world', { is: HelloWorld });
        document.body.appendChild(element);

        const input = element.shadowRoot.querySelector('lightning-input');
        input.value = 'Salesforce';
        input.dispatchEvent(new CustomEvent('change'));

        await Promise.resolve();

        const p = element.shadowRoot.querySelector('p');
        expect(p.textContent).toBe('Hello, Salesforce!');
    });
});
