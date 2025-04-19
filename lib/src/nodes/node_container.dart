import 'package:collection/collection.dart';
import 'package:novident_nodes/novident_nodes.dart';

/// An abstract container node that manages a collection of child nodes.
abstract class NodeContainer extends Node {
  /// Internal storage for child nodes
  final List<Node> _children;

  /// Callback for handling node change notifications
  NodeNotifierChangeCallback? _notifierCallback;

  NodeContainer({
    required List<Node> children,
    required super.details,
  }) : _children = children;

  NodeContainer.empty({
    required super.details,
  }) : _children = <Node>[];

  /// Return if the container is expanded
  bool get isExpanded;

  /// Handles node change events by propagating them to registered listeners.
  ///
  /// [change]: The change event to propagate
  void onChange(NodeChange change) {
    _notifierCallback?.call(change);
  }

  /// Attaches a change notifier callback to this node and all child containers.
  ///
  /// The callback will receive all change events from this node and its descendants.
  /// [callback]: The notification handler to attach
  void attachNotifier(NodeNotifierChangeCallback callback) {
    if (_notifierCallback == callback) return;
    _notifierCallback = callback;
    for (final Node child in _children) {
      if (child is NodeContainer) {
        child.attachNotifier(callback);
      }
    }
  }

  /// Detaches a change notifier callback from this node and all child containers.
  ///
  /// [callback]: The specific callback to remove (null removes all)
  void detachNotifier(NodeNotifierChangeCallback? callback) {
    if (_notifierCallback == null) return;
    if (_notifierCallback == callback) _notifierCallback = null;
    for (final Node child in _children) {
      if (child is NodeContainer) {
        child.detachNotifier(callback);
      }
    }
  }

  /// Filters direct child nodes using the given predicate.
  ///
  /// [predicate]: Condition to test each node against
  /// Returns an iterable of nodes that satisfy the condition
  Iterable<Node> where(ConditionalPredicate<Node> predicate) {
    final List<Node> nodes = <Node>[];
    for (final Node node in _children) {
      if (predicate(node)) {
        nodes.add(node);
      }
    }
    return nodes;
  }

  /// Recursively filters nodes using the given predicate.
  ///
  /// Searches through all descendants, not just direct children.
  /// [predicate]: Condition to test each node against
  /// Returns an iterable of all nodes in the hierarchy that satisfy the condition
  Iterable<Node> whereDeep(ConditionalPredicate<Node> predicate) {
    final List<Node> nodes = <Node>[];
    for (final Node node in _children) {
      if (predicate(node)) {
        nodes.add(node);
      } else if (node is NodeContainer) {
        nodes.addAll(node.whereDeep(predicate));
      }
    }
    return nodes;
  }

  /// Visits all nodes in the hierarchy until finding one that matches the condition.
  ///
  /// [shouldGetNode]: Predicate to determine if a node matches
  /// [reversed]: Whether to traverse in reverse order
  /// Returns the first matching node or null if none found
  @override
  Node? visitAllNodes({required Predicate shouldGetNode, bool reversed = false}) {
    for (int i = reversed ? length - 1 : 0;
        reversed ? i >= 0 : i < length;
        reversed ? i-- : i++) {
      final Node node = elementAt(i);
      if (shouldGetNode(node)) {
        return node;
      }
      final Node? foundedNode = node.visitAllNodes(shouldGetNode: shouldGetNode);
      if (foundedNode != null) return foundedNode;
    }
    return null;
  }

  /// Visits direct child nodes until finding one that matches the condition.
  ///
  /// [shouldGetNode]: Predicate to determine if a node matches
  /// [reversed]: Whether to traverse in reverse order
  /// Returns the first matching child or null if none found
  @override
  Node? visitNode({required Predicate shouldGetNode, bool reversed = false}) {
    for (int i = reversed ? length - 1 : 0;
        reversed ? i >= 0 : i < length;
        reversed ? i-- : i++) {
      final Node node = elementAt(i);
      if (shouldGetNode(node)) {
        return node;
      }
    }
    return null;
  }

  /// Counts all nodes in the hierarchy that match the condition.
  ///
  /// [countNode]: Predicate to test nodes against
  /// Returns the total count of matching nodes
  @override
  int countAllNodes({required Predicate countNode}) {
    int count = 0;
    for (int i = 0; i < length; i++) {
      final Node node = elementAt(i);
      if (countNode(node)) {
        count++;
      }
      count += node.countAllNodes(countNode: countNode);
    }
    return count;
  }

