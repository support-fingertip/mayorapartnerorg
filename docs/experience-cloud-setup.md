# Mayora DMS — Experience Cloud Setup

This guide explains how to deploy the Mayora DMS Lightning Web Components and assemble them
into an Experience Cloud site. Each screen is a self-contained LWC placed on its own tab page.

> The build is a **UI prototype on mock data** (`c/dmsData`) — no backend wiring. Each
> component is independent so it can be dropped onto an Experience Builder page.

## Tab → component map

| Site tab               | Component (drop onto the page)        | Notes                                            |
| ---------------------- | ------------------------------------- | ------------------------------------------------ |
| Home                   | `DMS Home` (`c/dmsHome`)              | P1 / P2 / Secondary dashboards                   |
| Products               | `DMS Products` (`c/dmsProducts`)      | Products + Schemes & Offers                      |
| Orders                 | `DMS Orders` (`c/dmsOrders`)          | P1/P2/Secondary + New Order + cart + detail      |
| Invoices               | `DMS Invoices` (`c/dmsInvoices`)      | Primary/Secondary + Create Invoice wizard        |
| GRN                    | `DMS GRN` (`c/dmsGrn`)                | List + Create GRN wizard (auto-return)           |
| Ledger                 | `DMS Ledger` (`c/dmsLedger`)          | Account statement                                |
| Inventory              | `DMS Inventory` (`c/dmsInventory`)    | Stock View + Stock Adjustments                   |
| Returns                | `DMS Returns` (`c/dmsReturns`)        | P1/P2/Secondary + Create Primary Return          |
| Claims                 | `DMS Claims` (`c/dmsClaims`)          | Scheme claims + New Claim                        |
| Secondary Collection   | `DMS Secondary Collection` (`c/dmsSecondaryCollection`) | Collections + Record Collection |
| Customers              | `DMS Customers` (`c/dmsCustomers`)    | Retailers / Sub-Distributors + detail            |
| Tickets                | `DMS Tickets` (`c/dmsTickets`)        | Support tickets + conversation + New Ticket      |
| **Reports**            | *Salesforce standard Reports*         | Use a Report/Report-chart component               |
| **Dashboard**          | *Salesforce standard Dashboards*      | Use the standard Dashboard component              |

**Reusable building blocks** (consumed internally, not placed directly): `c/dmsData`,
`c/dmsStatusBadge`, `c/dmsKpiCard`, `c/dmsPageHeader`, `c/dmsBarChart`, `c/dmsColumnChart`,
`c/dmsPieChart`.

## 1. Deploy the components

```bash
sf org login web --alias mayoraDev
sf project deploy start --manifest manifest/dms-deploy.xml --target-org mayoraDev
```

(Run with `--dry-run` first to validate without deploying.)

## 2. Create the Experience Cloud site

1. **Setup → Digital Experiences → All Sites → New**.
2. Choose **Build Your Own (LWR)** (recommended for custom LWC layouts).
3. Name it `Mayora DMS`, set the URL path, and create.

## 3. Add tabs/pages and drop components

In **Experience Builder**:

1. Create a page per tab (Home already exists — reuse it).
2. Drag the matching component (from the **Components** panel, *Custom* section) onto each page
   per the table above.
3. For **Reports** and **Dashboard**, use the standard Salesforce
   **Report Chart** / **Dashboard** components and point them at the org's DMS reports and
   dashboards.
4. Add each page to the site **navigation menu**, then **Publish**.

## Responsive / mobile

Every screen is responsive: SLDS-style grids, KPI strips that reflow, and data tables that
collapse into labeled stacked cards below ~640px. All icons are inline SVG (so they render
reliably in LWR), and in-modal dropdowns use native `<select>` to avoid clipping.

## Theming

Brand colors are inlined as `--dms-*` CSS custom properties at the top of each component's CSS
(red primary / navy ink). Adjust them to match the final Mayora palette / Figma tokens.

## Notes / next steps

- All data is mock and lives in `c/dmsData`. To move beyond the prototype, replace the
  `getX()` helpers with Apex/`@wire` calls to real Salesforce objects.
- `Reports` and `Dashboard` intentionally use standard Salesforce features rather than custom
  LWCs.
