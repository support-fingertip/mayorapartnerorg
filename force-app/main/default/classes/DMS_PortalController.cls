/**
 * @description Distributor portal / oversight API (Experience Cloud + internal).
 *
 *              DUAL-MODE access:
 *              - **Portal / community users** are strictly scoped to their own
 *                distributor Account (resolved via Contact.AccountId). They can
 *                never see or write another distributor's records.
 *              - **Internal / admin users** (standard Salesforce users) see ALL
 *                distributors' data (governed by their normal record access), so
 *                staff can oversee every distributor from the same screens.
 *
 *              Runs `with sharing`; portal scoping is additionally enforced in the
 *              query as defense-in-depth. Gated by the DMS master + portal toggles.
 * @author  SFA Development Team
 * @date    2024
 */
public with sharing class DMS_PortalController {

    /** Test hook: set a context account without a community user (forces scoped mode). */
    @TestVisible
    private static Id testAccountIdOverride;

    // ── Context & guards ──────────────────────────────────────────────────

    private static Boolean isInternalUser() {
        return UserInfo.getUserType() == 'Standard';
    }

    /**
     * @description The account to scope to: null = internal/admin (see ALL data);
     *              otherwise the portal user's own Account (scoped). Throws only
     *              when a portal user has no linked distributor account.
     */
    @TestVisible
    private static Id scopeAccountId() {
        if (testAccountIdOverride != null) {
            return testAccountIdOverride;
        }
        if (isInternalUser()) {
            return null; // internal/admin → all distributors
        }
        List<User> users = [
            SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];
        Id accountId = (users.isEmpty() || users[0].Contact == null)
            ? null : users[0].Contact.AccountId;
        if (accountId == null) {
            throw new AuraHandledException('No distributor account is linked to this user.');
        }
        return accountId;
    }

    /** For write actions that require a specific distributor context. */
    private static Id requireAccountId() {
        Id a = scopeAccountId();
        if (a == null) {
            throw new AuraHandledException(
                'No distributor context. Create these records from the internal DMS app on behalf of a specific distributor.');
        }
        return a;
    }

    private static void ensureEnabled() {
        if (!BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_MASTER) ||
            !BPM_FeatureToggle_Util.isEnabled(DMS_Constants.TOGGLE_PORTAL)) {
            throw new AuraHandledException('The distributor portal is not enabled.');
        }
    }

    private static Decimal nz(Decimal v) { return v == null ? 0 : v; }

    // ── Dashboard ─────────────────────────────────────────────────────────

    public class Dashboard {
        @AuraEnabled public Decimal outstanding;
        @AuraEnabled public Decimal creditLimit;
        @AuraEnabled public Decimal creditAvailable;
        @AuraEnabled public Decimal onHandUnits;
        @AuraEnabled public Integer openIndents;
        @AuraEnabled public Integer nearExpiryBatches;
    }

    @AuraEnabled(cacheable=true)
    public static Dashboard getDashboard() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        Dashboard d = new Dashboard();

        if (acctId == null) {
            // Internal/admin: org-wide across all distributors.
            for (AggregateResult ar : [
                SELECT SUM(Outstanding_Balance__c) o, SUM(Credit_Limit__c) c
                FROM Account WHERE Type = 'Distributor'
            ]) {
                d.outstanding = nz((Decimal) ar.get('o'));
                d.creditLimit = nz((Decimal) ar.get('c'));
            }
            for (AggregateResult ar : [
                SELECT SUM(Closing_Stock__c) total FROM Distributor_Stock__c WHERE Is_Current__c = true
            ]) {
                d.onHandUnits = nz((Decimal) ar.get('total'));
            }
            d.openIndents = [
                SELECT COUNT() FROM Indent__c WHERE Status__c IN ('Draft', 'Submitted', 'Approved')
            ];
            d.nearExpiryBatches = [
                SELECT COUNT() FROM Distributor_Stock__c
                WHERE Is_Current__c = true AND Closing_Stock__c > 0
                  AND Expiry_Date__c != null AND Expiry_Date__c <= :Date.today().addDays(30)
            ];
            d.creditAvailable = d.creditLimit - d.outstanding;
            return d;
        }

        // Portal user: scoped to own account.
        Account acct = [SELECT Outstanding_Balance__c, Credit_Limit__c FROM Account WHERE Id = :acctId];
        d.outstanding = nz(acct.Outstanding_Balance__c);
        d.creditLimit = nz(acct.Credit_Limit__c);
        d.creditAvailable = d.creditLimit - d.outstanding;
        for (AggregateResult ar : [
            SELECT SUM(Closing_Stock__c) total FROM Distributor_Stock__c
            WHERE Account__c = :acctId AND Is_Current__c = true
        ]) {
            d.onHandUnits = nz((Decimal) ar.get('total'));
        }
        d.openIndents = [
            SELECT COUNT() FROM Indent__c
            WHERE Account__c = :acctId AND Status__c IN ('Draft', 'Submitted', 'Approved')
        ];
        d.nearExpiryBatches = [
            SELECT COUNT() FROM Distributor_Stock__c
            WHERE Account__c = :acctId AND Is_Current__c = true AND Closing_Stock__c > 0
              AND Expiry_Date__c != null AND Expiry_Date__c <= :Date.today().addDays(30)
        ];
        return d;
    }

    // ── Read screens (account filter applied only for portal users) ────────

    @AuraEnabled(cacheable=true)
    public static List<Distributor_Stock__c> getInventory() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        String q = 'SELECT Id, Account__r.Name, Product_Ext__r.Name, Batch_No__c, Closing_Stock__c, Expiry_Date__c '
            + 'FROM Distributor_Stock__c WHERE Is_Current__c = true AND Closing_Stock__c > 0';
        if (acctId != null) { q += ' AND Account__c = :acctId'; }
        q += ' ORDER BY Expiry_Date__c ASC NULLS LAST LIMIT 2000';
        return Database.query(q);
    }

    @AuraEnabled(cacheable=true)
    public static List<Indent__c> getIndents() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        String q = 'SELECT Id, Name, Account__r.Name, Indent_Date__c, Status__c, Total_Amount__c, '
            + 'Requested_Delivery_Date__c FROM Indent__c';
        if (acctId != null) { q += ' WHERE Account__c = :acctId'; }
        q += ' ORDER BY Indent_Date__c DESC LIMIT 2000';
        return Database.query(q);
    }

    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoices() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        String q = 'SELECT Id, Invoice_Number__c, Account__r.Name, Invoice_Date__c, Order_Type__c, '
            + 'Total_Amount__c, Balance_Due__c, Status__c FROM Invoice__c';
        if (acctId != null) { q += ' WHERE (Account__c = :acctId OR Sold_From_Distributor__c = :acctId)'; }
        q += ' ORDER BY Invoice_Date__c DESC LIMIT 2000';
        return Database.query(q);
    }

    @AuraEnabled(cacheable=true)
    public static List<Ledger_Entry__c> getLedger() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        String q = 'SELECT Id, Account__r.Name, Entry_Date__c, Entry_Type__c, Amount__c, '
            + 'Reference_Number__c, Description__c FROM Ledger_Entry__c';
        if (acctId != null) { q += ' WHERE Account__c = :acctId'; }
        q += ' ORDER BY Entry_Date__c DESC LIMIT 2000';
        return Database.query(q);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getAging() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        return acctId == null ? DMS_Ledger_Service.getAgingAll() : DMS_Ledger_Service.getAging(acctId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Claim__c> getClaims() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        String q = 'SELECT Id, Name, Account__r.Name, Claim_Type__c, Claim_Date__c, Total_Amount__c, '
            + 'Approved_Amount__c, Status__c, Credit_Note_Number__c FROM Claim__c';
        if (acctId != null) { q += ' WHERE Account__c = :acctId'; }
        q += ' ORDER BY Claim_Date__c DESC LIMIT 2000';
        return Database.query(q);
    }

    @AuraEnabled(cacheable=true)
    public static List<Ticket__c> getTickets() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        String q = 'SELECT Id, Account__r.Name, Subject__c, Category__c, Priority__c, Status__c, '
            + 'Ticket_Date__c FROM Ticket__c';
        if (acctId != null) { q += ' WHERE Account__c = :acctId'; }
        q += ' ORDER BY Ticket_Date__c DESC LIMIT 2000';
        return Database.query(q);
    }

    // ── Self-service actions (require a specific distributor context) ──────

    public class IndentLineInput {
        @AuraEnabled public Id productId;
        @AuraEnabled public Decimal quantity;
    }

    @AuraEnabled
    public static Id placeIndent(List<IndentLineInput> lines) {
        ensureEnabled();
        Id acctId = requireAccountId();
        if (lines == null || lines.isEmpty()) {
            throw new AuraHandledException('At least one product line is required.');
        }
        Indent__c indent = new Indent__c(
            Account__c = acctId,
            Indent_Date__c = Date.today(),
            Status__c = DMS_Constants.INDENT_DRAFT,
            Notes__c = 'Placed via distributor portal'
        );
        insert indent;

        List<Indent_Line__c> indentLines = new List<Indent_Line__c>();
        for (IndentLineInput li : lines) {
            if (li.productId == null || li.quantity == null || li.quantity <= 0) {
                continue;
            }
            indentLines.add(new Indent_Line__c(
                Indent__c = indent.Id,
                Product_Ext__c = li.productId,
                Requested_Qty__c = li.quantity
            ));
        }
        if (indentLines.isEmpty()) {
            throw new AuraHandledException('No valid product lines provided.');
        }
        insert indentLines;
        return indent.Id;
    }

    @AuraEnabled
    public static Id submitClaim(String claimType, Decimal amount, String notes) {
        ensureEnabled();
        Id acctId = requireAccountId();
        Claim__c claim = new Claim__c(
            Account__c = acctId,
            Claim_Type__c = String.isNotBlank(claimType) ? claimType : 'Other',
            Claim_Date__c = Date.today(),
            Total_Amount__c = amount,
            Notes__c = notes,
            Status__c = 'Submitted'
        );
        insert claim;
        return claim.Id;
    }

    @AuraEnabled
    public static Id raiseTicket(String subject, String description, String category, String priority) {
        ensureEnabled();
        Id acctId = requireAccountId();
        Ticket__c ticket = new Ticket__c(
            Account__c = acctId,
            Subject__c = subject,
            Description__c = description,
            Category__c = category,
            Priority__c = String.isNotBlank(priority) ? priority : 'Medium',
            Status__c = 'Open',
            Ticket_Date__c = Date.today()
        );
        insert ticket;
        return ticket.Id;
    }

    // ── Secondary sale (distributor → retailer) ───────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<Account> getRetailers() {
        ensureEnabled();
        Id acctId = scopeAccountId();
        if (acctId == null) {
            // Internal/admin: all retailers.
            return [
                SELECT Id, Name, BillingCity, Outstanding_Balance__c
                FROM Account WHERE Type = 'Retailer' AND Is_Active__c = true
                ORDER BY Name LIMIT 500
            ];
        }
        Id territoryId = [SELECT Territory__c FROM Account WHERE Id = :acctId].Territory__c;
        if (territoryId != null) {
            return [
                SELECT Id, Name, BillingCity, Outstanding_Balance__c
                FROM Account
                WHERE Type = 'Retailer' AND Is_Active__c = true AND Territory__c = :territoryId
                ORDER BY Name LIMIT 200
            ];
        }
        return [
            SELECT Id, Name, BillingCity, Outstanding_Balance__c
            FROM Account WHERE Type = 'Retailer' AND Is_Active__c = true
            ORDER BY Name LIMIT 200
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Product_Extension__c> getProducts() {
        ensureEnabled();
        return [
            SELECT Id, Name, SKU_Code__c, Unit_Price__c, GST_Rate__c
            FROM Product_Extension__c
            WHERE Is_Active__c = true
            ORDER BY Name
            LIMIT 500
        ];
    }

    /**
     * @description Places a secondary sale (FEFO) from the running distributor's
     *              own stock to one of their retailers. Distributor = context
     *              account; never accepts a distributor id from the client.
     */
    @AuraEnabled
    public static Id placeSecondarySale(Id retailerId, List<IndentLineInput> lines) {
        ensureEnabled();
        Id distributorId = requireAccountId();
        if (retailerId == null || lines == null || lines.isEmpty()) {
            throw new AuraHandledException('Select a retailer and at least one product.');
        }
        List<DMS_SecondaryBilling_Service.LineRequest> reqs =
            new List<DMS_SecondaryBilling_Service.LineRequest>();
        for (IndentLineInput li : lines) {
            if (li.productId != null && li.quantity != null && li.quantity > 0) {
                // Unit price null → service falls back to product master price.
                reqs.add(new DMS_SecondaryBilling_Service.LineRequest(li.productId, li.quantity, null));
            }
        }
        if (reqs.isEmpty()) {
            throw new AuraHandledException('No valid product lines.');
        }
        try {
            return DMS_SecondaryBilling_Service.createSecondaryInvoice(distributorId, retailerId, reqs);
        } catch (DMS_SecondaryBillingException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ── Home dashboard (primary + secondary summary) ──────────────────────

    public class BrandStat {
        @AuraEnabled public String brand;
        @AuraEnabled public Decimal value;
        @AuraEnabled public Integer pct;
    }
    public class SchemeBanner {
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public String category;
    }
    public class HomeSummary {
        @AuraEnabled public Decimal purchased = 0;
        @AuraEnabled public Integer pendingOrders = 0;
        @AuraEnabled public Integer pendingGRN = 0;
        @AuraEnabled public Integer returnsCount = 0;
        @AuraEnabled public Integer claimsCount = 0;
        @AuraEnabled public List<BrandStat> brandStock = new List<BrandStat>();
        @AuraEnabled public Integer secondaryOrders = 0;
        @AuraEnabled public Integer secondaryPendingOrders = 0;
        @AuraEnabled public Integer secondaryReturns = 0;
        @AuraEnabled public Decimal collectionValue = 0;
        @AuraEnabled public Integer activeCustomers = 0;
        @AuraEnabled public List<BrandStat> brandSecondarySales = new List<BrandStat>();
        @AuraEnabled public List<SchemeBanner> schemes = new List<SchemeBanner>();
    }

    @AuraEnabled(cacheable=true)
    public static HomeSummary getHomeSummary(String period) {
        ensureEnabled();
        Id acctId = scopeAccountId();
        Date startDate = periodStart(period);
        String otPrimary = DMS_Constants.ORDER_TYPE_PRIMARY;
        String otSecondary = DMS_Constants.ORDER_TYPE_SECONDARY;
        String rtSecondary = DMS_Constants.RETURN_TYPE_SECONDARY;
        List<String> openStatuses = new List<String>{ 'Draft', 'Submitted', 'Approved' };
        Date nearCut = Date.today().addDays(30);

        HomeSummary s = new HomeSummary();

        // Primary purchased.
        String w = 'Order_Type__c = :otPrimary AND Invoice_Date__c >= :startDate'
            + (acctId == null ? '' : ' AND Account__c = :acctId');
        for (AggregateResult ar : Database.query('SELECT SUM(Total_Amount__c) t FROM Invoice__c WHERE ' + w)) {
            s.purchased = nz((Decimal) ar.get('t'));
        }

        s.pendingOrders = Database.countQuery('SELECT COUNT() FROM Indent__c WHERE Status__c IN :openStatuses'
            + (acctId == null ? '' : ' AND Account__c = :acctId'));
        s.pendingGRN = Database.countQuery('SELECT COUNT() FROM GRN__c WHERE Status__c IN (\'Pending\',\'Partial\')'
            + (acctId == null ? '' : ' AND Account__c = :acctId'));
        s.returnsCount = Database.countQuery('SELECT COUNT() FROM Return_Order__c'
            + (acctId == null ? '' : ' WHERE (Account__c = :acctId OR Returned_To_Distributor__c = :acctId)'));
        s.claimsCount = Database.countQuery('SELECT COUNT() FROM Claim__c'
            + (acctId == null ? '' : ' WHERE Account__c = :acctId'));

        // Brand-wise stock (current snapshots).
        String bw = 'Is_Current__c = true AND Closing_Stock__c > 0 AND Product_Ext__r.Brand__c != null'
            + (acctId == null ? '' : ' AND Account__c = :acctId');
        s.brandStock = toBrandStats(Database.query(
            'SELECT Product_Ext__r.Brand__c b, SUM(Closing_Stock__c) v FROM Distributor_Stock__c WHERE '
            + bw + ' GROUP BY Product_Ext__r.Brand__c ORDER BY SUM(Closing_Stock__c) DESC'), 'v');

        // Secondary metrics.
        String sw = 'Order_Type__c = :otSecondary AND Invoice_Date__c >= :startDate'
            + (acctId == null ? '' : ' AND Sold_From_Distributor__c = :acctId');
        s.secondaryOrders = Database.countQuery('SELECT COUNT() FROM Invoice__c WHERE ' + sw);
        s.secondaryPendingOrders = Database.countQuery(
            'SELECT COUNT() FROM Invoice__c WHERE Order_Type__c = :otSecondary AND Status__c = \'Draft\''
            + (acctId == null ? '' : ' AND Sold_From_Distributor__c = :acctId'));
        s.secondaryReturns = Database.countQuery('SELECT COUNT() FROM Return_Order__c WHERE Return_Type__c = :rtSecondary'
            + (acctId == null ? '' : ' AND Returned_To_Distributor__c = :acctId'));

        for (AggregateResult ar : Database.query(
            'SELECT SUM(Amount__c) t FROM Collection__c WHERE Collection_Date__c >= :startDate'
            + (acctId == null ? '' : ' AND Account__c = :acctId'))) {
            s.collectionValue = nz((Decimal) ar.get('t'));
        }
        for (AggregateResult ar : Database.query(
            'SELECT COUNT_DISTINCT(Account__c) c FROM Invoice__c WHERE Order_Type__c = :otSecondary'
            + (acctId == null ? '' : ' AND Sold_From_Distributor__c = :acctId'))) {
            s.activeCustomers = (Integer) ar.get('c');
        }

        // Brand-wise secondary sales value.
        String bsw = 'Invoice__r.Order_Type__c = :otSecondary AND Invoice__r.Invoice_Date__c >= :startDate '
            + 'AND Product_Ext__r.Brand__c != null'
            + (acctId == null ? '' : ' AND Invoice__r.Sold_From_Distributor__c = :acctId');
        s.brandSecondarySales = toBrandStats(Database.query(
            'SELECT Product_Ext__r.Brand__c b, SUM(Total_Amount__c) v FROM Invoice_Line__c WHERE '
            + bsw + ' GROUP BY Product_Ext__r.Brand__c ORDER BY SUM(Total_Amount__c) DESC'), 'v');

        // Active schemes for the hero banner.
        for (Scheme__c sch : [
            SELECT Name, Description__c, Scheme_Category__c FROM Scheme__c
            WHERE Is_Active__c = true ORDER BY Start_Date__c DESC LIMIT 5
        ]) {
            SchemeBanner b = new SchemeBanner();
            b.name = sch.Name;
            b.description = sch.Description__c;
            b.category = sch.Scheme_Category__c;
            s.schemes.add(b);
        }
        return s;
    }

    private static List<BrandStat> toBrandStats(List<AggregateResult> rows, String valAlias) {
        List<BrandStat> stats = new List<BrandStat>();
        Decimal maxVal = 0;
        for (AggregateResult ar : rows) {
            Decimal v = nz((Decimal) ar.get(valAlias));
            if (v > maxVal) { maxVal = v; }
        }
        for (AggregateResult ar : rows) {
            BrandStat bs = new BrandStat();
            bs.brand = (String) ar.get('b');
            bs.value = nz((Decimal) ar.get(valAlias));
            bs.pct = (maxVal > 0) ? (Integer) ((bs.value / maxVal) * 100).round() : 0;
            stats.add(bs);
        }
        return stats;
    }

    private static Date periodStart(String period) {
        Date today = Date.today();
        if (period == 'THIS_WEEK') { return today.toStartOfWeek(); }
        if (period == 'LAST_WEEK') { return today.toStartOfWeek().addDays(-7); }
        if (period == 'THIS_QUARTER') {
            Integer q = (today.month() - 1) / 3;
            return Date.newInstance(today.year(), q * 3 + 1, 1);
        }
        if (period == 'THIS_YEAR') { return Date.newInstance(today.year(), 1, 1); }
        if (period == 'LAST_JC') { return today.toStartOfMonth().addMonths(-1); }
        return today.toStartOfMonth(); // THIS_JC default
    }
}