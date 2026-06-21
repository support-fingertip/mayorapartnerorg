/**
 * @description Scheduled batch that alerts on schemes expiring in 3 days
 *              (BRD §13 — "Scheme expiry alert to users 3 days before expiry").
 *              Notifies each active scheme's owner via the org's
 *              NotificationDispatchService (in-app + email). Schedule daily, e.g.:
 *              System.schedule('Scheme Expiry Alert', '0 0 7 * * ?',
 *                  new SPM_SchemeExpiryAlert_Batch());
 *
 * @author  SFA Development Team
 * @date    2026
 */
public with sharing class SPM_SchemeExpiryAlert_Batch
        implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date alertDate = Date.today().addDays(3);
        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId, End_Date__c
            FROM Scheme__c
            WHERE Status__c = 'Active' AND End_Date__c = :alertDate
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Scheme__c> scope) {
        for (Scheme__c s : scope) {
            if (s.OwnerId == null) {
                continue;
            }
            String subject = 'Scheme expiring in 3 days: ' + s.Name;
            String body = 'Scheme "' + s.Name + '" expires on '
                + (s.End_Date__c == null ? '' : s.End_Date__c.format())
                + '. Please review before it goes inactive.';
            NotificationDispatchService.notify(new Set<Id>{ s.OwnerId }, s.Id, subject, body);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // no-op
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SPM_SchemeExpiryAlert_Batch(), 100);
    }
}