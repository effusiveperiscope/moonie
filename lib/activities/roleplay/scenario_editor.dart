import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moonie/activities/roleplay/chat_entities.dart';
import 'package:moonie/activities/roleplay/node_select.dart';
import 'package:moonie/activities/roleplay/scenario_entities.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/utils.dart';
import 'package:moonie/widgets/croppable_image2.dart';
import 'package:moonie/widgets/prompt_edit.dart';
import 'package:provider/provider.dart';

enum _ScenarioEditorTab { slots, prompts, greetings }

class ScenarioEditor extends StatefulWidget {
  final Scenario scenario;
  final MoonieCore core;
  const ScenarioEditor(this.scenario, this.core, {super.key});

  @override
  State<ScenarioEditor> createState() => _ScenarioEditorState();
}

class _ScenarioEditorState extends State<ScenarioEditor> {
  late final TextEditingController nameController, descriptionController;
  late final CroppableImageController croppableImageController;
  Set<_ScenarioEditorTab> selectedTabs = {_ScenarioEditorTab.slots};

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ChangeNotifierProvider.value(
            value: widget.scenario,
            child: Consumer<Scenario>(builder: (context, scenario, _) {
              return Column(
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
                                "Modified: ${formatDateTime1(widget.scenario.modified != null ? widget.scenario.modified! : widget.scenario.created!)}"),
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
                            SegmentedButton(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(
                                  label: Text('Slots'),
                                  value: _ScenarioEditorTab.slots,
                                ),
                                ButtonSegment(
                                  label: Text('Prompt'),
                                  value: _ScenarioEditorTab.prompts,
                                ),
                                ButtonSegment(
                                    value: _ScenarioEditorTab.greetings,
                                    label: Text('Greetings')),
                              ],
                              style: const ButtonStyle(
                                  textStyle: WidgetStatePropertyAll(
                                TextStyle(fontSize: 12),
                              )),
                              selected: selectedTabs,
                              onSelectionChanged: (s) {
                                setState(() {
                                  selectedTabs = s;
                                });
                              },
                            )
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
                  if (selectedTabs.contains(_ScenarioEditorTab.slots))
                    SlotsPage(widget.core, scenario: widget.scenario),
                  if (selectedTabs.contains(_ScenarioEditorTab.prompts))
                    PromptPage(widget.scenario, widget.core),
                  if (selectedTabs.contains(_ScenarioEditorTab.greetings))
                    GreetingsPage(widget.scenario, widget.core)
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SlotsPage extends StatelessWidget {
  final MoonieCore core;
  final Scenario scenario;
  const SlotsPage(this.core, {super.key, required this.scenario});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Map<BaseRole, List<NodeSlot>> slotsByRole = {};

    scenario.getSlots().forEach((slot) {
      slotsByRole.putIfAbsent(slot.getRole(), () => []).add(slot);
    });
    for (final role in BaseRole.values) {
      slotsByRole.putIfAbsent(role, () => []);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Row(
        //   children: [
        //     Text('Slots', style: TextStyle(fontWeight: FontWeight.bold)),
        //     SizedBox(width: 8),
        //   ],
        // ),
        for (final role in BaseRole.values)
          Column(
            children: [
              Card(
                color: colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Text(baseRoleNames[role]!),
                      const Spacer(),
                      SizedBox(
                        height: 24,
                        child: IconButton.outlined(
                          icon: const Icon(Icons.add),
                          iconSize: 24,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) {
                                return AddSlotDialog(
                                    role: role, scenario: scenario);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              for (final slot in slotsByRole[role]!)
                SlotDisplayWidget(slot, scenario, core),
            ],
          )
      ],
    );
  }
}

class AddSlotDialog extends StatefulWidget {
  const AddSlotDialog({super.key, required this.role, required this.scenario});
  final BaseRole role;
  final Scenario scenario;

  @override
  State<AddSlotDialog> createState() => _AddSlotDialogState();
}

class _AddSlotDialogState extends State<AddSlotDialog> {
  String slotTag = '';

  @override
  Widget build(BuildContext context) {
    final test = widget.scenario.testTagOk(slotTag);
    return AlertDialog(
      title: Text('Add slot (role: ${baseRoleNames[widget.role]!})'),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
                hintText: 'Tag', border: OutlineInputBorder()),
            onChanged: (value) {
              setState(() {
                slotTag = value;
              });
            },
          ),
          if (!test.$2 && slotTag.isNotEmpty)
            Text(test.$1!, style: const TextStyle(color: Colors.red)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (test.$2)
              ? () {
                  if (slotTag.isNotEmpty) {
                    widget.scenario.createSlot(slotTag, widget.role);
                    Navigator.of(context).pop();
                  }
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class SlotDisplayWidget extends StatefulWidget {
  final NodeSlot slot;
  final Scenario scenario;
  final MoonieCore core;
  const SlotDisplayWidget(this.slot, this.scenario, this.core, {super.key});

  @override
  State<SlotDisplayWidget> createState() => _SlotDisplayWidgetState();
}

class _SlotDisplayWidgetState extends State<SlotDisplayWidget> {
  late final TextEditingController slotTagController;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    slotTagController = TextEditingController(text: widget.slot.tag);
  }

  @override
  void dispose() {
    super.dispose();
    slotTagController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Card(
          child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: SizedBox(
                width: 140,
                child: TextField(
                  controller: slotTagController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Tag',
                    errorText: (errorMessage.isNotEmpty) ? errorMessage : null,
                    errorMaxLines: 2,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final test = widget.scenario
                        .testTagOk(value, oldTag: widget.slot.tag);
                    if (!test.$2) {
                      return setState(() {
                        errorMessage = test.$1!;
                      });
                    }
                    setState(() {
                      widget.slot.tag = value;
                      errorMessage = '';
                    });
                  },
                ),
              ),
            ),
            Expanded(child: FillEditor(widget.slot, widget.core)),
            IconButton.outlined(
              icon: const Icon(Icons.delete),
              iconSize: 24,
              visualDensity: VisualDensity.compact,
              onPressed: () {
                deleteSlotDialog(context);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      )),
    );
  }

  Future<void> deleteSlotDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete slot'),
          content: Text(
              'Are you sure you want to delete this slot (${widget.slot.tag})?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.scenario.removeSlot(widget.slot);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class FillEditor extends StatelessWidget {
  final NodeSlot slot;
  final String noFillText, hasFillText;
  final MoonieCore core;
  const FillEditor(this.slot, this.core,
      {super.key,
      this.noFillText = 'No default fill',
      this.hasFillText = 'Default fills'});

  @override
  Widget build(BuildContext context) {
    // What --can't-- I use as a label inside an ActionChip???
    return ChangeNotifierProvider.value(
      value: slot,
      child: Consumer<NodeSlot>(builder: (context, slot, _) {
        final fill = slot.defaultFill.target;
        return ActionChip(
          label: (fill == null)
              ? Text(noFillText)
              : Column(
                  children: [
                    Text(
                      hasFillText,
                      style: const TextStyle(fontSize: 12),
                    ),
                    for (final node in fill.nodes)
                      Row(
                        children: [
                          Text(node.name),
                          const Spacer(),
                          CircleAvatar(
                              radius: 12,
                              backgroundImage: (node.imagePath.isNotEmpty)
                                  ? FileImage(File(node.imagePath))
                                  : null)
                        ],
                      ),
                  ],
                ),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return NodeSelectPage(core, slot);
            }));
          },
        );
      }),
    );
  }
}

class PromptPage extends StatefulWidget {
  final MoonieCore core;
  final Scenario scenario;
  const PromptPage(this.scenario, this.core, {super.key});

  @override
  State<PromptPage> createState() => _PromptPageState();
}

class _PromptPageState extends State<PromptPage> {
  late final PromptEditingController promptController;

  @override
  void initState() {
    super.initState();
    promptController = PromptEditingController(
      text: widget.scenario.prompt,
      knownTags: widget.scenario.knownTags(),
      matchedTagStyle: const TextStyle(color: Colors.green),
      unmatchedTagStyle: const TextStyle(color: Colors.red),
      reservedTagStyle: const TextStyle(color: Colors.cyan),
    );
  }

  @override
  void dispose() {
    super.dispose();
    promptController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 16,
          child: ChangeNotifierProvider.value(
              value: promptController,
              child: Consumer<PromptEditingController>(
                  builder: (context, controller, _) {
                return (controller.unmatchedTags.isNotEmpty)
                    ? Text(
                        'Unmatched tags: ${Set.from(controller.unmatchedTags).join(', ')}',
                        style: const TextStyle(color: Colors.red, fontSize: 10),
                      )
                    : const Text('', style: TextStyle(fontSize: 10));
              })),
        ),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: promptController,
              decoration: InputDecoration(
                labelText: 'Prompt',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                errorText: (promptController.errorMessage.isNotEmpty)
                    ? promptController.errorMessage
                    : null,
                border: const OutlineInputBorder(),
              ),
              maxLines: null,
              minLines: 9,
              style: const TextStyle(
                fontSize: 14,
              ),
              onChanged: (value) {
                widget.scenario.setPrompt(value);
              },
            )),
      ],
    );
  }
}

