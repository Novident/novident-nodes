import 'package:meta/meta.dart';
import 'package:novident_nodes/novident_nodes.dart';

part 'node_insertion.dart';
part 'node_move.dart';
part 'node_update.dart';
part 'node_deletion.dart';
part 'node_clear.dart';

/// Abstract base class representing a change operation performed on a [Node].
///
/// This class serves as the foundation for all node modification operations
/// in the tree structure, providing common properties and serving as a
/// polymorphic type for all specific change types (insertion, move, update,
/// deletion).
///
/// All concrete change types should extend this class and implement their
/// specific behavior.
abstract class NodeChange {
  /// Creates a [NodeChange] instance.
  ///
  /// [newState]: The node state after the change (required)
  /// [oldState]: The node state before the change (optional, not available for insertions)
  NodeChange({
    required this.newState,
    this.oldState,
  });

  /// The state of the node before the change was applied.
  ///
  /// This may be null for certain operations like node insertion where
  /// there was no previous state.
  final Node? oldState;

  /// The state of the node after the change was applied.
  ///
  /// This always represents the current state of the node following
  /// the operation.
  final Node newState;

  @override
  @mustBeOverridden
  bool operator ==(Object other);

  @override
  @mustBeOverridden
  int get hashCode;

  @mustBeOverridden
  @override
  String toString();
}
