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
    if (identical(this, other)) return true;
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
    return 'FileNode(name: $name, content: $content, depth: $level, details: $details)';
  }

  @override
  FileNode clone({bool deep = true}) {
    return FileNode(
      details: details.clone(),
      content: content,
      name: name,
    );
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
  FileNode cloneWithNewLevel(int level, {bool deep = true}) {
    return copyWith(
      details: details.cloneWithNewLevel(level),
    );
  }
}
