# Mayora SFA/DMS — Data Model (Phase 2 backend)

This is the deployable Salesforce schema behind the four admin/config screens
(Positions & Roles, Scheme Management, Product Sharing, Targets vs Actual).
It is generated as SFDX source under `force-app/main/default/objects` and
deployed through the existing **Deploy** GitHub Action.

## Reuse vs. build

**Reused standard objects** (custom fields added, object not recreated):

| Standard object | Used for | Added fields |
|---|---|---|
| `Account` | Distributors (SS/DB/SD) and outlets | `Channel__c`, `Distributor_Type__c`, `Outlet_Type__c`, `Outlet_Tag__c` |
| `Product2` | SKUs | `Brand__c`, `Sub_Brand__c`, `Brand_Alias__c`, `Returnable__c` |
| `User` + `UserRole` | Role hierarchy that the Position→Role chain drives | — (standard) |

**New custom objects**

| Object | Role | Key relationships |
|---|---|---|
| `Geography__c` | Self-hierarchical geography (National→…→Beat) | `Parent_Geography__c` → self |
| `Position__c` | Position code / data-access spine | `Area__c`→Geography, `Reports_To__c`→self, `Assigned_User__c`→User |
| `Scheme__c` | Scheme header (the rule) | parent of the children below |
| `Scheme_Slab__c` | Buy-and-get steps | Master-Detail → `Scheme__c` (`Slabs__r`) |
| `Scheme_Eligibility__c` | Who the scheme applies to | Master-Detail → `Scheme__c` (`Eligibilities__r`) |
| `Scheme_Bundle_Line__c` | SKUs in a combo | Master-Detail → `Scheme__c` (`Bundle_Lines__r`) |
| `Scheme_Tier__c` | Pass-through P1/P2/P3 benefit | Master-Detail → `Scheme__c` (`Tiers__r`) |
| `Scheme_Claim__c` | Cumulative-scheme settlement | Lookup → `Scheme__c`, `Account` |
| `Product_Visibility__c` | SKU visibility rules | Lookup → `Product2`, `Geography__c`, `Account` |
| `Target__c` | Targets vs actual by tier | Lookup → `Account`, `Position__c` |

## Apex

- `SchemeController` — `@AuraEnabled(cacheable=true)` read API returning scheme
  headers with their child rows, plus claims. This is the pattern each LWC
  switches to (replacing the `c/dmsData` mock getters).
- `SchemeControllerTest` — coverage for the controller.

## Still to do (needs a connected org to validate)

1. Controllers for Positions, Product Visibility and Targets (same pattern).
2. Automation: Position→Role auto-create + owner assignment, scheme auto-apply
   / budget block at order time, target auto-increment, actuals roll-up.
   Recommended as Apex triggers or Flows, with tests (≥75% to deploy).
3. Rewire each LWC from its `c/dmsData` mock getter to the Apex controller
   (`@wire`), keeping the same view markup.
4. Sharing: set OWD + confirm role hierarchy gives the visibility the
   architecture relies on; add manual-share rows for CFA where needed.
