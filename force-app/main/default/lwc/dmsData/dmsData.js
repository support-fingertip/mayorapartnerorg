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

const PRODUCTS = [
    { id: 'P-1001', name: 'Malkist Cheese Crackers 130g', category: 'Biscuit', sku: 'MLK-CHE-130', price: 1450, stock: 1240, unit: 'carton', status: 'In Stock' },
    { id: 'P-1002', name: 'Beng-Beng Wafer Chocolate', category: 'Wafer', sku: 'BNG-CHOC-24', price: 1800, stock: 320, unit: 'carton', status: 'In Stock' },
    { id: 'P-1003', name: 'Malkist Double Chocolatey 130g', category: 'Biscuit', sku: 'MLK-CHO-130', price: 1575, stock: 48, unit: 'carton', status: 'Low Stock' },
    { id: 'P-1004', name: 'Danisa Butter Cookies 200g', category: 'Biscuit', sku: 'DAN-BUT-200', price: 6200, stock: 0, unit: 'carton', status: 'Out of Stock' },
    { id: 'P-1005', name: 'Kopiko Coffee Candy Jar 140g', category: 'Confectionery', sku: 'KOP-JAR-140', price: 2780, stock: 860, unit: 'carton', status: 'In Stock' },
    { id: 'P-1006', name: 'JoyMee Chicken Noodles 75g', category: 'Noodles', sku: 'JME-CHK-75', price: 2130, stock: 95, unit: 'carton', status: 'Low Stock' },
    { id: 'P-1007', name: 'Coffee Joy Biscuit 45g', category: 'Biscuit', sku: 'CFJ-BIS-45', price: 1990, stock: 540, unit: 'carton', status: 'In Stock' },
    { id: 'P-1008', name: 'Choki-Choki Chocolate Paste', category: 'Confectionery', sku: 'CHK-CHOC-50', price: 1320, stock: 12, unit: 'carton', status: 'Low Stock' }
];

const ORDERS = [
    { id: 'SO-24001', customer: 'Toko Sumber Rejeki', date: '2026-06-14', items: 18, amount: 42500, status: 'Pending' },
    { id: 'SO-24002', customer: 'UD Maju Jaya', date: '2026-06-13', items: 32, amount: 91200, status: 'Confirmed' },
    { id: 'SO-24003', customer: 'Grosir Berkah', date: '2026-06-13', items: 9, amount: 18750, status: 'Shipped' },
    { id: 'SO-24004', customer: 'Toko Anugerah', date: '2026-06-12', items: 24, amount: 64800, status: 'Delivered' },
    { id: 'SO-24005', customer: 'CV Sinar Pagi', date: '2026-06-11', items: 5, amount: 9800, status: 'Cancelled' },
    { id: 'SO-24006', customer: 'Toko Makmur Abadi', date: '2026-06-11', items: 41, amount: 117500, status: 'Confirmed' },
    { id: 'SO-24007', customer: 'Warung Bu Tini', date: '2026-06-10', items: 7, amount: 13400, status: 'Delivered' }
];

const INVOICES = [
    { id: 'INV-90012', order: 'SO-24004', customer: 'Toko Anugerah', date: '2026-06-12', due: '2026-06-26', amount: 64800, status: 'Paid' },
    { id: 'INV-90013', order: 'SO-24006', customer: 'Toko Makmur Abadi', date: '2026-06-11', due: '2026-06-25', amount: 117500, status: 'Pending' },
    { id: 'INV-90014', order: 'SO-24007', customer: 'Warung Bu Tini', date: '2026-06-10', due: '2026-06-24', amount: 13400, status: 'Paid' },
    { id: 'INV-90009', order: 'SO-23988', customer: 'UD Maju Jaya', date: '2026-05-28', due: '2026-06-11', amount: 89000, status: 'Overdue' },
    { id: 'INV-90007', order: 'SO-23975', customer: 'Grosir Berkah', date: '2026-05-22', due: '2026-06-05', amount: 34200, status: 'Overdue' },
    { id: 'INV-90015', order: 'SO-24002', customer: 'UD Maju Jaya', date: '2026-06-13', due: '2026-06-27', amount: 91200, status: 'Pending' }
];

export function getProducts() {
    return clone(PRODUCTS);
}

export function getOrders() {
    return clone(ORDERS);
}

export function getInvoices() {
    return clone(INVOICES);
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
    }
};

export function getP1Dashboard() {
    return clone(P1_DASHBOARD);
}

export function getP2Dashboard() {
    return clone(P2_DASHBOARD);
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

export { formatCurrency, formatLakh };
