import 'package:flutter_test/flutter_test.dart';
import 'package:novident_nodes/novident_nodes.dart';

import 'test_nodes/directory_node.dart';
import 'test_nodes/file_node.dart';

void main() {
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
