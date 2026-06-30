/*
 * Execute Anonymous — seed the FA Battleground sample KPIs (Battleground_KPI__c).
 * Re-runnable: skips any KPI whose Name already exists. No existing data is changed.
 * Columns per row: Name, Category (Qualifier/Discipline/Coverage/Sales),
 *                  Frequency (Daily/Weekly/Monthly), Measure (Number/Decimal/Percent/Currency/Duration)
 */
List<List<String>> rows = new List<List<String>>{
    new List<String>{'Day Start Time',                          'Qualifier',  'Daily',   'Time'},
    new List<String>{'Daily Target (Rs)',                       'Sales',      'Daily',   'Currency'},
    new List<String>{'Daily Target (StdUnit)',                  'Sales',      'Daily',   'Number'},
    new List<String>{'Total Retail Time',                       'Discipline', 'Daily',   'Duration'},
    new List<String>{'First Call Time',                         'Discipline', 'Daily',   'Time'},
    new List<String>{'First Physical Call Time',                'Discipline', 'Daily',   'Time'},
    new List<String>{'Last Physical Call Time',                 'Discipline', 'Daily',   'Time'},
    new List<String>{'TC',                                      'Coverage',   'Daily',   'Number'},
    new List<String>{'First PC Time',                           'Discipline', 'Daily',   'Time'},
    new List<String>{'Retailing Days',                          'Discipline', 'Monthly', 'Number'},
    new List<String>{'Physical Retail Time',                    'Discipline', 'Daily',   'Duration'},
    new List<String>{'New Outlets to be created Daily',         'Coverage',   'Daily',   'Number'},
    new List<String>{'No. of Distributors Visit (Month)',       'Coverage',   'Monthly', 'Number'},
    new List<String>{'No. of Distributor Search (Month)',       'Coverage',   'Monthly', 'Number'},
    new List<String>{'Monthly New Outlet',                      'Coverage',   'Monthly', 'Number'},
    new List<String>{'Monthly Total Calls',                     'Coverage',   'Monthly', 'Number'},
    new List<String>{'Monthly UTC',                             'Coverage',   'Monthly', 'Number'},
    new List<String>{'UBO',                                     'Coverage',   'Daily',   'Number'},
    new List<String>{'Average Total Calls',                     'Coverage',   'Monthly', 'Decimal'},
    new List<String>{'Focused Outlet Target (Borosil FA Engage)','Coverage',  'Monthly', 'Number'},
    new List<String>{'GPS Billed (%) (OVT Billed)',             'Qualifier',  'Daily',   'Percent'},
    new List<String>{'LPC Must Sell (Borosil)',                 'Sales',      'Daily',   'Number'},
    new List<String>{'Net Value',                               'Sales',      'Daily',   'Currency'},
    new List<String>{'PC',                                      'Coverage',   'Daily',   'Number'},
    new List<String>{'RS By Brand',                             'Sales',      'Daily',   'Currency'},
    new List<String>{'RS By Sub Brand',                         'Sales',      'Daily',   'Currency'},
    new List<String>{'RS by Brand alias',                       'Sales',      'Daily',   'Currency'},
    new List<String>{'RS BY SKU',                               'Sales',      'Daily',   'Currency'},
    new List<String>{'PJP Days follow %',                       'Qualifier',  'Monthly', 'Percent'},
    new List<String>{'Non PJP Days Count',                      'Discipline', 'Monthly', 'Number'},
    new List<String>{'Bundle Scheme Order count',              'Sales',      'Daily',   'Number'},
    new List<String>{'MUST Sell SKU coverage in beat %',        'Coverage',   'Daily',   'Percent'},
    new List<String>{'Joint Working Calls',                     'Discipline', 'Monthly', 'Number'},
    new List<String>{'Qty (Std Unit) per PC',                   'Sales',      'Daily',   'Decimal'},
    new List<String>{'Net Value per PC',                        'Sales',      'Daily',   'Currency'},
    new List<String>{'Physical TC',                             'Coverage',   'Daily',   'Number'},
    new List<String>{'%Productivity',                           'Coverage',   'Daily',   'Percent'},
    new List<String>{'Focus Product Sales (Std Unit)',          'Sales',      'Daily',   'Number'},
    new List<String>{'LPC',                                     'Sales',      'Daily',   'Number'},
    new List<String>{'Monthly Focus Product UPC',               'Sales',      'Monthly', 'Number'},
    new List<String>{'Monthly Productive New Outlet',           'Coverage',   'Monthly', 'Number'},
    new List<String>{'Requested New Outlet',                    'Coverage',   'Daily',   'Number'},
    new List<String>{'Productive New Outlet',                   'Coverage',   'Daily',   'Number'},
    new List<String>{'Monthly PC',                              'Coverage',   'Monthly', 'Number'},
    new List<String>{'Daily Target Amount',                     'Sales',      'Daily',   'Currency'},
    new List<String>{'Total Calls for Month',                   'Coverage',   'Monthly', 'Number'}
};

// Index existing sample KPIs by lower-cased name so a re-run corrects their
// Category / Frequency / Measure instead of creating duplicates.
Map<String, Battleground_KPI__c> existing = new Map<String, Battleground_KPI__c>();
for (Battleground_KPI__c k : [SELECT Id, Name FROM Battleground_KPI__c]) {
    if (k.Name != null) { existing.put(k.Name.toLowerCase(), k); }
}

List<Battleground_KPI__c> toUpsert = new List<Battleground_KPI__c>();
Integer inserted = 0, updated = 0, seq = 0;
for (List<String> r : rows) {
    seq++;
    Battleground_KPI__c k = existing.get(r[0].toLowerCase());
    if (k == null) { k = new Battleground_KPI__c(Name = r[0], Sequence__c = seq); inserted++; }
    else { updated++; }
    k.UI_Name__c      = r[0];
    k.Category__c     = r[1];
    k.Frequency__c    = r[2];
    k.Measure__c      = r[3];
    k.Is_Qualifier__c = (r[1] == 'Qualifier');
    k.Is_Active__c    = true;
    toUpsert.add(k);
}

if (!toUpsert.isEmpty()) {
    upsert toUpsert;
}
System.debug('>>> Battleground KPIs upserted: ' + toUpsert.size() + ' (new: ' + inserted + ', updated: ' + updated + ')');
