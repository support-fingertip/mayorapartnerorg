# JC06‑2026 Trade Schemes — Configuration Guide (Existing System, No Code Changes)

**Source file:** `TRADE_SCHEMES_JC06_2026.pdf` (25 pages)
**Prepared:** 2026‑06‑22
**Scope:** Map every scheme in the document to the *current* configuration capability of the
org. Where a scheme cannot be built with today's metadata/engine, it is called out
explicitly as **NOT POSSIBLE (needs code change)**.

---

## 1. The two configuration surfaces that already exist

Trade offers in this org are configured through **two independent surfaces**. Almost every
page of the PDF is a combination of the two.

### 1A. Price List — `Price_List__c`  (tab: **Price List**)
Holds the **buying price** a customer pays for a SKU. This is where **RBP (Retailer Buying
Price)** and **WBP (Wholesale Buying Price)** live — i.e. the bulk of the PDF.

| Field | Use |
|---|---|
| `Product_Ext__c` (Lookup → Product_Extension) | The SKU |
| `Price_Type__c` (Picklist) | **MRP / Distributor Price / Retailer Price / Special Price** |
| `Unit_Price__c` (Currency) | The price value (RBP, WBP, etc.) |
| `Channel__c` (GT/MT/E‑Commerce) | Channel scoping |
| `Customer__c` (Lookup → Account) | Specific customer (optional) |
| `Region__c` (Lookup → Company_Hierarchy) | Region scoping |
| `Territory__c` (Lookup → Territory_Master) | Territory scoping |
| `Min_Qty__c` | Minimum qty for this price |
| `Effective_From__c` / `Effective_To__c` | Validity window |
| `Priority__c`, `Is_Active__c`, `Status__c` | Resolution priority / activation |

> **Retailer vs Wholesale (WS):** model as two Price List rows — one `Price_Type = Retailer Price`
> (RBP) and one `Special Price`/`Distributor Price` (WBP) — or scope by `Channel__c`/`Customer__c`.

### 1B. Scheme Manager — `Scheme__c` (+ children)  (tabs: **Scheme Manager / Scheme Definition**)
Holds **offers calculated at order time** (discounts, free goods, reward points). Configured
through the Scheme Manager UI, which saves a `Scheme__c` plus three child lists in one
transaction (`SchemeDefinitionController.saveScheme`).

**Header — `Scheme__c`:** `Scheme_Type__c`, `Scheme_Category__c`, `Scheme_Class__c` (P1/P2/Secondary),
`Start_Date__c`/`End_Date__c`, `Min_Quantity__c`/`MOV__c`, `Discount_Percent__c`/`Price_Discount__c`,
`Free_Product_Ext__c`/`Free_Quantity__c`, `Applicable_Channel__c`, `Applicable_Outlet_Type__c`,
`Applicable_Region__c`, `Priority__c`, `Is_Stackable__c`, `Budget_Amount__c`, `Status__c`.

**Children:**
- **Scheme Product** (`Scheme_Product__c`): the buy/get SKUs — `Product_Ext__c`, `Is_Buy_Product__c`, `Is_Get_Product__c`, `Min_Quantity__c`.
- **Scheme Slab** (`Scheme_Slab__c`): qty/value tiers — `Slab_Type__c` (Quantity/Value), `Min_Quantity__c`/`Max_Quantity__c` (or `Min_Value__c`/`Max_Value__c`), and a benefit via `Discount_Type__c` = **Percent / Amount / Free Product / Price Discount / Reward Points**.
- **Scheme Mapping** (`Scheme_Mapping__c`): targeting — `Zone__c`, `Sub_Zone__c`, `Area__c`, `District__c`, `Territory__c`, `Account__c`, `Customer_Type__c` (Retailer / Wholesale / Distributor / Super Stockist / Modern Trade / D2R / Institutional).

#### Scheme types the engine (`SPM_SchemeEngine_Service`) actually computes
✅ **Active & implemented:** `Same Product (QTY)`, `Same Product (VAL)`, `Assorted Product (QTY)`,
`Assorted Product (VAL)`, `Invoice Qty Based`, `Invoice Val Based`.

⛔ **Present in the picklist but INACTIVE and NOT implemented in the engine:** `Buy X Get Y`,
`Combo Offer`, `Amount Off`, `Flat Discount Percent`, `Slab Based`. *(The first four mechanics
can often be reproduced with an active type + a slab — see below — but `Combo Offer` cannot.)*

#### Benefit categories
`Free Products`, `Discount in %`, `Discount in Value`, `Reward Points` (header‑level), or any of the
5 slab `Discount_Type__c` benefits per qty/value tier.

---

## 2. Capability matrix

