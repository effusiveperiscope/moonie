import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moonie/activity_directory.dart';
import 'package:moonie/core.dart';
import 'package:moonie/llm_interfaces/openrouter.dart';
import 'package:moonie/settings.dart';
import 'package:provider/provider.dart';
import 'package:rhttp/rhttp.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  await Rhttp.init();
  WidgetsFlutterBinding.ensureInitialized();
  MoonieCore core = await MoonieCore.create();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions =
        const WindowOptions(size: Size(480, 640), maximumSize: Size(640, 820));
    windowManager.waitUntilReadyToShow(windowOptions);
  }
  runApp(MainApp(core: core));
}

class MainApp extends StatelessWidget {
  final MoonieCore core;
  const MainApp({super.key, required this.core});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff3f165b), brightness: Brightness.dark)),
      home: Builder(builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text("moonie"),
                const SizedBox(width: 16),
                ChangeNotifierProvider.value(
                  value: core.settings,
                  child: Consumer<Settings>(builder: (context, settings, _) {
                    return Expanded(
                      child: core.interface.infoWidget(core),
                    );
                  }),
                )
              ],
            ),
            backgroundColor: colorScheme.surfaceContainer,
            actions: [
              SettingsButton(core: core),
              const SizedBox(width: 16.0),
            ],
          ),
          body: ActivityDirectory(core: core),
        );
      }),
    );
  }
}
