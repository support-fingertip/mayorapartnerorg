/**
 * Mayora DMS — central mock data source (Phase 1 UI prototype).
 * No backend wiring: every screen reads from these helpers so the
 * prototype stays internally consistent. Getters return clones so
 * components can sort/filter without mutating the source.
 */

const clone = (data) => JSON.parse(JSON.stringify(data));

const inr = new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0
});

/** Full rupee value, e.g. 18720 -> "₹18,720". */
const formatCurrency = (value) => inr.format(value);

/** Lakh shorthand, e.g. 498000 -> "₹4.98L". */
const formatLakh = (value) => `₹${(value / 100000).toFixed(2)}L`;

/* ----------------------------- Catalog screens ---------------------------- */

const CATALOG = [
    { sku: 'MLK-CHE-130', name: 'Malkist Cheese Crackers', code: 'MAY-001', brand: 'Malkist', subBrand: 'Malkist Cheese', alias: 'Malkist Cracker Cheese', packSize: '130g', mrp: 30, dist: 576, units: 24 },
    { sku: 'MLK-CHO-130', name: 'Malkist Double Chocolatey', code: 'MAY-002', brand: 'Malkist', subBrand: 'Malkist Choco', alias: 'Malkist Chocolate', packSize: '130g', mrp: 30, dist: 576, units: 24 },
    { sku: 'MLK-CAP-130', name: 'Malkist Cappuccino Crackers', code: 'MAY-003', brand: 'Malkist', subBrand: 'Malkist Cappuccino', alias: 'Malkist Coffee', packSize: '130g', mrp: 30, dist: 576, units: 24 },
    { sku: 'CFJ-100', name: 'Coffee Joy Thin Biscuit', code: 'MAY-004', brand: 'Coffee Joy', subBrand: 'Coffee Joy Thin', alias: 'Coffee Joy Biscuit', packSize: '100g', mrp: 20, dist: 576, units: 36 },
    { sku: 'RMG-250', name: 'Roma Marie Gold', code: 'MAY-005', brand: 'Roma', subBrand: 'Roma Marie Gold', alias: 'Roma Marie', packSize: '250g', mrp: 35, dist: 672, units: 24 },
    { sku: 'SOL-STR-90', name: "Slai O'lai Strawberry", code: 'MAY-006', brand: "Slai O'lai", subBrand: "Slai O'lai Strawberry", alias: 'Sla Olay', packSize: '90g', mrp: 15, dist: 432, units: 36 },
    { sku: 'KOP-CDY-140', name: 'Kopiko Coffee Candy', code: 'MAY-007', brand: 'Kopiko', subBrand: 'Kopiko Classic', alias: 'Kopiko Candy', packSize: '140g', mrp: 25, dist: 600, units: 24 },
    { sku: 'BNG-CHO-20', name: 'Beng-Beng Wafer Chocolate', code: 'MAY-008', brand: 'Beng-Beng', subBrand: 'Beng-Beng Original', alias: 'Beng Beng', packSize: '20g', mrp: 10, dist: 480, units: 48 },
    { sku: 'JME-CHK-75', name: 'JoyMee Chicken Noodles', code: 'MAY-009', brand: 'JoyMee', subBrand: 'JoyMee Cup', alias: 'JoyMee Noodle', packSize: '75g', mrp: 12, dist: 432, units: 36 },
    { sku: 'DAN-BUT-200', name: 'Danisa Butter Cookies', code: 'MAY-010', brand: 'Danisa', subBrand: 'Danisa Butter', alias: 'Danisa Cookies', packSize: '200g', mrp: 90, dist: 1080, units: 12 },
    { sku: 'CHK-CHO-50', name: 'Choki-Choki Chocolate Paste', code: 'MAY-011', brand: 'Choki-Choki', subBrand: 'Choki-Choki Paste', alias: 'Choki Choki', packSize: '50g', mrp: 8, dist: 384, units: 48 },
    { sku: 'MLK-CER-130', name: 'Malkist Gandum Sereal', code: 'MAY-012', brand: 'Malkist', subBrand: 'Malkist Cereal', alias: 'Malkist Wheat', packSize: '130g', mrp: 30, dist: 576, units: 24 },
    { sku: 'KOP-BRN-30', name: 'Kopiko Brown Coffee', code: 'MAY-013', brand: 'Kopiko', subBrand: 'Kopiko Brown', alias: 'Kopiko Brown Coffee', packSize: '30g', mrp: 10, dist: 480, units: 48 },
    { sku: 'RMG-300', name: 'Roma Sari Gandum', code: 'MAY-014', brand: 'Roma', subBrand: 'Roma Sari Gandum', alias: 'Roma Wheat', packSize: '300g', mrp: 40, dist: 720, units: 24 }
];

const SCHEMES = [
    { id: 's1', name: 'Malkist Buy 4 Get 1', type: 'Buy X Get Y', status: 'Expiring Soon', desc: 'Buy 4 cartons of any Malkist variant, get 1 carton free.', date: '31 May 2026' },
    { id: 's2', name: 'Kopiko Volume Slab', type: 'Slab Discount', status: 'Active', desc: 'Tiered discount on Kopiko orders based on carton quantity.', date: '30 Jun 2026' },
    { id: 's3', name: 'JoyMee Noodles Buy 10 Get 2', type: 'Buy X Get Y', status: 'Active', desc: 'Order 10 cartons of JoyMee Chicken Noodles, get 2 cartons free.', date: '15 Jun 2026' },
    { id: 's4', name: 'Beng-Beng Pack Scheme', type: 'Buy X Get Y', status: 'Expiring Soon', desc: 'Buy 1 carton (48 packs) of Beng-Beng, get 6 packs free.', date: '31 May 2026' },
    { id: 's5', name: 'Choki-Choki Value Slab', type: 'Slab Discount', status: 'Upcoming', desc: 'Discount on Choki-Choki orders above minimum carton thresholds.', date: '30 Jun 2026' },
    { id: 's6', name: 'Danisa Festive Combo', type: 'Buy X Get Y', status: 'Upcoming', desc: 'Buy 6 cartons of Danisa, get a festive gift pack free.', date: '30 Jun 2026' },
    { id: 's7', name: 'Coffee Joy Slab Discount', type: 'Slab Discount', status: 'Active', desc: 'Tiered discount on Coffee Joy orders based on carton quantity.', date: '30 Jun 2026' },
    { id: 's8', name: 'Roma Marie Combo', type: 'Buy X Get Y', status: 'Active', desc: 'Buy 8 cartons of Roma Marie Gold, get 1 carton free.', date: '20 Jun 2026' }
];

export function getCatalog() {
    return clone(CATALOG);
}

export function getSchemes() {
    return clone(SCHEMES);
}

const numFmt = new Intl.NumberFormat('en-IN');

/** Plain grouped number, e.g. 6000 -> "6,000". */
const formatNumber = (value) => numFmt.format(value);

// Line-item products used to build order details (units = cases × pcs,
// amount = cases × rate). Order summaries are derived from these lines so
// the list rows and the detail modal always reconcile.
const LINE_PRODUCTS = {
    'MLK-CHE-130': { name: 'Malkist Cheese Crackers', brand: 'Malkist', pcs: 24, rate: 576 },
    'MLK-CHO-130': { name: 'Malkist Double Chocolatey', brand: 'Malkist', pcs: 24, rate: 576 },
    'SOL-STR-90': { name: "Slai O'lai Strawberry", brand: "Slai O'lai", pcs: 36, rate: 432 },
    'KIS-MNT-18': { name: 'KIS Mint Candy', brand: 'KIS', pcs: 60, rate: 480 },
    'JMK-50': { name: 'JuizyMilk Candy', brand: 'JuizyMilk', pcs: 60, rate: 960 },
    'KOP-JAR-140': { name: 'Kopiko Jar', brand: 'Kopiko', pcs: 12, rate: 768 },
    'RMG-250': { name: 'Roma Marie Gold', brand: 'Roma', pcs: 24, rate: 672 },
    'DAN-BUT-200': { name: 'Danisa Butter', brand: 'Danisa', pcs: 12, rate: 1440 },
    'CFJ-100': { name: 'Coffee Joy', brand: 'Coffee Joy', pcs: 36, rate: 576 },
    'BNG-CHO-20': { name: 'Beng-Beng', brand: 'Beng-Beng', pcs: 48, rate: 480 },
    'JME-CHK-75': { name: 'JoyMee Noodles', brand: 'JoyMee', pcs: 36, rate: 432 },
    'CHK-CHO-50': { name: 'Choki-Choki', brand: 'Choki-Choki', pcs: 24, rate: 960 }
};

