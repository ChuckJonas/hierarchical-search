# Hierarchical Search

Allows working with an "hierarchical" SObject relationships (Lookup or Master-detail that references the same SObject type. EG: `Account.Parent`).

Works for any `SObject`.

## Functionality

- Find the "root" or highest ancestor
- Find ALL children

## Install

```bash
git clone git@github.com:ChuckJonas/hierarchical-search.git
sfdx force:source:convert -d dist
sfdx force:mdapi:deploy -d dist
```

## Usage

```java
//example function that sets the "primary" on an Account to it's root
void updatePrimaryAccount(Account child){
  RootSearch r = new RootSearch(Account.getSObjectType(), Account.ParentId);
  Map<Id, Id> roots = r.search(new Set<Id>{ child.Id });
  child.Primary_Account__c = roots.get(child.Id);
}
```

### Find the Root of any record

```java
//example function gets all children under and account
Id[] getAccountChildrenIds(Account parent){
  DescendantSearch r = new DescendantSearch(Account.getSObjectType(), Account.ParentId);
  Map<Id, List<Id>> children = r.search(new Set<Id, List<Id>>{ parent.Id });
  return children.get(parent.Id);
}

```

See unit tests for more examples.

## Performance

This code has been optimized to limit the number of SOQL queries and is capable of traversing "deep" trees. It for a depth of `N`, it should return in `CEIL(N/6)` SOQL queries.

## License

MIT
