# Hierarchical Search

Allows working with an "hierarchical" SObject relationships (Lookup or Master-detail that references the same SObject type. EG: `Account.Parent`).

## Functionality

- Find the "root" (AKA highest parent)
- Find ALL children
- Works for any `SObject`

## Install

```bash
git clone git@github.com:ChuckJonas/hierarchical-search.git
sfdx force:source:convert -d dist
sfdx force:mdapi:deploy -d dist -u your-user
```

## Usage

### Find the root of a record(s)

```java
RootSearch r = new RootSearch(Account.getSObjectType(), Account.ParentId);
Map<Id, Id> roots = r.search(new Set<Id>{ child.Id });
System.debug('The Root of this account is ' + roots.get(child.Id));
```

### Find the children of a record(s)

```java
DescendantSearch r = new DescendantSearch(Account.getSObjectType(), Account.ParentId);
Map<Id, List<Id>> children = r.search(new Set<Id, List<Id>>{ parent.Id });
System.debug('This Account has ' + children.get(parent.Id).size() + ' children');
```

### "Ultimate Parent"

A common use case for this type of thing is to create an ["Ultimate Parent Lookup"](https://trailblazers.salesforce.com/answers?id=90630000000ChkPAAS) on an Account:

- Realtime (trigger) (TODO: Add Example)
- near-realtime (trigger + @future) (TODO: Add Example)
- [Scheduled Batch Job](https://github.com/ChuckJonas/hierarchical-search/blob/master/examples/UltimateParentBatch.cls)

Depending on your requirements, you might use a combination of these approaches.

## Performance

This code has been optimized to limit the number of SOQL queries and is capable of traversing "deep" trees. It for a depth of `N`, it should return in `CEIL(N/6)` SOQL queries.

## License

MIT