| PDF scheme pattern | Where configured | Feasible today? |
|---|---|---|
| Special trade price RBP / WBP per SKU (most pages) | **Price List** | ✅ Yes |
| Region‑specific price (South / North / AP / JH&MP …) | **Price List** (Region/Territory) or Scheme **Mapping** | ✅ Yes |
| Retailer vs Wholesale price | **Price List** rows by Price_Type / Channel / Customer_Type | ✅ Yes |
| Per‑unit "P1 SCHEME" amount (Choki Rollz 2.5, Choki Stix 12) | **Scheme**: Same Product (QTY/VAL) + Price Discount | ✅ Yes |
| 7+1 free‑goods (Choki Stix) | **Scheme**: Same Product (QTY) + slab → Free Product | ✅ Yes (caveats) |
| Free physical gift (Kopiko "bucket free", "JOJ free") | **Scheme**: Free Products | ⚠️ Only if the gift is a real SKU |
| "Show & Earn" / display program reward | — | ⛔ No engine for display‑based earn |
| Multi‑SKU **Bundle** at a fixed price + variant‑mix rule (pp.18‑23) | — (`Combo Offer` inactive) | ⛔ NOT POSSIBLE without code |

---

## 3. Step‑by‑step configuration, per scheme

### Scheme group P — Standard trade price lists (RBP / WBP)
**Applies to:** Kopiko HPJ prices (p.2), Wholesale "Show & Earn" price tables (p.3‑6), all
Malkist schemes (p.7‑10), Choki XL Jar (p.12), Choki XL Share Pack (p.13), Choki Stix Share
Pack (p.17), Jam O Jam (p.24‑25). These are **pricing**, not order‑time discounts.

**Steps (per SKU, per region/customer type):**
1. Open the **Price List** tab → **New**.
2. `Product_Ext__c` = the SKU (match by SKU code, e.g. 310349).
3. Create **two rows** per SKU where both RBP and WBP are given:
   - Row A: `Price_Type__c = Retailer Price`, `Unit_Price__c = RBP` (e.g. 595).
   - Row B: `Price_Type__c = Special Price` (or Distributor Price), `Unit_Price__c = WBP` (e.g. 580).
4. Scope it: set `Channel__c`, and `Region__c`/`Territory__c` for region‑specific tables
   (e.g. "SOUTH (EX‑AP)" → the South region; "ANDHRA PRADESH" → AP).
5. `Effective_From__c` / `Effective_To__c` = the JC06‑2026 cycle dates.
6. `Min_Qty__c` if the price needs a minimum (e.g. Malkist "only on 17G for WS").
7. `Priority__c` so the region/customer‑specific row beats the national default.
8. `Is_Active__c = true`, `Status__c = Active`.

> Region pages (p.3‑6) differ only by **which SKUs are in scope** and the region — repeat the
> steps with the SKU list shown on each page and the matching `Region__c`.

---

### Scheme A — Per‑unit scheme amount ("P1 SCHEME")
**Applies to:** **Choki Rollz Trade Scheme (p.14)** — P1 scheme ₹2.5/pc; **Choki Stix Trade
Scheme (p.16)** — P1 scheme ₹12/pc.

This is a per‑unit value given on top of the price → model as a **Price Discount**.

**Steps (Scheme Manager → New Scheme):**
1. **Header:** `Scheme_Type__c = Same Product (QTY)`; `Scheme_Category__c = Discount in Value`;
   `Scheme_Class__c = P1`; set Start/End dates; `Status = Draft`.
2. **Scheme Product:** add the SKU (e.g. Choki Stix GB 422308) with `Is_Buy_Product__c = true`,
   `Min_Quantity__c = 1`.
3. **Benefit — choose one:**
   - Simple: set header `Price_Discount__c = 12` (Choki Stix) / `2.5` (Rollz). *Per‑unit value is
     applied against the qualifying line.*
   - Or **Scheme Slab:** `Slab_Type = Quantity`, `Min_Quantity = 1`, `Discount_Type = Price Discount`,
     `Price_Discount = 12`.
4. **Mapping:** add a `Scheme_Mapping__c` row with the target `Customer_Type__c = Retailer` (and
   Zone/Territory if regional).
5. Set `Applicable_Channel__c`, `Priority__c`, `Is_Stackable__c` as required → **Activate** (`Status = Active`).

---

### Scheme B — Quantity free‑goods "7+1"
**Applies to:** **Choki Stix 7+1 Offer (p.15)** — buy 7 get 1 (SD 3.5+0.5).

The `Buy X Get Y` type is inactive, but the mechanic is reproducible with **Same Product (QTY)
+ a Free Product slab**.

**Steps:**
1. **Header:** `Scheme_Type__c = Same Product (QTY)`; `Scheme_Category__c = Free Products`; dates; `Status = Draft`.
2. **Scheme Product:** the buy SKU (Choki Stix GB 421170) → `Is_Buy_Product__c = true`, `Min_Quantity__c = 7`.
3. **Scheme Slab:** `Slab_Type = Quantity`, `Min_Quantity = 7`, `Discount_Type = Free Product`,
   `Free_Product_Ext__c =` the same SKU, `Free_Quantity__c = 1`.
   *(Distributor 3.5+0.5 = a second slab or a separate scheme mapped to `Customer_Type = Distributor`.)*
