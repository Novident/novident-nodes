part of 'node_change.dart';

/// Represents an insertion operation of a node into a tree structure.
///
/// This change type is used when a new node is added to the tree,
/// either by creating a brand new node or by inserting an existing node
/// into a new position in the tree.
///
/// Extends [NodeChange] to provide specific insertion-related properties.
class NodeInsertion extends NodeChange {
  /// The destination index into the owner
  final int index;

  /// The node that was inserted into the tree.
  ///
  /// This represents the actual node instance that was added.
  final Node to;

  /// The original location of the node before insertion, if applicable.
  ///
  /// If null, indicates that this was a newly created node rather than
  /// a moved node. If not null, represents the node's previous location
  /// or state before being inserted in its new position.
  final Node? from;

  /// Creates a [NodeInsertion] instance representing a node addition.
  ///
  /// [to]: The node that was inserted (required)
  /// [from]: The original node location (required, but can be null for new nodes)
  /// [newState]: The new state of the tree after insertion (required)
  /// [oldState]: The state of the tree before insertion (optional)
  NodeInsertion({
    required this.to,
    required this.from,
    required this.index,
    required super.newState,
    super.oldState,
  });

  @override
  bool operator ==(Object other) {
    if (other is! NodeInsertion) return false;
    return newState == other.newState &&
        oldState == other.oldState &&
        to == other.to &&
        from == other.from &&
        index == other.index;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
        <Object?>[
          index,
          to,
          from,
          newState,
          oldState,
        ],
      );

  @override
  String toString() {
    return 'NodeInsertion('
        'from (direct owner): $from, '
        'to (direct owner): $to, '
        ')';
  }
}
