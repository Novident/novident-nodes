import 'package:novident_nodes/novident_nodes.dart';

class FileNode extends Node {
  final String name;
  final String content;

  FileNode({
    required super.details,
    required this.content,
    required this.name,
  });

  @override
  FileNode copyWith({
    NodeDetails? details,
    String? name,
    String? content,
  }) {
    return FileNode(
      details: details ?? this.details,
      content: content ?? this.content,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! FileNode) {
      return false;
    }
    return details == other.details &&
        content == other.content &&
        name == other.name;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
        <Object?>[
          details,
          content,
          name,
        ],
      );

  @override
  String toString() {
    return 'FileNode(name: $name, depth: $level)';
  }

  @override
  FileNode clone() {
    return FileNode(
      details: details,
      content: content,
      name: name,
    );
  }

  @override
  int countAllNodes({required Predicate countNode}) {
    return countNode(this) ? 1 : 0;
  }

  @override
  int countNodes({required Predicate countNode}) {
    return countNode(this) ? 1 : 0;
  }

  @override
  bool deepExist(String id) {
    return this.id == id;
  }

  @override
  bool exist(String id) {
    return this.id == id;
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'details': details.toJson(),
      'content': content,
    };
  }

  @override
  Node? visitAllNodes({required Predicate shouldGetNode}) {
    return shouldGetNode(this) ? this : null;
  }

  @override
  FileNode? visitNode({required Predicate shouldGetNode}) {
    return shouldGetNode(this) ? this : null;
  }

  @override
  FileNode cloneWithNewLevel(int level) {
    return copyWith(
      details: details.cloneWithNewLevel(level),
    );
  }
}
