import 'package:flutter/material.dart';
import 'package:moonie/core.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/objectbox.g.dart';
import 'package:objectbox/objectbox.dart';

/// Maintains the nodes in active context and disk storage.
/// Also the factory for nodes and attributes.
class RPContext extends ChangeNotifier {
  final MoonieCore core;
  final Store store;
  late final Box<BaseNode> baseNodes;
  late final Box<AttributeComponent> attributes;

  static Future<RPContext> create(MoonieCore core) async {
    final ctx = RPContext(core);
    ctx.baseNodes = ctx.store.box<BaseNode>();
    ctx.attributes = ctx.store.box<AttributeComponent>();
    return ctx;
  }

  RPContext(this.core) : store = core.store;

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
  AttributeComponent createAttribute(String name, String content,
      {String description = ''}) {
    final attr = AttributeComponent();
    attr.name = name;
    attr.description = description;
    attr.content = content;
    attr.context = this;
    attr.id = attributes.put(attr);
    return attr;
  }

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
