import 'package:flutter/material.dart';
import 'package:moonie/activities/roleplay/chat_entities.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/activities/roleplay/scenario.dart';
import 'package:moonie/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

/// Maintains the RP/scenario entities in disk storage and scenarios
/// Also the factory for nodes and scenarios.
class RPContext extends ChangeNotifier {
  final MoonieCore core;
  final Store store;
  late final Box<BaseNode> baseNodes;
  late final Box<AttributeComponent> attributes;
  late final Box<Scenario> scenarios;
  late final Box<RPChatMessage> chatMessages;
  late final Box<RPChat> chats;
  late final Box<NodeSlot> slots;
  late final Box<SlotFill> slotFills;

  static Future<RPContext> create(MoonieCore core) async {
    final ctx = RPContext(core);
    ctx.baseNodes = ctx.store.box<BaseNode>();
    ctx.attributes = ctx.store.box<AttributeComponent>();
    ctx.scenarios = ctx.store.box<Scenario>();
    ctx.chatMessages = ctx.store.box<RPChatMessage>();
    ctx.chats = ctx.store.box<RPChat>();
    ctx.slots = ctx.store.box<NodeSlot>();
    ctx.slotFills = ctx.store.box<SlotFill>();
    return ctx;
  }

  RPContext(this.core) : store = core.store;

  void deleteChat(RPChat chat) {
    chats.remove(chat.id);
    notifyListeners();
  }

  Scenario createScenario(String name, {String description = ''}) {
    final scenario = Scenario();
    scenario.name = name;
    scenario.description = description;
    scenario.created = DateTime.now();
    scenario.context = this;
    scenario.id = scenarios.put(scenario);
    notifyListeners();
    return scenario;
  }

  void deleteScenario(Scenario scenario) {
    scenarios.remove(scenario.id);
    notifyListeners();
  }

  BaseNode createNode(
    BaseRole role,
    String name, {
    String description = '',
  }) {
    final node = BaseNode();
    node.setRole(role);
    node.name = name;
    node.description = description;
    node.context = this;
    node.created = DateTime.now();
    node.id = baseNodes.put(node);
    notifyListeners();
    return node;
  }

  void deleteNode(BaseNode node) {
    baseNodes.remove(node.id);
    notifyListeners();
  }

  List<BaseNode> queryNodes(BaseRole role) {
    final query = baseNodes.query(BaseNode_.role.equals(role.index));
    final res = query.build().find();
    for (final node in res) {
      node.context = this;
    }
    return res;
  }

  /// Not to be called directly exccept by BaseNode
  /// (If not, then why not just put it inside BaseNode???)

  // Right now the plan is just to spit the entire graph out into context
  // If we want to look into more sophisticated solutions later,
  // we could look into letting the LLM use some kind of tool to traverse the graph
  // or something
}

enum BaseRole {
  character,
  user,
  world,
  writingRules,
  item,
  extra,
}

const baseRoleNames = {
  BaseRole.character: 'Character',
  BaseRole.user: 'User',
  BaseRole.world: 'World',
  BaseRole.writingRules: 'Writing Rules',
  BaseRole.item: 'Item',
  BaseRole.extra: 'Extra',
};

// Might hold things like RPG stats, not sure
enum SpecialAttributeType { exampleMessages }
