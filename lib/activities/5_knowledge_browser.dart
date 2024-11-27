import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/activities/commons.dart';
import 'package:moonie/activities/knowledge_browser/node_editor.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:provider/provider.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fw;

class NodeSelectController extends ChangeNotifier {
  LinkedHashSet<BaseNode> selectedNodes = nodeHashSet();

  void addNode(BaseNode node) {
    selectedNodes.add(node);
    notifyListeners();
  }

  void removeNode(BaseNode node) {
    selectedNodes.remove(node);
    notifyListeners();
  }

  bool isSelected(BaseNode node) => selectedNodes.contains(node);
  int count() => selectedNodes.length;

  void clear() {
    selectedNodes.clear();
    notifyListeners();
  }
}

class KnowledgeBrowser extends ActivityWidget {
  final NodeSelectController? nodeSelectController;
  final BaseRole? lockedPage;
  final bool dialogMode;
  const KnowledgeBrowser(
      {super.key,
      required super.core,
      this.lockedPage,
      this.dialogMode = false,
      this.nodeSelectController})
      : super(
            name: "Knowledge Browser",
            description: "Browse and edit knowledge nodes");

  @override
  State<KnowledgeBrowser> createState() => _KnowledgeBrowserState();
}

class _KnowledgeBrowserState extends State<KnowledgeBrowser> {
  late BaseRole currentPage;
  final sort = ValueNotifier(SortMode.alphabetical);
  final PageController _pageController =
      PageController(initialPage: BaseRole.character.index);
  final _searchController = TextEditingController();

  //ValueNotifier<> sort mode

  @override
  void initState() {
    super.initState();
    if (widget.lockedPage != null) {
      currentPage = widget.lockedPage!;
    } else {
      currentPage = BaseRole.character;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
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
                if (widget.dialogMode) const SizedBox(width: 8),
                if (widget.dialogMode)
                  ActionChip(
                    avatar: const Icon(Icons.clear),
                    label: const Text("Clear"),
                    onPressed: () {
                      widget.nodeSelectController?.clear();
                    },
                  ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: DropdownMenu(
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(
                          label: 'A-Z', value: SortMode.alphabetical),
                      DropdownMenuEntry(
                          label: 'Z-A', value: SortMode.reverseAlphabetical),
                      DropdownMenuEntry(
                          label: 'created (desc)', value: SortMode.created),
                      DropdownMenuEntry(
                          label: 'created (asc)',
                          value: SortMode.reverseCreated),
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
                if (widget.lockedPage == null)
                  DropdownMenu(
                    width: 100,
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
                  return MultiProvider(
                      providers: [
                        ChangeNotifierProvider.value(value: widget.core),
                        ChangeNotifierProvider.value(value: sort),
                        ChangeNotifierProvider.value(value: _searchController)
                      ],
                      child: KnowledgePage(
                        role: currentPage,
                        dialogMode: widget.dialogMode,
                        nodeSelectController: widget.nodeSelectController,
                      ));
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
  final bool dialogMode;
  final NodeSelectController? nodeSelectController;
  const KnowledgePage(
      {required this.role,
      required this.dialogMode,
      super.key,
      this.nodeSelectController});

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
          Consumer3<RPContext, ValueNotifier<SortMode>, TextEditingController>(
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
          case SortMode.alphabetical:
            nodesSorted.sort((a, b) => a.name.compareTo(b.name));
          case SortMode.reverseAlphabetical:
            nodesSorted.sort((a, b) => b.name.compareTo(a.name));
          case SortMode.created:
            nodesSorted.sort((a, b) {
              if (a.created == null && b.created == null) return 0;
              if (a.created == null) return 1;
              if (b.created == null) return -1;
              return a.created!.compareTo(b.created!);
            });
          case SortMode.reverseCreated:
            nodesSorted.sort((a, b) {
              if (a.created == null && b.created == null) return 0;
              if (a.created == null) return 1;
              if (b.created == null) return -1;
              return b.created!.compareTo(a.created!);
            });
          case SortMode.modified:
            nodesSorted.sort((a, b) {
              if (a.modified == null && b.modified == null) return 0;
              if (a.modified == null) return 1;
              if (b.modified == null) return -1;
              return a.modified!.compareTo(b.modified!);
            });
          case SortMode.reverseModified:
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
                          if (true) ...[
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
                          ],
                          if (widget.dialogMode &&
                              widget.nodeSelectController != null) ...[
                            const SizedBox(width: 8),
                            ChangeNotifierProvider.value(
                              value: widget.nodeSelectController,
                              child: Consumer<NodeSelectController>(
                                  builder: (context, controller, _) {
                                return Checkbox(
                                  value: controller.isSelected(node),
                                  onChanged: (value) {
                                    if (value == true) {
                                      controller.addNode(node);
                                    } else {
                                      controller.removeNode(node);
                                    }
                                  },
                                );
                              }),
                            )
                          ],
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
