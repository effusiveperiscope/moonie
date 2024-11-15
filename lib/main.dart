import 'package:flutter/material.dart';
import 'package:moonie/modules/1_basic_chat.dart';
import 'package:moonie/core.dart';
import 'package:moonie/settings.dart';
import 'package:provider/provider.dart';

void main() async {
  MoonieCore core = await MoonieCore.create();
  runApp(MainApp(core: core));
}

class MainApp extends StatelessWidget {
  final MoonieCore core;
  MainApp({super.key, required this.core});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff3f165b), brightness: Brightness.dark)),
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("moonie"),
            actions: [
              IconButton.outlined(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider.value(
                                value: core,
                                child: SettingsPage(settings: core.settings))));
                  },
                  icon: const Icon(Icons.settings)),
              const SizedBox(width: 16.0),
            ],
          ),
          body: const BasicInputWidget(),
        );
      }),
    );
  }
}
