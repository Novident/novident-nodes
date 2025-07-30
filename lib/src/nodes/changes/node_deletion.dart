part of 'node_change.dart';

/// Represents a node deletion operation within a tree structure.
///
/// This class captures all relevant information about a node deletion,
/// including the node's original position, its location in the tree,
/// and the states before and after the deletion.
///
/// Extends [NodeChange] to provide deletion-specific information
/// while maintaining the common change tracking interface.
class NodeDeletion extends NodeChange {
  /// The original index position of the node before deletion.
  ///
  /// This value represents where the node was located in its parent's
  /// children list prior to being deleted.
  final int originalPosition;

  /// The nearest parent node to the root that contained the deleted node.
  ///
  /// This represents the highest-level owner of the deleted node in the
  /// tree hierarchy, which may be different from the immediate parent
  /// in certain tree structures.
  final Node sourceOwner;

  /// The immediate parent node that contained the deleted node.
  ///
  /// This is the direct owner of the deleted node in the tree structure.
  final Node inNode;

  /// Creates a [NodeDeletion] instance representing a node deletion operation.
  ///
  /// [originalPosition]: The index position of the node before deletion (required)
  /// [inNode]: The immediate parent node that contained the deleted node (required)
  /// [sourceOwner]: The highest-level owner node nearest to the root (required)
  /// [newState]: The state of the tree after deletion (required)
  /// [oldState]: The state of the node before deletion (optional)
  NodeDeletion({
    required this.originalPosition,
    required this.inNode,
    required this.sourceOwner,
    required super.newState,
    super.oldState,
  });

  @override
  bool operator ==(Object other) {
    if (other is! NodeDeletion) return false;
    return newState == other.newState &&
        oldState == other.oldState &&
        originalPosition == other.originalPosition &&
        inNode == other.inNode &&
        sourceOwner == other.sourceOwner;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
        <Object?>[
          originalPosition,
          inNode,
          sourceOwner,
          newState,
          oldState,
        ],
      );

  @override
  String toString() {
    return 'NodeDeletion('
        'originalPosition: $originalPosition, '
        'into: $inNode, '
        'oldState (direct owner): $oldState, '
        'newState (direct owner): $newState, '
        'sourceOwner: $sourceOwner, '
        ')';
  }
}
