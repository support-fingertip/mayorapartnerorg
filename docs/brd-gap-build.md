# BRD Gap Build — Position/Role, Schemes, Product Sharing, Targets

The org already implements most of these four features. This documents the
declarative gaps added (deployable now) and the logic gaps staged for a
sandbox (cannot be compiled/validated from the current environment).

## Reused org foundations (NOT rebuilt)
- **Position/Role:** `Employee__c`, `Company_Hierarchy__c`, `Territory_Master__c`,
  `Employee_Category__c`, `Beat__c`/`Beat_Outlet__c`; `EmployeeController`,
  `MDM_*`/`BPM_*` handlers; `employeeManager`/`beatManager` LWCs.
- **Schemes:** `Scheme__c` + `Scheme_Product/Slab/Mapping/Accrual__c`, `Claim__c`;
  `SPM_SchemeEngine_Service` + `SPM_*` handlers; `schemeManager/Definition/Viewer`.
- **Targets:** `Target__c` + `Target_Period/Actual/Criteria/Line__c`, `KPI_Metric__c`;
  `TAM_Achievement_Batch/Service`, `TAM_Rollup_Service`; `tamTargetAllocation`.
- **Product Sharing:** `Price_List__c` (Channel/Region/Territory/Customer + priority)
  + `Product_Extension__c.Channels__c`; `ProductManagementController`;
  `productManagementHub`/`productCatalog`. UOM case/piece via `UOM__c`/`UOM_Conversion__c`.

## Declarative gaps added (deployable)
| Feature | Added | BRD |
|---|---|---|
| Schemes | `Scheme__c.Scheme_Class__c` (P1/P2/Secondary) | §13.2 |
| Schemes | `Scheme__c.Applicable_Outlet_Tag__c` (Alpha/Non-Alpha) | §13.2 |
| Targets | `Target__c.Tier__c` (P1/P2/Secondary/Outlet) | §13.1 |
| Targets | `Target_Period__c.Type__c` += **Journey Cycle** value | §8/§13 |
| Targets | new `Outlet_Target_Increment__c` (State + Outlet Type + Increment % + Basis) | §13.2 |
| Product Sharing | `Product_Extension__c.MT_Article_Code__c` | §9.5 |
| Product Sharing | `Product_Extension__c.Brand_Alias__c` | §9.1 |
| Position/Role | new `Temporary_Beat_Assignment__c` (Beat, Assigned-To User, From Employee, Start/End, Status, Notes) | §5.3 |

## Logic gaps staged for sandbox (need org to compile/validate)
- **Position/Role:** Position→`UserRole`/Profile/`ManagerId` provisioning on user
  assignment; vacant→System Admin ownership; position-code tag on transactions;
  sharing on Temporary Beat Assignment insert + expiry on End Date (§5.2–5.4, §6).
- **Schemes:** bundle-first priority + usage cap per outlet per JC; one-SKU-one-scheme;
  no-scheme-on-returns; FOC zero price/tax; IT→Sales Director approval; 3-day expiry
  alert (extend `SPM_SchemeEngine_Service` / add approval process + scheduled alert).
- **Targets:** JC-based actual rollup; outlet auto-increment using
  `Outlet_Target_Increment__c`; secondary-order & invoice-based actuals
  (extend `TAM_Achievement_Service` / `TAM_Achievement_Batch`).
- **Product Sharing:** explicit Nation/Branch visibility resolution + MT article-code
  mapping in order upload (extend `ProductManagementController`).
