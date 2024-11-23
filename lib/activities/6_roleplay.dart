import 'package:flutter/material.dart';
import 'package:moonie/activities/2_chat2.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_context.dart';

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
      itemBuilder: (context, index) => RoleplaySetup(),
    );
  }
}

class RoleplaySetup extends StatefulWidget {
  const RoleplaySetup({super.key});

  @override
  State<RoleplaySetup> createState() => _RoleplaySetupState();
}

class _RoleplaySetupState extends State<RoleplaySetup> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
