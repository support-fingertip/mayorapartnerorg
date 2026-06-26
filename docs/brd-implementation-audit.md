# BRD Implementation Audit — existing org vs. full BRD process list

Audit of the existing 382-class / 40-trigger org against every BRD process,
followed by the additive gaps built on this branch. Scope: Salesforce backend +
config + Salesforce-side Apex. **No REST/API** added (org already ships
`API_*_Rest`). SAP integration is a stated 2nd release (§12.4) and out of scope.

Legend: ✅ implemented · ◑ partial · ❌ missing → **[built]** added this branch ·
**[sandbox]** needs extending an existing Apex class (not done — see why below).

## Position / User / Beat / PJP / JC / Attendance (§5–8, 18)
| Requirement | Status |
|---|---|
| Position-code data access, user tagging, history preservation | ✅ (MDM_/BPM_ handlers) |
| Temporary Beat Assignment share + auto-expire | ✅ (`MDM_TempBeatAssignment_*`) |
| User onboarding, position→manager sync | ✅ (`Employee_Trigger`, MDM) |
| PJP repeatable 7/14/28, status flow | ✅ (`BPM_JourneyPlan_*`) |
| No-PJP day cap 3/JC, beat-switch | ✅ **[built earlier]** (`BPM_BeatDayRequest_TriggerHandler`) |
| Max 70 outlets per beat | ❌ → **[built]** VR `Beat__c.Max_70_Outlets` |
| Auto-end-day 23:55 | ❌ → **[built]** `DFO_DayAttendance_AutoClose_Batch` |
| Outlet colour-coding (New/Ordered/Active/Never, 28/56/84/112 bands) | ❌ **[sandbox]** needs Account date fields confirmed in org |
| Single-active-PJP, L1 6-beat-no-repeat | ◑ **[sandbox]** extend existing `BPM_JourneyPlan*` handler |
| Day-end reminders 9/10 PM | ❌ **[sandbox]** wire to `NotificationDispatchService` |

## Product / Pricing (§9–11)
| Requirement | Status |
|---|---|
| Product master, UOM Case↔Piece, MT article-code map | ✅ (`UOM_Conversion_Service`, `MDM_MTArticleCode_Service`) |
| Product visibility Nation/Branch/State/Channel/Distributor | ✅ (`Product_Sharing__c`) |
| Price cascade P1/P2/Secondary, resolution at order time | ✅ (`OMS_OrderPricing_Service`, `Pricebook_Priority__mdt`, `MDM_PriceList_Handler`) |
| ZPR0/ZSD1/ZSD2 landing-price calc | ◑ SAP-sourced (2nd release) |

## Orders / Invoice / Returns / Collection / Must-Sell (§12, 14–17)
| Requirement | Status |
|---|---|
| Order create rules, auto-apply schemes, must-sell compliance | ✅ (`OMS_*`, `SPM_SchemeEngine_Service`) |
| Collection (app + DMS) | ✅ (`API_Collection_Rest`, `OVE_Collection_*`) |
| Secondary returns → stock | ✅ (`DMS_ReturnOrder_TriggerHandler`) |
| Return only if SKU returnable | ❌ → **[built]** VR `Return_Line__c.SKU_Must_Be_Returnable` |
| On-Account/advance balance check | ❌ SAP-dependent (2nd release) |
| One-order-per-day strict + 9 PM edit cutoff | ◑ **[sandbox]** extend `OMS_OrderValidation_Service` |
| FOC price / purchase-price capture | ◑ **[sandbox]** extend `OMS_OrderPricing_Service` |
| P1 approval DO→ASM/ASE→CFA | ◑ generic `DynamicApprovalEngine` exists; **wiring is config data** (Approval_Rule__c records) |

## Schemes (§13)
| Requirement | Status |
|---|---|
| 6 scheme types, auto-apply, slabs, budget tracking, usage cap (per customer), 3-day expiry alert | ✅ (`SPM_SchemeEngine_Service`, `SPM_SchemeExpiryAlert_Batch`) |
| Budget exhaustion auto-stop + notify | ❌ → **[built]** `SPM_SchemeBudget_Batch` |
| Bundle basket model | ❌ → **[built earlier]** `Scheme_Basket__c` / `Scheme_Basket_Product__c` + `Is_Bundle_Scheme__c` |
| Bundle-first priority, one-SKU-one-scheme, per-outlet-per-JC cap, FOC zero price/tax, no-scheme-on-returns | ◑ **[sandbox]** extend `SPM_SchemeEngine_Service` / `OMS_OrderPricing_Service` / `OMS_ReturnOrder_TriggerHandler` |
| IT-admin→Sales-Director approval | ◑ **[config]** via `DynamicApprovalEngine` rules (data) |

