import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:novident_nodes/novident_nodes.dart';

/// An abstract container node that manages a collection of child nodes.
abstract class NodeContainer extends Node {
  /// Internal storage for child nodes
  final List<Node> _children;

  /// Callback for handling node change notifications
  List<NodeNotifierChangeCallback>? _notifierCallbacks;

  NodeContainer({
    required List<Node> children,
    required super.details,
  }) : _children = children;

  NodeContainer.empty({
    required super.details,
  }) : _children = <Node>[];

  /// Return if the container is expanded
  bool get isExpanded;

  @mustCallSuper
  bool get hasNotifiersAttached => _notifierCallbacks?.isNotEmpty ?? false;

  @mustCallSuper
  bool get hasNoNotifiersAttached => _notifierCallbacks?.isEmpty ?? true;

  /// Handles node change events by propagating them to registered listeners.
  ///
  /// [change]: The change event to propagate
  @mustCallSuper
  void onChange(NodeChange change) {
    if (_notifierCallbacks == null) return;
    for (final NodeNotifierChangeCallback notification in _notifierCallbacks!) {
      notification(change);
    }
  }

  /// Attaches a change notifier callback to this node and all child containers.
  ///
  /// The callback will receive all change events from this node and its descendants.
  ///
  /// - [callback]: The notification handler to attach.
  /// - [attachToChildren]: Determines if the notifier will be attached into it's children too.
  @mustCallSuper
  void attachNotifier(
    NodeNotifierChangeCallback callback, {
    bool attachToChildren = false,
    bool strict = true,
  }) {
    if (strict) {
      if (_notifierCallbacks != null &&
          _notifierCallbacks!.contains(callback)) {
        return;
      }
    }
    _notifierCallbacks ??= <NodeNotifierChangeCallback>[];
    _notifierCallbacks?.add(callback);
    if (attachToChildren) {
      for (final Node child in _children) {
        if (child is NodeContainer) {
          child.attachNotifier(callback);
        }
      }
    }
  }

  /// Detaches a change notifier callback from this node and all child containers.
  ///
  /// - [callback]: The specific callback to remove.
  /// - [detachInChildren]: Determines if the notifier will be removed from
  /// it's children too.
  @mustCallSuper
  void detachNotifier(
    NodeNotifierChangeCallback callback, {
    bool detachInChildren = false,
  }) {
    if (_notifierCallbacks == null) return;
    for (int i = 0; i < _notifierCallbacks!.length; i++) {
      final NodeNotifierChangeCallback? notify = _notifierCallbacks?[i];
      if (notify == callback) {
        _notifierCallbacks?.removeAt(i);
        break;
      }
    }
    if (detachInChildren) {
      for (final Node child in _children) {
        if (child is NodeContainer) {
          child.detachNotifier(callback);
        }
      }
    }
  }