const expandLines = (refs) =>
    refs.map((r) => {
        const lp = LINE_PRODUCTS[r.p];
        return {
            sku: r.p,
            name: lp.name,
            brand: lp.brand,
            cases: r.cases,
            units: r.cases * lp.pcs,
            rate: lp.rate,
            amount: r.cases * lp.rate
        };
    });

const buildOrder = (meta) => {
    const lines = expandLines(meta.lines);
    return {
        ...meta,
        lines,
        skus: lines.length,
        cases: lines.reduce((s, l) => s + l.cases, 0),
        units: lines.reduce((s, l) => s + l.units, 0),
        value: lines.reduce((s, l) => s + l.amount, 0)
    };
};

const P1_ORDERS = [
    { id: 'PO-2847', date: '29 May 2026', status: 'Pending Approval', lines: [{ p: 'MLK-CHE-130', cases: 40 }, { p: 'KOP-JAR-140', cases: 30 }, { p: 'CFJ-100', cases: 50 }, { p: 'DAN-BUT-200', cases: 20 }, { p: 'RMG-250', cases: 15 }] },
    { id: 'PO-2841', date: '26 May 2026', status: 'GRN Given', lines: [{ p: 'MLK-CHO-130', cases: 60 }, { p: 'SOL-STR-90', cases: 80 }, { p: 'BNG-CHO-20', cases: 100 }, { p: 'JME-CHK-75', cases: 70 }, { p: 'KIS-MNT-18', cases: 50 }, { p: 'CHK-CHO-50', cases: 30 }] },
    { id: 'PO-2828', date: '18 May 2026', status: 'GRN Given', lines: [{ p: 'RMG-250', cases: 70 }, { p: 'DAN-BUT-200', cases: 40 }, { p: 'MLK-CHE-130', cases: 90 }, { p: 'KOP-JAR-140', cases: 60 }, { p: 'CFJ-100', cases: 40 }] },
    { id: 'PO-2815', date: '08 May 2026', status: 'Rejected', lines: [{ p: 'SOL-STR-90', cases: 30 }, { p: 'CFJ-100', cases: 20 }] },
    { id: 'PO-2810', date: '05 May 2026', status: 'Draft', lines: [{ p: 'MLK-CHE-130', cases: 25 }, { p: 'CHK-CHO-50', cases: 15 }] }
].map(buildOrder);

const P2_ORDERS = [
    { id: 'PO-2835', date: '22 May 2026', lines: [{ p: 'MLK-CHO-130', cases: 40 }, { p: 'KOP-JAR-140', cases: 40 }, { p: 'DAN-BUT-200', cases: 30 }] },
    { id: 'PO-2820', date: '12 May 2026', lines: [{ p: 'BNG-CHO-20', cases: 120 }, { p: 'SOL-STR-90', cases: 100 }, { p: 'JME-CHK-75', cases: 80 }, { p: 'MLK-CHE-130', cases: 50 }] }
].map(buildOrder);

const SECONDARY_ORDERS = [
    { id: 'SO-6432', date: '29 May 2026', customer: 'ABC Mart', type: 'Retailer', lines: [{ p: 'MLK-CHE-130', cases: 3 }, { p: 'SOL-STR-90', cases: 1 }] },
    { id: 'SO-6431', date: '28 May 2026', customer: 'City Grocery', type: 'Retailer', lines: [{ p: 'BNG-CHO-20', cases: 6 }, { p: 'KIS-MNT-18', cases: 4 }] },
    { id: 'SO-6428', date: '25 May 2026', customer: 'North Zone SD', type: 'Sub-Dist.', lines: [{ p: 'MLK-CHE-130', cases: 20 }, { p: 'KOP-JAR-140', cases: 15 }, { p: 'DAN-BUT-200', cases: 10 }] },
    { id: 'SO-6424', date: '24 May 2026', customer: 'Fresh Mart', type: 'Retailer', lines: [{ p: 'CFJ-100', cases: 5 }, { p: 'RMG-250', cases: 3 }] },
    { id: 'SO-6420', date: '23 May 2026', customer: 'Metro General Store', type: 'Retailer', lines: [{ p: 'SOL-STR-90', cases: 4 }, { p: 'CHK-CHO-50', cases: 3 }, { p: 'MLK-CHO-130', cases: 2 }] },
    { id: 'SO-6416', date: '22 May 2026', customer: 'East Zone SD', type: 'Sub-Dist.', lines: [{ p: 'MLK-CHO-130', cases: 18 }, { p: 'SOL-STR-90', cases: 25 }, { p: 'KIS-MNT-18', cases: 30 }, { p: 'JMK-50', cases: 15 }] },
    { id: 'SO-6412', date: '21 May 2026', customer: 'Sharma Kirana', type: 'Retailer', lines: [{ p: 'MLK-CHE-130', cases: 4 }, { p: 'JME-CHK-75', cases: 3 }] }
].map(buildOrder);

// Products available in the New P1 Order entry screen.
const ORDER_PRODUCTS = [
    { id: 'op1', brand: 'Malkist', subBrand: 'Malkist Cheese', name: 'Malkist Cheese', packSize: '130g', pcs: 24, casePrice: 576, mrp: 30, scheme: 'Buy 4 Get 1' },
    { id: 'op2', brand: 'Malkist', subBrand: 'Malkist Choco', name: 'Malkist Choco', packSize: '130g', pcs: 24, casePrice: 576, mrp: 30, scheme: 'Buy 4 Get 1' },
    { id: 'op3', brand: 'Malkist', subBrand: 'Malkist Cappuccino', name: 'Malkist Cappuccino', packSize: '130g', pcs: 24, casePrice: 576, mrp: 30, scheme: 'Buy 4 Get 1' },
    { id: 'op4', brand: 'Coffee Joy', subBrand: 'Coffee Joy Thin', name: 'Coffee Joy', packSize: '100g', pcs: 36, casePrice: 576, mrp: 20, scheme: '' },
    { id: 'op5', brand: 'Roma', subBrand: 'Roma Marie Gold', name: 'Roma Marie Gold', packSize: '250g', pcs: 24, casePrice: 672, mrp: 35, scheme: '' },
    { id: 'op6', brand: "Slai O'lai", subBrand: "Slai O'lai Strawberry", name: "Slai O'lai Straw.", packSize: '90g', pcs: 36, casePrice: 432, mrp: 15, scheme: '' },
    { id: 'op7', brand: 'Danisa', subBrand: 'Danisa Butter', name: 'Danisa Butter', packSize: '200g', pcs: 12, casePrice: 1440, mrp: 150, scheme: '5% off >₹7.2k' },
    { id: 'op8', brand: 'Kopiko', subBrand: 'Kopiko Jar', name: 'Kopiko Jar', packSize: '140g', pcs: 12, casePrice: 768, mrp: 80, scheme: 'Vol. Slab 3–8%' },
    { id: 'op9', brand: 'Kopiko', subBrand: 'Kopiko Pouch', name: 'Kopiko Pouch', packSize: '27g', pcs: 48, casePrice: 768, mrp: 16, scheme: 'Vol. Slab 3–8%' },
    { id: 'op10', brand: 'KIS', subBrand: 'KIS Mint', name: 'KIS Mint', packSize: '18.4g', pcs: 60, casePrice: 480, mrp: 8, scheme: '' },
    { id: 'op11', brand: 'JuizyMilk', subBrand: 'JuizyMilk', name: 'JuizyMilk', packSize: '50g', pcs: 60, casePrice: 960, mrp: 16, scheme: '' },
    { id: 'op12', brand: 'Choki-Choki', subBrand: 'Choki-Choki', name: 'Choki-Choki', packSize: '10g × 10', pcs: 24, casePrice: 960, mrp: 40, scheme: 'Upcoming: 4–7%' }
];

const ORDER_BRANDS = ['Malkist', 'Coffee Joy', 'Roma', "Slai O'lai", 'Danisa', 'Kopiko', 'KIS', 'JuizyMilk', 'Choki-Choki', 'Beng-Beng', 'JoyMee'];

export const ORDER_CREDIT_LIMIT = 500000;
export const ORDER_ACTIVE_SCHEMES = 'Malkist B4G1 · JoyMee B10G2 · Kopiko Vol Slab 3–8% · Danisa 5% off above ₹7.2k';

export function getP1Orders() {
    return clone(P1_ORDERS);
}

export function getP2Orders() {
    return clone(P2_ORDERS);
}

export function getSecondaryOrders() {
    return clone(SECONDARY_ORDERS);
}

export function getOrderProducts() {
    return clone(ORDER_PRODUCTS);
}

export function getOrderBrands() {
    return [...ORDER_BRANDS];
}

