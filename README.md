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

- **General Change Notification**: Implements observer pattern via `NodeNotifier` that's an extension of `ChangeNotifier`.
- **Specific changes notifications**: Implements observer pattern for specific changes using `attachNotifier`. 
- **Tree Traversal**: Supports visitor pattern with `visitAllNodes()`, `collectNodes()`.
- **Cloning**: `cloneWithNewLevel()` and `clone()` for hierarchy-aware duplication.

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

## Listening specific changes using internal notifiers

The notifiers system in `NodeContainer` provides a mechanism to observe and react to changes in the node structure and its descendants. 

This system is a bit more accurate than the one used by `ChangeNotifier`, because we provide changes of a specific type that can be more useful, since depending on the change, the information can be very useful.

An example of this is `NodeMoveChange`, which tells us the position where the node will be inserted (`index`), the node itself (`newState`), its previous state (before the change: `oldState`), where it came from (its previous owner: `from`), and where it will be inserted (its new owner: `to`).

### Usage Considerations

* **Hierarchy:** Notifiers can operate on a single node or its entire child hierarchy (it's defined when you use `attachToChildren`).
* **Performance:** Change propagation through many nodes may impact performance.
* **Memory Management:** It's important to unregister callbacks when no longer needed to prevent memory leaks.

```dart
final container = NodeContainer(children: [], details: ...);

// Definir un callback
void handleChange(NodeChange change) {
  if(change is NodeClear) {
    // ... for when the children node are cleaned
  }
  if(change is NodeDeletion) {
    // ... for when a Node is removed from it's owner 
  }
  if(change is NodeInsertion) {
    // ... for when a Node is added/inserted to a owner 
  }
  if(change is NodeMoveChange) {
    // ... usually used when a node
    // from an owner is inserted into another
    // one
  }
  if(change is NodeUpdate) {
    // ... for when a Node is updated into it's owner
  }
}

// attach your notifier 
// you can also attach automatically this callback to it's children too
node.attachNotifier(handleChange, attachToChildren: false);

// you can also manually add a change or custom change using:
// container.onChange(SomeNodeChange());

// If you want to remove a notifier, you can use:
container.detachNotifier(handleChange);

// If you prefer you can:
//
// Dispose the node (Make it and its descendants unusable)
container.dispose();
// Or
//
// Just remove all/specific notifiers
container.detachNotifiers(detachChildren: true, excludeFromRemove: [callbacksThatWeNeedYet()]);
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
3. Dispose your nodes to prevent memory leaks using `dispose()`.

## Packages that uses **Novident Nodes** package:

- **[Novident-corkboard](https://github.com/Novident/novident-corkboard):** Nodes are used to display nodes in different ways in a customized way, such as creating index cards that can have a defined shape, or a defined point on the screen, that's also called **FreeForm** corkboard, which allows us to move these cards to any position we want in an infinite canvas view.

- **[Novident-tree-view](https://github.com/Novident/novident-tree-view):** Nodes are used to define where and how nodes will be displayed in a widget tree. It's quite similar to **TreeSliverView**, but this implementation is more tailored to work with Novident standards.

For now, these will be the most common uses. In the long term, the definition of these nodes may change, depending on Novident's needs and the feature being built.

