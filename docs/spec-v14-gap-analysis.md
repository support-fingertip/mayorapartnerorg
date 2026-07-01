# Mayora v14 Spec vs Org — Field-Level Gap Analysis

_Audit of 51 spec objects vs org metadata. Fields matched by meaning, not name. Object mapping reconciled (org uses different API names)._

## Summary

| Verdict | Count |
|---|---|
| Aligned (no gaps) | 14 |
| Minor gaps (1-3) | 16 |
| Major gaps (4+) | 18 |
| Cannot verify (standard obj not in repo) | 3 |

## JC / Journey Calendar

**Verdict: PARTIAL**

The spec's Journey Calendar (JC) is a dedicated shared master where 1 year = exactly 13 fixed reporting periods (JC Number 1-13, Year, Start/End Date, Is Current JC, Working Days) that all Targets, Game Scores, Expenses, plans and reports are grouped by.

Target_Period__c (/home/user/mayorapartnerorg/force-app/main/default/objects/Target_Period__c/fields) is the only object that partially covers this. It has Start_Date__c, End_Date__c, Is_Active__c (≈ Is Current), a self-referencing Parent_Period__c hierarchy, and a restricted Type__c picklist whose values include "Journey Cycle" (alongside Monthly/Quarterly/Yearly). So JC-style periods CAN be represented as rows of Type = Journey Cycle. However it is a generic mixed-granularity period object, NOT a dedicated 13-period calendar: there is no JC Number (1-13) field, no Year field, no Working Days field, and nothing that structures or enforces "13 periods per year." "Journey Cycle" is just one of four types sharing the same table.

Journey_Plan__c and Journey_Plan_Day__c (despite the "Journey" naming) are salesperson beat/route planning objects — Territory__c, Salesperson__c, Beat__c, daily Plan_Date__c/Week_Number, and a standard-calendar Month__c picklist (Jan-Dec) plus Year__c/Effective_From/To. They model physical visit routes on the ordinary Gregorian month/year, not the 13-period JC reporting calendar, so they do not provide the JC concept.

No Journey_Calendar__c object exists, and no field on the reviewed objects provides the 1-13 period number, per-period Working Days, or the company-wide JC grouping key the spec describes.

**Recommendation:** Treat JC as partially covered by Target_Period__c but not fully modeled. Recommended path: either (a) create the dedicated Journey_Calendar__c master exactly as specced (JC Name, JC Number 1-13, Year, Start/End Date, Is Current JC, Working Days) and have Target/Game Score/Expense lookup to it, or (b) if consolidating onto Target_Period__c, extend it with JC_Number__c (Number 2,0), Year__c (Text 4), and Working_Days__c (Number 3,0) fields, rely on Type = "Journey Cycle" to distinguish JC rows, and reuse Is_Active__c as Is Current JC. Do NOT map JC onto Journey_Plan__c/Journey_Plan_Day__c — those are route/beat planning objects on the standard calendar and serve a different domain.


## Major gaps (4+ missing fields)

### Attendance (Day Log) → Day_Attendance__c
- **Position Code** (Lookup(Position__c)) — No Position lookup on org
- **JC** (Lookup(Journey_Calendar__c)) — No Journey Calendar reporting-period lookup
- **Activity Type** (Picklist) — No Retailing/Official/JW/Leave activity picklist
- **Sub-Activity (Official)** (Picklist) — No official-work sub-type picklist
- **City Type / Grade** (Picklist) — No city grade picklist
- **Assigned Beats** (Text(255)) — No assigned-beats snapshot text
- **Selected Beats** (Text(255)) — No selected-beats text field
- **First Call Time** (DateTime) — No first-call timestamp field
- **Last Call Time** (DateTime) — No last-call timestamp field
- **Retail Time** (Text(10)) — No retailing-hours field
- **SC (Scheduled Calls)** (Number(5,0)) — No scheduled-calls count field
- **TC (Total Calls)** (Number(5,0)) — No total-calls count field
- **PC Must-Sell** (Number(5,0)) — No must-sell productive-calls field
- **CAP** (Number(5,0)) — No CAP metric field
- **OVC** (Number(5,0)) — No OVC metric field
- **Telephonic Orders** (Number(5,0)) — No telephonic-orders count field
- **LPC** (Number(6,2)) — No lines-per-call field
- **Qty (Pieces)** (Number(16,2)) — No pieces quantity field
- **Qty (Cases)** (Number(16,2)) — No cases quantity field
- **Qty (Super Unit)** (Number(16,2)) — No super-unit quantity field
- **Manager JW Calls** (Number(5,0)) — No joint-work call count field
- **Attendance Status** (Picklist) — No daily attendance-code picklist
- **Norm-Based Attendance** (Picklist) — No norm-based present/half/absent picklist
- **Regularised Attendance** (Picklist) — No regularized attendance picklist
- **Regularisation Reason** (Text(255)) — No regularisation reason field
- **Retailing Grade** (Text(20)) — No retailing grade field
- **PJP Adherence %** (Percent(5,2)) — No PJP adherence percent field
- **Platform (login)** (Picklist) — No login platform picklist
- **Leave Type** (Picklist) — No leave-type picklist; only Is_Leave_Day
- **Leave Session** (Picklist) — No leave full/half-day session picklist
- **Leave Reason** (Text(255)) — No leave reason field
- **Leave Status** (Picklist) — No leave approval-status picklist
- **Leave Approved By** (Lookup(User)) — No leave approver lookup

