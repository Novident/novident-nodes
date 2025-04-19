import 'package:flutter_test/flutter_test.dart';
import 'package:novident_nodes/src/nodes/node.dart';
import 'package:novident_nodes/src/nodes/node_container.dart';
import 'package:novident_nodes/src/nodes/node_details.dart';

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

  test('should notify until its parent', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 1),
          content: '',
          name: 'File 1',
        ),
      ],
      name: 'Dir',
    );
    expect(node.first.owner, node);
    final StringBuffer buffer = StringBuffer();
    node.addListener(() {
      buffer.write('Directory');
    });
    node.first.addListener(() {
      buffer.writeln('${' ' * (node.first.level + 1)}File 1');
    });
    node.first.notify(propagate: true);
    expect(buffer.toString().split('\n').reversed.join('\n'),
        'Directory\n  File 1');
  });

  test('should return a correct json', () {
    // The level will be updated automatically during Node build
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.byId(id: 'test 1', level: 0),
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
      ],
      name: 'Dir',
    );
    expect(node.toJson(), <String, dynamic>{
      'details': <String, dynamic>{
        'id': 'test 1',
        'level': 0,
        'owner': null,
        'value': null,
      },
      'name': 'Dir',
      'isExpanded': false,
      'children': <Map<String, dynamic>>[
        // children
        <String, dynamic>{
          'details': <String, dynamic>{
            'id': 'test 2',
            'level': 1,
            'owner': 'test 1',
            'value': null,
          },
          'name': 'Dir 2',
          'isExpanded': false,
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'details': <String, dynamic>{
                'id': 'test 3',
                'level': 2,
                'owner': 'test 2',
                'value': null,
              },
              'content': '',
              'name': 'File 2',
            },
          ],
        },
      ],
    });
  });
}

extension on Node {
  FileNode get castToFile => this as FileNode;
  DirectoryNode get castToDir => this as DirectoryNode;
  NodeContainer get castToContainer => this as NodeContainer;
}