  /// Counts direct child nodes that match the condition.
  ///
  /// [countNode]: Predicate to test nodes against
  /// Returns the count of matching direct children
  @override
  int countNodes({required Predicate countNode}) {
    int count = 0;
    for (int i = 0; i < length; i++) {
      final Node node = elementAt(i);
      if (countNode(node)) {
        count++;
      }
    }
    return count;
  }

  /// Checks if a node with the given ID exists among direct children.
  ///
  /// [nodeId]: The ID to search for
  /// Returns true if a direct child has the specified ID
  @override
  bool exist(String nodeId) {
    for (int i = 0; i < length; i++) {
      if (elementAt(i).details.id == nodeId) return true;
    }
    return false;
  }

  /// Recursively checks if a node with the given ID exists in the hierarchy.
  ///
  /// Searches through all descendants.
  /// [nodeId]: The ID to search for
  /// Returns true if any node in the hierarchy has the specified ID
  ///
  /// Note: This operation's performance depends on the tree depth.
  @override
  bool deepExist(String nodeId) {
    for (int i = 0; i < length; i++) {
      final Node node = elementAt(i);
      if (node.details.id == nodeId) {
        return true;
      }
      final bool foundedNode = node.deepExist(nodeId);
      if (foundedNode) return true;
    }
    return false;
  }

  /// Gets the first child node.
  /// Throws if there are no children.
  Node get first => _children.first;

  /// Gets the last child node.
  /// Throws if there are no children.
  Node get last => _children.last;

  /// Gets the last child node or null if empty.
  Node? get lastOrNull => _children.lastOrNull;

  /// Gets the first child node or null if empty.
  Node? get firstOrNull => _children.firstOrNull;

  /// Gets an iterator for the child nodes.
  Iterator<Node> get iterator => _children.iterator;

  /// Gets a reversed iterable of child nodes.
  Iterable<Node> get reversed => _children.reversed;

  /// Whether there are no child nodes.
  bool get isEmpty => _children.isEmpty;

  /// Whether there are no child nodes (alias for isEmpty).
  bool get hasNoChildren => _children.isEmpty;

  /// Whether there are any child nodes.
  bool get isNotEmpty => !isEmpty;

  /// The number of child nodes.
  int get length => _children.length;

  /// Gets the child node at the specified index.
  Node elementAt(int index) {
    return _children.elementAt(index);
  }

  /// Gets the child node at the specified index or null if out of bounds.
  Node? elementAtOrNull(int index) {
    return _children.elementAtOrNull(index);
  }

  /// Checks if the collection contains the given node.
  bool contains(Node object) {
    return _children.contains(object);
  }

  /// Replaces all children with the new list.
  void clearAndOverrideState(List<Node> newChildren) {
    clear(shouldNotify: false);
    addAll(newChildren);
  }

  /// Finds the index of the first node matching the condition.
  int indexWhere(bool Function(Node) callback) {
    return _children.indexWhere(callback);
  }

  /// Finds the index of the specified node starting from given position.
  int indexOf(Node element, [int start = 0]) {
    return _children.indexOf(element, start);
  }

  /// Gets the first node matching the condition.
  Node firstWhere(bool Function(Node) callback) {
    return _children.firstWhere(callback);
  }

  /// Gets the first node matching the condition or null if not satifies the condition.
  Node? firstWhereOrNull(bool Function(Node) callback) {
    return _children.firstWhereOrNull(callback);
  }

  /// Gets the last node matching the condition.
  Node lastWhere(bool Function(Node) callback) {
    return _children.lastWhere(callback);
  }

  /// Gets the last node matching the condition or null if not satifies the condition.
  Node? lastWhereOrNull(bool Function(Node) callback) {
    return _children.lastWhereOrNull(callback);
  }

  @override
  NodeContainer clone();

  @override
  NodeContainer cloneWithNewLevel(int level);

  /// Determines whether an operation should be treated as insertion or move.
  NodeChange _decideInsertionOrMove({
    required Node to,
    required Node? from,
    required Node newState,
    required Node? oldState,
  }) {
    if (from == null) {
      return NodeInsertion(to: to, from: from, newState: newState);
    }
    return NodeMoveChange(to: to, from: from, newState: newState);
  }

  /// Adds a node to the end of children list.
  ///
  /// [element]: The node to add
  /// [shouldNotify]: Whether to trigger change notifications
  void add(
    Node element, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    onChange(
      _decideInsertionOrMove(
        to: this,
        from: element.owner,
        newState: element.cloneWithNewLevel(level + 1),
        oldState: element,
      ),
    );
    if (element.owner != this) {
      element.owner = this;
    }
    _children.add(element.cloneWithNewLevel(level + 1));
    if (shouldNotify) notify(propagate: propagateNotifications);
  }

