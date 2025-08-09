import 'package:flutter_test/flutter_test.dart';
import 'package:novident_nodes/novident_nodes.dart';

import 'test_nodes/directory_node.dart';
import 'test_nodes/file_node.dart';

void main() {
  test('should insert node into correctly', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      name: 'Dir',
    )..insert(
        0,
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 0),
          content: '',
          name: 'File 1',
        ),
      );
    expect(node.length, 1);
    expect(node.first.id, 'test');
    expect(node.first.level, 1);
  });

  test('should get correct path', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        DirectoryNode(
          details: NodeDetails.byId(id: 'test', level: 0),
          children: <Node>[],
          name: 'First Dir',
        ),
        DirectoryNode(
          details: NodeDetails.byId(id: 'test 2', level: 0),
          children: <Node>[
            FileNode(
              details: NodeDetails.byId(id: 'test 3', level: 0),
              content: '',
              name: 'File 2',
            ),
            DirectoryNode(
              details: NodeDetails.byId(id: 'test 4', level: 0),
              children: <Node>[
                FileNode(
                  details: NodeDetails.byId(id: 'test 5', level: 0),
                  content: '',
                  name: 'File 3',
                ),
                FileNode(
                  details: NodeDetails.byId(id: 'test 6', level: 0),
                  content: '',
                  name: 'File 4',
                ),
                FileNode(
                  details: NodeDetails.byId(id: 'test 7', level: 0),
                  content: '',
                  name: 'File 5',
                ),
              ],
              name: 'Dir 2',
            ),
          ],
          name: 'Dir 3',
        ),
      ],
      name: 'Dir',
    );
    expect(
        node.last.castToDir.last.castToDir.last.findNodePath(), <int>[1, 1, 2]);
  });

  test('should swap children', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        DirectoryNode(
          details: NodeDetails.byId(id: 'test', level: 0),
          children: <Node>[],
          name: 'First Dir',
        ),
        DirectoryNode(
          details: NodeDetails.byId(id: 'test 2', level: 0),
          children: <Node>[
            FileNode(
              details: NodeDetails.byId(id: 'test 3', level: 0),
              content: '',
              name: 'File 2',
            ),
          ],
          name: 'Dir 2',
        ),
      ],
      name: 'Dir',
    );
    bool moved = false;
    if (Node.canMoveTo(
      node: node.last,
      target: node,
      inside: true,
      isSwapMove: true, // avoid crash with same reinserting child check
    )) {
      expect(node.first.id, 'test');
      expect(node.last.id, 'test 2');
      node.last.verticalMove(allowMoveToAncestor: true, down: false);
      expect(node.first.id, 'test 2');
      expect(node.last.id, 'test');
      moved = true;
    }
    expect(moved, isTrue);
    moved = false;
    // you can also check using the real target
    if (Node.canMoveTo(
      node: node.first,
      target: node.last,
      inside: false,
    )) {
      expect(node.first.id, 'test 2');
      expect(node.last.id, 'test');
      node.last.verticalMove(allowMoveToAncestor: true, down: false);
      expect(node.first.id, 'test');
      expect(node.last.id, 'test 2');
      moved = true;
    }
    expect(moved, isTrue);
  });

  test('shouldn\'t insert a node into a leaf node', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        DirectoryNode(
          details: NodeDetails.byId(id: 'test 2', level: 0),
          children: <Node>[
            FileNode(
              details: NodeDetails.byId(id: 'test 3', level: 0),
              content: '',
              name: 'File 2',
            ),
          ],
          name: 'Dir 2',
        ),
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 0),
          content: '',
          name: 'File 1',
        ),
      ],
      name: 'Dir',
    );
    bool moved = false;
    // should maintain moved in false
    // since we can't move a node inside
    // a leaf
    if (Node.canMoveTo(
      node: node.first,
      target: node.last,
      inside: true,
      isSwapMove: true,
    )) {
      moved = Node.moveTo(
          node: node.first, newOwner: node.last.castToContainer, index: 1);
    }
    expect(moved, isFalse);
  });

  test('should return false always', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 0),
          content: '',
          name: 'File 1',
        ),
        DirectoryNode(
          details: NodeDetails.byId(id: 'test 2', level: 0),
          children: <Node>[
            FileNode(
              details: NodeDetails.byId(id: 'test 3', level: 0),
              content: '',
              name: 'File 2',
            ),
          ],
          name: 'Dir 2',
        ),
      ],
      name: 'Dir',
    );
    // cannot reinsert a child node into its parent
    expect(Node.canMoveTo(node: node.first, target: node), isFalse);
    // cannot be moved into a leaf node
    expect(
        Node.canMoveTo(
            node: node.last.castToContainer.last, target: node.first),
        isFalse);
    // cannot move a node into its own children
    expect(Node.canMoveTo(node: node, target: node.last), isFalse);
  });

  test('should move first child node into the last child one', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        // this node
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 0),
          content: '',
          name: 'File 1',
        ),
        DirectoryNode(
          details: NodeDetails.byId(id: 'test 2', level: 0),
          children: <Node>[
            FileNode(
              details: NodeDetails.byId(id: 'test 3', level: 0),
              content: '',
              name: 'File 2',
            ),
            // should be moved here
          ],
          name: 'Dir 2',
        ),
      ],
      name: 'Dir',
    );
    expect(node.last.id, 'test 2');
    expect(node.last.castToDir.first.castToFile.name, 'File 2');
    expect(node.last.castToDir.length, 1);
    final NodeContainer parent = node.elementAt(1) as NodeContainer;
    if (Node.canMoveTo(node: node.first, target: parent)) {
      final bool moved = Node.moveTo(
        node: node.first,
        newOwner: parent,
      );
      expect(moved, isTrue);
    }
    // root checks
    expect(node.first.id, 'test 2');
    expect(node.castToDir.length, 1);
    // children checks
    expect(node.first.castToDir.length, 2);
    expect(node.first.castToDir.first.id, 'test 3');
    expect(node.first.castToDir.last.id, 'test');
    expect(node.first.castToDir.last.castToFile.name, 'File 1');
    expect(node.first.castToDir.last.level, 2);
  });

  test('should update node into correctly', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 1),
          content: '',
          name: 'File 1',
        )
      ],
      name: 'Dir',
    );
    expect(node.length, 1);
    expect(node.firstOrNull, isNotNull);
    expect(node.first.owner, node);
    node[0] = FileNode(
      details: NodeDetails.byId(id: 'test', level: 0),
      content: '',
      name: 'File 3',
    );
    expect(node.first.castToFile.name, 'File 3');
  });

  test('should remove node into correctly', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 1),
          content: '',
          name: 'File 1',
        )
      ],
      name: 'Dir',
    );
    expect(node.first.owner, node);
    node.removeWhere(
      (Node node) => node.id == 'test',
    );
    expect(node.length, 0);
    expect(node.firstOrNull, isNull);
  });

  test('should remove node at index correctly', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 1),
          content: '',
          name: 'File 1',
        )
      ],
      name: 'Dir',
    );
    expect(node.first.owner, node);
    final Node removedNode = node.removeAt(0);
    expect(node.length, 0);
    expect(node.firstOrNull, isNull);
    expect(removedNode.id, 'test');
  });

  test('should add subNode correctly', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        DirectoryNode(
          details: NodeDetails.zero(),
          children: <Node>[],
          name: 'Dir 2',
        ),
      ],
      name: 'Dir',
    );
    expect(node.length, 1);
    expect(node.firstOrNull, isNotNull);
    expect(node.first.owner, node);
    node[0].castToContainer.add(
          FileNode(
            details: NodeDetails.byId(id: 'test 3', level: 0),
            content: '',
            name: 'File 2',
          ),
        );

    expect(node.first.castToDir.isNotEmpty, isTrue);
    expect(node.first.castToDir.first.castToFile.name, 'File 2');
    expect(node.first.castToDir.first.castToFile.id, 'test 3');
  });

  test('should found the node at list of paths passed', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        DirectoryNode(
          details: NodeDetails.zero(),
          children: <Node>[
            DirectoryNode(
              details: NodeDetails.byId(level: 0, id: 'testing path'),
              children: <Node>[],
              name: 'Dir 3',
            ),
          ],
          name: 'Dir 2',
        ),
      ],
      name: 'Dir',
    );
    expect(node.atPath(<int>[0, 0]), isNotNull);
    expect(node.atPath(<int>[0, 0])?.id, 'testing path');
  });

  test(
      'should break the path when found '
      'unexpected node while path is not empty yet', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        DirectoryNode(
          details: NodeDetails.zero(),
          children: <Node>[
            DirectoryNode(
              details: NodeDetails.byId(level: 0, id: 'testing path'),
              children: <Node>[
                FileNode(
                  details: NodeDetails.byId(level: 0, id: 'testing path 3'),
                  content: '',
                  name: 'file 4',
                ),
              ],
              name: 'Dir 3',
            ),
            FileNode(
              details: NodeDetails.byId(level: 0, id: 'testing path 2'),
              content: '',
              name: 'file 3',
            ),
          ],
          name: 'Dir 2',
        ),
      ],
      name: 'Dir',
    );
    expect(node.atPath(<int>[0, 1, 0]), isNull);
  });
}

extension on Node {
  FileNode get castToFile => this as FileNode;
  DirectoryNode get castToDir => this as DirectoryNode;
  NodeContainer get castToContainer => this as NodeContainer;
}
