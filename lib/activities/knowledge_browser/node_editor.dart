import 'package:flutter/material.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/utils.dart';
import 'package:moonie/widgets/croppable_image.dart';
import 'package:provider/provider.dart';

Map<BaseRole, List<String>> suggestedSchema = {
  BaseRole.character: [
    'Appearance',
    'Personality',
    'Backstory',
    'Abilities',
    'Example Messages'
  ],
  BaseRole.item: ['Appearance', 'Description'],
  BaseRole.world: ['Setting', 'World Rules', 'Lore', 'Environment'],
};

class NodeEditor extends StatefulWidget {
  final BaseNode node;
  const NodeEditor({super.key, required this.node});

  @override
  State<NodeEditor> createState() => _NodeEditorState();
}

class _NodeEditorState extends State<NodeEditor> {
  late final TextEditingController nameController, descriptionController;
  late final CroppableImageController controller;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.node.name);
    descriptionController =
        TextEditingController(text: widget.node.description);
    controller = CroppableImageController(
        initialImage: widget.node.imagePath,
        onImagePicked: (imagePath) {
          widget.node.imagePath = imagePath;
        });
  }

  List<Widget> suggestedAttributes(BuildContext context) {
    final role = BaseRole.values[widget.node.role];
    final schema = suggestedSchema[role] ?? [];
    final attrs = widget.node.getAttributes();
    final ret = <Widget>[];
    for (final attr in schema) {
      if (!attrs.any((a) => a.name == attr)) {
        ret.add(Opacity(
          opacity: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ActionChip(
              label: Text('Suggested attribute: $attr'),
              avatar: const Icon(Icons.add),
              onPressed: () {
                showAddAttributeDialog(prefillName: attr);
              },
            ),
          ),
        ));
      }
    }

    return ret;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: nameController,
          onChanged: (value) => setState(
            () {
              widget.node.name = value;
            },
          ),
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              label: Text("Node name"),
              isDense: true),
        ),
        backgroundColor: colorScheme.surfaceContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ChangeNotifierProvider.value(
          value: widget.node,
          child: Consumer<BaseNode>(builder: (context, node, _) {
            return SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    'Created: ${(node.created == null) ? 'null' : formatDateTime1(node.created!)}'),
                                const SizedBox(height: 8),
                                Text(
                                    'Modified: ${(node.modified == null) ? 'null' : formatDateTime1(node.modified!)}'),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: descriptionController,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 3,
                                  onChanged: (value) => setState(() {
                                    node.description = value;
                                  }),
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      label: Text("Meta description"),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.always),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ActionChip(
                                      label: const Icon(Icons.add, size: 20),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        showAddAttributeDialog();
                                      },
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CroppableImage(
                            height: 200,
                            controller: controller,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const Text('Attributes:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(
                      height: 8,
                    ),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, index) =>
                          ChangeNotifierProvider.value(
                        key: Key(
                            node.getAttributeByPosition(index).id.toString()),
                        value: node,
                        child: AttributeDisplay(
                          attr: node.getAttributeByPosition(index),
                        ),
                      ),
                      itemCount: node.length(),
                      onReorder: (oldIndex, newIndex) => setState(() {
                        node.moveAttribute(oldIndex, newIndex);
                      }),
                    ),
                    if (node.getAttributes().isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No attributes'),
                      ),
                    ...suggestedAttributes(context)
                  ]),
            );
          }),
        ),
      ),
    );
  }

  Future<void> showAddAttributeDialog({String? prefillName}) async {
    final node = widget.node;
    final ctx = node.context!;

    String name =
        (prefillName != null) ? prefillName : ''; // Set initial text if needed
    TextEditingController nameController = TextEditingController(text: name);
    String content = ''; // Set initial text if needed

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Attribute'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(fontSize: 12),
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Attribute Name',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {
                  name = value;
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                  maxLines: 5,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Attribute Content',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {
                        content = value;
                      })),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (name.isNotEmpty && content.isNotEmpty) {
                  node.createAttribute(name, content);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    nameController.dispose();
  }
}

class AttributeDisplay extends StatefulWidget {
  final AttributeComponent attr;
  const AttributeDisplay({super.key, required this.attr});

  @override
  State<AttributeDisplay> createState() => _AttributeDisplayState();
}

class _AttributeDisplayState extends State<AttributeDisplay> {
  late final TextEditingController _nameController, _contentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.attr.name);
    _contentController = TextEditingController(text: widget.attr.content);
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _contentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = Provider.of<BaseNode>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: 2, right: 24, top: 2, bottom: 2),
          child: Row(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {
                    widget.attr.name = value;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {
                    widget.attr.content = value;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Icon(Icons.delete, size: 20),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(0),
                onPressed: () {
                  node.removeAttribute(widget.attr);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
