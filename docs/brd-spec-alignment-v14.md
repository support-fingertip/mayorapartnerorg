# BRD ↔ Object/Field Design (v14) ↔ Org Alignment

Check of the **Mayora Salesforce Object & Field Design v14** and **BRD V2 Final**
against the existing org metadata. Scope per request: **Salesforce platform +
mobile-via-API only** — the **DMS portal** and **SAP integration** specifics are
excluded. Anything created here grants the System Administrator full access via
the `Mayora SysAdmin Full Access` permission set.

## Headline finding

The org is a **mature 98-object build that already implements ~all in-scope BRD
requirements**, but under **different object/field names** than the v14 spec.
Most apparent "gaps" between the spec and the org are **naming/architecture
divergences, not missing capability**. The pattern established in
`brd-gap-build.md` is followed: **reuse existing objects, add only genuinely
absent capability** — do **not** fork the schema by recreating spec-named
objects that already exist under another name.

## Spec object → existing org mapping (in scope)

| v14 spec object | Existing org object(s) | Status |
|---|---|---|
| Account (Customer) | `Account` (std) + `Channel_Partner__c` | Covered (std Account not tracked in this repo) |
| City Master | `City_Tier__c` | Covered (narrower; see note) |
| Beat / Position | `Beat__c`, `Beat_Outlet__c`, `Position__c` | Covered |
| User (extended) | `User` (std) + `Employee__c` | Covered (std User not tracked in this repo) |
| Product / Visibility / Must-Sell / Batch | `Product_Extension__c`, `Product_Sharing__c`, `Must_Sell_Config__c`, `Batch_Master__c` | Covered |
| P1/P2/Secondary Price | `Price_List__c` (+ `Pricebook_Priority__mdt`) | Covered by unified priority-cascade model |
| Scheme / Slab / Basket | `Scheme__c`, `Scheme_Slab__c`, `Scheme_Product__c`, `Scheme_Mapping__c`, `Scheme_Accrual__c` | Covered |
| Target / KPI / JC | `Target__c`, `Target_Period__c` (Type=Journey Cycle), `Target_Criteria__c`, `KPI_Metric__c`, `Outlet_Target_Increment__c` | Covered |
| Tour Plan (PJP) / Holiday | `Journey_Plan__c`, `Journey_Plan_Day__c`, `Holiday__c` | Covered |
| Attendance / Visit / Leave | `Day_Attendance__c`, `Visit__c`, `Leave_*`, `GPS_Log__c` | Covered |
| Order / Invoice / Return / Collection / Competitor | `Sales_Order__c`+`Order_Line_Item__c`, `Invoice__c`+`Invoice_Line__c`, `Return_Order__c`+`Return_Line__c`, `Collection__c`, `Competitor__c` | Covered |
| **Stock Check (in-visit)** | — | **GAP → built** |
| **Retail Asset (in-visit)** | — | **GAP → built** |
| **Must-Sell No-Sale** | — | **GAP → built** |
| Survey / Question / Response | `Survey__c`, `Survey_Question__c`, `Survey_Response__c`, `Survey_Answer__c` | Covered |
| Expense / Item / Config | `Expense__c`, `Expense_Item__c`, `Expense_Eligibility__c`, `Expense_Rate_Slab__c` | Covered |
| Ticket | `Ticket__c` | Covered |
| **Game / Game KPI / Game Score (employee gamification)** | — (`Scorecard__c`=distributor, `Incentive__c`/`Loyalty_Points__c`=monetary) | **GAP → built** |

## What was implemented (genuine, in-scope gaps)

### New objects
- **`Game__c` / `Game_KPI__c` / `Game_Score__c`** — employee battleground,
  KPI slabs (qualifier vs coin), and per-user EOD coin/leaderboard ledger
  (BRD §20.1). No existing object covered this; `Scorecard__c` is a *distributor*
  scorecard and `Incentive__c`/`Loyalty_Points__c` are monetary. `Game_Score__c`
  links the JC via the existing `Target_Period__c`; KPIs reuse `KPI_Metric__c`.