class GreetingsPage extends StatefulWidget {
  final Scenario scenario;
  final MoonieCore core;
  const GreetingsPage(this.scenario, this.core, {super.key});

  @override
  State<GreetingsPage> createState() => _GreetingsPageState();
}

class _GreetingsPageState extends State<GreetingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ActionChip(
                label: const Text("Add greeting"),
                avatar: const Icon(Icons.add),
                onPressed: () {
                  widget.scenario.createGreeting();
                }),
          ],
        ),
        for (final greeting in widget.scenario.greetings)
          GreetingWidget(widget.scenario, greeting)
      ],
    );
  }
}

class GreetingWidget extends StatefulWidget {
  final Scenario scenario;
  final RPChatMessage greeting;
  const GreetingWidget(this.scenario, this.greeting, {super.key});

  @override
  State<GreetingWidget> createState() => _GreetingWidgetState();
}

class _GreetingWidgetState extends State<GreetingWidget> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.greeting,
      child: Consumer<RPChatMessage>(builder: (context, message, _) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      message.text.isEmpty ? '(empty)' : message.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  ActionChip(
                    label: const Text("Edit"),
                    avatar: const Icon(Icons.edit),
                    onPressed: () {
                      editGreetingDialog(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                      label: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        deleteGreetingDialog(context);
                      }),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Future editGreetingDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          String greetingText = widget.greeting.text;
          TextEditingController greetingController = TextEditingController(
            text: greetingText,
          );
          return AlertDialog(
              title: const Text('Edit greeting'),
              content: SizedBox(
                width: 400,
                child: TextField(
                  controller: greetingController,
                  decoration: const InputDecoration(
                    labelText: 'Greeting',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  minLines: 9,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  onChanged: (value) {
                    greetingText = value;
                    widget.greeting.text = greetingText;
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Exit'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ]);
        });
  }

  Future<dynamic> deleteGreetingDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete greeting: ${widget.greeting.text.substring(0, min(20, widget.greeting.text.length))}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                widget.scenario.deleteGreeting(widget.greeting);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
