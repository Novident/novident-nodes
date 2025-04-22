import 'package:novident_nodes/novident_nodes.dart';

/// This is a base class that contains the necessary method for
/// collect one or more nodes
mixin NodeCollector {
  /// Visit all nodes into the available posibilities and get
  /// all ones that satifies the predicate
  Iterable<Node> collectNodes({
    required Predicate shouldGetNode,
    bool deep = false,
  });
}
