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

export { formatCurrency, formatLakh };
