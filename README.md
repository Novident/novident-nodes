# 🗃️ Novident Nodes

> [!WARNING]
> This is a library just for internal uses of Novident application 
> and the packages related with the app. 
>
> This package can change constantly and may even have drastic breaking changes.
>
> Please, ensure that you're not using this package, since the values 
> into it wont work for other packages than Novident packages.

The nodes within this package have a specific behavior, and they are capable of updating themselves internally without having to do so themselves.

> [!NOTE]
> This doesn't mean we have to perform certain validations, as some errors could occur.

## What's Node?

A `Node` is the fundamental building block of a hierarchical tree structure, designed to represent parent-child relationships with strict ownership rules and movement validation. It forms the core architecture for systems requiring nested data organization (e.g., file systems, UI components, scene graphs).

### Key features

- **Change Notification**: Implements observer pattern via `NodeNotifier`
- **Tree Traversal**: Supports visitor pattern with `visitAllNodes()`, `collectNodes()`
- **Cloning**: `cloneWithNewLevel()` and `clone` for hierarchy-aware duplication

## Notifying changes 

When you want to update the state of a `Node`, you can use the `notify()` or `notify(propagate: true)` method.

* `propagate`: determines if the `Node` will notify its parent `Node` about its changes.

For example, when using **Drag and Drop** features, you will need to update all Nodes up to the main `Node` that contains your node, since moving nodes requires removing and inserting them in different positions and under different parents:

```dart
// ... perform your operations here
// first, notify the root that this Node has changed
oldParentOfNode.notify(propagate: true);
// then, notify the root that this Node has changed too 
// and contains the new node
newParentOfNode.notify(propagate: true);
```

However, if you only want to update a specific part that doesn't require updating multiple Nodes simultaneously, you can simply use: 

```dart
yourNode.notify();
```

## Moving Nodes

Before moving a node in your hierarchy, you can use `Node.canMoveTo()` to validate the operation. 

This method performs critical safety checks to prevent:

- **Circular references** (e.g., moving a parent into its own child)
- **Invalid targets** (non-containers when `inside = true`)
- **Hierarchy violations** (exceeding depth limits, invalid ownership)

### Usage Example:

```dart
if (Node.canMoveTo(
  node: sourceNode,
  target: targetNode,
  // Determines whether to check if a child is 
  // attempting to reinsert itself into its parent
  inside: true,    
  // Usually, put this to true, when sourceNode owner is the same
  // node that the targetNode (since, this usually happens when you 
  // will swap the position between two nodes that are in the same owner)
  isSwapMove: true, 
)) {
  // Safe to proceed with move operation
  Node.moveTo(node: sourceNode, newOwner: targetNode);
}
```

## We recommend following these practices when using **Novident Nodes** package: 

1. Always validate with `canMoveTo()` before `moveTo()`.
2. Use `notify(propagate: true)` only when you need update different parts of the Tree at the same time.
3. Prefer `jumpToParent()` over manual owner traversal.

## Packages that uses **Novident Nodes** package:

- **[Novident-corkboard](https://github.com/Novident/novident-corkboard):** Nodes are used to display nodes in different ways in a customized way, such as creating index cards that can have a defined shape, or a defined point on the screen, that's also called **FreeForm** corkboard, which allows us to move these cards to any position we want in an infinite canvas view.

- **[Novident-tree-view](https://github.com/Novident/novident-tree-view):** Nodes are used to define where and how nodes will be displayed in a widget tree. It's quite similar to **TreeSliverView**, but this implementation is more tailored to work with Novident standards.

For now, these will be the most common uses. In the long term, the definition of these nodes may change, depending on Novident's needs and the feature being built.

