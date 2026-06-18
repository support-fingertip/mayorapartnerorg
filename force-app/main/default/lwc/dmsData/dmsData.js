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
    { id: 'RET-045', date: '28 May 2026', qty: 5, status: 'Approved', ref: 'PI-SAP-0885', lines: [{ product: 'Malkist Cheese Crackers 130g', qty: 3, reason: 'Damaged goods' }, { product: 'JoyMee Chicken Noodles 75g', qty: 2, reason: 'Damaged goods' }] },
    { id: 'RET-043', date: '20 May 2026', qty: 5, status: 'Approved', ref: 'PI-SAP-0878', lines: [{ product: 'Kopiko Coffee Candy Jar 140g', qty: 5, reason: 'Quality issue' }] },
    { id: 'RET-040', date: '10 May 2026', qty: 4, status: 'Approved', ref: 'PI-SAP-0858', lines: [{ product: 'Danisa Butter Cookies 200g', qty: 4, reason: 'Expired stock' }] },
    { id: 'RET-038', date: '02 May 2026', qty: 11, status: 'Rejected', ref: 'PI-SAP-0841', lines: [{ product: 'Beng-Beng Wafer Chocolate 22g', qty: 6, reason: 'Damaged goods' }, { product: 'Choki-Choki Chocolate Paste', qty: 5, reason: 'Near-expiry' }] }
];

const P2_RETURNS = [
    { id: 'P2RET-012', date: '25 May 2026', qty: 3, status: 'Pending', ref: 'PO-2835', lines: [{ product: 'Malkist Double Chocolatey 130g', qty: 3, reason: 'Damaged goods' }] },
    { id: 'P2RET-011', date: '14 May 2026', qty: 5, status: 'Approved', ref: 'PO-2820', lines: [{ product: "Slai O'lai Strawberry 90g", qty: 5, reason: 'Quality issue' }] },
    { id: 'P2RET-010', date: '02 Apr 2026', qty: 2, status: 'Approved', ref: 'PO-2810', lines: [{ product: 'Coffee Joy Thin Biscuit 100g', qty: 2, reason: 'Wrong product' }] }
];

