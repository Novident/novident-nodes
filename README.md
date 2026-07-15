# 🗃️ Novident Nodes

A Flutter/Dart package for building and manipulating hierarchical tree structures
with strict ownership rules, movement validation, and change notification.

## Installation

```yaml
dependencies:
  novident_nodes: <latest>
```

## Quick Start

_These are just examples, default implementations for node are NOT provided by the library._ 

```dart
import 'package:novident_nodes/novident_nodes.dart';

// Create a tree
final root = DirectoryNode(
  details: NodeDetails.zero(),
  children: [
    FileNode(details: NodeDetails.byId(id: 'readme', level: 0),
             content: '# Hello', name: 'README.md'),
    DirectoryNode(details: NodeDetails.byId(id: 'src', level: 0),
                  children: [], name: 'src'),
  ],
  name: 'project',
);

// Listen for changes
root.attachListener((change) {
  if (change is NodeMoveChange) {
    print('Moved to ${change.to.id} at index ${change.index}');
  }
});

// Validate and move
if (Node.canMoveTo(
  node: root.first,
  target: root.last as NodeContainer,
  inside: true,
)) {
  Node.moveTo(node: root.first, newOwner: root.last as NodeContainer);
}
```

## Core Concepts

### `Node` (abstract)

The base class for all tree elements. Extends `ChangeNotifier` and provides:

| Capability | Methods |
|-----------|---------|
| Identity | `id`, `level`, `childrenLevel`, `isAtRootLevel` |
| Ownership | `owner`, `index`, `jumpToParent()` |
| Navigation | `nextSibling`, `previousSibling`, `findNodePath()` |
| Lifecycle | `unlink()`, `notify()`, `dispose()` |
| Cloning | `clone()`, `cloneWithNewLevel()`, `copyWith()` |
| Validation | `canMoveTo()` |
| Movement | `verticalMove()`, `moveTo()` |
| Re-depth | `redepthDescendants()` |

Implementations must override: `copyWith`, `cloneWithNewLevel`, `clone`, `toJson`, `==`, `hashCode`.

### `NodeContainer` (abstract)

Extends `Node` to manage child collections. Adds:

| Capability | Methods |
|-----------|---------|
| Children | `add()`, `insert()`, `remove()`, `removeAt()`, `clear()` |
| Movement | `moveNode()`, `moveNodeById()` |
| Updates | `update()`, `updateWhere()`, `updateAt()`, `operator []` / `[]=` |
| Search | `where()`, `whereDeep()`, `atPath()`, `visitAllNodes()`, `collectNodes()` |
| Listeners | `attachListener()`, `detachListener()`, `detachListeners()` |


### `NodeChange` subclasses

| Type | Triggered by | Key fields |
|------|-------------|------------|
| `NodeInsertion` | `add()`, `insert()` | `to`, `from`, `index` |
| `NodeDeletion` | `remove()`, `removeAt()` | `originalPosition`, `sourceOwner` |
| `NodeMoveChange` | `moveTo()`, `moveNode()` | `to`, `from`, `index`, `newState`, `oldState` |
| `NodeUpdate` | `update()`, `updateAt()`, `[]=` | `newState`, `oldState` |
| `NodeClear` | `clear()` | `newState`, `oldState` |

## Usage Guide

### Building a Tree

```dart
final root = DirectoryNode(
  details: NodeDetails.zero(),
  children: [
    DirectoryNode(
      details: NodeDetails.byId(id: 'docs', level: 0),
      children: [
        FileNode(details: NodeDetails.byId(id: 'api', level: 0),
                 content: '', name: 'api.md'),
      ],
      name: 'docs',
    ),
  ],
  name: 'root',
);

// Nodes auto-assign ownership and recalculate depth levels on construction.
print(root.first.level);  // 1
print(root.first.first.level);  // 2
```

### Listening for Changes

```dart
final container = DirectoryNode(
  details: NodeDetails.zero(), children: [], name: 'watched',
);

container.attachListener((NodeChange change) => switch (change) {
  NodeInsertion(:final to, :final index) =>
    print('Inserted into ${to.id} at $index'),
  NodeDeletion(:final originalPosition) =>
    print('Removed from position $originalPosition'),
  NodeMoveChange(:final to, :final from, :final index) =>
    print('Moved from ${from?.id} to ${to.id} at $index'),
  NodeUpdate(:final newState) =>
    print('Updated to ${newState.id}'),
  NodeClear() =>
    print('All children cleared'),
  _ => null,
});

// Detach when done
container.detachListener(myCallback);
// Or detach everything
container.detachListeners(detachChildren: true);
// Or dispose the whole subtree
container.dispose();
```

### Moving Nodes

Use `canMoveTo()` before any move operation:

```dart
// Move inside another container
if (Node.canMoveTo(node: leaf, target: folder, inside: true)) {
  Node.moveTo(node: leaf, newOwner: folder);
}

// Reorder within the same parent
if (Node.canMoveTo(
  node: leaf, 
  target: sibling,
  inside: false,
  isSwapMove: true,
)) {
  // leaf will be placed before sibling in their shared parent
}

// Same-parent reorder to a specific index
if (Node.canMoveTo(
  node: leaf, 
  target: parent,
  isSwapMove: true,
)) {
  Node.moveTo(node: leaf, newOwner: parent, index: 0);
}

// Depth limit
if (Node.canMoveTo(
  node: leaf, 
  target: deepFolder,
  inside: true, 
  maxDepthLevel: 3,
)) { /* safe */ }
```

### Traversing the Tree

```dart
// Find by path
final node = root.atPath([0, 1]);  // first child → second child

// Find by predicate
final found = root.visitAllNodes(
  shouldGetNode: (n) => n.id == 'api',
);

// Collect all matching nodes
final allFiles = root.collectNodes(
  shouldGetNode: (n) => n is FileNode,
  deep: true,
);

// Get a node's full path
print(node.findNodePath());  // [0, 1]
```

## Best Practices

1. **Validate before moving**: Always call `canMoveTo()` before `moveTo()` / `moveNode()`.
2. **Propagate notifications sparingly**: Use `notify(propagate: true)` only when multiple tree levels need simultaneous updates (e.g., drag-and-drop).
3. **Use `jumpToParent()`** instead of manual owner traversal — it handles null owners and stop conditions safely.
4. **Dispose unused subtrees**: Call `dispose()` to detach all listeners and prevent memory leaks.
5. **Provide `insertIndex` for same-parent reorders**: Without it, `canMoveTo` conservatively blocks re-insertion into the current parent.

## Ecosystem

- **[novident-tree-view](https://github.com/Novident/novident-tree-view):** Widget tree view for rendering hierarchical node structures, similar to TreeSliverView but tailored to Novident standards with full drag-and-drop support.
