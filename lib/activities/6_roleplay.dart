import 'package:flutter/material.dart';
import 'package:moonie/activities/2_chat2.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/activities/commons.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:provider/provider.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fw;

class RoleplayController {
  Chat2Controller chat2controller;

  final MoonieCore core;
  final RPContext ctx;
  RoleplayController(this.core)
      : chat2controller = Chat2Controller(core),
        ctx = core.rpContext {}
}

class RoleplayActivity extends ActivityWidget {
  const RoleplayActivity({required super.core, super.key})
      : super(
            name: 'Roleplay',
            description:
                'Traditional LLM-based roleplay with user/character interactions in scenarios');

  @override
  State<RoleplayActivity> createState() => _RoleplayState();
}

class _RoleplayState extends State<RoleplayActivity> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemBuilder: (context, index) => RoleplaySetup(widget.core),
    );
  }
}

class RoleplaySetup extends StatefulWidget {
  final MoonieCore core;
  const RoleplaySetup(this.core, {super.key});

  @override
  State<RoleplaySetup> createState() => _RoleplaySetupState();
}

class _RoleplaySetupState extends State<RoleplaySetup> {
  final sort = ValueNotifier(SortMode.alphabetical);
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    throw UnimplementedError();
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
                scenarios.sort();

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
                    for (final s in scenarios) Text(s.name),
                  ],
                );
              }))
        ],
      ),
    );
  }
}
