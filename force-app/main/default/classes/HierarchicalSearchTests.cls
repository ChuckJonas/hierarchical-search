@isTest
public class HierarchicalSearchTests {
  /* === TESTS FOR RootSearch === */
  @isTest
  private static void rootSearchSimple() {
    List<Account> accounts = createAccountChain(5);

    RootSearch r = new RootSearch(Account.getSObjectType(), Account.ParentId);
    Map<Id, Id> roots = r.search(new Set<Id>{ accounts[4].id });
    System.assertEquals(accounts[0].Id, roots.get(accounts[4].Id));
  }

  @isTest
  private static void rootSearchDifferentRoots() {
    List<Account> group1 = createAccountChain(3);

    List<Account> group2 = createAccountChain(7);

    RootSearch r = new RootSearch(Account.getSObjectType(), Account.ParentId);
    Map<Id, Id> roots = r.search(new Set<Id>{ group1[2].id, group2[6].Id });
    System.assertEquals(group1[0].Id, roots.get(group1[2].id));
    System.assertEquals(group2[0].Id, roots.get(group2[6].Id));
  }

  @isTest
  private static void rootSearchNoParent() {
    Account acc1 = new Account(Name = '1');
    insert acc1;
    Account accA = new Account(Name = 'a');
    insert accA;

    RootSearch r = new RootSearch(Account.getSObjectType(), Account.ParentId);
    Map<Id, Id> roots = r.search(new Set<Id>{ acc1.id, accA.Id });
    System.assertEquals(acc1.Id, roots.get(acc1.Id));
    System.assertEquals(accA.Id, roots.get(accA.Id));
  }

  @isTest
  private static void rootSearchWide() {
    List<Account> accounts = createAccountChain(3);

    List<Account> widen = new List<Account>{
      new Account(Name = '2-2', ParentId = accounts[1].Id),
      new Account(Name = '3-2', ParentId = accounts[2].Id),
      new Account(Name = '3-3', ParentId = accounts[2].Id),
      new Account(Name = '3-4', ParentId = accounts[2].Id)
    };
    insert widen;

    RootSearch r = new RootSearch(Account.getSObjectType(), Account.ParentId);
    Map<Id, Id> roots = r.search(new Map<Id, Account>(widen).keySet());
    for (Account acc : widen) {
      System.assertEquals(accounts[0].Id, roots.get(acc.Id));
    }
  }

  @isTest
  private static void rootSearchDeep() {
    List<Account> accounts = createAccountChain(10);

    RootSearch r = new RootSearch(Account.getSObjectType(), Account.ParentId);
    Map<Id, Id> roots = r.search(new Set<Id>{ accounts[9].id });
    System.assertEquals(accounts[0].Id, roots.get(accounts[9].Id));
  }

  /* === TESTS FOR DescendantSearch === */

  @isTest
  private static void descendantSearchShallowTest() {
    Account acc1 = new Account(Name = '1');
    insert acc1;
    Account acc2 = new Account(Name = '2', ParentId = acc1.Id);
    insert acc2;

    DescendantSearch r = new DescendantSearch(Account.sObjectType, Account.ParentId);
    Map<Id, Id[]> children = r.search(new Set<Id>{ acc1.id });
    System.assert(children.containsKey(acc1.Id));
    System.assertEquals(1, children.get(acc1.Id).size());
    System.assertEquals(acc2.Id, children.get(acc1.Id)[0]);
  }

  @isTest
  private static void descendantSearchDeepTest() {
    List<Account> accounts = createAccountChain(13);

    DescendantSearch r = new DescendantSearch(Account.sObjectType, Account.ParentId);
    Map<Id, Id[]> children = r.search(new Set<Id>{ accounts[0].id });
    System.assert(children.containsKey(accounts[0].Id));
    System.assertEquals(12, children.get(accounts[0].Id).size());

    children = r.search(new Set<Id>{ accounts[2].id });
    System.assert(children.containsKey(accounts[2].Id));
    System.assertEquals(10, children.get(accounts[2].Id).size());

    children = r.search(new Set<Id>{ accounts[9].id });
    System.assert(children.containsKey(accounts[9].Id));
    System.assertEquals(3, children.get(accounts[9].Id).size());

    children = r.search(new Set<Id>{ accounts[12].id });
    System.assert(!children.containsKey(accounts[12].Id));
  }

  @isTest
  private static void descendantSearchNoChildrenTest() {
    Account acc1 = new Account(Name = '1');
    insert acc1;

    DescendantSearch r = new DescendantSearch(Account.sObjectType, Account.ParentId);
    Map<Id, Id[]> children = r.search(new Set<Id>{ acc1.id });
    System.assert(!children.containsKey(acc1.Id));
  }

  /* === TestUtil === */

  /**
   * Creates a list of a given length where each subsequent child is parented to the previous item
   */
  public static List<Account> createAccountChain(Integer num) {
    List<Account> ret = new List<Account>();
    for (integer i = 0; i < num; i++) {
      ret.add(new Account(Name = String.valueOf(i)));
    }
    insert ret;

    Id pId = null;
    for (Account acc : (Account[]) randomize(ret)) {
      acc.ParentId = pId;
      pId = acc.Id;
    }
    update ret;
    return ret;
  }

  public static List<Object> randomize(List<Object> l) {
    Integer currentIndex = l.size();
    while (0 != currentIndex) {
      Integer randomIndex = integer.valueOf(Math.floor(Math.random() * currentIndex));
      currentIndex -= 1;
      Object temporaryValue = l[currentIndex];
      l[currentIndex] = l[randomIndex];
      l[randomIndex] = temporaryValue;
    }
    return l;
  }
}
