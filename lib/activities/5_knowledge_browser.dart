import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/activities/knowledge_browser/node_editor.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:provider/provider.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fw;

class KnowledgeBrowser extends ActivityWidget {
  const KnowledgeBrowser({super.key, required MoonieCore core})
      : super(
            core: core,
            name: "Knowledge Browser",
            description: "Browse and edit knowledge nodes");

  @override
  State<KnowledgeBrowser> createState() => _KnowledgeBrowserState();
}

enum _SortMode {
  alphabetical,
  reverseAlphabetical,
  created,
  reverseCreated,
  modified,
  reverseModified,
}

class _KnowledgeBrowserState extends State<KnowledgeBrowser> {
  BaseRole currentPage = BaseRole.character;
  final sort = ValueNotifier(_SortMode.alphabetical);
  final PageController _pageController =
      PageController(initialPage: BaseRole.character.index);
  final _searchController = TextEditingController();

  //ValueNotifier<> sort mode

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text("Node"),
                  onPressed: () {
                    addNodeDialog(widget.core);
                  },
                ),
                const SizedBox(width: 8),
                // ActionChip(
                // label: const Icon(Icons.delete, size: 20),
                // onPressed: () {},
                // ),
                const SizedBox(width: 8),
                // ActionChip(
                //   label: const Icon(Icons.sort, size: 20),
                //   onPressed: () {},
                // ),
                SizedBox(
                  width: 130,
                  child: DropdownMenu(
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(
                          label: 'A-Z', value: _SortMode.alphabetical),
                      DropdownMenuEntry(
                          label: 'Z-A', value: _SortMode.reverseAlphabetical),
                      DropdownMenuEntry(
                          label: 'created (desc)', value: _SortMode.created),
                      DropdownMenuEntry(
                          label: 'created (asc)',
                          value: _SortMode.reverseCreated),
                      DropdownMenuEntry(
                          label: 'modified (desc)', value: _SortMode.modified),
                      DropdownMenuEntry(
                          label: 'modified (asc)',
                          value: _SortMode.reverseModified),
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
                DropdownMenu(
                  width: 130,
                  requestFocusOnTap: false,
                  dropdownMenuEntries: [
                    for (final e in baseRoleNames.entries)
                      DropdownMenuEntry(label: e.value, value: e.key)
                  ],
                  label: const Text("Role"),
                  textStyle: const TextStyle(
                    fontSize: 12,
                  ),
                  initialSelection: currentPage,
                  inputDecorationTheme:
                      const InputDecorationTheme(isDense: true),
                  onSelected: (value) {
                    setState(() {
                      currentPage = value!;
                      _pageController.jumpToPage(currentPage.index);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text('Search (fuzzy)'),
                isDense: true),
          ),
          const Divider(),
          Expanded(
            child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, idx) {
                  return MultiProvider(providers: [
                    ChangeNotifierProvider.value(value: widget.core),
                    ChangeNotifierProvider.value(value: sort),
                    ChangeNotifierProvider.value(value: _searchController)
                  ], child: KnowledgePage(role: currentPage));
                },
                itemCount: BaseRole.values.length),
          )
        ],
      ),
    );
  }

  Future<dynamic> addNodeDialog(final MoonieCore core) {
    final ctx = core.rpContext;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        String nodeName = '';
        String nodeDescription = '';
        return AlertDialog(
          title: const Text('Add node'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              onChanged: (value) {
                nodeName = value;
              },
              decoration: const InputDecoration(
                  hintText: "Node name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                nodeDescription = value;
              },
              maxLines: 5,
              decoration: const InputDecoration(
                  hintText: "Node meta description",
                  border: OutlineInputBorder()),
            ),
          ]),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                ctx.createNode(currentPage, nodeName,
                    description: nodeDescription);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class KnowledgePage extends StatefulWidget {
  final BaseRole role;
  const KnowledgePage({required this.role, super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  List<BaseNode> nodes = [];
  String name() {
    return baseRoleNames[widget.role]!;
  }

  void getNodes(BuildContext context) {
    final core = Provider.of<MoonieCore>(context, listen: false);
    final ctx = core.rpContext;
    // Is synchronously doing this going to be a problem?
    nodes = ctx.queryNodes(widget.role);
  }

  @override
  Widget build(BuildContext context) {
    final core = Provider.of<MoonieCore>(context, listen: false);
    final ctx = core.rpContext;
    return ChangeNotifierProvider.value(
      value: ctx,
      child:
          Consumer3<RPContext, ValueNotifier<_SortMode>, TextEditingController>(
              builder: (context, rp, sort, search, _) {
        getNodes(context);
        var nodesSorted = nodes;
        if (search.value.text.isNotEmpty) {
          final extraction = fw.extractAll(
            query: search.value.text,
            choices: nodesSorted,
            getter: (node) => node.name,
            cutoff: 60,
          );
          nodesSorted = extraction.map((e) => e.choice).toList();
        }
        switch (sort.value) {
          case _SortMode.alphabetical:
            nodesSorted.sort((a, b) => a.name.compareTo(b.name));
          case _SortMode.reverseAlphabetical:
            nodesSorted.sort((a, b) => b.name.compareTo(a.name));
          case _SortMode.created:
            nodesSorted.sort((a, b) {
              if (a.created == null && b.created == null) return 0;
              if (a.created == null) return 1;
              if (b.created == null) return -1;
              return a.created!.compareTo(b.created!);
            });
          case _SortMode.reverseCreated:
            nodesSorted.sort((a, b) {
              if (a.created == null && b.created == null) return 0;
              if (a.created == null) return 1;
              if (b.created == null) return -1;
              return b.created!.compareTo(a.created!);
            });
          case _SortMode.modified:
            nodesSorted.sort((a, b) {
              if (a.modified == null && b.modified == null) return 0;
              if (a.modified == null) return 1;
              if (b.modified == null) return -1;
              return a.modified!.compareTo(b.modified!);
            });
          case _SortMode.reverseModified:
            nodesSorted.sort((a, b) {
              if (a.modified == null && b.modified == null) return 0;
              if (a.modified == null) return 1;
              if (b.modified == null) return -1;
              return b.modified!.compareTo(a.modified!);
            });
        }

        return Column(
          children: [
            if (nodes.isEmpty) Text('No nodes (${name()})'),
            for (final node in nodesSorted)
              ChangeNotifierProvider.value(
                value: node,
                child: Consumer<BaseNode>(builder: (context, node, _) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${node.id}',
                                    style: const TextStyle(fontSize: 10)),
                                Text(node.name),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton.outlined(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    ChangeNotifierProvider.value(
                                  value: core,
                                  child: NodeEditor(node: node),
                                ),
                              ));
                            },
                            icon: const Icon(Icons.edit),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            // Copy
                            onPressed: () {
                              node.copy();
                            },
                            icon: const Icon(Icons.copy),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          // IconButton.outlined(
                          //// Export
                          // onPressed: () {},
                          // icon: const Icon(Icons.upgrade),
                          // visualDensity: VisualDensity.compact,
                          // ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete'),
                                    content: Text(
                                        'Are you sure you want to delete ${node.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          rp.deleteNode(node);
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.delete),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: (node.imagePath.isNotEmpty)
                                ? FileImage(File(node.imagePath))
                                : null,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  );
                }),
              )
            // Text('ID: ${node.id} Name: ${node.name} '
            // 'Created: ${(node.created != null) ? formatDateTime1(node.created!) : null}')
          ],
        );
      }),
    );
  }
}