const PRIMARY_INVOICES = [
    { id: 'PI-SAP-0892', date: '29 May 2026', supplier: 'Mayora India Ltd.', orderRef: 'PO-2847', amount: 74880, grnDone: false },
    { id: 'PI-SAP-0885', date: '26 May 2026', supplier: 'Mayora India Ltd.', orderRef: 'PO-2841', amount: 89280, grnDone: true },
    { id: 'PI-SAP-0871', date: '22 May 2026', supplier: 'Mayora India Ltd.', orderRef: 'PO-2835', amount: 89280, grnDone: false },
    { id: 'PI-SAP-0858', date: '14 May 2026', supplier: 'Mayora India Ltd.', orderRef: 'PO-2828', amount: 57600, grnDone: true },
    { id: 'PI-SAP-0841', date: '05 May 2026', supplier: 'Mayora India Ltd.', orderRef: 'PO-2820', amount: 57600, grnDone: true }
];

const SECONDARY_INVOICES = [
    { id: 'INV-1024', date: '27 May 2026', customer: 'City Grocery', type: 'Retailer', orderRef: 'SO-6425', amount: 24768 },
    { id: 'INV-1023', date: '25 May 2026', customer: 'North Zone SD', type: 'Sub-Dist.', orderRef: 'SO-6416', amount: 89280 },
    { id: 'INV-1022', date: '22 May 2026', customer: 'ABC Mart', type: 'Retailer', orderRef: 'SO-6410, SO-6405', amount: 38016 },
    { id: 'INV-1021', date: '20 May 2026', customer: 'Fresh Mart', type: 'Retailer', orderRef: 'SO-6402', amount: 12672 }
];

// Customers + their open orders for the Create Invoice wizard. Each order
// carries product lines (qty + rate); product names and the order amount are
// derived so the wizard's order list and review step reconcile.
const INVOICE_RETAILERS = ['ABC Mart', 'City Grocery', 'Fresh Mart', 'Metro General Store', 'Sharma Kirana'];
const INVOICE_SUBDISTS = ['North Zone SD', 'East Zone SD', 'West Zone SD'];

const RAW_CUSTOMER_ORDERS = {
    'ABC Mart': [
        { id: 'SO-6432', date: '29 May 2026', lines: [{ name: 'Malkist Cheese Crackers 130g', qty: 8, rate: 576 }, { name: 'Kopiko Coffee Candy Jar 140g', qty: 4, rate: 768 }, { name: 'Beng-Beng Wafer Chocolate 22g', qty: 6, rate: 576 }] },
        { id: 'SO-6418', date: '22 May 2026', lines: [{ name: 'Coffee Joy Thin Biscuit 100g', qty: 5, rate: 576 }, { name: 'KIS Mint Candy 18.4g', qty: 3, rate: 480 }] }
    ],
    'City Grocery': [
        { id: 'SO-6431', date: '28 May 2026', lines: [{ name: "Slai O'lai Strawberry 90g", qty: 8, rate: 432 }, { name: 'Roma Marie Gold 250g', qty: 6, rate: 672 }] }
    ],
    'Fresh Mart': [
        { id: 'SO-6424', date: '24 May 2026', lines: [{ name: 'Coffee Joy Thin Biscuit 100g', qty: 4, rate: 576 }, { name: 'Roma Marie Gold 250g', qty: 3, rate: 672 }] }
    ],
    'Metro General Store': [
        { id: 'SO-6420', date: '23 May 2026', lines: [{ name: "Slai O'lai Strawberry 90g", qty: 5, rate: 432 }, { name: 'Choki-Choki 10g', qty: 3, rate: 960 }] }
    ],
    'Sharma Kirana': [
        { id: 'SO-6412', date: '21 May 2026', lines: [{ name: 'Malkist Cheese Crackers 130g', qty: 4, rate: 576 }, { name: 'JoyMee Noodles 75g', qty: 3, rate: 432 }] }
    ],
    'North Zone SD': [
        { id: 'SO-6428', date: '25 May 2026', lines: [{ name: 'Malkist Cheese Crackers 130g', qty: 20, rate: 576 }, { name: 'Kopiko Jar 140g', qty: 15, rate: 768 }, { name: 'Danisa Butter 200g', qty: 10, rate: 1440 }] }
    ],
    'East Zone SD': [
        { id: 'SO-6416', date: '22 May 2026', lines: [{ name: 'Malkist Double Chocolatey 130g', qty: 18, rate: 576 }, { name: "Slai O'lai Strawberry 90g", qty: 25, rate: 432 }, { name: 'KIS Mint Candy 18.4g', qty: 30, rate: 480 }, { name: 'JuizyMilk Candy 50g', qty: 15, rate: 960 }] }
    ],
    'West Zone SD': [
        { id: 'SO-6414', date: '20 May 2026', lines: [{ name: 'Beng-Beng Wafer Chocolate 22g', qty: 12, rate: 480 }, { name: 'Coffee Joy Thin Biscuit 100g', qty: 5, rate: 576 }] }
    ]
};

const buildCustomerOrder = (o) => ({
    ...o,
    products: o.lines.map((l) => l.name),
    amount: o.lines.reduce((s, l) => s + l.qty * l.rate, 0)
});

const CUSTOMER_ORDERS = Object.fromEntries(
    Object.entries(RAW_CUSTOMER_ORDERS).map(([cust, orders]) => [cust, orders.map(buildCustomerOrder)])
);

export function getPrimaryInvoices() {
    return clone(PRIMARY_INVOICES);
}

export function getSecondaryInvoices() {
    return clone(SECONDARY_INVOICES);
}

export function getInvoiceCustomers() {
    return {
        Retailer: INVOICE_RETAILERS.map((name) => ({ name, type: 'Retailer' })),
        'Sub-Distributor': INVOICE_SUBDISTS.map((name) => ({ name, type: 'Sub-Dist.' }))
    };
}

export function getCustomerOrders(name) {
    return clone(CUSTOMER_ORDERS[name] || []);
}

/* ---------------------------------- GRN ----------------------------------- */

const GRN_LIST = [
    { id: 'GRN-0391', date: '26 May 2026', invoiceRef: 'PI-SAP-0885', skus: 6, officer: 'Rajesh K.', status: 'Complete' },
    { id: 'GRN-0385', date: '20 May 2026', invoiceRef: 'PI-SAP-0878', skus: 5, officer: 'Suresh M.', status: 'Complete' },
    { id: 'GRN-0378', date: '14 May 2026', invoiceRef: 'PI-SAP-0858', skus: 4, officer: 'Rajesh K.', status: 'Complete' },
    { id: 'GRN-0370', date: '07 May 2026', invoiceRef: 'PI-SAP-0841', skus: 4, officer: 'Amit S.', status: 'Complete' }
];

// Pending SAP invoices available to GRN (the "GRN Not Done" primary invoices).
const PENDING_GRN_INVOICES = [
    {
        id: 'PI-SAP-0892', date: '29 May 2026', amount: 74880,
        lines: [
            { sku: 'MLK-CHE-130', name: 'Malkist Cheese Crackers 130g', qty: 50, mfg: '01 Feb 2026', expiry: '29 Oct 2026', shelf: '270d shelf life' },
            { sku: 'KOP-JAR-140', name: 'Kopiko Coffee Candy Jar 140g', qty: 20, mfg: '15 Nov 2025', expiry: '15 Nov 2026', shelf: '365d shelf life' },
            { sku: 'JME-CHK-75', name: 'JoyMee Chicken Noodles 75g', qty: 40, mfg: '10 Mar 2026', expiry: '06 Sept 2026', shelf: '180d shelf life' },
            { sku: 'DAN-BUT-200', name: 'Danisa Butter Cookies 200g', qty: 8, mfg: '20 Jan 2026', expiry: '17 Oct 2026', shelf: '270d shelf life' }
        ]
    },
    {
        id: 'PI-SAP-0871', date: '22 May 2026', amount: 89280,
        lines: [
            { sku: 'MLK-CHO-130', name: 'Malkist Double Chocolatey 130g', qty: 60, mfg: '05 Feb 2026', expiry: '01 Nov 2026', shelf: '270d shelf life' },
            { sku: 'MLK-CAP-130', name: 'Malkist Cappuccino Crackers 130g', qty: 40, mfg: '05 Feb 2026', expiry: '01 Nov 2026', shelf: '270d shelf life' },
            { sku: 'BNG-CHO-20', name: 'Beng-Beng Wafer Chocolate 22g', qty: 100, mfg: '12 Mar 2026', expiry: '08 Sept 2026', shelf: '180d shelf life' },
            { sku: 'CHK-CHO-50', name: 'Choki-Choki Chocolate Paste (10g×10)', qty: 30, mfg: '18 Jan 2026', expiry: '15 Oct 2026', shelf: '270d shelf life' }
        ]
    }
];