_Org grain matches (single per-user daily log) but the object is markedly thinner. Covered: Date, User, Travel Type (Duty_Type__c HQ/EX-HQ/OS), Tour Plan (Journey_Plan_Day__c), Login/Logout (Start/End times), Logout Type (Auto_Closed/Status), Total Time (Hours_Worked), PC (Productive_Calls), Productivity %, OVT (Total_Visits), Net/Sale Value (Total_Order_Value), Selected JW User (Companion, refs Employee not User), Original Beat, Beat Switched, Beat Switch Reason, Odometer Start/End, Distance, Start/End Selfie (URL), Device Info, Network Status, Battery Level. Reason(activity) approximated by Remarks/Late_Reason. Day Start Location approximated by Start_Location_Lat/Long geo fields. The entire Leave sub-model (merged from Leave object per spec) is absent except an Is_Leave_Day flag — biggest gap cluster. Retail-call metrics (SC/TC/CAP/OVC/LPC/Qty tiers) and attendance-status/regularisation picklists are all missing. Org adds extras not in spec (collections, GPS accuracy, lat/long, Week_Day)._

### Beat → Beat__c
- **Position Code** (Lookup(Position__c)) — No Position lookup; Territory points to Territory_Master__c
- **Tagged Distributor (DB)** (Lookup(Account)) — No Account lookup for distributor exists
- **Tagged Sub-Distributor (SD)** (Lookup(Account)) — No Account lookup for sub-distributor exists
- **Beat Grade** (Picklist) — No beat grade picklist field present

_Org grain differs: beat is tied to Territory_Master__c and Assigned User (User), not to Position or to DB/SD Account lookups. Matches found: Beat Id=Beat_Code__c (Text50 ExtId Unique), Outlet Count=Total_Outlets__c (plain Number, not COUNT roll-up), Is Active=Is_Active__c, Beat Name=standard Name, Creation Date/Last Updated=standard audit fields. Outlet Count is a static Number rather than a live COUNT(Account) roll-up, so counts may drift. Org adds fields with no spec counterpart: Beat_Day__c, Beat_Frequency__c, Frequency__c, Day_of_Week__c, Sequence__c, Pincode_Cluster__c, Description__c._

### City Master (Geography) → City_Tier__c
- **City Code** (Text(20) External Id) — No SAP city code field
- **City Name** (Text(80)) — No city name field present
- **Category** (Picklist (Urban; Rural)) — No urban/rural category picklist
- **Sub-District** (Text(80)) — No sub-district field present
- **District** (Text(80)) — No district field present
- **Zone** (Picklist) — No zone picklist present
- **Region** (Picklist) — No region picklist present
- **City Type** (Picklist (Metro; Non-Metro; Hill Station)) — No metro/hill-station type picklist
- **Is Delhi / NCR** (Checkbox) — No Delhi/NCR flag present
- **Is T1 Town** (Checkbox) — No T1 town flag present

_Org City_Tier__c is a thin tier-mapping table with only 3 fields (State text, Tier picklist, Active checkbox). Different grain: it maps tiers, not a full city master. Matches: City Tier==Tier__c, State==State__c, Is Active==Is_Active__c. Note State is Text here vs spec Picklist. No lookups needed (spec has none), consistent._

### Distributor Live Stock → Distributor_Stock__c
- **Warehouse ERP Id** (Text(50)) — no warehouse ERP id field
- **Current Stock (Cases)** (Number(16,2)) — no case-level stock field
- **Expired Qty** (Number(16,2)) — only Damaged_Qty, not expired qty
- **Price / Pc** (Currency(16,2)) — no price-per-piece field
- **MRP** (Currency(16,2)) — no MRP currency field
- **Total Value** (Currency(16,2)) — no total value field

_Org models transactional daily stock movements (Opening/Received/Sold/Closing/Damaged, Stock_Date, Batch, Expiry_Date, Visit lookup) rather than a live-stock snapshot with valuation. Distributor==Account__c and Is Active==Is_Current map cleanly; Product maps to Product_Ext__c (Product_Extension__c, not Product__c). Current Stock (Pieces) is loosely covered by Closing_Stock__c. No pricing/valuation grain (Price/Pc, MRP, Total Value) and no case-vs-piece distinction._

### Expense - Claim (Header) → Expense__c
- **Expense Date** (Date) — Only period start/end range exists
- **Day Activity** (Lookup(Day_Activity__c)) — No Day Activity lookup present
- **JC** (Lookup(Journey_Calendar__c)) — No Journey Calendar lookup present
- **DA Amount** (Currency(16,2)) — No daily allowance amount field
- **Outstation Type** (Picklist) — No HQ/Ex-HQ/Outstation picklist
- **City Grade** (Picklist) — No metro/city grade picklist
- **TA Type** (Picklist) — No travel-allowance type picklist
- **TA Amount** (Currency(14,2)) — No travel allowance amount field
- **Other Expense Amount** (Currency(14,2)) — No miscellaneous expense amount field
- **Travel Details** (Text Area(255)) — No from/to travel details field
- **Settlement Date** (Date) — No finance settlement date field
- **Expense Config** (Lookup(Expense_Config__c)) — No Expense Config policy lookup
- **Department** (Picklist) — No department picklist field
- **Location / HQ** (Text(120)) — No location/HQ text field
- **State** (Picklist) — No Indian state picklist field
- **Delay Submission Days** (Number(4,0)) — No delay-submission days field
- **Pre-Approval Status** (Picklist) — No pre-approval/requisition status picklist
- **Advance Adjusted** (Currency(14,2)) — No advance/imprest adjusted field
- **Advance Balance** (Currency(14,2)) — No advance/imprest balance field

