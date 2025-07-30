part of 'node_change.dart';

/// Represents a move operation of a node within a tree structure.
///
/// This change type captures when a node is relocated from one position
/// to another in the tree hierarchy. It tracks both the source and destination
/// of the move operation.
///
/// Extends [NodeChange] to provide specific move-related properties.
class NodeMoveChange extends NodeChange {
  /// The destination index into the owner
  final int index;

  /// The destination node where the moved node was placed.
  ///
  /// Represents the new parent or position in the tree structure.
  final Node to;

  /// The original node location before the move operation.
  ///
  /// If null, indicates this was actually a newly created node rather than
  /// a moved node. This can happen when a move operation is recorded
  /// for a node that was just created.
  final Node? from;

  /// Creates a [NodeMoveChange] instance representing a node relocation.
  ///
  /// [to]: The destination node where the node was moved (required)
  /// [from]: The original node location before moving (required, can be null for new nodes)
  /// [newState]: The tree state after the move operation (required)
  /// [oldState]: The tree state before the move operation (optional)
  NodeMoveChange({
    required this.index,
    required this.to,
    required this.from,
    required super.newState,
    super.oldState,
  });

  @override
  bool operator ==(Object other) {
    if (other is! NodeMoveChange) return false;
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
    return 'NodeMove('
        'from (direct owner): $from, '
        'to (direct owner): $to, '
        'toIndex: $index, '
        ')';
  }
}