export function getGrnList() {
    return clone(GRN_LIST);
}

export function getPendingGrnInvoices() {
    return clone(PENDING_GRN_INVOICES);
}

/* --------------------------------- Ledger --------------------------------- */

// Running-balance account statement (Dr positive). balance is pre-computed.
const LEDGER_TX = [
    { date: '01 May 2026', type: 'Opening Bal.', narration: 'Opening Balance (brought forward)', ref: '', debit: 0, credit: 0, balance: 45000 },
    { date: '05 May 2026', type: 'Primary Invoice', narration: 'Primary Invoice — PI-SAP-0871', ref: 'PI-SAP-0871', debit: 57600, credit: 0, balance: 102600 },
    { date: '08 May 2026', type: 'Payment Received', narration: 'Payment Received — NEFT/HDFC', ref: 'PMT-4810', debit: 0, credit: 102600, balance: 0 },
    { date: '14 May 2026', type: 'Primary Invoice', narration: 'Primary Invoice — PI-SAP-0878', ref: 'PI-SAP-0878', debit: 57600, credit: 0, balance: 57600 },
    { date: '15 May 2026', type: 'Return Credit', narration: 'Return Credit Note — RET-043', ref: 'RET-043', debit: 0, credit: 5760, balance: 51840 },
    { date: '17 May 2026', type: 'Scheme Claim', narration: 'Scheme Claim Credit Note — Choki-Choki Q4', ref: 'SCH-0041', debit: 0, credit: 2880, balance: 48960 },
    { date: '20 May 2026', type: 'Payment Received', narration: 'Payment Received — NEFT/HDFC', ref: 'PMT-4825', debit: 0, credit: 48960, balance: 0 },
    { date: '22 May 2026', type: 'Primary Invoice', narration: 'Primary Invoice — PI-SAP-0885', ref: 'PI-SAP-0885', debit: 89280, credit: 0, balance: 89280 },
    { date: '24 May 2026', type: 'Payment Received', narration: 'Payment Received — NEFT/HDFC', ref: 'PMT-4830', debit: 0, credit: 89280, balance: 0 },
    { date: '26 May 2026', type: 'Primary Invoice', narration: 'Primary Invoice — PI-SAP-0892', ref: 'PI-SAP-0892', debit: 74880, credit: 0, balance: 74880 },
    { date: '28 May 2026', type: 'Primary Invoice', narration: 'Primary Invoice — PI-SAP-0896', ref: 'PI-SAP-0896', debit: 89280, credit: 0, balance: 164160 },
    { date: '30 May 2026', type: 'Return Credit', narration: 'Return Credit Note — RET-046', ref: 'RET-046', debit: 0, credit: 5760, balance: 158400 },
    { date: '31 May 2026', type: 'Payment Received', narration: 'Payment Received — NEFT/HDFC', ref: 'PMT-4842', debit: 0, credit: 6720, balance: 151680 }
];

export function getLedger() {
    return clone(LEDGER_TX);
}

/* -------------------------------- Inventory ------------------------------- */

const INVENTORY = [
    { sku: 'MLK-CHE-130', name: 'Malkist Cheese Crackers', brand: 'Malkist', subBrand: 'Malkist Cheese', packSize: '130g', cases: 475, units: 11400, soldOut: 175, value: 274000, expired: 0, status: 'In Stock' },
    { sku: 'MLK-CHO-130', name: 'Malkist Double Chocolatey', brand: 'Malkist', subBrand: 'Malkist Choco', packSize: '130g', cases: 320, units: 7680, soldOut: 150, value: 184000, expired: 0, status: 'In Stock' },
    { sku: 'MLK-CAP-130', name: 'Malkist Cappuccino Crackers', brand: 'Malkist', subBrand: 'Malkist Cappuccino', packSize: '130g', cases: 270, units: 6480, soldOut: 130, value: 156000, expired: 0, status: 'In Stock' },
    { sku: 'CFJ-100', name: 'Coffee Joy Thin Biscuit', brand: 'Coffee Joy', subBrand: 'Coffee Joy Thin', packSize: '100g', cases: 520, units: 18720, soldOut: 200, value: 300000, expired: 2, status: 'In Stock' },
    { sku: 'RMG-250', name: 'Roma Marie Gold', brand: 'Roma', subBrand: 'Roma Marie Gold', packSize: '250g', cases: 180, units: 4320, soldOut: 90, value: 121000, expired: 0, status: 'In Stock' },
    { sku: 'SOL-STR-90', name: "Slai O'lai Strawberry", brand: "Slai O'lai", subBrand: "Slai O'lai Strawberry", packSize: '90g', cases: 300, units: 10800, soldOut: 120, value: 130000, expired: 0, status: 'In Stock' },
    { sku: 'KOP-JAR-140', name: 'Kopiko Jar', brand: 'Kopiko', subBrand: 'Kopiko Jar', packSize: '140g', cases: 260, units: 3120, soldOut: 100, value: 200000, expired: 0, status: 'In Stock' },
    { sku: 'KOP-PCH-27', name: 'Kopiko Pouch', brand: 'Kopiko', subBrand: 'Kopiko Pouch', packSize: '27g', cases: 480, units: 23040, soldOut: 180, value: 369000, expired: 0, status: 'In Stock' },
    { sku: 'BNG-CHO-20', name: 'Beng-Beng Wafer Chocolate', brand: 'Beng-Beng', subBrand: 'Beng-Beng Original', packSize: '20g', cases: 540, units: 25920, soldOut: 210, value: 259000, expired: 0, status: 'In Stock' },
    { sku: 'JME-CHK-75', name: 'JoyMee Chicken Noodles', brand: 'JoyMee', subBrand: 'JoyMee Cup', packSize: '75g', cases: 360, units: 12960, soldOut: 140, value: 156000, expired: 0, status: 'In Stock' },
    { sku: 'DAN-BUT-200', name: 'Danisa Butter Cookies', brand: 'Danisa', subBrand: 'Danisa Butter', packSize: '200g', cases: 220, units: 2640, soldOut: 80, value: 317000, expired: 0, status: 'In Stock' },
    { sku: 'CHK-CHO-50', name: 'Choki-Choki Chocolate Paste', brand: 'Choki-Choki', subBrand: 'Choki-Choki Paste', packSize: '10g × 10', cases: 300, units: 7200, soldOut: 110, value: 288000, expired: 0, status: 'In Stock' },
    { sku: 'KIS-MNT-18', name: 'KIS Mint Candy', brand: 'KIS', subBrand: 'KIS Mint', packSize: '18.4g', cases: 415, units: 24900, soldOut: 160, value: 199000, expired: 0, status: 'In Stock' },
    { sku: 'JMK-50', name: 'JuizyMilk Candy', brand: 'JuizyMilk', subBrand: 'JuizyMilk', packSize: '50g', cases: 460, units: 27600, soldOut: 170, value: 307000, expired: 0, status: 'In Stock' }
];

const STOCK_ADJUSTMENTS = [
    { id: 'ADJ-0011', date: '28 May 2026', product: 'Malkist Cheese', sku: 'MLK-CHE-130', type: 'Remove', reason: 'Damaged', qty: -2, notes: 'Cartons crushed during unloading from truck.', by: 'Ravi Kumar' },
    { id: 'ADJ-0010', date: '27 May 2026', product: 'Kopiko Pouch', sku: 'KOP-PCH-27', type: 'Remove', reason: 'Expiry', qty: -3, notes: 'Expired batch – Best Before Apr 2026.', by: 'Ravi Kumar' },
    { id: 'ADJ-0009', date: '25 May 2026', product: 'Beng-Beng', sku: 'BBG-22', type: 'Remove', reason: 'Missing', qty: -1, notes: 'Physical count short by 1 carton. Under investigation.', by: 'Sunil Patil' },
    { id: 'ADJ-0008', date: '22 May 2026', product: "Slai O'lai Straw.", sku: 'SOL-STR-90', type: 'Remove', reason: 'Non-saleable', qty: -2, notes: 'Packaging torn; not fit for sale to retailer.', by: 'Ravi Kumar' },
    { id: 'ADJ-0007', date: '20 May 2026', product: 'Danisa Butter', sku: 'DAN-BUT-200', type: 'Add', reason: 'Other', qty: 4, notes: 'Credit note received from Mayora – extra stock.', by: 'Sunil Patil' },
    { id: 'ADJ-0006', date: '18 May 2026', product: 'Kopiko Jar', sku: 'KOP-JAR-140', type: 'Remove', reason: 'Damaged', qty: -2, notes: 'Leakage found in 2 cartons during storage.', by: 'Ravi Kumar' },
    { id: 'ADJ-0005', date: '15 May 2026', product: 'JoyMee Noodles', sku: 'JME-CHK-75', type: 'Remove', reason: 'Missing', qty: -1, notes: 'Short received against GRN; raised with transporter.', by: 'Sunil Patil' }
];

