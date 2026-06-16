# Mayora DMS — Experience Cloud Setup (Phase 1)

This guide explains how to deploy the Phase 1 DMS components and assemble them into an
Experience Cloud site with tabs for **Home, Products, Orders, Invoices**.

> Phase 1 is a **UI prototype on mock data** — there is no backend wiring. Each screen is a
> self-contained Lightning Web Component you place on an Experience Builder page.

## Components delivered

| Component            | Type        | Exposed to Experience Cloud | Purpose                          |
| -------------------- | ----------- | --------------------------- | -------------------------------- |
| `c/dmsHome`          | Screen      | ✅                          | Dashboard landing (Home tab)     |
| `c/dmsProducts`      | Screen      | ✅                          | Product catalog (Products tab)   |
| `c/dmsOrders`        | Screen      | ✅                          | Sales orders (Orders tab)        |
| `c/dmsInvoices`      | Screen      | ✅                          | Invoices + collections (Invoices)|
| `c/dmsPageHeader`    | Reusable UI | ❌                          | Shared page title bar            |
| `c/dmsKpiCard`       | Reusable UI | ❌                          | KPI tile (used by Home)          |
| `c/dmsStatusBadge`   | Reusable UI | ❌                          | Status pill (Orders/Invoices)    |
| `c/dmsData`          | Service     | ❌                          | Central mock data source         |
| `c/dmsTokens`        | Shared CSS  | ❌                          | Brand design tokens (`@import`)  |

Only the four screen components are exposed; the rest are building blocks consumed internally.

## 1. Deploy the components

Authorize your org, then deploy the LWC source:

```bash
sf org login web --alias mayoraDev
sf project deploy start --source-dir force-app/main/default/lwc --target-org mayoraDev
```

(Run `sf project deploy start --dry-run ...` first to validate metadata without deploying.)

## 2. Create the Experience Cloud site

1. **Setup → Digital Experiences → All Sites → New**.
2. Choose the **Build Your Own (LWR)** template (recommended for custom LWC layouts).
3. Name it `Mayora DMS`, set the URL path, and create.

## 3. Add tabs / pages and drop components

In **Experience Builder** for the site:

1. Use the **Pages** menu → **New Page** (Standard page) for each tab: `Home`, `Products`,
   `Orders`, `Invoices`. (Home already exists — reuse it.)
2. On each page, drag the matching component from the **Components** panel (under the
   *Custom* section) onto the canvas:
   - Home → **DMS Home**
   - Products → **DMS Products**
   - Orders → **DMS Orders**
   - Invoices → **DMS Invoices**
3. Add each page to the site **navigation menu** (Settings → Navigation, or the nav
   component) so they appear as top tabs.
4. **Publish** the site.

## 4. Mobile / responsive check

Every screen is responsive via the SLDS grid plus component media queries:

- KPI tiles: 4-up (desktop) → 2-up (tablet) → 1-up (mobile).
- Product catalog: 4-up → 2-up → 1-up cards.
- Orders/Invoices tables: full table on desktop; rows collapse into labeled stacked cards
  below 640px.

Verify with the Experience Builder device toolbar (desktop / tablet / mobile) and on a real
device after publishing.

## Theming

Brand colors live in one place: `c/dmsTokens` (`dmsTokens.css`), imported by each component's
CSS via `@import 'c/dmsTokens';`. Adjust the `--dms-*` custom properties there to match the
final Mayora palette / Figma tokens.

## Next phases

Remaining Figma screens (GRN, Inventory, Ledger, Claims, Returns, Collection, Customers,
Reports, Feedback/Tickets, Dashboard) follow the same pattern: one exposed screen LWC each,
reusing `dmsData`, `dmsPageHeader`, `dmsKpiCard`, and `dmsStatusBadge`. Backend wiring (Apex /
Salesforce objects) replaces `c/dmsData` when moving beyond the prototype.