const SECONDARY_RETURNS = [
    { id: 'SRET-012', date: '27 May 2026', customer: 'ABC Mart', type: 'Retailer', qty: 5, status: 'Pending', lines: [{ product: 'Malkist Cheese Crackers 130g', qty: 5, reason: 'Damaged goods' }] },
    { id: 'SRET-011', date: '24 May 2026', customer: 'North Zone SD', type: 'Sub-Dist.', qty: 18, status: 'Approved', lines: [{ product: 'Kopiko Jar 140g', qty: 10, reason: 'Near-expiry' }, { product: 'Danisa Butter 200g', qty: 8, reason: 'Expired stock' }] },
    { id: 'SRET-010', date: '20 May 2026', customer: 'City Grocery', type: 'Retailer', qty: 2, status: 'Approved', lines: [{ product: 'Roma Marie Gold 250g', qty: 2, reason: 'Quality issue' }] },
    { id: 'SRET-009', date: '15 May 2026', customer: 'East Zone SD', type: 'Sub-Dist.', qty: 9, status: 'Approved', lines: [{ product: 'KIS Mint Candy 18.4g', qty: 9, reason: 'Damaged goods' }] },
    { id: 'SRET-008', date: '10 May 2026', customer: 'Fresh Mart', type: 'Retailer', qty: 3, status: 'Pending', lines: [{ product: 'Coffee Joy Thin Biscuit 100g', qty: 3, reason: 'Wrong product' }] }
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

/* --------------------------------- Claims --------------------------------- */

const CLAIMS = [
    { id: 'SCH-0041', date: '17 May 2026', scheme: 'Choki-Choki Q4 2025 Scheme', products: 3, amount: 2880, desc: 'B4G1 scheme claim for Q4 — Choki-Choki Chocolate Paste', status: 'Approved' },
    { id: 'SCH-0040', date: '01 May 2026', scheme: 'Malkist Summer Push Apr 2026', products: 5, amount: 5760, desc: 'Secondary volume push incentive — Malkist Cheese & Choco', status: 'Approved' },
    { id: 'SCH-0039', date: '10 Apr 2026', scheme: 'Kopiko Visibility Scheme Q1', products: 2, amount: 3200, desc: 'Shelf space and visibility scheme for Kopiko Candy range', status: 'Approved' },
    { id: 'SCH-0038', date: '25 Mar 2026', scheme: 'Beng-Beng POSM Display Q1', products: 1, amount: 1440, desc: 'POSM display scheme — Beng-Beng Wafer Chocolate 22g', status: 'Pending' }
];

const CLAIM_SCHEMES = [
    'Choki-Choki Q4 2025 Scheme',
    'Malkist Summer Push Apr 2026',
    'Kopiko Visibility Scheme Q1',
    'Beng-Beng POSM Display Q1',
    'JoyMee Trade Offer Q2',
    'Danisa Festive Scheme'
];

export function getClaims() {
    return clone(CLAIMS);
}

export function getClaimSchemes() {
    return [...CLAIM_SCHEMES];
}

/* --------------------------- Secondary Collection ------------------------- */

const COLLECTIONS = [
    { id: 'COL-0021', date: '29 May 2026', customer: 'North Zone SD', type: 'Sub-Distributor', code: 'SD-001', invoiceRef: 'SI-2204', amount: 45000, mode: 'NEFT', reference: 'NEFT2605290011', by: 'Ravi Kumar', notes: 'Full settlement against SI-2204.' },
    { id: 'COL-0020', date: '28 May 2026', customer: 'ABC Mart', type: 'Retailer', code: 'RET-001', invoiceRef: 'SI-2198', amount: 14928, mode: 'UPI', reference: 'UPI28052201@ybl', by: 'Ravi Kumar', notes: '—' },
    { id: 'COL-0019', date: '27 May 2026', customer: 'Metro General Store', type: 'Retailer', code: 'RET-004', invoiceRef: 'SI-2185', amount: 9800, mode: 'Cash', reference: '—', by: 'Sunil Patil', notes: 'Collected at store.' },
    { id: 'COL-0018', date: '25 May 2026', customer: 'East Zone SD', type: 'Sub-Distributor', code: 'SD-002', invoiceRef: 'SI-2174', amount: 22800, mode: 'Cheque', reference: 'CHQ-SBI-082341', by: 'Ravi Kumar', notes: 'Cheque deposited.' },
    { id: 'COL-0017', date: '22 May 2026', customer: 'Sharma Kirana', type: 'Retailer', code: 'RET-005', invoiceRef: 'SI-2162', amount: 7200, mode: 'UPI', reference: 'UPI22052001@paytm', by: 'Sunil Patil', notes: '—' },
    { id: 'COL-0016', date: '20 May 2026', customer: 'City Grocery', type: 'Retailer', code: 'RET-002', invoiceRef: 'SI-2155', amount: 24000, mode: 'NEFT', reference: 'NEFT2005200022', by: 'Ravi Kumar', notes: '—' },
    { id: 'COL-0015', date: '18 May 2026', customer: 'West Zone SD', type: 'Sub-Distributor', code: 'SD-003', invoiceRef: 'SI-2140', amount: 33500, mode: 'Cheque', reference: 'CHQ-HDFC-091122', by: 'Ravi Kumar', notes: 'Cheque cleared.' },
    { id: 'COL-0014', date: '15 May 2026', customer: 'Fresh Mart', type: 'Retailer', code: 'RET-003', invoiceRef: 'SI-2131', amount: 25000, mode: 'Cash', reference: '—', by: 'Sunil Patil', notes: '—' }
];

const COLLECTION_CUSTOMERS = {
    Retailer: [
        { name: 'ABC Mart', code: 'RET-001' }, { name: 'City Grocery', code: 'RET-002' },
        { name: 'Fresh Mart', code: 'RET-003' }, { name: 'Metro General Store', code: 'RET-004' },
        { name: 'Sharma Kirana', code: 'RET-005' }, { name: 'Star Provisions', code: 'RET-006' }
    ],
    'Sub-Distributor': [
        { name: 'North Zone SD', code: 'SD-001' }, { name: 'East Zone SD', code: 'SD-002' },
        { name: 'West Zone SD', code: 'SD-003' }
    ]
};

export function getCollections() {
    return clone(COLLECTIONS);
}

export function getCollectionCustomers() {
    return clone(COLLECTION_CUSTOMERS);
}

/* -------------------------------- Customers ------------------------------- */

const CUSTOMER_RETAILERS = [
    { name: 'ABC Mart', code: 'RET-001', type: 'Retailer', outletType: 'Grocery Store', beat: 'Andheri West', owner: 'Arvind Sharma', area: 'Andheri West', phone: '+91 98200 11234', monthly: 32000, lastOrder: 'SO-6432', address: 'Shop 14, Lokhandwala Market, Andheri West, Mumbai 400053', gstin: '27AABCS1429A1ZR' },
    { name: 'City Grocery', code: 'RET-002', type: 'Retailer', outletType: 'Grocery Store', beat: 'Bandra–Kurla', owner: 'Mehul Jain', area: 'Bandra East', phone: '+91 98209 44567', monthly: 24000, lastOrder: 'SO-6431', address: 'Shop 7, Linking Road, Bandra East, Mumbai 400051', gstin: '27AABCC2231B1Z5' },
    { name: 'Fresh Mart', code: 'RET-003', type: 'Retailer', outletType: 'Grocery Store', beat: 'Borivali North', owner: 'Suresh Patil', area: 'Borivali North', phone: '+91 91364 78901', monthly: 18000, lastOrder: 'SO-6430', address: 'Plot 22, LT Road, Borivali North, Mumbai 400092', gstin: '27AABCF3344C1Z9' },
    { name: 'Metro General Store', code: 'RET-004', type: 'Retailer', outletType: 'General Trade', beat: 'Bandra–Kurla', owner: 'Ramesh Gupta', area: 'Kurla', phone: '+91 99203 22345', monthly: 15000, lastOrder: 'SO-6420', address: 'Shop 3, Station Road, Kurla, Mumbai 400070', gstin: '27AABCM4455D1Z2' },
    { name: 'Sharma Kirana', code: 'RET-005', type: 'Retailer', outletType: 'Kirana', beat: 'Malad–Goregaon', owner: 'Dinesh Sharma', area: 'Malad East', phone: '+91 98765 55678', monthly: 12000, lastOrder: 'SO-6412', address: 'Shop 9, SV Road, Malad East, Mumbai 400097', gstin: '27AABCS5566E1Z7' },
    { name: 'Star Provisions', code: 'RET-006', type: 'Retailer', outletType: 'General Trade', beat: 'Malad–Goregaon', owner: 'Vijay Nair', area: 'Goregaon West', phone: '+91 97690 99012', monthly: 20000, lastOrder: 'SO-6429', address: 'Shop 5, MG Road, Goregaon West, Mumbai 400062', gstin: '27AABCS6677F1Z4' }
];

const CUSTOMER_SUBDISTS = [
    { name: 'North Zone SD', code: 'SD-001', type: 'Sub-Dist.', outletType: 'Sub-Distributor', beat: 'Mira-Bhayander', owner: 'Prakash Mehta', area: 'Mira-Bhayander', phone: '+91 98210 33456', monthly: 125000, lastOrder: 'SO-6440', address: 'Godown 4, MIDC Industrial Area, Mira Road East, Thane 401107', gstin: '27AABCN5567G1ZF' },
    { name: 'East Zone SD', code: 'SD-002', type: 'Sub-Dist.', outletType: 'Sub-Distributor', beat: 'Thane East', owner: 'Santosh Rao', area: 'Thane East', phone: '+91 98220 66789', monthly: 95000, lastOrder: 'SO-6416', address: 'Warehouse 12, Wagle Estate, Thane East 400604', gstin: '27AABCE6678H1Z3' },
    { name: 'West Zone SD', code: 'SD-003', type: 'Sub-Dist.', outletType: 'Sub-Distributor', beat: 'Vasai-Virar', owner: 'Anil Desai', area: 'Vasai-Virar', phone: '+91 98230 77890', monthly: 80000, lastOrder: 'SO-6410', address: 'Godown 8, GIDC, Vasai East, Palghar 401208', gstin: '27AABCW7789I1Z1' }
];

const DEFAULT_SKUS = [
    { code: 'MLK-CHE-130', name: 'Malkist Cheese Crackers 130g' },
    { code: 'KOP-JAR-140', name: 'Kopiko Coffee Candy Jar 140g' },
    { code: 'BBG-22', name: 'Beng-Beng Wafer Chocolate 22g' },
    { code: 'COF-100', name: 'Coffee Joy Thin Biscuit 100g' },
    { code: 'KIS-18', name: 'KIS Mint Candy 18.4g' }
];
const DEFAULT_TARGETS = [
    { code: 'MLK-CHE-130', name: 'Malkist Cheese Crackers 130g', target: 40, achieved: 36, pct: 90 },
    { code: 'KOP-JAR-140', name: 'Kopiko Coffee Candy Jar 140g', target: 20, achieved: 16, pct: 80 },
    { code: 'BBG-22', name: 'Beng-Beng Wafer Chocolate 22g', target: 30, achieved: 28, pct: 93 }
];
const DEFAULT_ALIASES = ['Malkist', 'Kopiko', 'Beng-Beng', 'Coffee Joy', 'KIS'];
const DEFAULT_SUBBRANDS = ['Malkist Cheese', 'Malkist Choco', 'Kopiko Classic', 'Coffee Joy Thin'];
const DEFAULT_BRANDS = ['Malkist', 'Kopiko', 'Beng-Beng', 'Coffee Joy', 'KIS', 'JoyMee'];

const CUSTOMER_DETAILS = {
    'RET-001': {
        orders: [
            { id: 'SO-6432', date: '29 May 2026', amount: 11136, items: 'Malkist Cheese 130g ×8, Kopiko Jar 140g ×4, Beng-Beng 22g ×6' },
            { id: 'SO-6418', date: '22 May 2026', amount: 4320, items: 'Coffee Joy 100g ×5, KIS Mint 18.4g ×3' },
            { id: 'SO-6402', date: '15 May 2026', amount: 8640, items: 'Malkist Cheese 130g ×10, Danisa 200g ×2' },
            { id: 'SO-6381', date: '08 May 2026', amount: 6912, items: 'Malkist Choco 130g ×8, JoyMee 75g ×6' },
            { id: 'SO-6360', date: '01 May 2026', amount: 9216, items: 'Kopiko Jar 140g ×6, Beng-Beng 22g ×10' }
        ],
        skus: DEFAULT_SKUS,
        aliases: DEFAULT_ALIASES,
        subBrands: DEFAULT_SUBBRANDS,
        brands: DEFAULT_BRANDS,
        targets: DEFAULT_TARGETS
    },
    'SD-001': {
        orders: [
            { id: 'SO-6440', date: '29 May 2026', amount: 52416, items: 'Malkist Cheese ×30, Malkist Choco ×20, Coffee Joy ×25, Kopiko Jar ×12' },
            { id: 'SO-6420', date: '22 May 2026', amount: 41472, items: 'Malkist Cheese ×25, Beng-Beng ×30, JoyMee ×20' },
            { id: 'SO-6398', date: '15 May 2026', amount: 36864, items: 'Malkist Choco ×20, Kopiko Jar ×18, Danisa ×8' }
        ],
        skus: DEFAULT_SKUS,
        aliases: DEFAULT_ALIASES,
        subBrands: DEFAULT_SUBBRANDS,
        brands: DEFAULT_BRANDS,
        targets: DEFAULT_TARGETS
    }
};

export function getCustomersData() {
    return { retailers: clone(CUSTOMER_RETAILERS), subDistributors: clone(CUSTOMER_SUBDISTS) };
}

export function getCustomerDetail(customer) {
    if (CUSTOMER_DETAILS[customer.code]) {
        return clone(CUSTOMER_DETAILS[customer.code]);
    }
    // generic detail derived from the customer
    const m = customer.monthly;
    return {
        orders: [
            { id: customer.lastOrder, date: '29 May 2026', amount: Math.round(m * 0.35), items: 'Malkist Cheese 130g ×8, Kopiko Jar 140g ×4' },
            { id: 'SO-6300', date: '20 May 2026', amount: Math.round(m * 0.22), items: 'Coffee Joy 100g ×5, KIS Mint 18.4g ×3' },
            { id: 'SO-6285', date: '12 May 2026', amount: Math.round(m * 0.28), items: 'Malkist Choco 130g ×8, JoyMee 75g ×6' }
        ],
        skus: DEFAULT_SKUS,
        aliases: DEFAULT_ALIASES,
        subBrands: DEFAULT_SUBBRANDS,
        brands: DEFAULT_BRANDS,
        targets: DEFAULT_TARGETS
    };
}

/* --------------------------------- Tickets -------------------------------- */

const TICKETS = [
    { id: 'TKT-0085', date: '28 May 2026', category: 'Delivery Delay', subject: 'PO-2847 not received — dispatch not initiated', reference: 'PO-2847', priority: 'High', status: 'Open', lastUpdate: '28 May 2026', messages: [{ from: 'Sharma Distributors', type: 'sd', date: '28 May 2026', text: 'Primary order PO-2847 placed on 29 May 2026. Mayora India has not provided dispatch details or LR number. Expected delivery was 3 Jun 2026.' }] },
    { id: 'TKT-0082', date: '25 May 2026', category: 'Product Quality', subject: 'Beng-Beng Wafer — damaged packaging in PO-2841', reference: 'PO-2841 / RET-045', priority: 'High', status: 'In Progress', lastUpdate: '27 May 2026', messages: [{ from: 'Sharma Distributors', type: 'sd', date: '25 May 2026', text: 'Received 60 cartons of Beng-Beng Wafer Chocolate (BBG-22) in PO-2841. 5 cartons found with crushed packaging and broken wafers. Return RET-045 already raised.' }, { from: 'Mayora India Ltd.', type: 'mayora', date: '27 May 2026', text: 'Field quality team has been informed. Credit note will be processed once RET-045 is approved by ASM.' }] },
    { id: 'TKT-0079', date: '20 May 2026', category: 'Invoice Dispute', subject: 'PI-SAP-0871 — wrong carton quantity billed for GRN-0385', reference: 'PI-SAP-0871 / GRN-0385', priority: 'Medium', status: 'In Progress', lastUpdate: '24 May 2026', messages: [{ from: 'Sharma Distributors', type: 'sd', date: '20 May 2026', text: 'PI-SAP-0871 billed 100 cartons but GRN-0385 received 96. Requesting correction of 4 cartons.' }, { from: 'Mayora India Ltd.', type: 'mayora', date: '24 May 2026', text: 'Reconciliation in progress with the SAP team; correction note to follow.' }] },
    { id: 'TKT-0075', date: '14 May 2026', category: 'Order Issue', subject: 'Wrong SKU dispatched — Kopiko Jar vs Kopiko Pouch', reference: 'PO-2820', priority: 'High', status: 'Resolved', lastUpdate: '18 May 2026', messages: [{ from: 'Sharma Distributors', type: 'sd', date: '14 May 2026', text: 'Kopiko Jar dispatched instead of Kopiko Pouch in PO-2820.' }, { from: 'Mayora India Ltd.', type: 'mayora', date: '18 May 2026', text: 'Replacement dispatched and short-pick corrected. Issue resolved.' }] },
    { id: 'TKT-0071', date: '08 May 2026', category: 'Scheme / Pricing', subject: 'Kopiko Jar Q4 trade scheme not applied on PI-SAP-0858', reference: 'PI-SAP-0858', priority: 'Medium', status: 'Resolved', lastUpdate: '12 May 2026', messages: [{ from: 'Sharma Distributors', type: 'sd', date: '08 May 2026', text: 'Q4 trade scheme not applied on PI-SAP-0858.' }, { from: 'Mayora India Ltd.', type: 'mayora', date: '12 May 2026', text: 'Scheme credit applied via SCH-0041. Resolved.' }] },
    { id: 'TKT-0068', date: '02 May 2026', category: 'Feedback', subject: 'Request: add JuizyMilk Candy larger pack (100g)', reference: '—', priority: 'Low', status: 'Closed', lastUpdate: '10 May 2026', messages: [{ from: 'Sharma Distributors', type: 'sd', date: '02 May 2026', text: 'Request: add JuizyMilk Candy larger pack (100g) to the catalog.' }, { from: 'Mayora India Ltd.', type: 'mayora', date: '10 May 2026', text: 'Forwarded to the product team for evaluation. Closing for now.' }] }
];

const TICKET_CATEGORIES = ['Order Issue', 'Invoice Dispute', 'Product Quality', 'Delivery Delay', 'Scheme / Pricing', 'Feedback', 'Other'];

export function getTickets() {
    return clone(TICKETS);
}

export function getTicketCategories() {
    return [...TICKET_CATEGORIES];
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

export { formatCurrency, formatLakh, formatNumber };