export function getInventory() {
    return clone(INVENTORY);
}

export function getStockAdjustments() {
    return clone(STOCK_ADJUSTMENTS);
}

/* --------------------------------- Returns -------------------------------- */

const P1_RETURNS = [
    { id: 'RET-045', date: '28 May 2026', qty: 5, status: 'Approved' },
    { id: 'RET-043', date: '20 May 2026', qty: 5, status: 'Approved' },
    { id: 'RET-040', date: '10 May 2026', qty: 4, status: 'Approved' },
    { id: 'RET-038', date: '02 May 2026', qty: 11, status: 'Rejected' }
];

const P2_RETURNS = [
    { id: 'P2RET-012', date: '25 May 2026', qty: 3, status: 'Pending' },
    { id: 'P2RET-011', date: '14 May 2026', qty: 5, status: 'Approved' },
    { id: 'P2RET-010', date: '02 Apr 2026', qty: 2, status: 'Approved' }
];

const SECONDARY_RETURNS = [
    { id: 'SRET-012', date: '27 May 2026', customer: 'ABC Mart', type: 'Retailer', qty: 5, status: 'Pending' },
    { id: 'SRET-011', date: '24 May 2026', customer: 'North Zone SD', type: 'Sub-Dist.', qty: 18, status: 'Approved' },
    { id: 'SRET-010', date: '20 May 2026', customer: 'City Grocery', type: 'Retailer', qty: 2, status: 'Approved' },
    { id: 'SRET-009', date: '15 May 2026', customer: 'East Zone SD', type: 'Sub-Dist.', qty: 9, status: 'Approved' },
    { id: 'SRET-008', date: '10 May 2026', customer: 'Fresh Mart', type: 'Retailer', qty: 3, status: 'Pending' }
];

// GRN-done SAP invoices that can be returned against (Create Primary Return).
const RETURNABLE_INVOICES = [
    { id: 'PI-SAP-0885', date: '26 May 2026', lines: [{ name: 'Malkist Cheese Crackers 130g', delivered: 50 }, { name: 'Kopiko Coffee Candy Jar 140g', delivered: 20 }, { name: 'JoyMee Chicken Noodles 75g', delivered: 40 }] },
    { id: 'PI-SAP-0858', date: '14 May 2026', lines: [{ name: 'Malkist Double Chocolatey 130g', delivered: 60 }, { name: 'Danisa Butter Cookies 200g', delivered: 8 }, { name: 'Beng-Beng Wafer Chocolate 22g', delivered: 100 }] }
];

export function getReturns() {
    return { p1: clone(P1_RETURNS), p2: clone(P2_RETURNS), secondary: clone(SECONDARY_RETURNS) };
}

export function getReturnableInvoices() {
    return clone(RETURNABLE_INVOICES);
}


/* --------------------------- Home: P1 Dashboard --------------------------- */

const P1_DASHBOARD = {
    kpis: [
        { id: 'tov', label: 'Total Order Value', value: formatLakh(498000) },
        { id: 'tiv', label: 'Total Invoice Value', value: formatLakh(416000) },
        { id: 'noo', label: 'No. of Orders', value: '8' },
        { id: 'grn', label: 'GRN Pending', value: '2', variant: 'warning' },
        { id: 'noi', label: 'No. of Invoices', value: '6' },
        { id: 'nor', label: 'No. of Returns', value: '4', variant: 'danger' }
    ],
    // Order Analysis is grouped by dimension; each has order-count + value series.
    orderAnalysis: {
        brand: {
            orders: [
                { label: 'Malkist', value: 18 }, { label: 'Kopiko', value: 12 },
                { label: 'Beng-Beng', value: 10 }, { label: 'JoyMee', value: 7 },
                { label: 'Coffee Joy', value: 5 }, { label: 'Danisa', value: 4 },
                { label: 'Choki-Choki', value: 3 }
            ],
            value: [
                { label: 'Malkist', value: 1.95 }, { label: 'Kopiko', value: 1.45 },
                { label: 'Beng-Beng', value: 1.2 }, { label: 'JoyMee', value: 0.8 },
                { label: 'Coffee Joy', value: 0.6 }, { label: 'Danisa', value: 0.4 },
                { label: 'Choki-Choki', value: 0.3 }
            ]
        },
        subBrand: {
            orders: [
                { label: 'Malkist Crackers', value: 11 }, { label: 'Malkist Choco', value: 7 },
                { label: 'Kopiko Classic', value: 8 }, { label: 'Kopiko Brown', value: 4 },
                { label: 'Beng-Beng Share', value: 6 }, { label: 'JoyMee Cup', value: 5 }
            ],
            value: [
                { label: 'Malkist Crackers', value: 1.2 }, { label: 'Malkist Choco', value: 0.75 },
                { label: 'Kopiko Classic', value: 0.95 }, { label: 'Kopiko Brown', value: 0.5 },
                { label: 'Beng-Beng Share', value: 0.7 }, { label: 'JoyMee Cup', value: 0.55 }
            ]
        },
        brandAlias: {
            orders: [
                { label: 'MLK', value: 18 }, { label: 'KPK', value: 12 },
                { label: 'BNG', value: 10 }, { label: 'JME', value: 7 },
                { label: 'CFJ', value: 5 }, { label: 'DAN', value: 4 }
            ],
            value: [
                { label: 'MLK', value: 1.95 }, { label: 'KPK', value: 1.45 },
                { label: 'BNG', value: 1.2 }, { label: 'JME', value: 0.8 },
                { label: 'CFJ', value: 0.6 }, { label: 'DAN', value: 0.4 }
            ]
        }
    },
    skuReturns: [
        { code: 'MLK-CHE-130', name: 'Malkist Cheese Crackers 130g', qty: '14 ctns' },
        { code: 'KOP-JAR-140', name: 'Kopiko Coffee Candy Jar 140g', qty: '8 ctns' },
        { code: 'MLK-CHO-130', name: 'Malkist Double Chocolatey 130g', qty: '6 ctns' },
        { code: 'JME-CHK-75', name: 'JoyMee Chicken Noodles 75g', qty: '4 ctns' },
        { code: 'DAN-BUT-200', name: 'Danisa Butter Cookies 200g', qty: '2 ctns' }
    ],
    schemeClaims: [
        { name: 'Malkist Buy 4 Get 1', value: formatCurrency(18720), status: 'Approved' },
        { name: 'Kopiko Volume Slab 5%', value: formatCurrency(11520), status: 'Pending' },
        { name: 'Beng-Beng Display Scheme', value: formatCurrency(8400), status: 'Approved' },
        { name: 'Danisa Festive Combo', value: formatCurrency(6250), status: 'Pending' }
    ]
};

/* --------------------------- Home: P2 Dashboard --------------------------- */

