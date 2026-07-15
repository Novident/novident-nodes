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

  test('shouldn\'t insert a node into a leaf node', () {
    final DirectoryNode root = DirectoryNode(
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
    expect(root.first.findNodePath(), <int>[0]);
    // should maintain moved in false
    // since we can't move a node inside
    // a leaf
    if (Node.canMoveTo(
      node: root.first,
      target: root.last,
      inside: true,
    )) {
      moved = Node.moveTo(
          node: root.first, newOwner: root.last.castToContainer, index: 1);
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
    final DirectoryNode root = DirectoryNode(
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
    expect(root.first.findNodePath(), <int>[0]);
    expect(root.first.id, equals('test'));
    expect(root.last.castToContainer.first.findNodePath(), <int>[1, 0]);
    expect(root.last.castToContainer.id, equals('test 2'));
    expect(root.last.id, 'test 2');
    expect(root.last.castToDir.first.castToFile.name, 'File 2');
    expect(root.last.castToDir.length, 1);
    NodeContainer parent = root.last.castToContainer;
    bool moved = false;
    if (Node.canMoveTo(node: root.first, target: parent)) {
      moved = Node.moveTo(
        node: root.first,
        newOwner: parent,
      );
      expect(moved, isTrue);
    }
    expect(root.first.id, equals('test 2'));
    expect(root.first.castToContainer.first.id, equals('test 3'));
    expect(root.first.castToContainer.first.findNodePath(), <int>[0, 0]);
    expect(root.first.castToContainer.last.id, equals('test'));
    expect(root.first.castToContainer.last.findNodePath(), <int>[0, 1]);
    // root checks
    expect(root.first.id, 'test 2');
    expect(root.castToDir.length, 1);
    // children checks
    expect(root.first.castToDir.length, 2);
    expect(root.first.castToDir.first.id, 'test 3');
    expect(root.first.castToDir.last.id, 'test');
    expect(root.first.castToDir.last.castToFile.name, 'File 1');
    expect(root.first.castToDir.last.level, 2);

    parent = root.last.castToContainer;
    moved = false;
    if (Node.canMoveTo(
      node: parent.first,
      target: parent,
      inside: true,
      // there are too many ways to know if a movement is a swap one
      isSwapMove: parent.first.nextSibling?.id == parent.last.id,
    )) {
      moved = Node.moveTo(
        node: parent.first,
        newOwner: parent,
        index: 1,
      );
    }
    expect(moved, isTrue);
    expect(root.first.id, equals('test 2'));
    expect(root.first.castToContainer.first.id, equals('test'));
    expect(root.first.castToContainer.first.findNodePath(), <int>[0, 0]);
    expect(root.first.castToContainer.last.id, equals('test 3'));
    expect(root.first.castToContainer.last.findNodePath(), <int>[0, 1]);
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