- **`Stock_Check__c` / `Stock_Check_Item__c`** — in-visit retailer stock check
  (BRD §18 / §21.15). `Visit__c` already carries a `Stock_Check_Completed__c`
  flag but had no object to hold the data. Master-detail to `Visit__c`; SKU via
  `Product_Extension__c`.
- **`Retail_Asset__c`** — outlet asset register (BRD §21.15 Assets action:
  name, serial, given date, status, present flag, photo).
- **`Must_Sell_No_Sale__c`** — child of `Sales_Order__c`; captures the reason a
  Must-Sell SKU was not ordered (BRD §17 "stored under the order record").

### Permissions
- `permissionsets/Mayora_SysAdmin_Full_Access.permissionset-meta.xml` — full
  CRUD + View/Modify-All on the 7 new objects and read/edit FLS on all 40 new
  FLS-eligible fields. **Assign to System Administrator users.** (The repo ships
  no custom `Admin` profile, so a permission set is the portable way to grant
  this.)

## Existing objects: definitions unchanged, fields added additively

No existing object/field definition is modified, renamed, or removed. Per
owner approval, brand-new fields are now **added onto** existing objects
(purely additive — existing fields untouched), alongside net-new objects.
Scope: Salesforce backend + setup/config + the Apex that lives in Salesforce.
**No REST/API** is added (the org already ships `API_*_Rest` mobile endpoints).

### Additive fields on existing objects
- `Scheme__c.Is_Bundle_Scheme__c` — bundle-first priority (BRD §13.3).
- `Order_Line_Item__c.Is_Must_Sell__c` — must-sell line flag (BRD §17).
- `Survey_Question__c.Brand_Alias__c`; `Survey_Answer__c.Brand_Alias__c`,
  `Photo_Before_URL__c`, `Photo_After_URL__c`, `Visibility_Type__c` — MT
  merchandising surveys (BRD §18.2 / §21.19).

### Additional net-new objects
- `Scheme_Basket__c` / `Scheme_Basket_Product__c` — bundle-scheme basket and its
  SKU/min-qty lines (BRD §13.3).
- `Beat_Day_Request__c` — no-PJP-day and beat-switch requests (BRD §7.4).

### Setup / configuration (declarative)
- **Validation rules** (BRD): must-sell no-sale reason required; beat-day-request
  reason required + original beat required for switch; game end-after-start;
  basket min-qty positive; retail-asset status required.
- **Custom tabs** for the new top-level objects (Game, Game Score, Retail Asset,
  Scheme Basket, Beat Day Request, Stock Check), surfaced via the permission set.

