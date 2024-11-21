import 'package:flutter/material.dart';
import 'package:moonie/activities/2_chat2.dart';
import 'package:moonie/activities/3_webpage_to_knowledge_base.dart';
import 'package:moonie/activities/4_knowledge_decomposer.dart';
import 'package:moonie/activities/5_knowledge_browser.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/core.dart';
import 'package:moonie/llm_interfaces/openrouter.dart';
import 'package:moonie/settings.dart';
import 'package:provider/provider.dart';

class ActivityDirectory extends StatelessWidget {
  final MoonieCore core;
  const ActivityDirectory({super.key, required this.core});

  @override
  Widget build(BuildContext context) {
    final List<ActivityWidget> activities = [
      KnowledgeBrowser(core: core),
      Chat2Widget(core: core),
      WebpageToKnowledgeBase(core: core),
      KnowledgeDecomposerWidget(core: core)
    ];
    return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        itemCount: activities.length, // Number of activities
        itemBuilder: (context, index) {
          final activity = activities[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
                child: InkWell(
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return Scaffold(
                    appBar: AppBar(
                        actions: [
                          SettingsButton(core: core),
                          const SizedBox(width: 16)
                        ],
                        title: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    child: Text(
                                  activity.name,
                                  style: const TextStyle(fontSize: 16),
                                )),
                                ChangeNotifierProvider.value(
                                  value: core.settings,
                                  child: Consumer<Settings>(
                                      builder: (context, settings, _) {
                                    return core.interface.infoWidget(core);
                                  }),
                                )
                              ],
                            ),
                          ],
                        )),
                    body: activity,
                  );
                }));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: [
                  Text(activity.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text(activity.description),
                ]),
              ),
            )),
          );
        });
  }
}