_Org Expense__c is grained as a monthly/period expense sheet (Month, Year, Period Start/End, Working Days, rollup summaries Total_Claimed/Approved/Eligible) rather than the spec's per-claim header. Matched: User->User__c, Status/Approval Stage->Status__c (Submitted/Manager Approved/Finance Approved/Rejected/Paid), Total Amount->Total_Claimed__c (rollup), User Travelled Distance->Total_Distance_KM__c. Settled is approximated by Status=Paid (no checkbox). Org adds Employee__c lookup, distinct approver/date/remarks fields (L1/L2/Manager/Finance) and Comments_History not in spec. Key spec relationships to Day_Activity__c, Journey_Calendar__c and Expense_Config__c are entirely absent._

### Expense Config (DA-TA Policy) → DA_Policy__c
- **Employee Type** (Picklist) — no policy-table classification field in org
- **Designation** (Picklist) — no designation picklist in org
- **Grade / Class** (Picklist) — no grade/class field in org
- **DA Amount** (Currency(12,2)) — no DA amount currency field
- **Food Allowance** (Currency(12,2)) — no food allowance field
- **Local Conveyance (Ex-HQ)** (Currency(12,2)) — no ex-HQ conveyance field
- **Local Conveyance (Night Stay)** (Currency(12,2)) — no night-stay conveyance field
- **Hotel Cap - Metro** (Currency(12,2)) — no metro hotel cap field
- **Hotel Cap - T1/Hill** (Currency(12,2)) — no T1/Hill hotel cap field
- **Hotel Cap - Others** (Currency(12,2)) — no other hotel cap field
- **Mobile & Internet** (Currency(12,2)) — no mobile/internet allowance field
- **Two-Wheeler Rate/Km** (Currency(6,2)) — no two-wheeler per-km rate
- **Four-Wheeler Rate/Km** (Currency(6,2)) — no four-wheeler per-km rate
- **Air Class** (Picklist) — no air travel class field
- **Train Class** (Picklist) — no train travel class field
- **Imprest Limit** (Currency(12,2)) — no travel-advance cap field
- **Ex-HQ Distance Threshold (Km)** (Number(5,0)) — no distance threshold number field
- **Is TA Claim** (Checkbox) — no TA-claim toggle field
- **Meter Reading Allowed** (Checkbox) — no meter-reading toggle field
- **Remark Mandatory** (Checkbox) — no remark-mandatory toggle field
- **Travel Purpose Mandatory** (Checkbox) — no travel-purpose-mandatory toggle field
- **Approval Authority** (Picklist) — no approval authority picklist
- **Effective From** (Date) — no effective-from date field
- **Effective To** (Date) — no effective-to date field

_Org DA_Policy__c has only 3 custom fields: Description__c (TextArea), Expense_Eligibility__c (Lookup), Is_Active__c (Checkbox). Only "Is Active" matches the spec. The spec explicitly says this object has NO lookups/master-detail, yet the org adds an Expense_Eligibility__c lookup — different grain: org models DA policy as a child of an eligibility record rather than a self-contained master keyed by Employee Type x Designation/Grade. All rate/cap/allowance/toggle/date policy attributes are absent; the object is essentially a stub._

### Expense Item (Line) → Expense_Item__c
- **Day** (Text(3)) — No day-of-week text field
- **Attendance Status** (Picklist (Present/Absent)) — No present/absent status picklist
- **Vehicle Reading Start** (Number(10,0)) — No odometer start reading field
- **Vehicle Reading End** (Number(10,0)) — No odometer end reading field
- **Own Accommodation (50%)** (Checkbox) — No own-accommodation 50% flag
- **Hotel Stay Type** (Picklist (Booked/Own/None)) — No hotel stay-type picklist
- **PAX Names** (Text(255)) — No PAX names field for actuals
- **Line Total** (Formula (Currency)) — No per-day line total; per-type grain

_Grain differs fundamentally: org models one Expense_Item per expense TYPE (Expense_Type__c picklist: DA/Food/Fuel/Hotel/Toll/Mobile/etc.) with a single Claimed_Amount__c per row, rather than the spec's one wide row-per-day carrying a separate currency column for every component (DA/Food/Local Conveyance/Fuel/Hotel/Ticket/Mobile/Toll/Printing/Counter). Consequently the spec's per-component amount columns and Line Total map onto per-type Claimed/System_Calculated/Eligible/Approved amounts, not dedicated fields. City To is org To_Location__c (Text) instead of a City_Master__c lookup — relationship weaker but meaning covered. Attendance link exists via Day_Attendance__c lookup (to Day_Attendance__c, not Day_Activity__c). Org adds calc/approval fields (GPS/Manual/Applied distance, Is_Eligible, Approval_Status, Approved_Amount, Receipt) absent from spec._

### GRN Item (Line) → GRN_Line__c
- **Invoiced Qty** (Number(16,2)) — no invoiced quantity field present
- **Manufacturing Date** (Date) — no manufacturing date field present
- **Return Qty** (Number(16,2)) — no return quantity field present
- **Return Reason** (Picklist) — no return reason picklist present

_GRN (MD), Product (Lookup Product2), Received Qty, and Expiry Date (plain Date vs spec formula) all map. Org adds Batch_No, Damaged_Qty, Dispatched_Qty, Short_Qty, Notes, and a second Product_Ext lookup not in spec. Product lookup targets Product2 rather than a Product__c custom object._

### Must-Sell - Focus Setup (Must_Sell_Focus__c) → Must_Sell_Config__c
- **Scope Level** (Picklist (All-India; State; Outlet Type; Beat; Position; Distributor)) — No scope-targeting selector field exists
- **State** (Picklist (Indian states & UTs)) — No state-scope picklist in org
- **Beat** (Lookup(Beat__c)) — No beat lookup; Territory differs in grain
- **Position Code** (Lookup(Position__c)) — No position/rep lookup present
- **Distributor** (Lookup(Account)) — No distributor/Account lookup exists
- **JC** (Lookup(Journey_Calendar__c)) — No journey calendar period lookup
- **Sequence** (Number(3,0)) — No display-order field; Min_Qty is unrelated

