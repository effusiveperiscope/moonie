import 'package:flutter/material.dart';
import 'package:moonie/modules/rp_context.dart';

Map<BaseRole, List<String>> suggestedSchema = {
  BaseRole.character: ['Appearance', 'Personality', 'Backstory', 'Abilities'],
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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.node.name);
    descriptionController =
        TextEditingController(text: widget.node.description);
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: descriptionController,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  onChanged: (value) => setState(() {
                    widget.node.description = value;
                  }),
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text("Meta description"),
                      floatingLabelBehavior: FloatingLabelBehavior.always),
                ),
              ),
            ],
          ),
          const Divider(),
          const Text('Attributes'),
        ]),
      ),
    );
  }
}