4. **Mapping:** `Customer_Type = Retailer`.
5. Activate.

⚠️ **Caveats:** (a) "Applicable only on OLD STOCK (421170)" cannot be enforced automatically —
limit it by listing only the old‑stock SKU as the buy product. (b) The engine returns the free
qty as a benefit; the slab does not auto‑repeat for multiples of 7 unless additional slabs/logic
are configured — verify the multiple‑of‑7 behaviour during UAT.

---

### Scheme C — Free physical gift with purchase
**Applies to:** **Kopiko HPJ Offer (p.2)** — "BUCKET FREE" / "JOJ FREE".

**Feasible only if the giveaway exists as a `Product_Extension__c` record.**
- If yes: `Scheme_Type = Same Product (QTY)`, `Scheme_Category = Free Products`,
  `Free_Product_Ext__c =` the gift SKU, `Free_Quantity__c = 1`, buy product = the Kopiko SKU.
  Configure the SKU price itself in the Price List (Scheme group P).
- If the "bucket"/"JOJ" is **merchandising material, not a sellable SKU** → ⛔ not configurable as
  a free product (no non‑inventory giveaway object today). Handle the price via Price List and the
  gift manually/offline.

---

## 4. Schemes that are NOT POSSIBLE without code changes

### 4.1 Multi‑SKU Bundle offers (pp. 18‑23) — ⛔ NOT POSSIBLE
**Examples:** "CHOKI BUNDLE OFFER – Purchase all these @ ₹1050 / ₹900 / ₹880 …", region‑specific,
with a fixed basket (e.g. 2× Malkist Cheese SP + 1× Malkist Choc SP + 2× Choki Duo Jar + 1× Choki
Rollz + 1× Jam O Jam) **sold at one fixed bundle price**, plus a **variant‑mix rule** (2 Cheese+1
Choc / 1 Cheese+2 Choc / 3 Cheese / 3 Choc).

**Why not:** The `Combo Offer` scheme type is **inactive** and **`SPM_SchemeEngine_Service` has no
combo logic**. The engine can aggregate quantity/value across products (`Assorted`) but it cannot:
(a) require a *specific basket of specific SKUs at specific quantities*, (b) charge a *single fixed
bundle price*, or (c) enforce the *variant‑mix substitution* rule. Building this needs development
(activate `Combo Offer` + implement basket matching, fixed‑price settlement, and mix rules).

### 4.2 "Show & Earn" / Display program *earn* component (pp. 3‑6) — ⛔ NOT POSSIBLE (as an earn mechanic)
The **prices** on these pages are configurable via the Price List. But "Show & Earn / Display
Program" implies a reward for *displaying* product (visibility/merchandising verification → payout).
There is no object/flow that captures a display, verifies it, and accrues an earn. The price side is
fine; the *earn‑for‑display* side needs development (or handle via manual `Scheme_Accrual__c` claims).

---

## 5. One‑line summary per PDF page

| Page | Scheme | Configure via | Feasible |
|---|---|---|---|
| 2 | Kopiko HPJ (bucket/JOJ free) | Price List + Scheme (Free Products) | ✅ price / ⚠️ gift if SKU |
| 3‑6 | Wholesale "Show & Earn" (4 regions) | Price List (region/customer) | ✅ price / ⛔ display‑earn |
| 7‑10 | Malkist trade schemes | Price List | ✅ |
| 11 | Project Alpha+ (section header) | — | N/A |
| 12 | Choki XL Jar | Price List | ✅ |
| 13 | Choki XL Share Pack | Price List | ✅ |
| 14 | Choki Rollz (P1 ₹2.5) | Scheme: Same Product (QTY) + Price Discount | ✅ |
| 15 | Choki Stix 7+1 | Scheme: Same Product (QTY) + Free Product slab | ✅ (caveats) |
| 16 | Choki Stix (P1 ₹12) | Scheme: Same Product (QTY) + Price Discount | ✅ |
| 17 | Choki Stix Share Pack | Price List | ✅ |
| 18‑23 | Choki **Bundle** offers (fixed basket/price) | — (`Combo Offer` inactive) | ⛔ NO |
| 24‑25 | Jam O Jam trade schemes | Price List | ✅ |

---

## 6. Recommended configuration order
1. **Load all SKUs' prices** (MRP/RBP/WBP) into **Price List**, scoped by region/channel/customer type — this covers the majority of the document.
2. **Build the Scheme records** for the value/free‑goods offers (pp.14,15,16, and p.2 gift if a SKU).
3. **Flag for development:** Bundle offers (pp.18‑23) and the Show‑&‑Earn *display earn* — these are blocked on code changes.
4. **UAT:** verify region/customer‑type resolution, the 7+1 multiple behaviour, and price‑vs‑scheme stacking (`Is_Stackable__c`).
