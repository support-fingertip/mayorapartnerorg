import { LightningElement } from 'lwc';
import { getProducts, formatCurrency } from 'c/dmsData';

/** Product catalog screen for the Experience Cloud Products tab. */
export default class DmsProducts extends LightningElement {
    allProducts = [];
    searchKey = '';
    selectedCategory = 'All';

    connectedCallback() {
        this.allProducts = getProducts();
    }

    get categoryOptions() {
        const cats = ['All', ...new Set(this.allProducts.map((p) => p.category))];
        return cats.map((c) => ({ label: c, value: c }));
    }

    get filteredProducts() {
        const key = this.searchKey.toLowerCase();
        return this.allProducts
            .filter((p) => this.selectedCategory === 'All' || p.category === this.selectedCategory)
            .filter((p) => !key || p.name.toLowerCase().includes(key) || p.sku.toLowerCase().includes(key))
            .map((p) => ({ ...p, priceLabel: formatCurrency(p.price) }));
    }

    get resultCount() {
        return this.filteredProducts.length;
    }

    get isEmpty() {
        return this.filteredProducts.length === 0;
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
    }

    handleCategory(event) {
        this.selectedCategory = event.detail.value;
    }
}
