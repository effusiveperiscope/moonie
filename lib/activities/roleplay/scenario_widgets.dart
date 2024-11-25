import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fw;
import 'package:moonie/activities/commons.dart';
import 'package:moonie/activities/roleplay/scenario_editor.dart';
import 'package:moonie/activities/roleplay/scenario_entities.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';

class ScenarioBrowser extends StatefulWidget {
  final MoonieCore core;
  const ScenarioBrowser(this.core, {super.key});

  @override
  State<ScenarioBrowser> createState() => _ScenarioBrowserState();
}

class _ScenarioBrowserState extends State<ScenarioBrowser> {
  final sort = ValueNotifier(SortMode.alphabetical);
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void addScenarioDialog(final MoonieCore core) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String scenarioName = '', scenarioDescription = '';
        bool doDefaults = true;
        return AlertDialog(
          title: const Text('Add scenario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                    hintText: "Scenario name", border: OutlineInputBorder()),
                onChanged: (value) {
                  scenarioName = value;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                    hintText: "Scenario meta description",
                    border: OutlineInputBorder()),
                maxLines: 5,
                onChanged: (value) {
                  scenarioDescription = value;
                },
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                  value: doDefaults,
                  onChanged: (value) {
                    setState(() {
                      doDefaults = value!;
                    });
                  },
                  title: const Text('Provide default slots/prompt/greeting'))
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
                final s = core.rpContext.createScenario(
                  scenarioName,
                  description: scenarioDescription,
                );
                Navigator.of(context).pop();
                if (doDefaults) {
                  s.doDefaults();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              ActionChip(
                  label: const Text('Scenario'),
                  onPressed: () {
                    addScenarioDialog(widget.core);
                  },
                  avatar: const Icon(Icons.add)),
              const SizedBox(width: 8),
              SizedBox(
                width: 130,
                child: DropdownMenu(
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(
                        label: 'A-Z', value: SortMode.alphabetical),
                    DropdownMenuEntry(
                        label: 'Z-A', value: SortMode.reverseAlphabetical),
                    DropdownMenuEntry(
                        label: 'created (desc)', value: SortMode.created),
                    DropdownMenuEntry(
                        label: 'created (asc)', value: SortMode.reverseCreated),
                    DropdownMenuEntry(
                        label: 'modified (desc)', value: SortMode.modified),
                    DropdownMenuEntry(
                        label: 'modified (asc)',
                        value: SortMode.reverseModified),
                  ],
                  requestFocusOnTap: false,
                  textStyle: const TextStyle(
                    fontSize: 12,
                  ),
                  initialSelection: sort.value,
                  inputDecorationTheme:
                      const InputDecorationTheme(isDense: true),
                  label: const Text("Sort"),
                  trailingIcon: const Icon(Icons.sort),
                  onSelected: (v) {
                    sort.value = v!;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Search (fuzzy)'),
                      isDense: true),
                ),
              ),
            ],
          ),
          const Divider(),
          MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: sort),
                ChangeNotifierProvider.value(value: _searchController),
                ChangeNotifierProvider.value(value: widget.core.rpContext),
              ],
              child: Consumer3<ValueNotifier<SortMode>, TextEditingController,
                  RPContext>(builder: (context, sort, search, ctx, _) {
                final scenarios = ctx.queryScenarios();
                if (search.value.text.isNotEmpty) {
                  final extraction = fw.extractAll(
                    query: search.value.text,
                    choices: scenarios,
                    getter: (s) => s.name,
                    cutoff: 60,
                  );
                  scenarios.clear();
                  scenarios.addAll(extraction.map((e) => e.choice));
                }
                switch (sort.value) {
                  case SortMode.alphabetical:
                    scenarios.sort((a, b) => a.name.compareTo(b.name));
                  case SortMode.reverseAlphabetical:
                    scenarios.sort((a, b) => b.name.compareTo(a.name));
                  case SortMode.created:
                    scenarios.sort((a, b) {
                      if (a.created == null && b.created == null) return 0;
                      if (a.created == null) return 1;
                      if (b.created == null) return -1;
                      return a.created!.compareTo(b.created!);
                    });
                  case SortMode.reverseCreated:
                    scenarios.sort((a, b) {
                      if (a.created == null && b.created == null) return 0;
                      if (a.created == null) return 1;
                      if (b.created == null) return -1;
                      return b.created!.compareTo(a.created!);
                    });
                  case SortMode.modified:
                    scenarios.sort((a, b) {
                      if (a.modified == null && b.modified == null) return 0;
                      if (a.modified == null) return 1;
                      if (b.modified == null) return -1;
                      return a.modified!.compareTo(b.modified!);
                    });
                  case SortMode.reverseModified:
                    scenarios.sort((a, b) {
                      if (a.modified == null && b.modified == null) return 0;
                      if (a.modified == null) return 1;
                      if (b.modified == null) return -1;
                      return b.modified!.compareTo(a.modified!);
                    });
                }

                return Column(
                  children: [
                    for (final s in scenarios)
                      ScenarioDisplayWidget(s, widget.core),
                  ],
                );
              }))
        ],
      ),
    );
  }
}

class ScenarioDisplayWidget extends StatelessWidget {
  final Scenario scenario;
  final MoonieCore core;
  const ScenarioDisplayWidget(this.scenario, this.core, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider.value(
      value: scenario,
      child: Consumer<Scenario>(builder: (context, scenario, _) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Card(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scenario.name),
                      Text(
                        scenario.description ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${formatDateTime1(scenario.created!)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      Text(
                        'Modified: ${formatDateTime1(scenario.modified != null ? scenario.modified! : scenario.created!)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton.outlined(
                  onPressed: () {
                    throw UnimplementedError();
                  },
                  icon: const Icon(Icons.chat),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ChangeNotifierProvider.value(
                            value: scenario,
                            child: ScenarioEditor(scenario, core))));
                  },
                  icon: const Icon(Icons.edit),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: () {
                    scenario.copy();
                  },
                  icon: const Icon(Icons.copy),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 16),
                deleteButton(context, scenario),
                const SizedBox(width: 16),
                SizedBox(
                    width: 48,
                    height: 72,
                    child: ((scenario.imagePath != null)
                        ? Image(image: FileImage(File(scenario.imagePath!)))
                        : Container(color: colorScheme.onSecondary))),
                const SizedBox(width: 16),
              ],
            ),
          ),
        );
      }),
    );
  }

  IconButton deleteButton(BuildContext context, Scenario scenario) {
    final RPContext ctx = core.rpContext;
    return IconButton.outlined(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete scenario'),
              content:
                  const Text('Are you sure you want to delete this scenario?'),
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
                    ctx.deleteScenario(scenario);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      icon: const Icon(Icons.delete),
      visualDensity: VisualDensity.compact,
    );
  }
}
