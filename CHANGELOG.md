## 1.1.6

* Fix: some changes are not being notifier to the attached listeners.
* Feat: added `removeFirst` method for `NodeContainer`, 
* Feat: added `hasNotifiersAttached` to know if there's any listener attached.
* Feat: added `findNodePath` to Node class to get the exact index path (the list start with index of the hightest owner)


## 1.1.5

* Fix: `attachNotifier` does not check if the notifier is already added.
* Fix: infinite equality method when we use something like: `node.details == other.details`;
* Fix: `removeAt` is giving a wrong `originalPosition` value for notifiers.
* Fix: bad implementation of equality for `NodeChange` class implementations.
* Feat: `detachNotifiers` now can exclude some callbacks from the deletion using `excludeFromRemove`.
* Chore(test): added tests for `NodeChange` notifiers.
* Chore(doc): added documentation about attaching and detaching notifiers.

## 1.1.4

* Feat(breaking changes): added `index` property to `NodeMoveChange` and `NodeInsertion` changes.

## 1.1.3

* Fix: cannot attach more than one `NodeNotifierChangeCallback`.
* Fix: `removeWhere` does not notify with `NodeChange` type.
* Chore: improved some `NodeChange` calls.
* Feat: added `NodeClear` change for when the `children` are cleaned using `clear()`.
* Feat(breaking changes): added optional property called `deep` for `clone` and `cloneWithNewLevel` methods.

## 1.1.2

* Fix: moving node operations has not implemented `NodeChange` events.
* Feat: added `childrenLevel` getter, that allow us know what should be the children level.
* Chore(breaking changes): removed non used properties in `canMoveTo`.

## 1.1.1

* Fix: cannot use `canMoveTo` correctly because it's returning `false` always.
* Fix: insertion methods and related won't work by unconfigurable `canMoveTo`.
* Chore(test): added tests to avoid error with ancestor checking in a swap operation.

## 1.1.0

* Feat: added `verticalMove()` method, to allow moving Nodes between the Tree.
* Feat: added `NodeCollector` mixin to allow collecting `Nodes`.
* Feat: added static methods `canMoveTo` and `verticalMove` into `Node` class.
* Fix: `jumpToParent` isn't passing `stopAt` property to its owners.
* Chore: removed unnecessary `mustCallSuper` annotation for `owner`, `id`, `level`, `jumpToParent`, and `index` getters.
* Chore: added `mustCallSuper` to `notify()` method.
* Chore: deprecated `atRoot` getter and replaced by `isAtRootLevel`.
* Chore: implemented default functions for `NodeVisitor` and `NodeCollector` into `Node` to avoid unnecessary implementation in leaf nodes. Only `NodeContainer` overrides the implementation to include its `children`. 

## 1.0.5

* Fix: `moveNode()` never move node since is comparing parent index instead Node child index.
* Chore(BREAKING CHANGES): changed return Node type in `jumpToParent()` method to be `NodeContainer` type.

## 1.0.4

* Fix: `propagate` property in `notify` method is `true` by default.

## 1.0.3

* Feat: improved updating, notifying and moving Nodes API [#2](https://github.com/Novident/novident-nodes/pull/2)

## 1.0.2

* Chore: added tests for nodes.
* Fix: recursive `toJson()` calls in `NodeDetails`.
* Fix: bad type comparations in `owner` setter into `Node` class.

## 1.0.1

* Fix: Node levels not updating on insertion/addition [#1](https://github.com/Novident/novident-nodes/pull/1).

## 1.0.0

* First release