const P2_DASHBOARD = {
    kpis: [
        { id: 'sd', label: 'Active SDs', value: '5' },
        { id: 'noo', label: 'No. of Orders', value: '46', variant: 'accent' },
        { id: 'noi', label: 'No. of Invoices', value: '41' },
        { id: 'nor', label: 'No. of Returns', value: '6', variant: 'danger' },
        { id: 'ov', label: 'Order Value', value: formatLakh(599000), variant: 'accent' },
        { id: 'iv', label: 'Invoice Value', value: formatLakh(559000), variant: 'accent' },
        { id: 'rv', label: 'Return Value', value: formatLakh(40000), variant: 'danger' }
    ],
    topSDs: [
        { label: 'North Zone SD (Mira-Bhayander)', value: 1.82 },
        { label: 'East Zone SD (Thane)', value: 1.45 },
        { label: 'West Zone SD (Vasai-Virar)', value: 1.12 },
        { label: 'Central SD (Bhiwandi)', value: 0.88 },
        { label: 'Harbour SD (Navi Mumbai)', value: 0.72 }
    ],
    allSDs: [
        { name: 'North Zone SD (Mira-Bhayander)', orders: '14', invoices: '12', returns: '2', ov: '₹1.82L', iv: '₹1.65L', rv: '₹0.17L' },
        { name: 'East Zone SD (Thane)', orders: '11', invoices: '10', returns: '1', ov: '₹1.45L', iv: '₹1.38L', rv: '₹0.07L' },
        { name: 'West Zone SD (Vasai-Virar)', orders: '9', invoices: '8', returns: '2', ov: '₹1.12L', iv: '₹1.02L', rv: '₹0.10L' },
        { name: 'Central SD (Bhiwandi)', orders: '7', invoices: '6', returns: '1', ov: '₹0.88L', iv: '₹0.82L', rv: '₹0.06L' },
        { name: 'Harbour SD (Navi Mumbai)', orders: '5', invoices: '5', returns: '—', ov: '₹0.72L', iv: '₹0.72L', rv: '—' },
        { name: 'South SD (Panvel)', noSales: true, orders: '—', invoices: '—', returns: '—', ov: '—', iv: '—', rv: '—' },
        { name: 'Suburban SD (Kalyan-Dombivali)', noSales: true, orders: '—', invoices: '—', returns: '—', ov: '—', iv: '—', rv: '—' }
    ],
    rangeSelling: {
        brand: [
            { name: 'Malkist', covered: '38 / 45', pct: 84 }, { name: 'Kopiko', covered: '30 / 45', pct: 67 },
            { name: 'Beng-Beng', covered: '25 / 45', pct: 56 }, { name: 'JoyMee', covered: '20 / 45', pct: 44 },
            { name: 'Coffee Joy', covered: '15 / 45', pct: 33 }, { name: 'Danisa', covered: '12 / 45', pct: 27 },
            { name: 'Choki-Choki', covered: '10 / 45', pct: 22 }
        ],
        subBrand: [
            { name: 'Malkist Crackers', covered: '34 / 45', pct: 76 }, { name: 'Malkist Choco', covered: '22 / 45', pct: 49 },
            { name: 'Kopiko Classic', covered: '28 / 45', pct: 62 }, { name: 'Beng-Beng Share', covered: '19 / 45', pct: 42 }
        ],
        brandAlias: [
            { name: 'MLK', covered: '38 / 45', pct: 84 }, { name: 'KPK', covered: '30 / 45', pct: 67 },
            { name: 'BNG', covered: '25 / 45', pct: 56 }, { name: 'JME', covered: '20 / 45', pct: 44 }
        ],
        sku: [
            { name: 'MLK-CHE-130', covered: '31 / 45', pct: 69 }, { name: 'KOP-JAR-140', covered: '27 / 45', pct: 60 },
            { name: 'BNG-CHOC-24', covered: '23 / 45', pct: 51 }, { name: 'JME-CHK-75', covered: '18 / 45', pct: 40 }
        ]
    },
    tickets: [
        { id: 'TKT-001', subject: 'Invoice discrepancy — North Zone SD', priority: 'High', priorityTheme: 'danger', status: 'Open', statusTheme: 'info' },
        { id: 'TKT-002', subject: 'Scheme credit not applied — East SD', priority: 'Medium', priorityTheme: 'warning', status: 'In Review', statusTheme: 'warning' },
        { id: 'TKT-003', subject: 'Return approval delay — West SD', priority: 'Low', priorityTheme: 'neutral', status: 'Resolved', statusTheme: 'success' }
    ]
};

/* ------------------------ Home: Secondary Dashboard ----------------------- */

const SECONDARY_DASHBOARD = {
    kpisTop: [
        { id: 'ao', label: 'Active Outlets', value: '45', variant: 'brand' },
        { id: 'beats', label: 'No. of Beats', value: '6', variant: 'brand' },
        { id: 'users', label: 'No. of Users', value: '8', variant: 'brand' }
    ],
    kpisMain: [
        { id: 'noo', label: 'No. of Orders', value: '38', variant: 'brand' },
        { id: 'noi', label: 'No. of Invoices', value: '34', variant: 'brand' },
        { id: 'nor', label: 'No. of Returns', value: '5', variant: 'brand' },
        { id: 'ov', label: 'Order Value', value: formatLakh(649000), variant: 'brand' },
        { id: 'iv', label: 'Invoice Value', value: formatLakh(593000), variant: 'brand' },
        { id: 'rv', label: 'Return Value', value: formatLakh(56000), variant: 'brand' }
    ],
    beatSales: [
        { label: 'Andheri West', value: 1.05 }, { label: 'Bandra-Kurla', value: 1.5 },
        { label: 'Borivali North', value: 0.78 }, { label: 'Malad-Goregaon', value: 0.92 },
        { label: 'Kandivali', value: 0.62 }, { label: 'Jogeshwari', value: 0.5 }
    ],
    outletTypes: [
        { label: 'Kirana', value: 18 }, { label: 'Supermarket', value: 10 },
        { label: 'Wholesale', value: 8 }, { label: 'Bakery', value: 5 }, { label: 'Tea Shop', value: 4 }
    ],
    topCustomers: [
        { label: 'ABC Mart (Andheri W.)', value: 0.98 }, { label: 'City Grocery (Bandra E.)', value: 0.82 },
        { label: 'North Zone SD (Mira-Bhayander)', value: 0.7 }, { label: 'Quick Mart (Borivali)', value: 0.6 },
        { label: 'Star Kirana (Malad)', value: 0.5 }
    ],
    rangeSelling: {
        brand: [
            { name: 'Malkist', covered: '38 / 45', pct: 84 }, { name: 'Kopiko', covered: '30 / 45', pct: 67 },
            { name: 'Beng-Beng', covered: '25 / 45', pct: 56 }, { name: 'JoyMee', covered: '20 / 45', pct: 44 },
            { name: 'Coffee Joy', covered: '15 / 45', pct: 33 }, { name: 'Danisa', covered: '12 / 45', pct: 27 },
            { name: 'Choki-Choki', covered: '10 / 45', pct: 22 }
        ],
        subBrand: [
            { name: 'Malkist Crackers', covered: '34 / 45', pct: 76 }, { name: 'Malkist Choco', covered: '22 / 45', pct: 49 },
            { name: 'Kopiko Classic', covered: '28 / 45', pct: 62 }, { name: 'Beng-Beng Share', covered: '19 / 45', pct: 42 }
        ],
        brandAlias: [
            { name: 'MLK', covered: '38 / 45', pct: 84 }, { name: 'KPK', covered: '30 / 45', pct: 67 },
            { name: 'BNG', covered: '25 / 45', pct: 56 }, { name: 'JME', covered: '20 / 45', pct: 44 }
        ],
        sku: [
            { name: 'MLK-CHE-130', covered: '31 / 45', pct: 69 }, { name: 'KOP-JAR-140', covered: '27 / 45', pct: 60 },
            { name: 'BNG-CHOC-24', covered: '23 / 45', pct: 51 }, { name: 'JME-CHK-75', covered: '18 / 45', pct: 40 }
        ]
    },
    secondaryCollection: [
        { customer: 'ABC Mart (Andheri W.)', inv: 'INV-1024', amt: formatCurrency(24768), collected: formatCurrency(24768), status: 'Collected', statusTheme: 'success' },
        { customer: 'City Grocery (Bandra E.)', inv: 'INV-1023', amt: formatCurrency(89280), collected: formatCurrency(60000), status: 'Partial', statusTheme: 'warning' },
        { customer: 'North Zone SD (Mira-Bhayander)', inv: 'INV-1022', amt: formatCurrency(38016), collected: '—', status: 'Pending', statusTheme: 'danger' },
        { customer: 'Quick Mart (Borivali)', inv: 'INV-1021', amt: formatCurrency(12672), collected: formatCurrency(12672), status: 'Collected', statusTheme: 'success' },
        { customer: 'Star Kirana (Malad)', inv: 'INV-1019', amt: formatCurrency(31200), collected: formatCurrency(31200), status: 'Collected', statusTheme: 'success' }
    ],
    newOutletsLabel: 'This JC: 4 new',
    newOutlets: [
        { name: 'Sunrise Kirana (Goregaon W.)', beat: 'Malad–Goregaon', type: 'Kirana', date: '03 Jun 2026' },
        { name: 'Fresh Bake (Kandivali E.)', beat: 'Kandivali', type: 'Bakery', date: '01 Jun 2026' },
        { name: 'Metro Wholesale (Andheri)', beat: 'Andheri West', type: 'Wholesale', date: '28 May 2026' },
        { name: 'Coffee Corner (Bandra)', beat: 'Bandra–Kurla', type: 'Tea Shop', date: '26 May 2026' }
    ],
    tickets: [
        { id: 'TKT-004', subject: 'Overcharge on INV-1023 — City Grocery', priority: 'High', priorityTheme: 'danger', status: 'Open', statusTheme: 'info' },
        { id: 'TKT-005', subject: 'New outlet approval — Sunrise Kirana', priority: 'Medium', priorityTheme: 'warning', status: 'In Review', statusTheme: 'warning' },
        { id: 'TKT-006', subject: 'Beat route change request — Kandivali', priority: 'Low', priorityTheme: 'neutral', status: 'Resolved', statusTheme: 'success' }
    ]
};

