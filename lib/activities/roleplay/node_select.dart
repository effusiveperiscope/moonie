import 'package:flutter/material.dart';
import 'package:moonie/activities/5_knowledge_browser.dart';
import 'package:moonie/activities/roleplay/scenario_entities.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:provider/provider.dart';

class NodeSelectPage extends StatefulWidget {
  final String title;
  final MoonieCore core;
  final NodeSlot? slot;
  const NodeSelectPage(
    this.core,
    this.slot, {
    super.key,
    this.title = 'Select nodes',
  });

  @override
  State<NodeSelectPage> createState() => _NodeSelectPageState();
}

class _NodeSelectPageState extends State<NodeSelectPage> {
  late final NodeSelectController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NodeSelectController();
    if (widget.slot != null) {
      final defaultFill = widget.slot!.defaultFill.target;
      if (defaultFill != null) {
        _controller.selectedNodes.addAll(defaultFill.nodes);
      }
    }
  }

  void commitSelection() {
    if (widget.slot != null) {
      // Default fill creation
      widget.slot!.removeDefaultFill();
      if (_controller.count() == 0) return;
      widget.slot!.createDefaultFill(_controller.selectedNodes.toList());
    }
    // Case to handle: Fill creation in chat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final oldSet = nodeHashSet();
            for (final node in _controller.selectedNodes) {
              oldSet.add(node);
            }
            if (_controller.selectedNodes == oldSet) {
              Navigator.pop(context);
              return;
            }
            commitSelection();
            Navigator.pop(context);
            // await showDialog(
            //   context: context,
            //   builder: (BuildContext dialogContext) {
            //     return AlertDialog(
            //       title: const Text('Selection'),
            //       content: Text(
            //           'You have ${_controller.count()} nodes selected (old count: $oldCount). What do you want to do?'),
            //       actions: [
            //         TextButton(
            //           onPressed: () {
            //             Navigator.of(dialogContext).pop(); // Dismiss dialog
            //           },
            //           child: const Text('Cancel'),
            //         ),
            //         TextButton(
            //           onPressed: () {
            //             commitSelection();
            //             Navigator.of(dialogContext).pop();
            //             Navigator.pop(context);
            //           },
            //           child: const Text('Commit changes and exit'),
            //         ),
            //         TextButton(
            //           onPressed: () {
            //             Navigator.of(dialogContext).pop(); // Dismiss dialog
            //             Navigator.pop(context); // Go back
            //           },
            //           child: const Text('Exit without changes'),
            //         ),
            //       ],
            //     );
            //   },
            // );
          },
        ),
        title: ChangeNotifierProvider.value(
            value: _controller,
            child: Consumer<NodeSelectController>(
                builder: (context, controller, _) {
              return Text('${widget.title} (${controller.count()})');
            })),
      ),
      body: KnowledgeBrowser(
        core: widget.core,
        dialogMode: true,
        nodeSelectController: _controller,
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            commitSelection();
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.done)),
    );
  }
}
