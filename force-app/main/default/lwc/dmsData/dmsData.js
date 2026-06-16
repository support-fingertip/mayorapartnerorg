/**
 * Mayora DMS — central mock data source (Phase 1 UI prototype).
 * No backend wiring: every screen reads from these helpers so the
 * prototype stays internally consistent. Getters return clones so
 * components can sort/filter without mutating the source.
 */

const clone = (data) => JSON.parse(JSON.stringify(data));

const PRODUCTS = [
    { id: 'P-1001', name: 'Kopiko Black 3-in-1', category: 'Coffee', sku: 'KPK-BLK-30', price: 24500, stock: 1240, unit: 'carton', status: 'In Stock' },
    { id: 'P-1002', name: 'Beng Beng Wafer Chocolate', category: 'Wafer', sku: 'BNG-CHOC-24', price: 18000, stock: 320, unit: 'carton', status: 'In Stock' },
    { id: 'P-1003', name: 'Roma Malkist Crackers', category: 'Biscuit', sku: 'RMA-MLK-20', price: 15750, stock: 48, unit: 'carton', status: 'Low Stock' },
    { id: 'P-1004', name: 'Danisa Butter Cookies 454g', category: 'Biscuit', sku: 'DNS-BTR-12', price: 62000, stock: 0, unit: 'carton', status: 'Out of Stock' },
    { id: 'P-1005', name: 'Torabika Cappuccino', category: 'Coffee', sku: 'TRB-CAP-30', price: 27800, stock: 860, unit: 'carton', status: 'In Stock' },
    { id: 'P-1006', name: 'Astor Wafer Stick Chocolate', category: 'Wafer', sku: 'AST-CHOC-24', price: 21300, stock: 95, unit: 'carton', status: 'Low Stock' },
    { id: 'P-1007', name: 'Slai O Lai Soft Cake Strawberry', category: 'Cake', sku: 'SLO-STR-24', price: 19900, stock: 540, unit: 'carton', status: 'In Stock' },
    { id: 'P-1008', name: 'Choki Choki Chocolate Paste', category: 'Confectionery', sku: 'CHK-CHOC-50', price: 13200, stock: 12, unit: 'carton', status: 'Low Stock' }
];

const ORDERS = [
    { id: 'SO-24001', customer: 'Toko Sumber Rejeki', date: '2026-06-14', items: 18, amount: 4250000, status: 'Pending' },
    { id: 'SO-24002', customer: 'UD Maju Jaya', date: '2026-06-13', items: 32, amount: 9120000, status: 'Confirmed' },
    { id: 'SO-24003', customer: 'Grosir Berkah', date: '2026-06-13', items: 9, amount: 1875000, status: 'Shipped' },
    { id: 'SO-24004', customer: 'Toko Anugerah', date: '2026-06-12', items: 24, amount: 6480000, status: 'Delivered' },
    { id: 'SO-24005', customer: 'CV Sinar Pagi', date: '2026-06-11', items: 5, amount: 980000, status: 'Cancelled' },
    { id: 'SO-24006', customer: 'Toko Makmur Abadi', date: '2026-06-11', items: 41, amount: 11750000, status: 'Confirmed' },
    { id: 'SO-24007', customer: 'Warung Bu Tini', date: '2026-06-10', items: 7, amount: 1340000, status: 'Delivered' }
];

const INVOICES = [
    { id: 'INV-90012', order: 'SO-24004', customer: 'Toko Anugerah', date: '2026-06-12', due: '2026-06-26', amount: 6480000, status: 'Paid' },
    { id: 'INV-90013', order: 'SO-24006', customer: 'Toko Makmur Abadi', date: '2026-06-11', due: '2026-06-25', amount: 11750000, status: 'Pending' },
    { id: 'INV-90014', order: 'SO-24007', customer: 'Warung Bu Tini', date: '2026-06-10', due: '2026-06-24', amount: 1340000, status: 'Paid' },
    { id: 'INV-90009', order: 'SO-23988', customer: 'UD Maju Jaya', date: '2026-05-28', due: '2026-06-11', amount: 8900000, status: 'Overdue' },
    { id: 'INV-90007', order: 'SO-23975', customer: 'Grosir Berkah', date: '2026-05-22', due: '2026-06-05', amount: 3420000, status: 'Overdue' },
    { id: 'INV-90015', order: 'SO-24002', customer: 'UD Maju Jaya', date: '2026-06-13', due: '2026-06-27', amount: 9120000, status: 'Pending' }
];

const formatCurrency = (value) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(value);

export function getProducts() {
    return clone(PRODUCTS);
}

export function getOrders() {
    return clone(ORDERS);
}

export function getInvoices() {
    return clone(INVOICES);
}

/** KPI tiles for the Home/dashboard screen. */
export function getKpis() {
    const totalSales = ORDERS.filter((o) => o.status !== 'Cancelled').reduce((sum, o) => sum + o.amount, 0);
    const openOrders = ORDERS.filter((o) => ['Pending', 'Confirmed'].includes(o.status)).length;
    const outstanding = INVOICES.filter((i) => i.status !== 'Paid').reduce((sum, i) => sum + i.amount, 0);
    const lowStock = PRODUCTS.filter((p) => p.status !== 'In Stock').length;

    return [
        { id: 'sales', label: 'Total Sales (MTD)', value: formatCurrency(totalSales), delta: '+12.4%', positive: true, icon: 'utility:moneybag' },
        { id: 'orders', label: 'Open Orders', value: String(openOrders), delta: '+3', positive: true, icon: 'utility:cart' },
        { id: 'outstanding', label: 'Outstanding', value: formatCurrency(outstanding), delta: '-5.1%', positive: true, icon: 'utility:account' },
        { id: 'stock', label: 'Low / Out of Stock', value: String(lowStock), delta: '+2', positive: false, icon: 'utility:warning' }
    ];
}

export { formatCurrency };