  /// Detaches all change notifier callbacks from this node.
  ///
  /// - [detachChildren]: Determines if need to clear the notifiers in
  /// it's children too.
  @mustCallSuper
  void detachNotifiers({
    bool detachChildren = true,
    List<NodeNotifierChangeCallback>? excludeFromRemove,
  }) {
    if (_notifierCallbacks == null) return;
    if (excludeFromRemove != null) {
      final List<NodeNotifierChangeCallback> cloneList =
          <NodeNotifierChangeCallback>[..._notifierCallbacks!];
      for (int i = 0; i < _notifierCallbacks!.length; i++) {
        final NodeNotifierChangeCallback notifier =
            _notifierCallbacks!.elementAt(i);
        if (excludeFromRemove.contains(notifier)) {
          continue;
        }
        cloneList.removeAt(i);
      }
      _notifierCallbacks!
        ..clear()
        ..addAll(cloneList);
    } else {
      _notifierCallbacks = null;
    }
    if (detachChildren) {
      for (final Node child in _children) {
        if (child is NodeContainer) {
          child.detachNotifiers(
            detachChildren: detachChildren,
            excludeFromRemove: excludeFromRemove,
          );
        }
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

  @override
  Iterable<Node> collectNodes(
      {required Predicate shouldGetNode, bool deep = false}) {
    final List<Node> nodes = <Node>[];
    for (final Node child in children) {
      if (shouldGetNode(child)) {
        nodes.add(child);
      } else if (deep) {
        final Iterable<Node> collectedNodes = child.collectNodes(
          shouldGetNode: shouldGetNode,
          deep: deep,
        );
        nodes.addAll(collectedNodes);
      }
    }
    return <Node>[...nodes];
  }

  @override
  Node? visitAllNodes({
    required Predicate shouldGetNode,
    bool reversed = false,
  }) {
    for (int i = reversed ? length - 1 : 0;
        reversed ? i >= 0 : i < length;
        reversed ? i-- : i++) {
      final Node node = elementAt(i);
      if (shouldGetNode(node)) {
        return node;
      }
      final Node? foundedNode =
          node.visitAllNodes(shouldGetNode: shouldGetNode);
      if (foundedNode != null) return foundedNode;
    }
    return null;
  }

  @override
  Node? visitNode({
    required Predicate shouldGetNode,
    bool reversed = false,
  }) {
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

  @override
  int countAllNodes({required Predicate countNode}) {
    int count = 0;
    for (int i = 0; i < length; i++) {
      count += elementAt(i).countAllNodes(
        countNode: countNode,
      );
    }
    return count;
  }

  @override
  int countNodes({required Predicate countNode}) {
    int count = 0;
    for (int i = 0; i < length; i++) {
      final Node node = elementAt(i);
      count += node.countNodes(countNode: countNode);
    }
    return count;
  }

  @override
  bool exist(String nodeId) {
    for (int i = 0; i < length; i++) {
      final Node node = elementAt(i);
      if (node.id == nodeId) {
        return true;
      }
    }
    return false;
  }

  @override
  bool deepExist(String nodeId) {
    for (int i = 0; i < length; i++) {
      if (_children[i].id == nodeId) return true;
      if (_children[i].exist(nodeId)) return true;
    }
    return false;
  }

  /// Gets the list of direct child nodes.
  List<Node> get children => _children;

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
    return _children[index];
  }

  /// Gets the child node at the specified index or null if out of bounds.
  Node? elementAtOrNull(int index) {
    return index < 0 || index >= length ? _children[index] : null;
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
  NodeContainer clone({bool deep = true});

  @override
  NodeContainer cloneWithNewLevel(int level, {bool deep = true});

  /// Determines whether an operation should be treated as insertion or move.
  NodeChange _decideInsertionOrMove({
    required Node to,
    required Node? from,
    required Node newState,
    required Node? oldState,
    required int index,
  }) {
    if (from == null) {
      return NodeInsertion(
        to: to,
        from: from,
        index: index,
        newState: newState,
        oldState: oldState,
      );
    }
    return NodeMoveChange(
      to: to,
      index: index,
      from: from,
      newState: newState,
      oldState: oldState,
    );
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
    if (node.index < 0 || insertIndex != null && insertIndex < 0) return false;
    final Node exactClone = node.clone();
    // if has no parent, them we can ignore the [removed] flag
    final bool removed = node.owner == null ? true : node.unlink();
    if (!removed) {
      throw StateError(
        'The node founded at $index '
        'couldn\'t be removed in $runtimeType:$id',
      );
    }
    if (insertIndex == null || (insertIndex >= to.length || insertIndex < 0)) {
      to.add(node, shouldNotify: false);
    } else {
      to.insert(insertIndex, node, shouldNotify: false);
    }
    final NodeMoveChange change = NodeMoveChange(
      index: insertIndex ?? to.length,
      to: to,
      from: this,
      newState: node.cloneWithNewLevel(to.childrenLevel),
      oldState: exactClone,
    );
    onChange(change);
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
    final Node exactClone = node.clone();
    final bool removed = node.unlink();
    if (!removed) {
      throw StateError(
        'The node founded at $index '
        'couldn\'t be removed in $runtimeType:$id',
      );
    }
    if (insertIndex == null || (insertIndex >= to.length || insertIndex < 0)) {
      to.add(node, shouldNotify: false);
    } else {
      to.insert(insertIndex, node, shouldNotify: false);
    }
    final NodeMoveChange change = NodeMoveChange(
      to: to,
      index: insertIndex ?? to.length,
      from: this,
      newState: node.cloneWithNewLevel(to.childrenLevel),
      oldState: exactClone,
    );
    onChange(change);
    if (shouldNotify) {
      to.notify(propagate: propagate);
      notify(propagate: propagate);
    }
    return true;
  }

  /// Adds a node to the end of children list.
  ///
  /// - [element]: The node to add
  /// - [shouldNotify]: Whether to trigger change notifications
  void add(
    Node element, {
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    onChange(
      _decideInsertionOrMove(
        to: this,
        index: length,
        from: element.owner,
        newState: element.cloneWithNewLevel(childrenLevel)
          ..details.owner = this,
        oldState: element,
      ),
    );
    if (element.owner != this) {
      element.owner = this;
    }
    _children.add(
      element.cloneWithNewLevel(
        childrenLevel,
      ),
    );
    if (shouldNotify) notify(propagate: propagateNotifications);
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
    int lastLength = length;
    for (final Node child in children) {
      onChange(
        _decideInsertionOrMove(
          to: this,
          index: lastLength,
          from: child.owner,
          newState: child.cloneWithNewLevel(childrenLevel)
            ..details.owner = this,
          oldState: child,
        ),
      );
      if (child.owner != this) {
        child.owner = this;
      }
      _children.add(
        child.cloneWithNewLevel(
          childrenLevel,
        ),
      );
      lastLength++;
    }
    if (shouldNotify) notify(propagate: propagateNotifications);
  }

  /// Inserts a node at the specified position.
  ///
  /// - [index]: The position to insert at
  /// - [element]: The node to insert
  /// - [shouldNotify]: Whether to trigger change notifications
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
      element.cloneWithNewLevel(childrenLevel),
    );
    onChange(
      _decideInsertionOrMove(
        to: this,
        index: index + 1,
        from: originalElement.owner,
        newState: element.cloneWithNewLevel(childrenLevel),
        oldState: originalElement,
      ),
    );
    if (shouldNotify) notify(propagate: propagateNotifications);
  }

  /// Removes all child nodes.
  ///
  /// [shouldNotify]: Whether to trigger change notifications
  void clear({bool shouldNotify = true, bool propagateNotifications = false}) {
    final NodeContainer oldState = clone();
    _children
      ..forEach((Node e) => e.details.detachOwner())
      ..clear();
    onChange(
      NodeClear(
        newState: clone(),
        oldState: oldState,
      ),
    );
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
    removeAt(index, shouldNotify: true);
    return true;
  }

  /// Removes and returns the first child node.
  ///
  /// [shouldNotify]: Whether to trigger change notifications
  Node removeFirst({
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    final Node value = _children.first;
    final bool removed = value.unlink(path: 0);
    if (!removed) {
      throw Exception(
        'couldn\'t be removed. Tipically, this happens '
        'The Node at ${0} '
        'when the path of the Node is outdated. please, report '
        'this issue here: https://github.com/Novident/novident-nodes/issues',
      );
    }
    onChange(
      NodeDeletion(
        originalPosition: 1,
        sourceOwner: jumpToParent(stopAt: (Node node) => node.isAtRootLevel),
        inNode: clone(),
        newState: value.clone()..details.detachOwner(),
        oldState: value.clone(),
      ),
    );
    if (shouldNotify) notify(propagate: propagateNotifications);
    return value;
  }

  /// Removes and returns the last child node.
  ///
  /// [shouldNotify]: Whether to trigger change notifications
  Node removeLast({
    bool shouldNotify = true,
    bool propagateNotifications = false,
  }) {
    final Node value = _children.last;
    final int lastPosition = _children.length;
    final bool removed = value.unlink(path: lastPosition - 1);
    if (!removed) {
      throw Exception(
        'couldn\'t be removed. Tipically, this happens '
        'The Node at ${lastPosition - 1} '
        'when the path of the Node is outdated. please, report '
        'this issue here: https://github.com/Novident/novident-nodes/issues',
      );
    }
    onChange(
      NodeDeletion(
        originalPosition: lastPosition,
        sourceOwner: jumpToParent(stopAt: (Node node) => node.isAtRootLevel),
        inNode: clone(),
        newState: value.clone()..details.detachOwner(),
        oldState: value.copyWith(details: value.details.copyWith(owner: this)),
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
    Node? node;
    int indexAt = 0;
    final NodeContainer oldStateOwner = clone();
    for (int i = 0; i < length; i++) {
      indexAt = i;
      node = _children.elementAt(i);
      if (callback(node)) {
        node.unlink(path: i);
        break;
      }
      node = null;
    }
    if (node == null || indexAt >= length) {
      return;
    }
    onChange(
      NodeDeletion(
        originalPosition: indexAt + 1,
        sourceOwner: jumpToParent(stopAt: (Node node) => node.isAtRootLevel),
        inNode: clone(),
        newState: node.copyWith(details: node.details.copyWith(owner: null)),
        oldState:
            node.copyWith(details: node.details.copyWith(owner: oldStateOwner)),
      ),
    );
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
    final Node value = _children[index];
    final bool removed = value.unlink(path: index);
    if (!removed) {
      throw Exception(
        'couldn\'t be removed. Tipically, this happens '
        'The Node at $index '
        'when the path of the Node is outdated. please, report '
        'this issue here: https://github.com/Novident/novident-nodes/issues',
      );
    }
    onChange(
      NodeDeletion(
        originalPosition: index + 1,
        sourceOwner: jumpToParent(stopAt: (Node node) => node.isAtRootLevel),
        inNode: clone(),
        newState: value.clone()..details.detachOwner(),
        oldState: value.copyWith(
          details: value.details.copyWith(owner: this),
        ),
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
    final int index =
        _children.indexWhere((Node node) => node.id == newNodeState.id);
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
  void updateAt(
    int index,
    Node newNodeState, {
    bool propagateNotifications = false,
  }) {
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
  @mustCallSuper
  void dispose() {
    detachNotifiers();
    super.dispose();
  }
}