export function getP1Dashboard() {
    return clone(P1_DASHBOARD);
}

export function getP2Dashboard() {
    return clone(P2_DASHBOARD);
}

export function getSecondaryDashboard() {
    return clone(SECONDARY_DASHBOARD);
}

/** Period selector options shared across dashboards. */
export function getPeriodOptions() {
    return [
        { label: 'This JC', value: 'this-jc' },
        { label: 'Last JC', value: 'last-jc' },
        { label: 'MTD', value: 'mtd' },
        { label: 'QTD', value: 'qtd' },
        { label: 'YTD', value: 'ytd' }
    ];
}

/* ======================================================================== */
/* Admin / Config screens (Phase 1 prototype)                               */
/* Position & Role Management, Scheme Management, Product Sharing, Targets.  */
/* These mirror the Mayora Salesforce & Schemes architecture documents.     */
/* Additive only — existing screens above are untouched.                    */
/* ======================================================================== */

/* ------------------- Position & Role Management (BRD §5–6) ---------------- */
/* When a Position is created a matching Role is auto-created and mapped.    */
/* When a User is assigned, that Role + Profile + Manager flow to the user   */
/* and the user owns all records tied to the Position. Vacant => Sys Admin.  */

const POSITIONS = [
    { code: 'PC-NSM-01', designation: 'NSM', level: 'L8', area: 'National', reportsTo: '—', role: 'NSM-Role', user: 'Suresh Menon', status: 'Filled', beats: 0 },
    { code: 'PC-ZSM-W', designation: 'ZSM', level: 'L7', area: 'West Zone', reportsTo: 'PC-NSM-01', role: 'ZSM-W-Role', user: 'Anil Kapoor', status: 'Filled', beats: 0 },
    { code: 'PC-RSM-MH', designation: 'RSM', level: 'L6', area: 'Maharashtra Region', reportsTo: 'PC-ZSM-W', role: 'RSM-MH-Role', user: 'Deepak Joshi', status: 'Filled', beats: 0 },
    { code: 'PC-ASM-PUN', designation: 'ASM', level: 'L5', area: 'Pune Area', reportsTo: 'PC-RSM-MH', role: 'ASM-PUN-Role', user: 'Ravindra Patil', status: 'Filled', beats: 0 },
    { code: 'PC-DO-PUN-2', designation: 'DO', level: 'L2', area: 'Pune City', reportsTo: 'PC-ASM-PUN', role: 'DO-PUN-2-Role', user: '—', status: 'Vacant', beats: 4 },
    { code: 'PC-SR-PUN-05', designation: 'SR', level: 'L1', area: 'Pune City', reportsTo: 'PC-DO-PUN-2', role: 'SR-PUN-05-Role', user: 'Manoj Kale', status: 'Filled', beats: 6 },
    { code: 'PC-SR-PUN-06', designation: 'SR', level: 'L1', area: 'Pune City', reportsTo: 'PC-DO-PUN-2', role: 'SR-PUN-06-Role', user: '—', status: 'Vacant', beats: 5 },
    { code: 'PC-DBSM-PUN', designation: 'DBSM', level: 'L1', area: 'Pune City', reportsTo: 'PC-DO-PUN-2', role: 'DBSM-PUN-Role', user: 'Sunil Rao', status: 'Filled', beats: 3 },
    { code: 'PC-CFA-W', designation: 'CFA', level: 'L5 (parallel)', area: 'West Zone', reportsTo: '— (independent)', role: 'CFA-W-Role', user: 'Western C&F Agent', status: 'Filled', beats: 0 }
];

/* Temporary beat assignments (BRD §5.3) — cover an absent user / group work. */
const TEMP_ASSIGNMENTS = [
    { beat: 'Kothrud–Karve Rd', fromPosition: 'PC-SR-PUN-06', toUser: 'Manoj Kale', start: '14 Jun 2026', end: '20 Jun 2026', status: 'Active' },
    { beat: 'Hadapsar East', fromPosition: 'PC-SR-PUN-05', toUser: 'Sunil Rao', start: '10 Jun 2026', end: '12 Jun 2026', status: 'Expired' },
    { beat: 'Viman Nagar', fromPosition: 'PC-DO-PUN-2', toUser: 'Ravindra Patil', start: '17 Jun 2026', end: '24 Jun 2026', status: 'Active' }
];

export function getPositions() {
    return clone(POSITIONS);
}

export function getTempAssignments() {
    return clone(TEMP_ASSIGNMENTS);
}

/* ------------------- Scheme Management engine (BRD §13) ------------------- */
/* Header (Scheme) + children: Slabs, Eligibility, Bundle Lines, Tiers, plus */
/* the Claim settlement record — per the Schemes Architecture document.      */

const MANAGED_SCHEMES = [
    {
        id: 'SCH-0001', name: 'Malkist Secondary Buy 4 Get 1', schemeClass: 'Secondary',
        type: 'Proportional', basis: 'Single-Invoice', benefit: 'Free goods', passThrough: false,
        claimable: false, start: '01 Jun 2026', end: '30 Jun 2026', budget: 500000, utilized: 312000,
        status: 'Active', eligibility: 'GT · Maharashtra · All GT outlets',
        slabs: [{ buy: 4, get: 1, note: 'Ratio repeats per block of 4' }],
        eligibilityRows: [{ region: 'Maharashtra', channel: 'General Trade', outletType: 'All', tag: '—' }],
        tiers: [], bundleLines: []
    },
    {
        id: 'SCH-0002', name: 'Kopiko Volume Slab', schemeClass: 'Secondary',
        type: 'Slab', basis: 'Cycle-Cumulative', benefit: 'Free goods', passThrough: false,
        claimable: true, start: '01 Jun 2026', end: '28 Jun 2026', budget: 800000, utilized: 760000,
        status: 'Active', eligibility: 'GT · All-India · Alpha outlets',
        slabs: [
            { buy: 12, get: 2, note: 'Step 1' },
            { buy: 24, get: 5, note: 'Step 2' },
            { buy: 48, get: 12, note: 'Step 3 — highest reached is paid' }
        ],
        eligibilityRows: [{ region: 'All-India', channel: 'General Trade', outletType: 'All', tag: 'Alpha' }],
        tiers: [], bundleLines: []
    },
    {
        id: 'SCH-0003', name: 'Beng-Beng Festive Bundle', schemeClass: 'Secondary',
        type: 'Bundle', basis: 'Single-Invoice', benefit: 'Free goods', passThrough: false,
        claimable: false, start: '05 Jun 2026', end: '15 Jul 2026', budget: 300000, utilized: 84000,
        status: 'Active', eligibility: 'Both · Maharashtra + Gujarat',
        slabs: [],
        eligibilityRows: [
            { region: 'Maharashtra', channel: 'Both', outletType: 'All', tag: '—' },
            { region: 'Gujarat', channel: 'Both', outletType: 'All', tag: '—' }
        ],
        tiers: [],
        bundleLines: [
            { product: 'Beng-Beng Wafer Chocolate', qty: 2, role: 'Buy' },
            { product: 'Choki-Choki Chocolate Paste', qty: 1, role: 'Buy' },
            { product: 'Beng-Beng Wafer Chocolate', qty: 1, role: 'Free' }
        ]
    },
    {
        id: 'SCH-0004', name: 'Roma Order-Value Flat Discount', schemeClass: 'Secondary',
        type: 'Value-Based', basis: 'Single-Invoice', benefit: 'Value discount', passThrough: false,
        claimable: false, start: '01 Jun 2026', end: '30 Jun 2026', budget: 250000, utilized: 240000,
        status: 'Active', eligibility: 'GT · Maharashtra · Wholesale',
        slabs: [
            { buy: 10000, get: 0, note: '≥ ₹10,000 → 3% off total' },
            { buy: 25000, get: 0, note: '≥ ₹25,000 → 5% off total' }
        ],
        eligibilityRows: [{ region: 'Maharashtra', channel: 'General Trade', outletType: 'Wholesale', tag: '—' }],
        tiers: [], bundleLines: []
    },
    {
        id: 'SCH-0005', name: 'Danisa P1→P2→P3 Pass-Through', schemeClass: 'Primary',
        type: 'Slab', basis: 'Single-Invoice', benefit: 'Free goods', passThrough: true,
        claimable: true, start: '01 Jun 2026', end: '31 Jul 2026', budget: 1200000, utilized: 0,
        status: 'Pending Director', eligibility: 'GT · All-India',
        slabs: [],
        eligibilityRows: [{ region: 'All-India', channel: 'General Trade', outletType: 'All', tag: '—' }],
        tiers: [
            { tier: 'P1 (Primary)', buy: 4, get: 1, note: 'Mayora → distributor' },
            { tier: 'P2 (Secondary)', buy: 4, get: 1, note: 'distributor → wholesaler' },
            { tier: 'P3 (Retail)', buy: 8, get: 1, note: 'wholesaler → retailer' }
        ],
        bundleLines: []
    },
    {
        id: 'SCH-0006', name: 'Coffee Joy Monsoon Slab', schemeClass: 'Secondary',
        type: 'Slab', basis: 'Period-Cumulative', benefit: 'Percent discount', passThrough: false,
        claimable: true, start: '01 Jul 2026', end: '28 Jul 2026', budget: 400000, utilized: 0,
        status: 'Pending IT Review', eligibility: 'GT · Karnataka',
        slabs: [
            { buy: 20, get: 0, note: '≥ 20 cartons → 4% off' },
            { buy: 40, get: 0, note: '≥ 40 cartons → 7% off' }
        ],
        eligibilityRows: [{ region: 'Karnataka', channel: 'General Trade', outletType: 'All', tag: '—' }],
        tiers: [], bundleLines: []
    },
    {
        id: 'SCH-0007', name: 'JoyMee Noodles Buy 10 Get 2', schemeClass: 'Secondary',
        type: 'Slab', basis: 'Single-Invoice', benefit: 'Free goods', passThrough: false,
        claimable: false, start: '20 May 2026', end: '31 May 2026', budget: 200000, utilized: 200000,
        status: 'Expired', eligibility: 'GT · Maharashtra',
        slabs: [{ buy: 10, get: 2, note: 'Single step' }],
        eligibilityRows: [{ region: 'Maharashtra', channel: 'General Trade', outletType: 'All', tag: '—' }],
        tiers: [], bundleLines: []
    },
    {
        id: 'SCH-0008', name: 'Choki-Choki Draft Combo', schemeClass: 'Secondary',
        type: 'Bundle', basis: 'Single-Invoice', benefit: 'Free goods', passThrough: false,
        claimable: false, start: '01 Aug 2026', end: '31 Aug 2026', budget: 150000, utilized: 0,
        status: 'Draft', eligibility: 'Not set',
        slabs: [],
        eligibilityRows: [],
        tiers: [],
        bundleLines: [{ product: 'Choki-Choki Chocolate Paste', qty: 3, role: 'Buy' }, { product: 'Choki-Choki Chocolate Paste', qty: 1, role: 'Free' }]
    }
];

