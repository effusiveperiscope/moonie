import 'package:flutter/material.dart';
import 'package:moonie/core.dart';

class ActivityWidget extends StatefulWidget {
  final String name;
  final String description;
  final MoonieCore core;
  const ActivityWidget(
      {super.key,
      required this.name,
      required this.description,
      required this.core});

  @override
  State<ActivityWidget> createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