_Org uses Territory_Master__c lookup (Territory__c) for scoping instead of spec's discrete Beat/Position/Distributor/State scope fields plus a Scope Level selector, so the scoping grain differs materially. Product lookup targets Product_Extension__c rather than Product__c but is a valid equivalent. Org adds an extra Min_Qty__c field not in spec. Sell Type maps to Classification__c, Effective From/To to Start_Date__c/End_Date__c, Outlet Type to Customer_Type__c, Is Active and Channel map directly._

### Order (Header) → Sales_Order__c
- **JC** (Lookup(Journey_Calendar__c)) — No journey calendar lookup exists
- **Is Telephonic** (Checkbox) — No telephonic order flag field
- **Is Joint-Work Call** (Checkbox) — No joint-work call checkbox
- **Total Qty (Cases)** (Number(16,2)) — Only pieces/items count; no cases quantity
- **SAP PO No** (Text(50)) — No SAP PO number text field
- **Editable Until** (DateTime) — No same-day edit cut-off field

_Customer/Salesman/Beat/Visit lookups, order type/date, and all value fields (gross, discount, scheme, net, tax, tax-incl via Total_Amount__c) are covered. Salesman is duplicated (Sales_Rep__c and Salesperson__c both User lookups). Order Number treated as covered by standard Name. Two Status picklists (Status__c, Order_Status__c) both satisfy Status; picklist values differ from spec (P1/P2/Secondary/Telephonic; Pending Approval). Org has many extra fields (addresses, credit, warehouse, sync) beyond spec grain._

### P2 Price (SD) / Price_List__c → Price_List__c
- **Price Level** (Picklist (Nation/State)) — No Nation/State price-level picklist
- **Distributor Type** (Picklist (DB-RT;DB-M;...)) — No distributor-type picklist; Price_Type differs
- **State** (Text(80)) — No state text field present
- **MRP** (Currency(16,2)) — No dedicated MRP currency field
- **Margin %** (Percent(7,3)) — No margin percentage field

_Matched: Channel=Channel__c; Product=Product_Ext__c (lookup to Product_Extension__c, not Product__c — different target object); Account=Customer__c (Account lookup); RBP=Unit_Price__c (single generic currency); Valid From/To=Effective_From__c/Effective_To__c. Org uses one Unit_Price__c currency plus Price_Type__c picklist instead of separate MRP/RBP currency fields — different grain, so MRP has no equivalent. Org has extra fields (Category, Region, Territory, Min_Qty, Priority, Status, Is_Active) not in spec._

### Scheme → Scheme__c
- **Eligible Distributor Type** (Multi-Select Picklist) — no distributor-type eligibility field
- **Eligible Distributor** (Lookup(Account)) — no Account/distributor lookup exists
- **Apply on Single Order Only** (Checkbox) — no single-order-only flag present
- **Auto-Stop on Budget** (Checkbox) — no budget auto-stop checkbox
- **Payout Calculation Type** (Picklist) — no Continuous/Slab/Step scaling field

_Key relationship gap: spec's Eligible Distributor -> Account lookup has no org equivalent (org has no Account lookup). Most fields map cleanly (Scheme_Type, Status, Budget_Amount/Used, Priority, Approved_By User lookup, Scheme_Class as customer tier, Applicable_Outlet_Tag as Alpha flag). Eligible State/States map loosely to Region__c/Applicable_Region__c (Company_Hierarchy lookup), which is a region-grain proxy rather than a state list. Constraint Type is spread across Scheme_Type plus Qty/Val threshold fields rather than a single picklist._

### Survey - Form → Survey__c
- **Visit** (Lookup(Visit__c)) — no Visit lookup on org object
- **Account (Outlet/DB)** (Lookup(Account)) — no Account lookup; only Outlet_Type picklist
- **User** (Lookup(User)) — no User lookup relationship
- **Survey Date/Time** (DateTime) — no DateTime; only Effective From/To dates
- **Latitude** (Geolocation) — no geolocation latitude field
- **Longitude** (Geolocation) — no geolocation longitude field

_Org Survey__c is a survey-definition/template (Survey_Code externalId, Effective_From/To, Is_Active, Is_Mandatory, Outlet_Type multipicklist), not the per-instance survey form the spec describes. Matched: Survey Type=Survey_Type__c, Remarks=Description__c. All three spec relationships (Visit, Account, User) and the geolocation/date-time capture fields are absent, indicating a different object grain._

### Survey Response → Survey_Response__c
- **Question** (Lookup(Survey_Question__c)) — No lookup to Survey Question
- **Brand Alias** (Picklist) — No brand-alias picklist present
- **Answer (Text)** (Text Area(255)) — No answer text field
- **Photo Before** (Text(255) File) — No before-photo field
- **Photo After** (Text(255) File) — No after-photo field
- **Visibility Type** (Picklist (Paid; Unpaid)) — No paid/unpaid visibility picklist

_Grain mismatch: spec models one answer per question (per-question child of Survey), but org models a whole-survey scoring record. Org has scoring/status fields (Total_Score, Max_Possible_Score, Score_Percentage, Status, Respondent, Account, Visit, Response_Date) absent from spec. Spec Survey is master-detail; org Survey__c is only a lookup, and org lacks any Survey_Question relationship, so per-answer capture is not implemented._