  /// Move the [Node] passed to a new parent.
  ///
  /// * [node]: The [Node] that you want to move
  /// * [to]: The [NodeContainer] where the [Node] will be moved
  /// * [insertIndex]: The index where will be inserted the [Node] into the target passed
  /// * [shouldNotify]: Whether to trigger change notifications
  /// * [ensureDeletion]: determines if the method will ensure that the [Node] passed is removed from the current [NodeContainer]
  bool moveNode(
    Node node,
    NodeContainer to, {
    int? insertIndex,
    bool shouldNotify = true,
    bool propagate = true,
    bool ensureDeletion = true,
  }) {
    if (index < 0) return false;
    removeWhere((Node n) => n.id == node.id, shouldNotify: false);
    if (ensureDeletion) {
      final Node? removed = firstWhereOrNull((Node n) => n.id == node.id);
      if (removed != null) {
        throw StateError(
          'The node founded at index $index '
          'couldn\'t be removed in $this',
        );
      }
    }
    if (insertIndex == null || (insertIndex >= to.length || insertIndex < 0)) {
      to.add(node, shouldNotify: false);
    } else {
      to.insert(insertIndex, node, shouldNotify: false);
    }
    if (shouldNotify) {
      to.notify(propagate: propagate);
      notify(propagate: propagate);
    }
    return true;
  }

  /// Find the [Node] by the [id] passed and Move it to a new parent.
  ///
  /// * [id]: The identifier of the [Node] that you want to move
  /// * [to]: The [NodeContainer] where the [Node] will be moved
  /// * [insertIndex]: The index where will be inserted the [Node] into the target passed
  /// * [shouldNotify]: Whether to trigger change notifications
  bool moveNodeById(
    String id,
    NodeContainer to, {
    int? insertIndex,
    bool shouldNotify = true,
    bool propagate = true,
  }) {
    final int index = _children.indexWhere((Node node) => node.id == id);
    if (index < 0) return false;
    final Node node = elementAt(index);
    final bool removed = remove(node, shouldNotify: false);
    if (!removed) {
      throw StateError(
        'The node founded at index $index '
        'couldn\'t be removed in $this',
      );
    }
    if (insertIndex == null || (insertIndex >= to.length || insertIndex < 0)) {
      to.add(node, shouldNotify: false);
    } else {
      to.insert(insertIndex, node, shouldNotify: false);
    }
    if (shouldNotify) {
      to.notify(propagate: propagate);
      notify(propagate: propagate);
    }
    return true;
  }

  /// Adds multiple nodes to the end of children list.
  ///
  /// * [children]: The nodes to add
  /// * [shouldNotify]: Whether to trigger change notifications
  void addAll(
    Iterable<Node> children, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    for (final Node child in children) {
      onChange(
        _decideInsertionOrMove(
          to: this,
          from: child.owner,
          newState: child.clone()..owner = this,
          oldState: child,
        ),
      );
      if (child.owner != this) {
        child.owner = this;
      }
      _children.add(child.cloneWithNewLevel(level + 1));
    }
    if (shouldNotify) notify(propagate: propagateNotifications);
  }

  /// Inserts a node at the specified position.
  ///
  /// [index]: The position to insert at
  /// [element]: The node to insert
  /// [shouldNotify]: Whether to trigger change notifications
  void insert(
    int index,
    Node element, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    final Node originalElement = element.clone();
    if (element.owner != this) {
      element.owner = this;
    }
    _children.insert(
      index,
      element.cloneWithNewLevel(level + 1),
    );
    onChange(
      _decideInsertionOrMove(
        to: this,
        from: originalElement.owner,
        newState: element.cloneWithNewLevel(level + 1),
        oldState: originalElement,
      ),
    );
    if (shouldNotify) notify(propagate: propagateNotifications);
  }

  /// Removes all child nodes.
  ///
  /// [shouldNotify]: Whether to trigger change notifications
  void clear({bool shouldNotify = true, bool propagateNotifications = false}) {
    _children.clear();
    if (shouldNotify) notify(propagate: propagateNotifications);
  }

