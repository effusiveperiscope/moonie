import 'package:flutter/material.dart';
import 'package:moonie/activities/roleplay/scenario_entities.dart';
import 'package:moonie/utils.dart';
import 'package:moonie/widgets/croppable_image2.dart';

class ScenarioEditor extends StatefulWidget {
  final Scenario scenario;
  const ScenarioEditor(this.scenario, {super.key});

  @override
  State<ScenarioEditor> createState() => _ScenarioEditorState();
}

class _ScenarioEditorState extends State<ScenarioEditor> {
  late final TextEditingController nameController, descriptionController;
  late final CroppableImageController croppableImageController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.scenario.name);
    descriptionController =
        TextEditingController(text: widget.scenario.description);
    croppableImageController = CroppableImageController(
        initialImage: widget.scenario.imagePath,
        onImagePicked: (imagePath) {
          widget.scenario.setImagePath(imagePath);
        });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: nameController,
          decoration: const InputDecoration(
              labelText: 'Scenario name',
              border: OutlineInputBorder(),
              isDense: true),
          onChanged: (value) {
            widget.scenario.setName(value);
          },
        ),
        backgroundColor: colorScheme.surfaceContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                          "Created: ${formatDateTime1(widget.scenario.created!)}"),
                      const SizedBox(height: 8),
                      Text(
                          "Modified: ${formatDateTime1(widget.scenario.modified!)}"),
                      const SizedBox(height: 16),
                      TextField(
                        maxLines: 5,
                        controller: descriptionController,
                        decoration: const InputDecoration(
                            labelText: 'Meta description',
                            border: OutlineInputBorder(),
                            isDense: true),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (value) {
                          widget.scenario.setDescription(value);
                        },
                      ),
                      const SizedBox(height: 8),
                      // SegmentedButton(segments: [
                      // ButtonSegment(
                      // label: const Text('Slots'),
                      // )
                      // ], selected: {})
                      // const Row(
                      // children: [
                      // ActionChip(
                      // label: Text('Add slot'),
                      // avatar: Icon(Icons.add),
                      // ),
                      // ],
                      // )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14.0),
                    // very important to get the pixel alignment ;)
                    child: CroppableImage2(
                      controller: croppableImageController,
                      aspectWidth: 2,
                      aspectHeight: 3,
                      height: 200,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Slots',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
