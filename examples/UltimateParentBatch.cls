/**
 * Author: Charlie@callaway.cloud
 * Batch to set Ultimate_Parent__c
 */
global class UltimateParentBatch implements Database.Batchable<sObject> {
  global Database.QueryLocator start(Database.BatchableContext BC) {
    // all accounts which do not have parents
    return Database.getQueryLocator([SELECT Id FROM Account WHERE ParentId = NULL]);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    Map<Id, Account> parentAccounts = new Map<Id, Account>((List<Account>) scope);

    DescendantSearch ds = new DescendantSearch(Account.getSObjectType(), Account.ParentId);
    Map<Id, Id[]> children = ds.search(parentAccounts.keySet());
    Account[] childrenToUpdate = new List<Account>{};
    for (Id parentId : children.keySet()) {
      for (Id childId : children.get(parentId)) {
        childrenToUpdate.add(new Account(Id = childId, Ultimate_Parent__c = parentId));
      }
    }
    update childrenToUpdate;
  }

  global void finish(Database.BatchableContext BC) {
  }
}
