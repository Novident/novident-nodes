import 'package:flutter/foundation.dart';
import 'package:novident_nodes/novident_nodes.dart';

class DirectoryNode extends NodeContainer {
  final String name;
  bool _isExpanded;

  DirectoryNode({
    required super.details,
    List<Node>? children,
    required this.name,
    bool isExpanded = false,
  })  : _isExpanded = isExpanded,
        super(children: children ?? <Node>[]) {
    for (final Node child in super.children) {
      child.owner = this;
    }
    redepthChildren();
  }

  @override
  bool get isExpanded => _isExpanded;

  void openOrClose({bool forceOpen = false}) {
    _isExpanded = forceOpen ? true : !isExpanded;
    notifyListeners();
  }

  /// adjust the depth level of the children
  void redepthChildren({int? alternativeLevel}) {
    void redepth(List<Node> unformattedChildren, int currentLevel) {
      for (int i = 0; i < unformattedChildren.length; i++) {
        final Node node = unformattedChildren.elementAt(i);
        final int childLevel = currentLevel + 1;
        unformattedChildren[i] = node.cloneWithNewLevel(childLevel);
        if (node is NodeContainer && node.isNotEmpty) {
          redepth(node.children, childLevel);
        }
      }
    }

    redepth(children, alternativeLevel ?? level);
    notifyListeners();
  }

  set isExpanded(bool expand) {
    _isExpanded = expand;
    notifyListeners();
  }

  @override
  DirectoryNode copyWith({
    NodeDetails? details,
    List<Node>? children,
    bool? isExpanded,
    String? name,
  }) {
    return DirectoryNode(
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      details: details ?? this.details,
      name: name ?? this.name,
    );
  }

  @override
  String toString() {
    return 'DirectoryNode(name: $name, isExpanded: $isExpanded, count nodes: ${children.length}, depth: $level)';
  }

  @override
  DirectoryNode clone({bool deep = true}) {
    return DirectoryNode(
      children: !deep
          ? children
          : children
              .map(
                (Node e) => e.clone(),
              )
              .toList(),
      details: NodeDetails.withLevel(level),
      isExpanded: _isExpanded,
      name: name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! DirectoryNode) {
      return false;
    }
    return listEquals(children, other.children) &&
        name == other.name &&
        details == other.details &&
        _isExpanded == other._isExpanded;
  }

  @override
  int get hashCode => Object.hashAllUnordered(<Object?>[
        details,
        name,
        details,
        _isExpanded,
      ]);

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'details': details.toJson(),
      'name': name,
      'children': children.map((Node e) => e.toJson()).toList(),
      'isExpanded': _isExpanded,
    };
  }

  @override
  DirectoryNode cloneWithNewLevel(int level, {bool deep = true}) {
    return copyWith(
      details: details.cloneWithNewLevel(
        level,
      ),
    );
  }
}
