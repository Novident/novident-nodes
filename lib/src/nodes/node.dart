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
      final int ownerIndex = owner?.index ?? -2;
      if (ownerIndex == -2) break;
      owner = owner!.owner;
      path.add(ownerIndex);
      if (owner == null) break;
    }

    return <int>[...path.reversed];
  }

  /// Validates if a node can be moved to a target location in the hierarchy by checking these rules:
  ///
  /// Self-move prevention
  ///
  ///  * Blocks moving a node to itself (node == target)
  ///
  /// Container constraints
  ///
  ///  * Prevents moving containers into their own descendants
  ///  * Requires target to be a NodeContainer (when inside=true)
  ///
  /// Ownership validation
  ///
  ///  * Rejects moves to parentless targets
  ///  * Blocks redundant moves (when already a child of target)
  ///
  /// Hierarchy integrity
  ///
  ///  Blocks moves that would:
  ///
  ///   * Create circular references
  ///   * Violate parent-child relationships (inside = true blocks ancestor moves)
  ///   * Exceed optional depth limits (maxDepthLevel)
  static bool canMoveTo({
    required Node node,
    required Node target,
    bool inside = true,
    bool isSwapMove = false,
    int? maxDepthLevel,
  }) {
    // 1. Basic invalid cases
    if (node.id == target.id) return false; // Can't move to self

    // 2. Prevent moving a container into its own descendants
    if (node is NodeContainer) {
      final bool isOwnDescendant =
          target.jumpToParent(stopAt: (Node p) => p.id == node.id).id ==
              node.id;

      if (isOwnDescendant) return false;
    }

    // 3. Check if target is a direct ancestor of the node
    final bool isAncestor = node.owner?.id == target.id;

    // Is the descendant node is trying to move into its ancestor
    //
    // When [isSwapMove] is true, means that we are swapping the positions
    // between two nodes into a same node owner (so, we don't need to
    // make this check)
    if (isAncestor && inside && !isSwapMove) {
      // Already a direct child of target
      return false;
    }

    // 4. Type-specific validation
    if (inside && target is! NodeContainer) {
      // Can only move to containers (unless special cases apply)
      return false;
    }

    // 5. Level validation (optional - if you have hierarchy depth limits)
    if (maxDepthLevel != null && inside) {
      if (target.level >= maxDepthLevel) {
        // Prevent moving too deep in the hierarchy
        return false;
      }
    }
    return true;
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
    final Node exactClone = node.clone();
    final NodeContainer? oldOwner = node.owner;
    node.unlink();
    index == null || (index >= newOwner.length || index < 0)
        ? newOwner.add(node, shouldNotify: false)
        : newOwner.insert(index, node, shouldNotify: false);
    final NodeMoveChange change = NodeMoveChange(
      to: newOwner,
      from: oldOwner,
      index: index ?? newOwner.length,
      newState: node.cloneWithNewLevel(newOwner.childrenLevel),
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
  /// |   |
  /// |   └── LeafNode 1 (will be moved here) <──────────────────┐
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
  @Deprecated('atRoot is no longer used and '
      'will be removed in future releases. Use '
      'isAtRootLevel instead.')
  bool get atRoot => level == 0;

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
  Iterable<Node> collectNodes(
          {required Predicate shouldGetNode, bool deep = false}) =>
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
