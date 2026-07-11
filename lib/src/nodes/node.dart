import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:novident_nodes/novident_nodes.dart';

/// Abstract base class representing a node in a hierarchical tree structure.
///
/// This class combines notification capabilities ([NodeNotifier]), visitor pattern
/// support ([NodeVisitor]), and cloning functionality ([ClonableMixin]).
/// It serves as the foundation for all node types in the hierarchy.
abstract class Node extends NodeNotifier
    with NodeVisitor, NodeCollector, ClonableMixin<Node> {
  /// Contains metadata and identification information about this node
  final NodeDetails details;

  /// Provides a link between layers in the rendering composition
  final LayerLink layer;

  Node({
    required this.details,
  }) : layer = LayerLink();

  Node.zero({
    NodeContainer? owner,
  })  : details = NodeDetails.zero(owner),
        layer = LayerLink();

  Node.level({
    NodeContainer? owner,
    int level = 0,
  })  : details = NodeDetails(owner: owner, level: level),
        layer = LayerLink();

  /// Returns the level that should have its children
  int get childrenLevel => level + 1;

  /// Notifies all listeners that this node has changed.
  ///
  /// Should be called whenever the node's state changes in a way that
  /// should trigger updates in dependent systems.
  @mustCallSuper
  void notify({bool propagate = false}) {
    notifyListeners();
    if (propagate) {
      owner?.notify(propagate: propagate);
    }
  }

  /// Find the full depth path of this [Node]
  List<int> findNodePath() {
    if (this.owner == null) return <int>[];
    final int i = index;
    if (i == -2) return <int>[];
    final List<int> path = <int>[i];
    NodeContainer? owner = this.owner;
    while (true) {
      final int? ownerIndex = owner?.index;
      if (ownerIndex == -2 || ownerIndex == null) break;
      owner = owner!.owner;
      path.add(ownerIndex);
      if (owner == null) break;
    }

    return <int>[...path.reversed];
  }

  /// Validates if a node can be moved to a target location in the hierarchy.
  ///
  /// [node]: The node to move.
  /// [target]: The destination node. When [inside] is true, [target] must be
  ///   a [NodeContainer]; when [inside] is false, [target] is the reference
  ///   node for the adjacent position.
  /// [inside]: Whether to move [node] inside [target] (true) or adjacent to
  ///   it (false), placing it in [target]'s owner at the same level.
  /// [insertIndex]: The exact insertion index within the destination container
  ///   (when [inside]=true) or the desired position adjacent to [target]
  ///   (when [inside]=false). When null, appends to the end. The index refers
  ///   to the position *before* [node] is removed from its current owner.
  /// [isSwapMove]: When true, bypasses the direct-ancestor re-insertion check
  ///   (used when two nodes swap positions within the same owner).
  /// [maxDepthLevel]: Optional absolute depth limit. Nodes cannot be placed
  ///   deeper than this level (1-indexed, where 0 is root).
  static bool canMoveTo({
    required Node node,
    required Node target,
    bool inside = true,
    int? insertIndex,
    @Deprecated(
      'isSwapMove is not a required parameter now. It is not used and will be removed in future releases',
    )
    bool isSwapMove = false,
    int? maxDepthLevel,
  }) {
    // 1. Self-move prevention
    if (node.id == target.id) return false;

    // 2. insertIndex bounds
    if (insertIndex != null && insertIndex < 0) return false;

    // 3. Target must have an owner when positioning adjacent (inside=false)
    //    since we need to insert into target.owner's children list.
    if (!inside && target.owner == null) return false;

    // 4. Circular reference: prevent moving a container into its own subtree.
    //    Guard: only containers can be ancestors, and target needs an owner
    //    chain for jumpToParent to traverse safely.
    if (node is NodeContainer) {
      final bool isOwnDescendant =
          target.jumpToParent(stopAt: (Node p) => p.id == node.id).id ==
              node.id;
      if (isOwnDescendant) return false;
    }

    // 5. Direct ancestor: prevent re-inserting a node into its current parent
    //    when inside=true (it's already there). Allow when a real position
    //    change is requested via insertIndex, or when isSwapMove is set.
    final bool isAncestor = node.owner?.id == target.id;
    if (isAncestor && inside && !isSwapMove) {
      // If no explicit index or the index doesn't change position → block.
      if (insertIndex == null) return false;
      // Mirror moveTo logic: removal shrinks length by 1, then >= length = append.
      final int nodeIdx = node.index;
      final int newLen = (target as NodeContainer).length - 1;
      final int landPos =
          insertIndex >= newLen ? newLen : insertIndex;
      if (landPos == nodeIdx) return false;
    }

    // 6. Type validation: when inside=true, target must be a container.
    if (inside && target is! NodeContainer) return false;

    // 7. No-op detection: prevents moves that would leave the node in the
    //    same effective position after accounting for removal-then-insertion.
    //    The logic mirrors Node.moveTo: after node.unlink() shrinks the list
    //    by 1, an insertIndex >= newLength is treated as append.
    if (!isSwapMove) {
      final int nodeIndex = node.index;
      final bool sameOwner = node.owner?.id == target.owner?.id;

      if (inside && target is NodeContainer && target.id == node.owner?.id) {
        // Moving within the same owner.
        final int newLen = target.length - 1; // after removal
        if (insertIndex == null) {
          // Appending: the new last position is newLen.
          if (newLen == nodeIndex) return false;
        } else {
          // If insertIndex >= newLen, moveTo treats it as append.
          final int landPos = insertIndex >= newLen ? newLen : insertIndex;
          if (landPos == nodeIndex) return false;
        }
      }

      if (!inside && sameOwner) {
        final int targetIndex = target.index;
        if (targetIndex == nodeIndex) return false; // same position
        if (insertIndex != null) {
          // Direction-aware: compute landing position after removal.
          final int newLen = (node.owner as NodeContainer).length - 1;
          final int landPos = insertIndex >= newLen ? newLen : insertIndex;
          if (landPos == nodeIndex) return false;
        } else {
          // Without explicit index, conservatively block if already adjacent
          if (nodeIndex + 1 == targetIndex) return false;
          if (targetIndex + 1 == nodeIndex) return false;
        }
      }
    }

    // 8. Depth limit: the moved node lands at target.level + 1 when
    //    inside=true. Check that the resulting depth doesn't exceed the cap.
    if (maxDepthLevel != null && inside) {
      if (target.level + 1 > maxDepthLevel) return false;
    }

    return true;
  }

  /// Ensures that every children of this [Node]
  /// will have the correct level assigned
  ///
  /// [level] property of this [Node] must be assigned or
  /// updated before calling this method to ensure the proper
  /// expected output value
  static void redepthDescendants(
    NodeContainer container, {
    bool shouldNotify = true,
    bool propagate = true,
  }) {
    for (int i = 0; i < container.children.length; i++) {
      final Node child = container.children[i];
      final Node reDepthed = child.clone();
      container.updateAt(
        i,
        reDepthed,
        shouldNotify: false,
        propagateNotifications: false,
      );
      if (reDepthed is NodeContainer && reDepthed.isNotEmpty) {
        redepthDescendants(
          container.elementAt(
            i,
          ) as NodeContainer,
        );
      }
    }
    if (shouldNotify) {
      container.notify(propagate: propagate);
    }
  }

  /// Move the [Node] passed to a new parent.
  static bool moveTo({
    required Node node,
    required NodeContainer newOwner,
    int? index,
    bool shouldNotify = true,
    bool propagate = true,
  }) {
    if (index != null && index < 0) return false;
    // it just exists for events
    final Node exactClone = node.clone();
    final NodeContainer? oldOwner = node.owner;
    final bool removed = node.owner == null ? true : node.unlink();
    if (!removed) {
      throw StateError(
        'The node founded at $index '
        'couldn\'t be removed in ${node.runtimeType}:${node.id}',
      );
    }
    index == null || (index >= newOwner.length || index < 0)
        ? newOwner.add(node, shouldNotify: false)
        : newOwner.insert(index, node, shouldNotify: false);
    final int storedIndex =
        (index != null && index >= 0 && index < newOwner.length)
            ? index
            : newOwner.length - 1;
    final Node storedNode = newOwner.elementAt(storedIndex);
    if (storedNode is NodeContainer) {
      storedNode.redepthDescendants(shouldNotify: false);
    }
    final NodeMoveChange change = NodeMoveChange(
      to: newOwner,
      from: oldOwner,
      index: index ?? newOwner.length - 1,
      newState: storedNode,
      oldState: exactClone,
    );
    oldOwner?.onChange(change);
    newOwner.onChange(change);
    if (shouldNotify) {
      newOwner.notify(propagate: propagate);
      oldOwner?.notify(propagate: propagate);
    }
    return true;
  }

  /// Moves this [Node] vertically based on [`down`] property.
  ///
  /// If this [Node] does not have a owner, then won't execute the move.
  ///
  /// - [down]: determines if the node will be moved to down or up of the current position
  /// - [allowMoveOutsideOfOwner]: determines if the Node is the first child of its parent, the Node will be moved to be upside of its parent
  ///
  /// Example:
  ///
  /// ```
  /// NodeContainer (root)
  /// |
  /// ├── NodeContainer 1
  /// |
  /// ├── (will be moved here) <─────────────────────────────────┐
  /// |                                                          |
  /// └── NodeContainer 2                                        |
  ///     |                                                      |
  ///     ├── LeafNode 1 ─── when [allowMoveToAncestor] is true ─┘
  ///     |         (moves to owner's ancestor)
  ///     └── LeafNode 2
  /// ```
  void verticalMove({
    bool allowMoveToAncestor = true,
    bool down = false,
  }) {
    if (owner == null) return;
    final int nodeIndex = index;
    final bool needMoveOutside =
        down ? nodeIndex + 1 >= owner!.length : nodeIndex == 0;
    if (!allowMoveToAncestor && needMoveOutside) {
      return;
    }
    if (needMoveOutside) {
      // we get the owner of the current owner
      final NodeContainer? upperOwner = owner!.owner;
      if (upperOwner != null) {
        final int ownerIndex = owner!.index;
        int effectiveNextIndex = 0;
        if (down) {
          effectiveNextIndex = (ownerIndex + 1) >= upperOwner.length
              ? upperOwner.length
              : ownerIndex + 1;
        } else {
          effectiveNextIndex = (ownerIndex - 1) < 0 ? 0 : ownerIndex - 1;
        }
        owner?.moveNode(
          this,
          upperOwner,
          insertIndex: effectiveNextIndex,
        );
      }
      return;
    }
    owner!.moveNode(
      this,
      owner!,
      insertIndex: !down ? nodeIndex - 1 : nodeIndex + 1,
    );
  }

  /// Returns the index of this node within its parent list.
  ///
  /// If there's no owner attached, then it returns -2 when the owner is not defined.
  int get index => owner == null
      ? -2
      : (owner as NodeContainer).indexWhere(
          (Node node) => node.id == id,
        );

  /// Unlink this [Node] from its parent list
  @mustCallSuper
  bool unlink({
    int? path,
    bool shouldNotify = false,
    bool propagateNotify = false,
    bool notifyParticularChange = false,
  }) {
    if (owner != null) {
      final int effectiveIndex = path ?? index;
      if (effectiveIndex <= -1) {
        return false;
      }
      final Node node = owner!.elementAt(effectiveIndex);
      if (node.id == id) {
        owner!.children.removeAt(effectiveIndex);
        details.owner = null;
        if (notifyParticularChange) {
          owner!.onChange(
            NodeDeletion(
              originalPosition: effectiveIndex + 1,
              inNode: owner!.clone(),
              sourceOwner: owner!.jumpToParent().clone(),
              newState: this,
              oldState: copyWith(
                details: details.copyWith(owner: owner),
              ),
            ),
          );
        }
        if (shouldNotify) {
          notify(propagate: propagateNotify);
        }
        return true;
      }
      int oldLength = owner!.length;
      // Probably, at this point, we have an outdated index
      // path, and we need to remove manually the Node
      // from its owner
      owner!.children.removeWhere((Node n) => n.id == id);
      // verify if the node was removed successfully
      // from the owner
      if (oldLength != owner!.length) {
        details.owner = null;
        if (shouldNotify) {
          notify(propagate: propagateNotify);
        }
        return true;
      }
    }
    return false;
  }

  /// Return the next [Node] if has [owner] and if this
  /// [Node] is not at the end of the [List]
  @mustCallSuper
  Node? get nextSibling {
    final int efIndex = index;
    return owner == null
        ? null
        : efIndex + 1 >= owner!.children.length
            ? null
            : owner?.children[efIndex + 1];
  }

  /// Return the previous [Node] if has [owner] and if this
  /// [Node] is not the first element of the [List]
  @mustCallSuper
  Node? get previousSibling {
    final int efIndex = index;
    return owner == null
        ? null
        : efIndex == 0
            ? null
            : owner?.children[efIndex - 1];
  }

  /// Return if this node has a node in front
  bool get hasNextSibling => nextSibling != null;

  /// Return if this node has a node behind
  bool get hasPreviousSibling => previousSibling != null;

  /// Traverses up the parent hierarchy until reaching a stopping condition.
  ///
  /// - [stopAt]: Optional predicate that determines when to stop ascending. If returns true, stops at current node.
  ///
  /// Returns the highest parent node that satisfies the conditions,
  /// or this node if no parent exists or stop condition is met.
  NodeContainer jumpToParent({bool Function(Node node)? stopAt}) {
    if (owner == null || (stopAt?.call(this) ?? false)) {
      return this as NodeContainer;
    }
    return owner!.jumpToParent(stopAt: stopAt);
  }

  /// Unique identifier for this node.
  ///
  /// Derived from [details.id].
  String get id => details.id;

  /// Depth level of this node in the hierarchy (0 = root).
  ///
  /// Derived from [details.level].
  int get level => details.level;

  /// Whether this node is at the root level (level == 0).
  bool get isAtRootLevel => level == 0;

  /// The owning node of this node (alias for [parent]).
  ///
  /// Derived from [details.owner].
  NodeContainer? get owner => details.owner;

  /// Sets the owning node of this node.
  ///
  /// Only updates if the new owner is different from current.
  /// Automatically notifies listeners of the change.
  set owner(NodeContainer? node) {
    if (details.owner == node) return;
    details.owner = node;
    notify();
  }

  /// Creates a copy of this node with optional overrides.
  ///
  /// - [details]: Optional new [NodeDetails] to use
  @mustBeOverridden
  Node copyWith({NodeDetails? details});

  /// Creates a copy of this node but changing the level by the
  /// given passed.
  ///
  /// Usually used when a [Node] is inserted or moved into the Nodes Tree.
  Node cloneWithNewLevel(int level, {bool deep = true});

  /// Equality comparison between nodes.
  ///
  /// Implementing classes should compare all relevant properties.
  @override
  @mustBeOverridden
  bool operator ==(Object other);

  /// Generates a hash code based on the node's properties.
  ///
  /// Should be consistent with [operator ==].
  @override
  @mustBeOverridden
  int get hashCode;

  /// Returns a string representation of this node.
  ///
  /// Shows the node's details in a readable format.
  @override
  String toString() {
    return '$runtimeType(details: $details)';
  }

  /// Serializes this node to a JSON-compatible map.
  ///
  /// Implementing classes should include all relevant properties.
  Map<String, dynamic> toJson();

  @override
  Iterable<Node> collectNodes({
    required Predicate shouldGetNode,
    bool deep = false,
  }) =>
      shouldGetNode(this) ? <Node>[this] : <Node>[];

  @override
  Node? visitAllNodes({required Predicate shouldGetNode}) =>
      shouldGetNode(this) ? this : null;

  @override
  Node? visitNode({required Predicate shouldGetNode}) =>
      shouldGetNode(this) ? this : null;

  @override
  int countAllNodes({required Predicate countNode}) => countNode(this) ? 1 : 0;

  @override
  int countNodes({required Predicate countNode}) => countNode(this) ? 1 : 0;

  @override
  bool exist(String nodeId) => id == nodeId ? true : false;

  @override
  bool deepExist(String nodeId) => exist(nodeId);
}
