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
