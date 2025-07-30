part of 'node_change.dart';

/// Represents an update operation performed on an existing [Node].
///
/// This change type is used when modifications are made to a node's properties
/// or contents while keeping the node in the same position within the tree.
/// It captures both the previous state (before update) and the new state
/// (after update) of the node.
///
/// Example cases:
/// - Changing a node's value
/// - Modifying a node's metadata
/// - Updating a node's internal state
class NodeUpdate extends NodeChange {
  /// Creates a [NodeUpdate] instance representing a node modification.
  ///
  /// [newState]: The node state after the update (required)
  /// [oldState]: The node state before the update (optional but typically provided)
  NodeUpdate({
    required super.newState,
    super.oldState,
  });

  @override
  bool operator ==(Object other) {
    if (other is! NodeUpdate) return false;
    return newState == other.newState && oldState == other.oldState;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
        <Object?>[
          newState,
          oldState,
        ],
      );

  @override
  String toString() {
    return 'NodeUpdate('
        'OldState: $oldState, '
        'newState: $newState, '
        ')';
  }
}
