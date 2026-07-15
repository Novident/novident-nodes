import 'package:flutter_test/flutter_test.dart';
import 'package:novident_nodes/novident_nodes.dart';

import 'test_nodes/directory_node.dart';
import 'test_nodes/file_node.dart';

/// Helper to find a container by id within a tree
NodeContainer _findContainer(NodeContainer root, String id) {
  final Node? found = root.visitAllNodes(
    shouldGetNode: (Node n) => n.id == id && n is NodeContainer,
  );
  return found! as NodeContainer;
}

void main() {
  group('moveNode', () {
    test('should move leaf node to another container and update level', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'leaf', level: 0),
            content: '',
            name: 'Leaf',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer target = _findContainer(root, 'target');
      final Node leaf = root.firstWhere((Node n) => n.id == 'leaf');

      expect(leaf.level, 1);
      expect(target.isEmpty, isTrue);

      final bool moved = root.moveNode(leaf, target);
      expect(moved, isTrue);

      // Root should only have targetContainer now
      expect(root.length, 1);
      expect(root.first.id, 'target');

      // Target container should have the leaf
      expect(target.length, 1);
      expect(target.first.id, 'leaf');
      expect(target.first.level, 2);
    });

    test('should move container with children and re-depth all descendants',
        () {
      // Build the tree: root -> [dirToMove, target]
      //   dirToMove -> [file_in_dir, nested]
      //     nested -> [deep_file]
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          DirectoryNode(
            details: NodeDetails.byId(id: 'to_move', level: 0),
            children: <Node>[
              FileNode(
                details: NodeDetails.byId(id: 'file_in_dir', level: 0),
                content: '',
                name: 'File in dir',
              ),
              DirectoryNode(
                details: NodeDetails.byId(id: 'nested', level: 0),
                children: <Node>[
                  FileNode(
                    details: NodeDetails.byId(id: 'deep_file', level: 0),
                    content: '',
                    name: 'Deep File',
                  ),
                ],
                name: 'Nested Dir',
              ),
            ],
            name: 'Dir to Move',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      // Get references from the tree
      final NodeContainer dirToMove = root.first as NodeContainer;
      final NodeContainer target = root.last as NodeContainer;
      final Node nestedInTree = dirToMove.last;

      // Verify initial state (dirToMove at level 1, children at level 2, etc.)
      expect(dirToMove.id, 'to_move');
      expect(dirToMove.level, 1);
      expect(dirToMove.first.id, 'file_in_dir');
      expect(dirToMove.first.level, 2);
      expect(dirToMove.last.id, 'nested');
      expect(dirToMove.last.level, 2);

      // nested's children should be at level 3
      expect((nestedInTree as NodeContainer).first.id, 'deep_file');
      expect(nestedInTree.first.level, 3);

      // Move dirToMove into targetContainer (target is at level 1, so moved
      // node should be at level 2, its children at 3, and nested's at 4)
      final bool moved = root.moveNode(dirToMove, target);
      expect(moved, isTrue);

      // Root should only have target
      expect(root.length, 1);
      expect(root.first.id, 'target');

      // Target should have dirToMove at level 2 (target.childrenLevel)
      expect(target.length, 1);
      final NodeContainer movedDir = target.first as NodeContainer;
      expect(movedDir.id, 'to_move');
      expect(movedDir.level, 2);

      // dirToMove's direct children should now be at level 3
      expect(movedDir.length, 2);
      expect(movedDir.first.id, 'file_in_dir');
      expect(movedDir.first.level, 3);

      // nested should be at level 3
      final Node movedNested = movedDir.last;
      expect(movedNested.id, 'nested');
      expect(movedNested.level, 3);

      // nested's children should be at level 4
      final NodeContainer nestedContainer = movedNested as NodeContainer;
      expect(nestedContainer.first.id, 'deep_file');
      expect(nestedContainer.first.level, 4);
    });

    test('should move node at specific insertIndex', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'leaf', level: 0),
            content: '',
            name: 'Leaf',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[
              FileNode(
                details: NodeDetails.byId(id: 'existing_1', level: 0),
                content: '',
                name: 'Existing 1',
              ),
              FileNode(
                details: NodeDetails.byId(id: 'existing_2', level: 0),
                content: '',
                name: 'Existing 2',
              ),
            ],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer target = _findContainer(root, 'target');
      final Node leaf = root.firstWhere((Node n) => n.id == 'leaf');

      // Move leafNode into targetContainer at index 0
      final bool moved = root.moveNode(leaf, target, insertIndex: 0);
      expect(moved, isTrue);

      expect(target.length, 3);
      expect(target.first.id, 'leaf');
      expect(target.first.level, 2);
      expect(target.elementAt(1).id, 'existing_1');
      expect(target.elementAt(2).id, 'existing_2');
    });

    test('should notify NodeMoveChange when moving node', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'leaf', level: 0),
            content: '',
            name: 'Leaf',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer target = _findContainer(root, 'target');
      final Node leaf = root.firstWhere((Node n) => n.id == 'leaf');

      NodeChange? change;
      root
        ..attachListener((NodeChange inChange) {
          change = inChange;
        })
        ..moveNode(leaf, target);

      expect(change, isNotNull);
      expect(change, isA<NodeMoveChange>());
      final NodeMoveChange moveChange = change as NodeMoveChange;
      expect(moveChange.to.id, target.id);
      expect(moveChange.from!.id, root.id);
      expect(moveChange.index, 0);
    });

    test('should not move node with invalid index', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'leaf', level: 0),
            content: '',
            name: 'Leaf',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer target = _findContainer(root, 'target');
      final Node leaf = root.firstWhere((Node n) => n.id == 'leaf')
        // Unlink the node first to make its index invalid (-1)
        ..unlink();
      final bool moved = root.moveNode(leaf, target);
      expect(moved, isFalse);
    });

    test('should return false for negative insertIndex', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'leaf', level: 0),
            content: '',
            name: 'Leaf',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer target = _findContainer(root, 'target');
      final Node leaf = root.firstWhere((Node n) => n.id == 'leaf');

      final bool moved = root.moveNode(leaf, target, insertIndex: -1);
      expect(moved, isFalse);
    });
  });

  group('moveNodeById', () {
    test('should move node by id and re-depth descendants', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          DirectoryNode(
            details: NodeDetails.byId(id: 'to_move', level: 0),
            children: <Node>[
              FileNode(
                details: NodeDetails.byId(id: 'file_in_dir', level: 0),
                content: '',
                name: 'File in dir',
              ),
            ],
            name: 'Dir to Move',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer target = _findContainer(root, 'target');

      final bool moved = root.moveNodeById('to_move', target);
      expect(moved, isTrue);

      expect(root.length, 1);
      expect(root.first.id, 'target');
      expect(target.length, 1);
      expect(target.first.id, 'to_move');
      expect(target.first.level, 2);

      // Child should be re-depthed
      final NodeContainer movedDir = target.first as NodeContainer;
      expect(movedDir.first.id, 'file_in_dir');
      expect(movedDir.first.level, 3);
    });

    test('should return false when id not found', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer target = _findContainer(root, 'target');
      final bool moved = root.moveNodeById('non_existent', target);
      expect(moved, isFalse);
    });
  });

  group('canMoveTo constraints', () {
    test('should prevent moving container into its own descendants', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          DirectoryNode(
            details: NodeDetails.byId(id: 'outer', level: 0),
            children: <Node>[
              DirectoryNode(
                details: NodeDetails.byId(id: 'inner', level: 0),
                children: <Node>[],
                name: 'Inner Dir',
              ),
            ],
            name: 'Outer Dir',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer outer = _findContainer(root, 'outer');
      final NodeContainer inner = _findContainer(root, 'inner');

      // outerDir should NOT be movable into innerDir (its own descendant)
      expect(
        Node.canMoveTo(
            node: outer, target: inner, position: DropPosition.inside),
        isFalse,
      );
    });

    test('should prevent moving node into a leaf node', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          DirectoryNode(
            details: NodeDetails.byId(id: 'dir', level: 0),
            children: <Node>[
              FileNode(
                details: NodeDetails.byId(id: 'leaf', level: 0),
                content: '',
                name: 'Leaf',
              ),
            ],
            name: 'Dir',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer dir = _findContainer(root, 'dir');
      final Node leaf = dir.firstWhere((Node n) => n.id == 'leaf');

      // dirNode should NOT be movable INTO leafNode
      expect(
        Node.canMoveTo(node: dir, target: leaf, position: DropPosition.inside),
        isFalse,
      );
    });

    test('should prevent moving a node to itself', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          DirectoryNode(
            details: NodeDetails.byId(id: 'dir', level: 0),
            children: <Node>[],
            name: 'Dir',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer dir = _findContainer(root, 'dir');
      expect(Node.canMoveTo(node: dir, target: dir), isFalse);
    });

    test('should prevent moving adjacent same-level nodes', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'node1', level: 0),
            content: '',
            name: 'Node 1',
          ),
          FileNode(
            details: NodeDetails.byId(id: 'node2', level: 0),
            content: '',
            name: 'Node 2',
          ),
        ],
        name: 'Root',
      );

      final Node n1 = root.firstWhere((Node n) => n.id == 'node1');
      final Node n2 = root.firstWhere((Node n) => n.id == 'node2');

      // n1 is above n2 → whenAbove blocked, whenBelow allowed
      expect(
        Node.canMoveTo(
          node: n1,
          target: n2,
          position: DropPosition.above,
        ),
        isFalse,
      );
      expect(
        Node.canMoveTo(
          node: n1,
          target: n2,
          position: DropPosition.below,
        ),
        isTrue,
      );

      // n2 is below n1 → whenBelow blocked, whenAbove allowed
      expect(
        Node.canMoveTo(
          node: n2,
          target: n1,
          position: DropPosition.below,
        ),
        isFalse,
      );
      expect(
        Node.canMoveTo(
          node: n2,
          target: n1,
          position: DropPosition.above,
        ),
        isTrue,
      );
    });

    test('should allow moving node between different containers', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'leaf', level: 0),
            content: '',
            name: 'Leaf',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'target', level: 0),
            children: <Node>[],
            name: 'Target',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer target = _findContainer(root, 'target');
      final Node leaf = root.firstWhere((Node n) => n.id == 'leaf');

      expect(
          Node.canMoveTo(
              node: leaf, target: target, position: DropPosition.inside),
          isTrue);
    });
  });

  group('verticalMove with moveNode', () {
    test('should re-depth children when moving container between siblings', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          DirectoryNode(
            details: NodeDetails.byId(id: 'first', level: 0),
            children: <Node>[],
            name: 'First Dir',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'second', level: 0),
            children: <Node>[
              DirectoryNode(
                details: NodeDetails.byId(id: 'inner', level: 0),
                children: <Node>[
                  FileNode(
                    details: NodeDetails.byId(id: 'deep_file', level: 0),
                    content: '',
                    name: 'Deep File',
                  ),
                ],
                name: 'Inner Dir',
              ),
            ],
            name: 'Second Dir',
          ),
        ],
        name: 'Root',
      );

      final NodeContainer firstDir = _findContainer(root, 'first');
      final NodeContainer secondDir = _findContainer(root, 'second');
      final NodeContainer innerDir = _findContainer(root, 'inner');

      // Verify can move
      final bool canMove = Node.canMoveTo(
          node: innerDir, target: firstDir, position: DropPosition.inside);
      expect(canMove, isTrue);

      // Move innerDir from secondDir to firstDir
      final bool moved = secondDir.moveNode(innerDir, firstDir);
      expect(moved, isTrue);

      // Verify firstDir has innerDir at level 2 (firstDir is at level 1)
      expect(firstDir.length, 1);
      expect(firstDir.first.id, 'inner');
      expect(firstDir.first.level, 2);

      // Verify innerDir's children are at level 3
      final NodeContainer movedInner = firstDir.first as NodeContainer;
      expect(movedInner.first.id, 'deep_file');
      expect(movedInner.first.level, 3);
    });
  });

  group('canMoveTo position-aware', () {
    test('should detect no-op when appending and node is already last', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'a', level: 0),
            content: '',
            name: 'A',
          ),
          FileNode(
            details: NodeDetails.byId(id: 'b', level: 0),
            content: '',
            name: 'B',
          ),
        ],
        name: 'Root',
      );

      final Node b = root.firstWhere((Node n) => n.id == 'b');

      // Appending B when it's already last should be blocked
      expect(
        Node.canMoveTo(node: b, target: root, position: DropPosition.inside),
        isFalse,
      );
    });

    test('should allow moving to end of same owner via inside', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'a', level: 0),
            content: '',
            name: 'A',
          ),
          FileNode(
            details: NodeDetails.byId(id: 'b', level: 0),
            content: '',
            name: 'B',
          ),
          FileNode(
            details: NodeDetails.byId(id: 'c', level: 0),
            content: '',
            name: 'C',
          ),
        ],
        name: 'Root',
      );

      final Node a = root.firstWhere((Node n) => n.id == 'a');

      // position: inside with insertIndex=3 appends A to end → real move
      expect(
        Node.canMoveTo(
            node: a,
            target: root,
            position: DropPosition.inside,
            insertIndex: 3),
        isTrue,
      );
    });

    test('should allow adjacent move when position differs from current', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'a', level: 0),
            content: '',
            name: 'A',
          ),
          FileNode(
            details: NodeDetails.byId(id: 'b', level: 0),
            content: '',
            name: 'B',
          ),
        ],
        name: 'Root',
      );

      final Node a = root.firstWhere((Node n) => n.id == 'a');
      final Node b = root.firstWhere((Node n) => n.id == 'b');

      // A and B are adjacent: [A(0), B(1)]
      // A whenBelow B → real move (A goes from 0 to 1)
      expect(
        Node.canMoveTo(node: a, target: b, position: DropPosition.below),
        isTrue,
      );

      // B whenAbove A → real move (B goes from 1 to 0)
      expect(
        Node.canMoveTo(node: b, target: a, position: DropPosition.above),
        isTrue,
      );
    });

    test('should block self-move regardless of position', () {
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'a', level: 0),
            content: '',
            name: 'A',
          ),
        ],
        name: 'Root',
      );

      final Node a = root.firstWhere((Node n) => n.id == 'a');

      // Self-move is always blocked by check 1
      expect(
        Node.canMoveTo(node: a, target: a, position: DropPosition.above),
        isFalse,
      );
    });

    test('should respect maxDepthLevel with off-by-one fix', () {
      // root(0) → target(1). Moving into target puts node at level 2.
      // maxDepthLevel=2 means level 2 is allowed, level 3 is not.
      final DirectoryNode root = DirectoryNode(
        details: NodeDetails.zero(),
        children: <Node>[
          FileNode(
            details: NodeDetails.byId(id: 'leaf', level: 0),
            content: '',
            name: 'Leaf',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'shallow', level: 0),
            children: <Node>[],
            name: 'Shallow',
          ),
          DirectoryNode(
            details: NodeDetails.byId(id: 'deep', level: 0),
            children: <Node>[
              FileNode(
                details: NodeDetails.byId(id: 'nested', level: 0),
                content: '',
                name: 'Nested',
              ),
            ],
            name: 'Deep',
          ),
        ],
        name: 'Root',
      );

      final Node leaf = root.firstWhere((Node n) => n.id == 'leaf');
      final NodeContainer shallow = _findContainer(root, 'shallow');
      final NodeContainer deep = _findContainer(root, 'deep');

      // shallow is at level 1, moving leaf into it → leaf at level 2.
      // maxDepthLevel=2 → allowed
      expect(
        Node.canMoveTo(
            node: leaf,
            target: shallow,
            position: DropPosition.inside,
            maxDepthLevel: 2),
        isTrue,
      );

      // deep is at level 1, but already has a child at level 2.
      // Moving leaf into deep → leaf at level 2. Still allowed with maxDepth=2.
      expect(
        Node.canMoveTo(
            node: leaf,
            target: deep,
            position: DropPosition.inside,
            maxDepthLevel: 2),
        isTrue,
      );

      // maxDepthLevel=1 → moving into shallow (level 1) puts leaf at level 2 > 1 → blocked
      expect(
        Node.canMoveTo(
            node: leaf,
            target: shallow,
            position: DropPosition.inside,
            maxDepthLevel: 1),
        isFalse,
      );
    });
  });
}
