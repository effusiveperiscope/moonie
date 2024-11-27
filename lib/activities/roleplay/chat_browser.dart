import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moonie/activities/commons.dart';
import 'package:moonie/activities/roleplay/chat_edit.dart';
import 'package:moonie/activities/roleplay/chat_entities.dart';
import 'package:moonie/activities/roleplay/scenario_entities.dart';
import 'package:moonie/core.dart';
import 'package:moonie/utils.dart';
import 'package:provider/provider.dart';

class ChatBrowser extends StatefulWidget {
  final Scenario scenario;
  final MoonieCore core;
  const ChatBrowser(this.core, this.scenario, {super.key});

  @override
  State<ChatBrowser> createState() => _ChatBrowserState();
}

class _ChatBrowserState extends State<ChatBrowser> {
  ValueNotifier<SortMode> sortMode = ValueNotifier(SortMode.modified);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          actions: [
            IconButton.outlined(
              onPressed: () {
                widget.scenario.createChat();
              },
              icon: const Icon(Icons.add),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            DropdownMenu(
              dropdownMenuEntries: const [
                DropdownMenuEntry(label: 'Created', value: SortMode.created),
                DropdownMenuEntry(label: 'Modified', value: SortMode.modified),
                DropdownMenuEntry(
                    label: 'Reverse created', value: SortMode.reverseCreated),
                DropdownMenuEntry(
                    label: 'Reverse modified', value: SortMode.reverseModified),
              ],
              onSelected: (value) {
                setState(() {
                  sortMode.value = value!;
                });
              },
              requestFocusOnTap: false,
              initialSelection: sortMode.value,
              trailingIcon: const Icon(Icons.sort),
              width: 200,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ChangeNotifierProvider.value(
          value: widget.scenario,
          child: Consumer<Scenario>(builder: (context, scenario, _) {
            final chatsSorted = scenario.chats.toList();
            if (sortMode.value == SortMode.created) {
              chatsSorted.sort((a, b) => a.created!.compareTo(b.created!));
            } else if (sortMode.value == SortMode.reverseCreated) {
              chatsSorted.sort((a, b) => b.created!.compareTo(a.created!));
            } else if (sortMode.value == SortMode.modified) {
              chatsSorted.sort((a, b) => a.modified!.compareTo(b.modified!));
            } else if (sortMode.value == SortMode.reverseModified) {
              chatsSorted.sort((a, b) => b.modified!.compareTo(a.modified!));
            }
            return Column(
              children: [
                for (final chat in scenario.chats)
                  ChatDisplayWidget(widget.core, chat, widget.scenario),
              ],
            );
          }),
        ));
  }
}

class ChatDisplayWidget extends StatelessWidget {
  final Scenario scenario;
  final RPChat chat;
  final MoonieCore core;
  const ChatDisplayWidget(this.core, this.chat, this.scenario, {super.key});

  @override
  Widget build(BuildContext context) {
    final String? firstMessage = chat.messages.firstOrNull?.text;
    final String? truncated =
        firstMessage?.substring(0, min(80, firstMessage.length));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Created ${formatDateTime1(chat.created!)}',
                        style: const TextStyle(
                          fontSize: 10,
                        )),
                  ],
                ),
                Text('First message: ${truncated ?? '(None)'}'),
              ],
            ),
            const Spacer(),
            IconButton.outlined(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy),
              onPressed: () {
                throw UnimplementedError();
              },
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chat),
              onPressed: () {
                throw UnimplementedError();
              },
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatEdit(core, chat, scenario)));
              },
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete),
              onPressed: () {
                deleteChatDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void deleteChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete chat'),
          content: const Text('Are you sure you want to delete this chat?'),
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
                scenario.removeChat(chat);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
