import 'package:flutter/material.dart';
import 'package:moonie/activities/2_chat.dart';
import 'package:moonie/activities/3_webpage_to_knowledge_base.dart';
import 'package:moonie/activities/activity.dart';
import 'package:moonie/core.dart';
import 'package:moonie/openrouter.dart';
import 'package:moonie/settings.dart';
import 'package:provider/provider.dart';

class ActivityDirectory extends StatelessWidget {
  final MoonieCore core;
  const ActivityDirectory({super.key, required this.core});

  @override
  Widget build(BuildContext context) {
    final List<ActivityWidget> activities = [
      Chat2Widget(core: core),
      WebpageToKnowledgeBase(core: core)
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
                          IconButton.outlined(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ChangeNotifierProvider.value(
                                                value: core,
                                                child: SettingsPage(
                                                    settings: core.settings))));
                              },
                              icon: const Icon(Icons.settings)),
                          const SizedBox(width: 16)
                        ],
                        title: Row(
                          children: [
                            SizedBox(width: 100, child: Text(activity.name)),
                            const Spacer(),
                            OpenRouterInfo(core: core),
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
