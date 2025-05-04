import 'package:flutter_test/flutter_test.dart';
import 'package:novident_nodes/novident_nodes.dart';

import 'test_nodes/directory_node.dart';
import 'test_nodes/file_node.dart';

void main() {
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

  test('should notify about NodeInsertion', () {
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
    expect(node.isNotEmpty, isTrue);
    expect(node.first.owner, node);
    NodeChange? change;
    node.attachNotifier((NodeChange inChange) {
      change = inChange;
    });
    expect(change, isNull);
    node.add(
      FileNode(
        details: NodeDetails.byId(id: 'test 2', level: 1),
        content: '',
        name: 'File 2',
      ),
    );
    expect(
      change,
      NodeInsertion(
        to: node,
        from: null,
        index: 1,
        newState: node.last,
        oldState: node.last,
      ),
    );
  });

  test('should notify about NodeDeletion', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 1),
          content: '',
          name: 'File 1',
        ),
        FileNode(
          details: NodeDetails.byId(id: 'test 2', level: 1),
          content: '',
          name: 'File 2',
        ),
      ],
      name: 'Dir',
    );
    expect(node.isNotEmpty, isTrue);
    NodeChange? change;
    node.attachNotifier((NodeChange inChange) {
      change = inChange;
    });
    expect(change, isNull);
    expect(node.last.details.id, 'test 2');
    final Node last = node.removeLast();
    expect(node.last.details.id, 'test');
    expect(last.details.id, 'test 2');
    expect(
      change,
      NodeDeletion(
        originalPosition: 1,
        sourceOwner: node,
        inNode: node,
        newState: last.clone()..details.detachOwner(),
        oldState: last,
      ),
    );
  });

  test('should notify about NodeMoveChange', () {
    final DirectoryNode node = DirectoryNode(
      details: NodeDetails.zero(),
      children: <Node>[
        FileNode(
          details: NodeDetails.byId(id: 'test', level: 1),
          content: '',
          name: 'File 1',
        ),
        FileNode(
          details: NodeDetails.byId(id: 'test 2', level: 1),
          content: '',
          name: 'File 2',
        ),
      ],
      name: 'Dir',
    );
    expect(node.isNotEmpty, isTrue);
    expect(node.first.details.id, 'test');
    expect(node.last.details.id, 'test 2');
    NodeChange? change;
    node.attachNotifier((NodeChange inChange) {
      change = inChange;
    });
    expect(change, isNull);
    node.last.verticalMove();
    expect(node.first.details.id, 'test 2');
    expect(node.last.details.id, 'test');
    expect(
      change,
      NodeMoveChange(
        index: 0,
        to: node,
        from: node,
        newState: node.first,
        oldState: node.first,
      ),
    );
    // now we try to move to down again
    node.first.verticalMove(down: true);
    expect(node.first.details.id, 'test');
    expect(node.last.details.id, 'test 2');
    expect(
      change,
      NodeMoveChange(
        index: 1,
        to: node,
        from: node,
        newState: node.last,
        oldState: node.last,
      ),
    );
  });
}