### Target → Target__c
- **Customer** (Lookup(Account)) — No Account lookup on org object
- **Target Product Level** (Picklist) — No Brand/SubBrand/SKU level picklist
- **JC** (Lookup(Journey_Calendar__c)) — No Journey_Calendar lookup; only Period dates
- **Frequency** (Picklist) — No Monthly/JC/Quarterly/Yearly frequency picklist
- **Full Day Target** (Number(16,2)) — No full-day attendance target field
- **Half Day Target** (Number(16,2)) — No half-day target field
- **KPI** (Lookup(Target_Criteria__c)) — No Target_Criteria KPI lookup exists
- **Auto-Increment %** (Percent(7,3)) — No auto-increment percent field
- **Increment Basis** (Picklist) — No Last JC Target/Actual basis picklist
- **Increment Config Level** (Picklist) — No State/Outlet-Type config-level picklist

_Different grain/design: org uses Salesperson__c and User__c (both User lookups) but no Account/Customer lookup, so P1/P2/outlet customer-level targets cannot be represented. No Journey_Calendar__c relationship; period modeled via Period_Start/End dates and Period_Month/Year, not a JC lookup or frequency. No Target_Criteria__c KPI master lookup; Target_Type__c picklist is a rough substitute but not the modeled relationship. Auto-increment mechanism (percent, basis, config level) entirely absent. Org adds extras not in spec: Achievement_Percent__c, KPI_Weight__c, Status__c, Parent_Target__c, Territory__c._

### Tour Plan (PJP) Header → Journey_Plan__c
- **JC** (Lookup(Journey_Calendar__c)) — No Journey_Calendar lookup; Territory lookup instead
- **Is Repeatable** (Checkbox) — No repeatable-plan checkbox present
- **Frequency (days)** (Picklist (7;14;28)) — No frequency-in-days picklist field
- **Submission Date** (Date) — No plan submission date field
- **Is Active Plan** (Checkbox) — No active-plan boolean; Status has Active value

_User lookup present as Salesperson__c (User__c deprecated dup). Start/End map to Effective_From/To; Status, Approval_Date, Approved_By all present. Missing the JC (Journey_Calendar__c) relationship — org instead has a Territory_Master__c lookup plus Month/Year picklists, indicating a month/territory grain rather than a JC-period grain. No submission-tracking or repeatable/frequency scheduling fields. Active-plan handled via a Status picklist value rather than a dedicated single-active flag._

### Tour Plan Day → Journey_Plan_Day__c
- **Activity Type** (Picklist (Retailing; Official Work; Holiday; Leave; Weekly Off)) — No activity-type picklist; Status is Planned/Completed/Cancelled
- **Territory / District** (Text(80)) — No territory/district field on org object
- **JW User** (Lookup(User)) — No joint-work User lookup present
- **Followed** (Checkbox) — No followed/actual-activity boolean flag

_Master-detail parent (Journey_Plan__c), Plan Date, Day (Day_of_Week__c picklist), Beat lookup, and Reason (Notes__c TextArea) all match by meaning. Org adds extra fields with no spec counterpart: Planned_Outlets__c, Visited_Outlets__c, Sequence__c, Sequence_Order__c, Week_Number__c, Beat_Name__c, Status__c — suggesting the org models plan-vs-actual/sequencing detail the spec lacks. Reason mapped to Notes__c is a loose semantic match. Spec Day is Text(10) but org uses a restricted weekday picklist (acceptable by meaning)._

### Visit → Visit__c
- **Position Code** (Lookup(Position__c)) — No Position lookup exists on org
- **Lines No.** (Number(5,0)) — No unique-lines-cut count field
- **Order Qty (Std Unit)** (Number(16,2)) — No order quantity field (only count/value)
- **check out comments** (Picklist) — No no-sales reason category picklist

_All other spec fields map by meaning: Time Spent->Duration_Minutes__c, Net Value->Order_Value__c, No Order Reason->Non_Productive_Reason__c, Visit Latitude/Longitude->Check_In_Latitude__c/Check_In_Longitude__c, Checked-in In Geofence->Is_Geo_Fenced__c. Grain/relationship differences: spec Day Activity is Master-Detail(Day_Activity__c) but org uses a Lookup Journey_Plan_Day__c (different parent object, not master-detail); org has redundant duplicate lookups (Account__c+Outlet__c to Account, User__c+Salesperson__c to User, Beat__c+Original_Beat__c to Beat)._


## Minor gaps (1-3 missing fields)

### Competitor Activity → Competitor__c
- **RBP** (Currency(16,2)) — only one currency price field exists
- **Schemes Available** (Text(255)) — no scheme text field present

_Most fields map: Visit=Visit__c, Outlet=Account__c, Competitor Name=Competitor_Company__c, Competitor Product=Competitor_SKU__c, MRP=Competitor_Price__c, Photo=Photo_URL__c. Only one currency field exists so MRP maps but RBP has no equivalent. Notes__c is a generic LongTextArea, not a Schemes-Available field. Org adds extra fields not in spec (Product_Category__c, Shelf_Percent__c, Own_Product__c, Activity_Date__c, Is_Active__c, External__c)._

### GRN (Goods Receipt Note) → 
- **Has Return** (Checkbox) — no has-return flag; auto-return trigger unsupported

_GRN Number (Auto Number) treated as the standard Name field (ignored per instructions). Primary Invoice->Invoice__c, Distributor->Account__c, GRN Date->GRN_Date__c, Status->Status__c all match by meaning. Org adds extra line-level quantity fields (Damaged/Excess/Short Qty), Notes, Received_By not in spec — suggests header carries some detail-grain data._

### Game Score → Game_Score__c
- **JC** (Lookup(Journey_Calendar__c)) — No Journey_Calendar reporting-period lookup in org

_9 of 10 spec fields matched. User lookup maps to Salesperson__c (referenceTo User); Date to Score_Date__c. Org adds an extra Employee__c lookup (to Employee__c) with no spec counterpart. Only gap: JC lookup to Journey_Calendar__c is absent._