/* Settlement records for cumulative schemes (Scheme_Claim__c). */
const SCHEME_CLAIMS = [
    { id: 'CLM-2041', scheme: 'Kopiko Volume Slab', distributor: 'Pune Super Stockiest', amount: 48200, status: 'Approved' },
    { id: 'CLM-2042', scheme: 'Kopiko Volume Slab', distributor: 'Nashik DB (Retail)', amount: 31750, status: 'Settled' },
    { id: 'CLM-2043', scheme: 'JoyMee Noodles Buy 10 Get 2', distributor: 'Pune Super Stockiest', amount: 18400, status: 'Draft' }
];

export function getManagedSchemes() {
    return clone(MANAGED_SCHEMES);
}

export function getSchemeClaims() {
    return clone(SCHEME_CLAIMS);
}

/* ------------------- Product Sharing / Visibility (BRD §9.3) -------------- */
/* Admin assigns each SKU's visibility: Nation / Branch / State / Channel /  */
/* Distributor-specific. Channel GT / MT / Both.                            */

const PRODUCT_SHARING = [
    { id: 'PV-001', sku: 'MLK-CHE-130', skuName: 'Malkist Cheese Crackers', level: 'Nation', scope: 'All India', channel: 'Both', status: 'Active' },
    { id: 'PV-002', sku: 'MLK-CHO-130', skuName: 'Malkist Double Chocolatey', level: 'Nation', scope: 'All India', channel: 'Both', status: 'Active' },
    { id: 'PV-003', sku: 'CFJ-100', skuName: 'Coffee Joy Thin Biscuit', level: 'State', scope: 'Karnataka', channel: 'GT', status: 'Active' },
    { id: 'PV-004', sku: 'RMG-250', skuName: 'Roma Marie Gold', level: 'Branch', scope: 'Pune Branch', channel: 'GT', status: 'Active' },
    { id: 'PV-005', sku: 'DAN-BUT-200', skuName: 'Danisa Butter Cookies', level: 'Channel', scope: 'Modern Trade', channel: 'MT', status: 'Active' },
    { id: 'PV-006', sku: 'BNG-CHO-20', skuName: 'Beng-Beng Wafer Chocolate', level: 'Distributor', scope: 'Reliance Smart (DB-M)', channel: 'MT', status: 'Active' },
    { id: 'PV-007', sku: 'KOP-CDY-140', skuName: 'Kopiko Coffee Candy', level: 'State', scope: 'Maharashtra', channel: 'Both', status: 'Active' },
    { id: 'PV-008', sku: 'SOL-STR-90', skuName: "Slai O'lai Strawberry", level: 'Distributor', scope: 'Pune Super Stockiest', channel: 'GT', status: 'Inactive' },
    { id: 'PV-009', sku: 'CHK-CHO-50', skuName: 'Choki-Choki Chocolate Paste', level: 'Channel', scope: 'General Trade', channel: 'GT', status: 'Active' },
    { id: 'PV-010', sku: 'JME-CHK-75', skuName: 'JoyMee Chicken Noodles', level: 'State', scope: 'Gujarat', channel: 'GT', status: 'Active' },
    { id: 'PV-011', sku: 'MLK-CER-130', skuName: 'Malkist Gandum Sereal', level: 'Nation', scope: 'All India', channel: 'Both', status: 'Active' },
    { id: 'PV-012', sku: 'KOP-BRN-30', skuName: 'Kopiko Brown Coffee', level: 'Branch', scope: 'Nashik Branch', channel: 'GT', status: 'Inactive' }
];

export function getProductSharing() {
    return clone(PRODUCT_SHARING);
}

/* ------------------- Targets vs Actual (BRD §13 Targets) ----------------- */
/* Tiers: P1 (SS/DB), P2 (SD), Secondary (by User), Outlet (outlet-wise).   */
/* Always broken down by Product Hierarchy. Actuals roll up on a JC basis.   */

const TARGETS = [
    { id: 'T-001', tier: 'P1', entity: 'Pune Super Stockiest', brand: 'Malkist', kpi: 'Sales Value', target: 1200000, actual: 1044000, jc: 'JC-06' },
    { id: 'T-002', tier: 'P1', entity: 'Nashik DB (Retail)', brand: 'Kopiko', kpi: 'Sales Value', target: 800000, actual: 856000, jc: 'JC-06' },
    { id: 'T-003', tier: 'P2', entity: 'North Zone SD', brand: 'Malkist', kpi: 'Sales Value', target: 450000, actual: 369000, jc: 'JC-06' },
    { id: 'T-004', tier: 'P2', entity: 'South Zone SD', brand: 'Roma', kpi: 'Sales Value', target: 300000, actual: 171000, jc: 'JC-06' },
    { id: 'T-005', tier: 'Secondary', entity: 'Manoj Kale (PC-SR-PUN-05)', brand: 'Malkist', kpi: 'Sales Value', target: 180000, actual: 162000, jc: 'JC-06' },
    { id: 'T-006', tier: 'Secondary', entity: 'Manoj Kale (PC-SR-PUN-05)', brand: 'Kopiko', kpi: 'Lines Per Call', target: 6, actual: 5, jc: 'JC-06' },
    { id: 'T-007', tier: 'Secondary', entity: 'Sunil Rao (PC-DBSM-PUN)', brand: 'Beng-Beng', kpi: 'Unique Productive Calls', target: 420, actual: 455, jc: 'JC-06' },
    { id: 'T-008', tier: 'Outlet', entity: 'ABC Mart (Andheri W.)', brand: 'Malkist', kpi: 'Sales Value', target: 24000, actual: 18720, jc: 'JC-06' },
    { id: 'T-009', tier: 'Outlet', entity: 'City Grocery (Bandra E.)', brand: 'Roma', kpi: 'Sales Value', target: 16000, actual: 16800, jc: 'JC-06' },
    { id: 'T-010', tier: 'Outlet', entity: 'Star Kirana (Malad)', brand: 'Coffee Joy', kpi: 'Sales Value', target: 12000, actual: 7200, jc: 'JC-06' }
];

export function getTargets() {
    return clone(TARGETS);
}

export { formatCurrency, formatLakh, formatNumber };
