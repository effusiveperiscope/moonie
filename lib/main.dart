import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moonie/modules/1_basic_chat.dart';
import 'package:moonie/core.dart';
import 'package:moonie/settings.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
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
                const Spacer(),
                ChangeNotifierProvider.value(
                    value: core.settings,
                    child: Consumer<Settings>(builder: (context, settings, _) {
                      TextStyle style = const TextStyle(fontSize: 10.0);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'model: ${core.settings.currentModel}',
                            style: style,
                          ),
                          Text(
                              'credits remaining: ${core.openRouterInterface.creditsRemaining?.toStringAsFixed(4)}',
                              style: style)
                        ],
                      );
                    }))
              ],
            ),
            backgroundColor: colorScheme.surfaceContainer,
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
          body: BasicChatWidget(openRouterInterface: core.openRouterInterface),
        );
      }),
    );
  }
}
