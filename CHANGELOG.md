## 1.2.2

* Feat: `index` now cache the value to avoid make a re-calculation every time it's called
  using `getCachedValue` and `cacheValue` methods in `NodeDetails`
* Revert: `canMoveTo` restored to its original API with `inside` (bool) and
  `isSwapMove` parameters. The `DropPosition`/`position` API introduced in
  1.2.1 was over-engineered and caused more edge cases than it solved.
  Adjacent move validation will be handled at the drag-and-drop layer.
* Fix: `moveTo`, `moveNode`, and `moveNodeById` no longer throw a `StateError`
  when `unlink` fails due to a race condition (e.g. double-invocation during
  drag-and-drop). If the node is already detached, the operation proceeds.
* Chore(test): removed DropPosition and position-aware tests.

## 1.2.1

* Feat(breaking changes): replaced `inside` (bool) with `position`
  (`DropPosition?`) in `Node.canMoveTo`. `DropPosition.above` inserts
  before the target, `DropPosition.inside` inserts as a child, and
  `DropPosition.below` inserts after. When null, only structural checks
  run — backward compatible with the old `inside: true` default.
* Feat(breaking changes): removed deprecated `isSwapMove` parameter from
  `canMoveTo`. The `position` + `insertIndex` API replaces it fully.
* Feat: `DropPosition` enum with direction-aware adjacent no-op detection.
  `above`/`below` detect no-ops using only the position and target index
  (no `insertIndex` needed). `inside` with same parent requires `insertIndex`
  for exact position validation; without it, re-insertion is conservatively
  blocked.
* Feat: `insertIndex` in `canMoveTo` is now optional. It is only required
  for `inside` + same-parent reorder validation. `above`/`below` adjacent
  checks work without it.
* Fix: `moveTo`, `moveNode`, and `moveNodeById` no longer throw a `StateError`
  when `unlink` fails due to a race condition (e.g. double-invocation during
  drag-and-drop). If the node is already detached, the operation proceeds.
* Chore(test): 24 total tests covering `moveNode`, `moveNodeById`, `canMoveTo`
  constraints, position-aware no-ops, adjacent moves, and depth limits.

## 1.2.0

* Feat(breaking changes): renamed `attachNotifier` → `attachListener` for consistency with the new `ChangeEventCallback` typedef.
* Feat(breaking changes): renamed `hasNotifiersAttached` → `hasEventListeners` and removed `hasNoNotifiersAttached` (use `!hasEventListeners` instead).
* Feat(breaking changes): renamed typedef `NodeNotifierChangeCallback` → `ChangeEventCallback`.
* Feat(breaking changes): removed deprecated `atRoot` getter from `Node`. Use `isAtRootLevel` instead.
* Feat(breaking changes): added `insertIndex` parameter to `Node.canMoveTo` (positioned before `isSwapMove`). All parameters remain named so existing callers are unaffected.
* Feat(breaking changes): `NodeContainer.update`, `updateWhere`, `updateAt` now accept `shouldNotify` (default `true`) to suppress notifications during internal operations like re-depting.
* Deprecated: `isSwapMove` parameter in `canMoveTo`. With `insertIndex`, the method can now distinguish no-ops from legitimate reorders without it.
* Feat: `canMoveTo` is now position-aware via `insertIndex`, enabling exact insertion position validation that mirrors `moveTo` logic (`>= length` = append). Includes no-op detection for same-owner same-position moves.
* Feat: `redepthDescendants` static method on `Node` and instance method on `NodeContainer` that recursively reassigns depth levels to all descendants after moving a container.
* Fix: `moveNode`, `moveNodeById`, and `Node.moveTo` now recursively re-depth all descendant levels when moving a `NodeContainer`, fixing incorrect depth hierarchies after relocation.
* Fix: `canMoveTo` maxDepthLevel off-by-one: now validates `target.level + 1` against the limit instead of `target.level`.
* Fix: `canMoveTo` jumpToParent guard prevents unsafe cast when `target` is an ownerless node.
* Fix: `update`, `updateWhere`, `updateAt` now use `childrenLevel` instead of `level + 1` for correct child depth assignment.
* Fix: `findNodePath` null safety: accepts `null` alongside `-2` as stop signal for `ownerIndex`.
* Chore(test): 14 new tests for `moveNode`, `moveNodeById`, and `canMoveTo` covering re-depth, insertIndex, no-ops, maxDepthLevel, and edge cases.
* Chore(test): 7 new tests for `canMoveTo` with `insertIndex` covering no-op detection, directional adjacent moves, and depth limits.

## 1.1.9

* Fix: `elementAtOrNull` is always returning null even if the `index` is a valid num.
* Fix: `unlink` method, cannot notify to the listeners when required.
* Feat: added `atPath` method.
* Chore: general improvements in the API.

## 1.1.8

* Fix: `removeAt` and `removeFirst` are throwing exceptions when no required.

## 1.1.7

* Fix: `verticalMove` is not working as expected when `down` is true.
* Feat: added `nextSibling`, `previousSibling`, `hasNextSibling`, `hasPreviousSibling` methods.
* Feat: added `unlink` method to removed a `Node` directly without calling the `owner`.
* Feat: added `createNodeId` static method for `NodeDetails` class to create ids that are ready to be used for any new `Node`
* Chore: added `toString` method definition for `NodeChange` and subclasses.
* Chore: general improvements in the `NodeContainer` API and `children` management.

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