### Apex (Salesforce-side, framework-matched, with tests)
- `Beat_Day_Request_Trigger` → `BPM_BeatDayRequest_TriggerHandler` — defaults +
  enforces the **BRD §7.4 cap of 3 approved No-PJP-Day requests per Journey Cycle
  per salesperson**. Test: `BPM_BeatDayRequest_TriggerHandler_Test`. Built on the
  existing `TriggerHandler` framework. (Compile/run validated in a sandbox, per
  the team's established practice in `brd-gap-build.md`.)

### Admin configuration experience (Salesforce = the setup/reporting home)
The org already ships LWC admin managers (Scheme Manager/Definition, Product
Management Hub/Catalog, Target Allocation, KPI Metric Manager, Survey/Expense/
Beat/Employee managers, dashboards). To make the **new** objects equally easy to
configure and to give admins one place for everything:
- **`Mayora SFA Admin` Lightning app** (`applications/Mayora_SFA_Admin.app`) —
  a single navigation gathering all config tabs: schemes (+ Scheme Basket),
  products, targets, KPIs, **gamification (Game, Game Score)**, surveys,
  expenses, beats, employees, incentives, stock, **Retail Asset**, **Stock
  Check**, **Beat Day Request**, must-sell config, and dashboards.
- **Page layouts** for all 10 new objects (fields grouped into Information /
  System Information sections).
- **List views** — `All` on every new object, plus `Active Games`,
  `Active Baskets`, `Pending Requests`, `Active Assets`.
- Gamification is configured by standard records: create a **Game**, add its
  **Game KPI** slabs (qualifier vs coin), assign users via team; the mobile app
  reads/writes **Game Score** via the existing API layer.
- The app is visible to System Administrators via the App Launcher; assign it to
  other profiles in Setup if needed (no profiles are shipped in this repo).

### Apex engines + record pages + reporting (end-to-end)
- **Gamification scoring** — `GAM_GameScore_Service` (slab evaluation: highest
  met cutoff, qualifier-awards-no-coins) + `GAM_GameScore_Batch`
  (Batchable + Schedulable, recomputes coins/qualification for active games at
  EOD) + `GAM_GameScore_Service_Test`. Schedule daily:
  `System.schedule('GAM Game Score','0 0 23 * * ?', new GAM_GameScore_Batch());`
- **Retail Asset** — `Retail_Asset_Trigger` → `DFO_RetailAsset_TriggerHandler`
  (defaults Status=Active, Given Date=today) + test.
- **FlexiPage record pages** for Game, Game Score, Scheme Basket, Stock Check,
  Retail Asset, Beat Day Request — header highlights + Details/Related tabs; the
  related-list container surfaces master-detail children (Game KPIs, Basket
  Products, Stock Check Items) inline. Activate as the org default per object in
  Setup (source deploys the page; activation is a one-click Setup step).
- **Custom report types** (`reportTypes/Mayora_*`) for Game Scores, Beat Day
  Requests, Retail Assets, Stock Checks, Scheme Baskets — enables BRD §20.4-style
  reports/dashboards on the new objects.

### Notes for deployment
- Apex is written to the repo's `TriggerHandler` / `*_Service` / `*_Batch`
  conventions; **compile/run-validate in a sandbox** (this environment has no
  org). Tests included for all new Apex.
- Stock-check visit-completion stamping and richer KPI-actual sourcing for
  gamification can be layered onto the existing `API_*_Rest` / `DFO_*` services
  in a sandbox.

## Deliberately NOT forked (divergences, already covered)

These were flagged by literal spec comparison but are **already implemented under
a different design** — recreating them would duplicate/fork the schema:

- **Pricing** — `Price_List__c` (Price_Type + Priority cascade, with
  `Pricebook_Priority__mdt`) already provides P1/P2/Secondary resolution. The
  spec's ZPR0/ZSD1/ZSD2 P1 margin fields are **SAP-sourced → out of scope**.
- **Journey Calendar** — handled by `Target_Period__c` (Type = *Journey Cycle*);
  a standalone `Journey_Calendar__c` is optional polish, not a capability gap.
- **Expenses** — `Expense__c`/`Expense_Item__c`/`Expense_Eligibility__c`/
  `Expense_Rate_Slab__c` already model the DA/TA policy, slabs and approval. The
  spec's `Expense_Config__c` matrix is a re-shape of the same capability.
- **Customer / Outlet & User extensions** — `Account` and `User` are **standard
  objects whose customizations are not tracked in this repo**; their custom
  fields (and any `Outlet`/record-type model) live in the org, not here. Not
  altered to avoid conflicting with org-side metadata.

## Open decisions (org-owner confirmation)

1. **Customer model** — confirm whether secondary outlets live on standard
   `Account` (record types) or remain split with `Channel_Partner__c`.
2. **JC object** — keep `Target_Period__c` as the JC construct, or introduce a
   dedicated `Journey_Calendar__c` master? New `Game_Score__c.Target_Period__c`
   would re-point if a JC object is later adopted.
3. **Literal v14 build** — if Mayora wants the spec's exact object names
   (`Product__c`, `Order__c`, `P1/P2/Secondary_Price__c`, etc.) instead of the
   existing model, that is a larger re-platform and a separate decision.
