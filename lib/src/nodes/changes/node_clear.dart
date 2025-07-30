part of 'node_change.dart';

/// Represents a node deletion operation within a tree structure.
///
/// This class captures all relevant information about a node deletion,
/// including the node's original position, its location in the tree,
/// and the states before and after the deletion.
///
/// Extends [NodeChange] to provide deletion-specific information
/// while maintaining the common change tracking interface.
class NodeClear extends NodeChange {
  NodeClear({
    required super.newState,
    super.oldState,
  });

  @override
  bool operator ==(Object other) {
    if (other is! NodeClear) return false;
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
    return 'NodeClear('
        'from: ${(oldState as NodeContainer?)?.length}, '
        'to: ${(newState as NodeContainer).length}'
        ')';
  }
}