### Invoice (Header) / Invoice__c → 
- **Invoice Type** (Picklist (Primary; Secondary)) — No Primary/Secondary invoice type picklist
- **Invoice Sub-Type** (Picklist (GST e-Invoice; Normal)) — No sub-type picklist field present
- **ERP Invoice No** (Text(50)) — No dedicated ERP invoice number field

_Most fields align: Invoice Number, Order->Sales_Order__c, Account, Invoice Date, IRN->E_Invoice_IRN__c, Net Value->Net_Amount__c, Tax Value->Tax_Amount__c, Gross Value->Total_Amount__c all present. User and Position both covered by two User lookups (Salesperson__c, Sales_Rep__c). Status__c exists but uses order-lifecycle values (Draft/Confirmed/...), not spec's GRN Done/GRN Not Done values -- meaning-level match but semantic mismatch. External__c is generic text, not a true ERP invoice number. Org has many extra logistics/payment fields beyond spec._

### Invoice Item (Line) → Invoice_Line__c
- **Invoiced Qty (Cases)** (Number(16,2)) — No case-level quantity field exists
- **Invoiced Qty (Pieces)** (Number(16,2)) — No piece-level quantity breakdown field

_Org uses a single Quantity__c (total) rather than the spec's cases/pieces/total breakdown; Invoiced Qty (Total) maps to Quantity__c. Invoice master-detail and Product lookup both present (Product references standard Product2 vs spec Product__c, same meaning). Net Value=Net_Amount__c, Tax Value=Tax_Amount__c, Unit Price/MRP/Batch No/Free Qty all covered. Org additionally has many tax/discount/scheme fields beyond spec._

### Journey Calendar (JC) → Target_Period__c
- **JC Number** (Number(2,0)) — no 1-13 period sequence number
- **Year** (Text(4)) — no calendar year field
- **Working Days** (Number(3,0)) — no working-days count field

_Different grain: org Target_Period__c is a hierarchical target period (Parent_Period__c self-lookup, Type__c picklist Journey Cycle/Monthly/Quarterly/Yearly, Is_Cumulative__c), not a flat 13-period company journey calendar. Spec declares no relationships, but org adds a Parent_Period self-lookup for nested periods. Matched: Start Date=Start_Date__c, End Date=End_Date__c, Is Current JC=Is_Active__c/Is_Default__c, JC Name=standard Name._

### Order Item (Line) → Order_Line_Item__c
- **Scheme Slab** (Lookup(Scheme_Slab__c)) — No Scheme_Slab lookup; only text Scheme_Category

_Master-detail parent is Sales_Order__c, not Order__c (different grain/relationship naming). All other spec fields have org equivalents: Order=Sales_Order__c(MD), Product=Product__c(Product2), Ordered Qty Pieces=Quantity__c, Ordered Qty Cases=Base_Quantity__c, Free/FOC=Free_Quantity__c, MRP=MRP__c, Unit Price=Unit_Price__c, Gross Value=Line_Amount__c/Total_Amount__c, Product Discount=Discount_Amount__c, GST=Tax_Amount__c/CGST/SGST/IGST, Net Value=Net_Amount__c, Is Must Sell=Is_Must_Sell__c, Batch No=Batch_Master__c(lookup rather than text). Spec's Free/FOC is a Yes/No picklist but org models it as a numeric free-qty field._

### P1 Price (SS-DB) → 
- **ZSD1 (DB/SD Margin %)** (Percent(7,3)) — No margin percent field in org
- **ZSD2 (SS Margin %)** (Percent(7,3)) — No second margin percent field
- **Landing Price** (Formula (Currency)) — No computed landing price formula field

_Org Price_List__c is a generic multi-dimensional price list, not the SS/DB margin-cascade grain of the spec. Mapped: Product=Product_Ext__c (lookup Product_Extension__c, not Product__c), Distributor=Customer__c (Account lookup), ZPR0=Unit_Price__c, Valid From/To=Effective_From/To__c, Channel/Distributor Type=Channel__c, Price Level~Price_Type__c (different value sets). Spec State (Text 80) has no free-text equivalent; geography is via Territory__c/Region__c lookups (different grain) so not listed as a hard gap. The margin-based landing-price computation (ZPR0-ZSD1-ZSD2) is entirely absent._

### Position Code → Position__c
- **Level** (Picklist (L1..L10; CFA)) — No hierarchy level picklist; Designation is free text
- **Current User** (Lookup(User)) — No User lookup for current holder
- **Vacant Position** (Checkbox) — No vacant flag; Is_Active is not equivalent

_Parent Position (self-lookup) and Position Code (external id, unique text) are present. Position Name assumed covered by standard Name field. Org adds Role_Developer_Name formula/Designation not in spec. Is_Active tracks active status, semantically distinct from spec's Vacant flag._

### Return (Header) → Return_Order__c
- **Auto-Created from GRN** (Checkbox) — no GRN auto-creation flag field

_8 of 9 spec fields map cleanly: Return Type=Return_Type__c, Source Invoice=Invoice__c, Source Order=Sales_Order__c (spec references Order__c), Customer=Account__c, Return Date=Return_Date__c, Total Return Value=Total_Return_Value__c, Status=Status__c. Return Number maps to standard auto-number Name (ignored). Org adds many extra line/financial fields (Return_Quantity, Net_Amount, Tax_Amount, Credit_Note_Number, etc.), suggesting a flatter/combined header+line grain than the spec header._

### Return Item (Line) → Return_Line__c
- **Return Qty (Pieces)** (Number(16,2)) — only single return-quantity field, no pieces split

