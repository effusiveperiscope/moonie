import 'package:flutter/material.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:moonie/objectbox.g.dart';
import 'package:provider/provider.dart';

class KnowledgeBrowser extends ActivityWidget {
  const KnowledgeBrowser({super.key, required MoonieCore core})
      : super(
            core: core,
            name: "Knowledge Browser",
            description: "Browse and edit knowledge nodes");

  @override
  State<KnowledgeBrowser> createState() => _KnowledgeBrowserState();
}

class _KnowledgeBrowserState extends State<KnowledgeBrowser> {
  BaseRole currentPage = BaseRole.character;
  final PageController _pageController =
      PageController(initialPage: BaseRole.character.index);

  //ValueNotifier<> sort mode

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
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
              ActionChip(
                label: const Icon(Icons.delete, size: 20),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Icon(Icons.sort, size: 20),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              DropdownMenu(
                width: 150,
                dropdownMenuEntries: [
                  for (final e in baseRoleNames.entries)
                    DropdownMenuEntry(label: e.value, value: e.key)
                ],
                textStyle: const TextStyle(
                  fontSize: 14,
                ),
                initialSelection: currentPage,
                onSelected: (value) {
                  setState(() {
                    currentPage = value!;
                    _pageController.jumpToPage(currentPage.index);
                  });
                },
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, idx) {
                  return ChangeNotifierProvider.value(
                      value: widget.core,
                      child: KnowledgePage(role: currentPage));
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
    final query = ctx.baseNodes.query(BaseNode_.role.equals(widget.role.index));
    // Is synchronously doing this going to be a problem?
    nodes = query.build().find();
  }

  @override
  Widget build(BuildContext context) {
    final core = Provider.of<MoonieCore>(context, listen: false);
    final ctx = core.rpContext;
    return ChangeNotifierProvider.value(
      value: ctx,
      child: Consumer<RPContext>(builder: (context, rp, _) {
        getNodes(context);
        return Column(
          children: [
            if (nodes.isEmpty) Text('No nodes (${name()})'),
            for (final node in nodes) Text('ID: ${node.id} Name: ${node.name}')
          ],
        );
      }),
    );
  }
}
