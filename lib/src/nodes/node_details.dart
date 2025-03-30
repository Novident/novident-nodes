import 'package:flutter/foundation.dart';
import 'package:novident_nodes/novident_nodes.dart';
import 'package:novident_nodes/src/utils/id_generator.dart';

/// Represents a node within a tree structure, containing identification details
/// and enabling tree operations.
class NodeDetails implements ClonableMixin<NodeDetails> {
  /// Unique identifier for this node
  final String id;

  /// Depth level of this node within the tree (0 = root)
  final int level;

  /// Optional value associated with this node
  final Object? value;

  /// Private reference to the owning/parent node
  Node? _owner;

  /// Main constructor for creating a [NodeDetails] instance.
  ///
  /// [level]: The depth level of this node in the tree (required)
  /// [value]: Optional value to associate with this node
  /// [owner]: Optional parent/owning node reference
  ///
  /// Automatically generates a unique ID using [IdGenerator]
  NodeDetails({
    required this.level,
    this.value,
    Node? owner,
  })  : _owner = owner,
        id = IdGenerator.gen();

  /// Testing constructor that allows specifying all properties directly.
  ///
  /// This should only be used for testing purposes.
  /// [level]: The depth level of this node
  /// [id]: Explicit ID to use (rather than generating one)
  /// [value]: Optional associated value
  /// [owner]: Optional parent node reference
  @visibleForTesting
  NodeDetails.testing({
    required this.level,
    required this.id,
    this.value,
    Node? owner,
  }) : _owner = owner;

  /// Alternative constructor that accepts an explicit ID.
  ///
  /// [level]: The depth level of this node (required)
  /// [id]: Explicit ID to use (required)
  /// [value]: Optional associated value
  /// [owner]: Optional parent node reference
  NodeDetails.byId({
    required this.level,
    required this.id,
    this.value,
    Node? owner,
  }) : _owner = owner;

  /// Returns true if this node has no owner/parent
  bool get hasNotOwner => !hasOwner;

  /// Returns true if this node has an owner/parent
  bool get hasOwner => owner != null;

  /// Gets the owner/parent node of this node
  Node? get owner => _owner;

  /// Sets the owner/parent node of this node.
  /// Only updates if the new owner is different from current.
  set owner(Node? node) {
    if (_owner == node) return;
    _owner = node;
  }

  /// Creates a clone of this node with a modified level.
  ///
  /// [level]: New level to use (defaults to 0 if not specified)
  /// Returns a new [NodeDetails] instance with updated level
  NodeDetails cloneWithNewLevel([int? level]) {
    level ??= 0;
    return copyWith(level: level);
  }

  /// Creates a copy of this node with optional overrides.
  ///
  /// [level]: Optional new level value
  /// [id]: Optional new ID
  /// [owner]: Optional new owner reference
  /// [value]: Optional new associated value
  /// Returns a new [NodeDetails] instance with specified overrides
  NodeDetails copyWith({int? level, String? id, Node? owner, Object? value}) {
    return NodeDetails.byId(
      level: level ?? this.level,
      id: id ?? this.id,
      value: value ?? this.value,
      owner: owner ?? this.owner,
    );
  }

  /// Factory constructor for creating from JSON data.
  ///
  /// [json]: Map containing serialized node data
  /// Returns a new [NodeDetails] instance reconstructed from JSON
  factory NodeDetails.fromJson(Map<String, dynamic> json) {
    return NodeDetails.byId(
      level: json['level'] as int,
      value: json['value'] as Object?,
      id: json['id'] as String,
      owner: json['owner'] as Node?,
    );
  }

  /// Serializes this node to a JSON-compatible map.
  ///
  /// Returns a [Map] containing all node properties
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'level': level,
      'id': id,
      'owner': owner?.toJson(),
      'value': value,
    };
  }

  /// Factory constructor for creating a base-level node.
  ///
  /// [id]: Optional explicit ID (generates one if not provided)
  /// [owner]: Optional owner reference
  /// Returns a new root-level (level 0) [NodeDetails] instance
  factory NodeDetails.base([String? id, Node? owner]) {
    return NodeDetails.byId(
      level: 0,
      id: id ?? IdGenerator.gen(version: 4),
      owner: owner,
    );
  }

  /// Factory constructor for creating a node at specified level.
  ///
  /// [level]: Optional level value (defaults to 0)
  /// [owner]: Optional owner reference
  /// Returns a new [NodeDetails] instance at specified level
  factory NodeDetails.withLevel([int? level, Node? owner]) {
    level ??= 0;
    return NodeDetails.byId(
      level: level,
      id: IdGenerator.gen(version: 4),
      owner: owner,
    );
  }

  /// Factory constructor for creating a zero-level node.
  ///
  /// [owner]: Optional owner reference
  /// Returns a new root-level (level 0) [NodeDetails] instance
  factory NodeDetails.zero([Node? owner]) {
    return NodeDetails.byId(
      level: 0,
      id: IdGenerator.gen(version: 4),
      owner: owner,
    );
  }

  /// Returns a string representation of this node.
  ///
  /// Shows truncated ID (first 4 chars), level, value, and owner
  @override
  String toString() {
    return 'Level: $level, '
        'ID: ${id.substring(0, id.length < 4 ? id.length : 4)}, '
        'value: $value, '
        'Owner: $owner';
  }

  /// Generates a hash code based on node properties.
  @override
  int get hashCode =>
      level.hashCode ^ value.hashCode ^ owner.hashCode ^ id.hashCode;

  /// Equality comparison with another node.
  ///
  /// Nodes are considered equal if all their properties match.
  @override
  bool operator ==(covariant NodeDetails other) {
    if (identical(this, other)) return true;
    return level == other.level &&
        id == other.id &&
        owner == other.owner &&
        value == other.value;
  }

  /// Creates an exact copy of this node.
  ///
  /// Implements the [ClonableMixin] interface.
  /// Returns a new [NodeDetails] instance with identical properties
  @override
  NodeDetails clone() {
    return NodeDetails.byId(
      level: level,
      value: value,
      owner: owner,
      id: id,
    );
  }
}