_Grain differs on quantity: spec models return qty as two dimensions (Cases + Pieces); org has a single Return_Quantity__c, so only Cases-level is covered. All other spec fields map: Return->Return_Order__c (MasterDetail to Return_Order__c, though parent differs from spec's Return__c), Product->Product__c (Lookup Product2), Reason->Return_Reason__c, Price->Unit_Price__c, Return Value->Net_Amount__c/Line_Total__c. Org also adds tax/discount/batch/expiry/HSN fields beyond spec._

### Scheme Basket Product → Scheme_Basket_Product__c
- **Is Active** (Checkbox) — No active/status checkbox field in org

_4 of 5 spec fields present. Scheme Basket master-detail and Min Qty Number(6,0) match exactly. Product (SKU) lookup is implemented as Product_Ext__c but references Product_Extension__c, not spec's Product__c — same meaning, different target object. Only Is Active checkbox is genuinely missing._

### Scheme Claim → Scheme_Accrual__c
- **No Of Products** (Number(16,2)) — no product-quantity field in org

_Object grain differs: org models accruals (with Invoice/Accrual Date), not claims; Claim__c is a separate object the org looks up to. Matches by meaning: Distributor=Account__c, Scheme=Scheme__c, Claim Amount=Accrued_Amount__c (Number not Currency), Status=Status__c (picklist values differ: Open/Claimed/Settled/Reversed vs Submitted/Approved/Rejected)._

### Scheme Slab - Line → Scheme_Slab__c
- **Slab / Step No** (Number(3,0)) — No slab/step sequence number field
- **Buy Product** (Lookup(Product__c)) — No buy-product lookup; only free-product lookup exists
- **Is Bundle Item** (Checkbox) — No bundle-item flag checkbox
- **Flat Discount on Total** (Currency(16,2)) — No flat-discount-on-total order value field

_Get/Free Product maps to Free_Product_Ext__c but references Product_Extension__c, not Product__c. Order Value From/To map to Min_Value__c/Max_Value__c; Buy Min Qty to Min_Quantity__c. Org adds extra fields (Discount_Amount, Discount_Percent, Price_Discount, Reward_Points, Max_Quantity, Slab_Type) beyond spec. Counted 4 genuine gaps, technically major_gaps._

### Secondary Price (Retailer) → Price_List__c
- **Price Level** (Picklist (Distributor-Type; Outlet-Type; Channel)) — No cascade price-level picklist in org
- **Distributor Type** (Picklist (DB-RT; DB-M; ...)) — No distributor-type picklist in org
- **Outlet Type** (Lookup(Shop_Type__c)) — No Shop_Type outlet lookup in org

_7 of 10 spec fields map: Channel->Channel__c, Account->Customer__c (Account lookup), Product->Product_Ext__c (product lookup, references Product_Extension__c not Product__c), Price->Unit_Price__c, Valid From->Effective_From__c, Valid To->Effective_To__c. Org adds pricing-resolution fields absent from spec (Category, Region, Territory, Min_Qty, Price_Type, Priority, Status, Is_Active), indicating a broader multi-dimensional price-list grain than the spec's simpler retailer-price record. Product lookup targets Product_Extension__c rather than the spec's Product__c._

### Survey Question (Master) → Survey_Question__c
- **Is Active** (Checkbox) — No active/enabled flag on org object

_8 of 9 spec fields covered. Survey (Form) master-detail = Survey__c, Sequence = Sort_Order__c, Question Text = Question_Text__c, Answer Type = Question_Type__c (picklist has Rating instead of Boolean; near-equivalent), Options = Options__c, Brand Alias = Brand_Alias__c, Is Mandatory = Is_Required__c, Name = standard. Only Is Active (active flag) is missing. Org adds Score_Weight__c and Validation_Rule__c beyond spec._


## Aligned (full coverage)

### Batch Master → Batch_Master__c

_All 10 spec fields have org equivalents (Batch Name = standard Name). One relationship discrepancy: spec Product (SKU) targets Product__c, but org Product_Ext__c lookup referenceTo is Product_Extension__c — same meaning, different target object._

### Collection → Collection__c

_All 8 non-standard spec fields have org equivalents: Customer=Account__c (Account lookup), Visit=Visit__c, Invoice=Invoice__c, Amount=Amount__c, Mode of Payment=Payment_Mode__c (picklist superset incl. RTGS/Online), Reference No=Transaction_Reference__c, Description=Notes__c (TextArea), Collection Date=Collection_Date__c. Org adds extra fields (Bank_Name, Cheque_Date, Status, Salesperson, etc.)._

### Game (Battle Ground) → Game__c

_All 5 spec fields have org equivalents: Team Name→Team_Name__c, Start Date→Start_Date__c, End Date→End_Date__c, Is Active→Is_Active__c, Game Name→standard Name (or Game_Code__c). Org additionally has Description__c, Filter_Level__c, Filter_State__c, Type__c beyond spec. Spec declares no relationships; org has none either — grain matches._

### Game KPI - Slab → Game_KPI__c

_All 7 spec fields (excluding standard Name) have org equivalents: Game=Game__c MasterDetail(Game__c), Role=Role__c Picklist, KPI Name=KPI_Name__c, KPI Type=KPI_Type__c Picklist, Slab Number=Slab_Number__c, Cutoff Value=Cutoff_Value__c, Reward Coins=Reward_Coins__c. Master-detail to Game__c present, matching grain. Minor type difference: spec KPI Name is Picklist but org KPI_Name__c is Text (semantic equivalent, not a gap). Org also adds extra fields (Battleground_KPI__c, Category__c, Eligibility_Criteria__c, Is_Continuous__c, Is_Qualifier__c, KPI_Metric__c, Measure__c, Use_Slabs__c) beyond the spec._

### Holiday → 

_All 5 spec fields have org equivalents. Holiday Name -> standard Name; Date -> Holiday_Date__c; Region/Zone -> Applicable_Region__c (org is Text vs spec Picklist North/South/East/West, so allowed values are unconstrained); Type -> Type__c (org picklist adds Restricted/Company values, labels are 'X Holiday'); Branch -> Territory__c, but spec expects a plain Text(80) branch while org models it as a Lookup to Territory_Master__c — grain/relationship differs, and notably spec explicitly says the object has NO lookups/master-detail, yet org introduces one. Extra org fields not in spec: Is_Active__c, Description__c, Year__c._

### Must Sell No Sell → Must_Sell_No_Sale__c

_All spec fields have org equivalents. Order master-detail -> Sales_Order__c; Product lookup -> Product_Ext__c (referenceTo Product_Extension__c); reason picklist -> No_Sale_Reason__c with identical values. Referenced objects differ in name (Sales_Order__c vs Order__c, Product_Extension__c vs Product__c) but match by meaning/grain._

### Product Visibility → Product_Sharing__c

_All 7 spec fields map 1:1 to org fields: Product(SKU)->Product__c, Visibility Level->Visibility_Level__c, Channel->Channel__c, State->State__c, Branch->Branch__c, Distributor->Distributor__c, Is Active->Is_Active__c. Object-level differences: (1) Product__c is a Lookup to standard Product2, not a Master-Detail to a custom Product__c object — relationship type and grain differ (no master-detail). (2) Distributor->Account lookup matches. Minor picklist value drift: Visibility Level uses "National" vs spec "Nation"; Channel uses "E-Commerce" vs spec "Both". Not counted as field gaps._

### Retail Asset → Retail_Asset__c

_All 7 spec fields have org equivalents: Asset Name=standard Name (audit-ignored); Account=Account__c Lookup(Account, label "Outlet"); Serial Number=Serial_Number__c Text(60); Given Date=Given_Date__c Date; Status=Status__c Picklist with exact values Active/Returned/Not Working/Scrap; Asset Present=Asset_Present__c Checkbox; Photo=Photo_URL__c (Url instead of spec's Text(255)File, semantically equivalent photo reference). Account relationship present as required. Org adds two extra fields not in spec: Asset_Type__c (Picklist) and Visit__c (Lookup to Visit__c)._

### Scheme Basket → Scheme_Basket__c

_All 5 spec fields have org equivalents. Basket Name = standard Name field (master object). Basket Code = Basket_Code__c (Text 40, External Id, Unique). Description = Description__c. Channel = Channel__c picklist (org adds a third 'Both' value beyond spec's GT/MT). Is Active = Is_Active__c. No lookups expected or present, consistent with spec._

### Stock Adjustment → Stock_Adjustment__c

_All spec fields have org equivalents: Distributor=Account__c (Lookup Account), Product=Product__c (Lookup Product2, spec expected Product__c), Adjustment Qty (+/-)=Adjustment_Qty__c (Number), Reason=Reason__c (org is TextArea not Picklist — type mismatch but present), Adjustment Type=Adjustment_Type__c (Picklist; values differ: org uses Physical Count/Damage/Expiry Write Off/Correction Add/Correction Deduct vs spec Remove/Add), Adjustment Date=Adjustment_Date__c. Org adds extra fields (Actual_Qty, System_Qty, Batch_Number, Warehouse, Status, approvals, Location_Type). No genuine field gaps._

### Stock Check (Header) → Stock_Check__c

_All spec fields have org equivalents. Visit=Visit__c (MasterDetail→Visit__c), Outlet=Outlet__c (Lookup→Account), Check Date/Time=Check_Date_Time__c (DateTime). Name is standard Auto Number (ignored). Relationships match spec (master-detail to Visit, lookup to Account). Note: org DateTime and Outlet fields are marked required=false vs spec req=Yes, but the field equivalents exist._

### Stock Check Item → Stock_Check_Item__c

_All spec fields have org equivalents. Note: spec Product lookup targets Product__c, but org Product_Ext__c references Product_Extension__c instead — same meaning (product lookup), different target object. Stock Check master-detail matches. Both quantity fields present._

### Target Criteria (KPI) / Target_Criteria__c → 

_All 13 spec fields have org equivalents. Category, Object, Field, Operator, Date Field, User Field, Filters, Filter Logic map directly; Weight %==Incentive_Weight__c; Prerequisite KPI==Prerequisite_Criteria__c (self-lookup, matches); Prerequisite Min %==Prerequisite_Min_Percent__c; Is Active==Active__c. Criteria Name is served by standard Name field (ignored). Org adds an extra field Enable_Customer_Targets__c not in spec. Category and Operator picklist values match exactly._

### Ticket (Help Desk) → Ticket__c

_All 8 spec business fields have org equivalents. Ticket Number → Name field (AutoNumber, label "Ticket Number", displayFormat TKT-{0000}). Raised By (User) → Reported_By__c (User lookup). Raised By (Distributor) → Account__c (Account lookup). Visit → Visit__c lookup. Category/Subject/Description/Status/Created Date all present (Created Date via standard CreatedDate). Org adds extra fields not in spec: Assigned_To__c, Priority__c, Resolution__c, Resolved_Date__c, Ticket_Date__c, External__c, Photo_URL__c. Spec category picklist values differ from org values but field exists._


## Cannot verify from repo

### Account (Customer) → Account (standard)

_No custom-field metadata for this standard object in the repo; the spec fields must be verified directly in the live org._

### Product (SKU) → Product2 (standard)

_No custom-field metadata for this standard object in the repo; the spec fields must be verified directly in the live org._

### User (extended) → User (standard)

_No custom-field metadata for this standard object in the repo; the spec fields must be verified directly in the live org._
