import 'package:flutter/material.dart';
import 'package:moonie/activities/roleplay/chat_entities.dart';
import 'package:moonie/activities/roleplay/scenario_entities.dart';
import 'package:moonie/core.dart';
import 'package:moonie/utils.dart';

class ChatEdit extends StatefulWidget {
  final RPChat chat;
  final Scenario scenario;
  final MoonieCore core;
  const ChatEdit(this.core, this.chat, this.scenario, {super.key});

  @override
  State<ChatEdit> createState() => _ChatEditState();
}

class _ChatEditState extends State<ChatEdit> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Chat created ${formatDateTime1(widget.chat.created!)}',
            style: const TextStyle(fontSize: 10.0),
          ),
        ),
        body: const Column(
          children: [],
        ));
  }
}
