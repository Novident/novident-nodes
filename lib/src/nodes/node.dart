import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';
import 'package:novident_nodes/novident_nodes.dart';

/// Abstract base class representing a node in a hierarchical tree structure.
///
/// This class combines notification capabilities ([NodeNotifier]), visitor pattern
/// support ([NodeVisitor]), and cloning functionality ([ClonableMixin]).
/// It serves as the foundation for all node types in the hierarchy.
abstract class Node extends NodeNotifier with NodeVisitor, ClonableMixin<Node> {
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

  /// Notifies all listeners that this node has changed.
  ///
  /// Should be called whenever the node's state changes in a way that
  /// should trigger updates in dependent systems.
  void notify({bool propagate = false}) {
    notifyListeners();
    if (propagate) {
      owner?.notify(propagate: propagate);
    }
  }

  /// Returns the index of this node within its parent list.
  ///
  /// Returns -1 when the owner is not defined.
  @mustCallSuper
  int get index => owner == null
      ? -1
      : (owner as NodeContainer).indexWhere(
          (Node node) => node.id == id,
        );

  /// Traverses up the parent hierarchy until reaching a stopping condition.
  ///
  /// [stopAt]: Optional predicate that determines when to stop ascending.
  ///           If returns true, stops at current node.
  ///
  /// Returns the highest parent node that satisfies the conditions,
  /// or this node if no parent exists or stop condition is met.
  @mustCallSuper
  Node? jumpToParent({bool Function(Node node)? stopAt}) {
    if (owner == null || (stopAt?.call(this) ?? false)) {
      return this;
    }
    return owner!.jumpToParent();
  }

  /// Unique identifier for this node.
  ///
  /// Derived from [details.id].
  @mustCallSuper
  String get id => details.id;

  /// Depth level of this node in the hierarchy (0 = root).
  ///
  /// Derived from [details.level].
  @mustCallSuper
  int get level => details.level;

  /// Whether this node is at the root level (level == 0).
  bool get atRoot => level == 0;

  /// The owning node of this node (alias for [parent]).
  ///
  /// Derived from [details.owner].
  @mustCallSuper
  Node? get owner => details.owner;

  /// Sets the owning node of this node.
  ///
  /// Only updates if the new owner is different from current.
  /// Automatically notifies listeners of the change.
  set owner(Node? node) {
    if (node is! NodeContainer) return;
    if (details.owner == node) return;
    details.owner = node;
    notify();
  }

  /// Creates a copy of this node with optional overrides.
  ///
  /// [details]: Optional new [NodeDetails] to use
  /// Returns a new node instance with the specified modifications
  @mustBeOverridden
  Node copyWith({NodeDetails? details});

  /// Creates a copy of this node but changing the level by the
  /// given passed.
  ///
  /// Usually used when a [Node] is inserted or moved into the Nodes Tree.
  @mustBeOverridden
  Node cloneWithNewLevel(int level);

  /// Equality comparison between nodes.
  ///
  /// Implementing classes should compare all relevant properties.
  @override
  @mustBeOverridden
  bool operator ==(covariant Node other);

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
    return 'Node(details: $details)';
  }

  /// Serializes this node to a JSON-compatible map.
  ///
  /// Implementing classes should include all relevant properties.
  Map<String, dynamic> toJson();
}