## Targets / KPI / Gamification / DA / Incentives (§13, 19–20)
| Requirement | Status |
|---|---|
| Target JC rollup, outlet auto-increment (State+Outlet-Type %) | ✅ (`TAM_Achievement_Batch`, `TAM_OutletTargetIncrement_Service`) |
| KPI framework (configurable COUNT/SUM) | ✅ (`KPI_Metric__c`, `DKD_QueryEngine_Service`) |
| Gamification slab scoring + coins/qualifier | ✅ **[built]** `GAM_GameScore_Service/Batch` on `Game__c/Game_KPI__c/Game_Score__c` |
| DA Policy (KPI half/full-day → DA) | ❌ → **[built]** `DA_Policy__c` / `DA_Policy_KPI__c` objects (calc logic = sandbox) |
| KPI-actual persistence feeding Game Score Achievement | ◑ **[sandbox]** persist TC/PC/etc. and stamp `Game_Score__c.Achievement__c` |
| Incentive manual upload | ◑ via data loader (`Incentive__c`) |

## Approvals / Expense / MAP / Notifications / Tickets / Integration (§4.2, 4.8, 4.9, 21.7, 23)
| Requirement | Status |
|---|---|
| Generic approval engine (multi-level, auto/manual, approver resolution) | ✅ (`DynamicApprovalEngine`) |
| Expense policy + DA auto-calc + multi-stage approval + over-limit alerts | ✅ (`EXP_Expense_Service`, `Expense_Eligibility__c`) |
| Notifications (in-app + email; SMS/WhatsApp stubbed) | ✅ (`NotificationDispatchService`) |
| **MAP (Budget / Order / Actuals)** | ❌ → **[built]** `MAP_Budget__c` (+ rollup spend, remaining) / `MAP_Order__c` (actuals) |
| Approval routing wired for outlet/PJP/order/return/scheme/MAP | ◑ **[config]** engine exists; create `Approval_Rule__c` records per flow |
| Visit checklist scoring by outlet-type/channel | ◑ **[sandbox]** wire `Survey_*` to visit checkout |
| Ticket auto-assign by category / escalation | ❌ **[sandbox]** add `Ticket_Trigger` + routing config |
| SMS OTP (outlet verify), WhatsApp navigate-only | ❌ integration (out of scope) |

---

## Built this branch (all additive — no existing definition changed)
**New objects (14 total):** Game / Game KPI / Game Score, Stock Check / Stock Check Item, Retail Asset, Must-Sell No-Sale, Scheme Basket / Scheme Basket Product, Beat Day Request, **MAP Budget / MAP Order**, **DA Policy / DA Policy KPI**.

**Apex (with tests, on the org's framework):** `GAM_GameScore_Service` + `GAM_GameScore_Batch`; `BPM_BeatDayRequest_TriggerHandler`; `DFO_RetailAsset_TriggerHandler`; **`SPM_SchemeBudget_Batch`** (budget auto-stop); **`DFO_DayAttendance_AutoClose_Batch`** (auto-end-day).

**Config:** validation rules (incl. **Beat max-70**, **return-eligibility**), additive fields on Scheme/Order Line/Survey, tabs, page layouts, list views, FlexiPage record pages, custom report types, the **Mayora SFA Admin** Lightning app, and the **Mayora SysAdmin Full Access** permission set.

## Why some items are "[sandbox]" not built here
They require **editing existing Apex classes** (e.g. `SPM_SchemeEngine_Service`,
`OMS_OrderPricing_Service`, `BPM_JourneyPlan*`), which the standing instruction is
to leave unchanged, and which need a live org to compile/regression-test. They are
small, well-scoped extensions — each noted against its owning class above. Items
marked **[config]** are Salesforce data records (Approval_Rule__c etc.), not
deployable source. SAP/SMS/WhatsApp are integrations outside this scope.
