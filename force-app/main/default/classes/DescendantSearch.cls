/**
 * Author: charlie@callaway.cloud
 *  Class to find all "Descendant" or children under a "hierarchical" relationship
 *  (lookup or master detail pointing to the same object)
 */
public class DescendantSearch {
  SObjectType sobType;
  SObjectField relationship;
  String query;

  /**
   * Constructor
   * @param sobType The SObject Type to search on
   * @param parentField The Master-Detail or Lookup relationship to traverse
   */
  public DescendantSearch(SObjectType sobType, SObjectField relationship) {
    this.relationship = relationship;
    this.sobType = sobType;
    query = generateQuery();
  }

  /**
   * Given a set of ID, it will return a Map<Id,Id> where the Key is the ID passed in,
   *  and the Value a list of children Ids
   * @param ids the Set of records to find children of
   */
  public Map<Id, Id[]> search(Set<Id> parentIds) {
    Map<Id, Id[]> trunkLeafMap = new Map<Id, Id[]>();

    //initialize hierarchical lookup
    Map<Id, TrunkReference> leafTrunkMap = new Map<Id, TrunkReference>();
    for (Id pId : parentIds) {
      leafTrunkMap.put(pId, new TrunkReference(pId, 0));
    }

    Account[] children = Database.query(query);

    // leaf id -> trunk id
    Map<Id, Id> potentialLeafMap = new Map<Id, Id>();
    for (SObject child : children) {
      TrunkReference tr = getTrunkReference(child, 1, leafTrunkMap);
      Id trunkId = tr.trunkId;

      if (tr.depth == 6) {
        // matched at deepest depth, there MAY still be children at deeper depths
        potentialLeafMap.put(child.Id, trunkId);
      }

      leafTrunkMap.put(child.Id, tr);

      if (trunkLeafMap.containsKey(trunkId)) {
        trunkLeafMap.get(trunkId).add(child.Id);
      } else {
        trunkLeafMap.put(trunkId, new List<Id>{ child.Id });
      }
    }

    //recurse if needed
    if (potentialLeafMap.size() > 0) {
      Set<Id> potentialLeafKeyset = potentialLeafMap.keySet();
      Map<Id, Id[]> deepLeafs = search(potentialLeafKeyset);
      for (Id potentialLeaf : potentialLeafKeyset) {
        Id trunkId = potentialLeafMap.get(potentialLeaf);
        if (deepLeafs.containsKey(potentialLeaf)) {
          trunkLeafMap.get(trunkId).addAll(deepLeafs.get(potentialLeaf));
        }
      }
    }
    return trunkLeafMap;
  }

  public TrunkReference getTrunkReference(SObject sob, Integer depth, Map<Id, TrunkReference> cachedLeafTrunks) {
    Id parentId = (Id) sob.get(relationship);
    TrunkReference td = cachedLeafTrunks.get(parentId);
    if (td != null) {
      return new TrunkReference(td.trunkId, td.depth + depth);
    }
    return getTrunkReference(sob.getSObject(relationship), ++depth, cachedLeafTrunks);
  }

  /**
   * Example
      SELECT
        ParentId,
        Parent.ParentId,
        Parent.Parent.ParentId,
        Parent.Parent.Parent.ParentId,
        Parent.Parent.Parent.Parent.ParentId,
        Parent.Parent.Parent.Parent.Parent.ParentId
      FROM Account
      WHERE
        ParentId IN :parentIds
        OR Parent.ParentId IN :parentIds
        OR Parent.Parent.ParentId IN :parentIds
        OR Parent.Parent.Parent.ParentId IN :parentIds
        OR Parent.Parent.Parent.Parent.ParentId IN :parentIds
        OR Parent.Parent.Parent.Parent.Parent.ParentId IN :parentIds
      ORDER BY
        Parent.Parent.Parent.Parent.Parent.ParentId NULLS LAST,
        Parent.Parent.Parent.Parent.ParentId NULLS LAST,
        Parent.Parent.Parent.ParentId NULLS LAST,
        Parent.Parent.ParentId NULLS LAST,
        Parent.ParentId NULLS LAST,
        ParentId NULLS LAST
   */
  private String generateQuery() {
    String[] selectList = HierarchicalSearchUtil.generateMaxTraverseFields(relationship);
    Integer fieldSize = selectList.size();

    String[] whereList = new List<String>{};
    String[] orderList = new List<String>(fieldSize);
    for (Integer i = 0; i < fieldSize; i++) {
      String field = selectList[i];
      whereList.add(field + ' IN :parentIds ');
      orderList[fieldSize - 1 - i] = field + ' NULLS LAST';
    }

    String sObjectName = sobType.getDescribe().getName();

    return String.format(
      'SELECT {0} \n FROM {1} \n WHERE \n {2} \n ORDER BY {3}',
      new List<String>{
        String.join(selectList, ',\n'),
        sObjectName,
        String.join(whereList, '\nOR '),
        String.join(orderList, ',\n')
      }
    );
  }

  //inner classed use to hold Trunk information
  class TrunkReference {
    Id trunkId;
    Integer depth;
    public TrunkReference(Id trunkId, Integer depth) {
      this.trunkId = trunkId;
      this.depth = depth;
    }
  }
}