  /// Removes the first occurrence of the specified node.
  ///
  /// [element]: The node to remove
  /// [shouldNotify]: Whether to trigger change notifications
  /// Returns true if the node was found and removed
  bool remove(
    Node element, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    final int index = _children.indexOf(element);
    if (index <= -1) return false;
    _children.removeAt(index);
    onChange(
      NodeDeletion(
        originalPosition: index,
        sourceOwner: jumpToParent(stopAt: (Node node) => node.atRoot)!,
        inNode: clone(),
        newState: element,
        oldState: element,
      ),
    );
    if (shouldNotify) notify(propagate: propagateNotifications);
    return true;
  }

  /// Removes and returns the last child node.
  ///
  /// [shouldNotify]: Whether to trigger change notifications
  /// Returns the removed node
  Node removeLast({
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    final Node value = _children.removeLast();
    onChange(
      NodeDeletion(
        originalPosition: _children.length,
        sourceOwner: jumpToParent(stopAt: (Node node) => node.atRoot)!,
        inNode: clone(),
        newState: value.clone(),
        oldState: value.clone(),
      ),
    );
    if (shouldNotify) notify(propagate: propagateNotifications);
    return value;
  }

  /// Removes all child nodes matching the condition.
  ///
  /// [callback]: Condition to test nodes against
  /// [shouldNotify]: Whether to trigger change notifications
  void removeWhere(
    bool Function(Node) callback, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    _children.removeWhere(callback);
    if (shouldNotify) notify(propagate: propagateNotifications);
  }

  /// Removes the child node at the specified position.
  ///
  /// [index]: The position to remove from
  /// [shouldNotify]: Whether to trigger change notifications
  /// Returns the removed node
  Node removeAt(
    int index, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    final Node value = _children.removeAt(index);
    onChange(
      NodeDeletion(
        originalPosition: index,
        sourceOwner: jumpToParent(stopAt: (Node node) => node.atRoot)!,
        inNode: clone(),
        newState: value.clone(),
        oldState: value.clone(),
      ),
    );
    if (shouldNotify) notify(propagate: propagateNotifications);
    return value;
  }

  /// Update a child [Node] if it is founded, or insert if it does not exist
  void update(
    Node newNodeState, {
    bool propagateNotifications = false,
    bool insertIfNotExist = true,
  }) {
    final int index = _children.indexWhere((Node node) => node.id == newNodeState.id);
    if (index < 0 && !insertIfNotExist) {
      return;
    } else if (index < 0 && insertIfNotExist) {
      add(
        newNodeState,
        propagateNotifications: propagateNotifications,
      );
      return;
    }
    onChange(
      NodeUpdate(
        newState: newNodeState,
        oldState: _children[index],
      ),
    );
    if (newNodeState.owner != this) {
      newNodeState.owner = this;
    }
    _children[index] = newNodeState.cloneWithNewLevel(level + 1);
    notify(propagate: propagateNotifications);
  }

  /// Updates the child node by a predicate.
  void updateWhere(
    Node newNodeState,
    ConditionalPredicate<Node> predicate, {
    bool propagateNotifications = false,
  }) {
    final int index = _children.indexWhere(predicate);
    if (index < 0) return;
    onChange(
      NodeUpdate(
        newState: newNodeState,
        oldState: _children[index],
      ),
    );
    if (newNodeState.owner != this) {
      newNodeState.owner = this;
    }
    _children[index] = newNodeState.cloneWithNewLevel(level + 1);
    notify(propagate: propagateNotifications);
  }

  /// Updates the child node at the specified index.
  void updateAt(int index, Node newNodeState, {bool propagateNotifications = false}) {
    if (index < 0) return;
    onChange(
      NodeUpdate(
        newState: newNodeState,
        oldState: _children[index],
      ),
    );
    if (newNodeState.owner != this) {
      newNodeState.owner = this;
    }
    _children[index] = newNodeState.cloneWithNewLevel(level + 1);
    notify(propagate: propagateNotifications);
  }

  /// Updates the child node at the specified index.
  void operator []=(int index, Node newNodeState) {
    if (index < 0) return;
    onChange(
      NodeUpdate(
        newState: newNodeState,
        oldState: _children[index],
      ),
    );
    if (newNodeState.owner != this) {
      newNodeState.owner = this;
    }
    _children[index] = newNodeState.cloneWithNewLevel(level + 1);
    notify(propagate: true);
  }

  /// Gets the child node at the specified index.
  Node operator [](int index) {
    return _children[index];
  }

  /// Cleans up resources and detaches all notifiers.
  @override
  void dispose() {
    detachNotifier(_notifierCallback);
    super.dispose();
  }
}
