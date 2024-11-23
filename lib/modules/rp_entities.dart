import 'package:flutter/material.dart';
import 'package:moonie/modules/rp_context.dart';
import 'package:objectbox/objectbox.dart';
import 'package:moonie/utils.dart';

/// A base node of the context graph. Typically a character or a world etc.
@Entity()
class BaseNode extends ChangeNotifier {
  int id = 0;

  int role = BaseRole.extra.index;
  String _name = '';
  String _description = '';

  @Property(type: PropertyType.date)
  DateTime? created;
  @Property(type: PropertyType.date)
  DateTime? modified;

  // Do we need multiple of these?
  String _imagePath = '';

  String get imagePath => _imagePath;
  set imagePath(String value) {
    _imagePath = value;
    modified = DateTime.now();
    notifyListeners();
  }

  String get name => _name;
  set name(String value) {
    _name = value;
    modified = DateTime.now();
    notifyListeners();
  }

  String get description => _description;
  set description(String value) {
    _description = value;
    modified = DateTime.now();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.baseNodes.put(this);
  }

  @Backlink('baseNodeParent')
  final attributes = ToMany<AttributeComponent>();

  @Transient()
  RPContext? context;

  AttributeComponent createAttribute(String name, String content,
      {String description = ''}) {
    final attr = AttributeComponent();
    attr.name = name;
    attr.description = description;
    attr.content = content;
    attr.baseNodeParent.target = this;
    attr.context = context!;
    attr.id = context!.attributes.put(attr);
    attributes.add(attr);
    attr.attributePosition = attributes.length - 1;
    refreshAttributePositions();
    notifyListeners();
    return attr;
  }

  List<AttributeComponent> getAttributes() {
    return attributes.map((e) {
      e.context = context!;
      return e;
    }).toList();
  }

  AttributeComponent getAttributeByPosition(int index) {
    return attributes.singleWhere((e) => e.attributePosition == index);
  }

  int length() => attributes.length;

  void moveAttribute(int from, int to) {
    final attrs = attributes.toList();

    // https://stackoverflow.com/questions/54162721/onreorder-arguments-in-flutter-reorderablelistview
    if (from < to) {
      to -= 1;
    }

    if (from < 0 ||
        from >= attrs.length ||
        to < 0 ||
        to >= attrs.length ||
        from == to) {
      return; // Invalid indices or no movement needed
    }

    attrs.sort((a, b) => a.attributePosition!.compareTo(b.attributePosition!));
    final attribute = attrs.removeAt(from);
    attrs.insert(to, attribute);

    refreshAttributePositions(override: attrs);
    notifyListeners();
  }

  BaseRole getRole() {
    if (role >= BaseRole.values.length) return BaseRole.extra;
    return BaseRole.values[role];
  }

  void setRole(BaseRole r) {
    role = r.index;
  }

  void removeAttribute(AttributeComponent attr) {
    attributes.remove(attr);
    refreshAttributePositions();
    notifyListeners();
  }

  void refreshAttributePositions({List<AttributeComponent>? override}) {
    final attrs = override ?? attributes.toList();
    if (override == null) {
      attrs
          .sort((a, b) => a.attributePosition!.compareTo(b.attributePosition!));
    }
    for (var i = 0; i < attributes.length; i++) {
      attrs[i].attributePosition = i;
    }
    notifyListeners();
  }

  BaseNode();

  BaseNode copy() {
    final newNode = BaseNode();
    newNode.role = role;
    newNode.name = name;
    newNode.description = description;
    newNode.imagePath = imagePath;
    newNode.id = context!.baseNodes.put(newNode);
    newNode.created = DateTime.now();
    newNode.context = context!;
    for (final attr in getAttributes()) {
      newNode.attributes.add(attr.copy(null, newNode));
    }
    context!.notifyListeners();
    return newNode;
  }

  String toXML() {
    final xml = StringBuffer();
    final tagName = sanitizeTagName(baseRoleNames[getRole()]!);
    xml.writeln('<$tagName name="$name">');
    for (final attr in getAttributes()) {
      xml.writeln('\t${attr.toXML()}');
    }
    xml.writeln('</$tagName>');
    return xml.toString();
  }
}

/// An attribute, typically of a base node.
/// Theoretically this can support a tree structure
/// but that hasn't been properly implemented and I'm not sure how useful it is.
@Entity()
class AttributeComponent extends ChangeNotifier {
  int id = 0;

  int? _attributePosition;

  String _name = '';

  /// Unused - may decide to get rid of it later as it's not very useful
  String _description = '';
  String _content = '';

  int? get attributePosition => _attributePosition;
  set attributePosition(int? value) {
    _attributePosition = value;
    notifyListeners();
  }

  String get name => _name;
  set name(String value) {
    _name = value;
    notifyListeners();
  }

  String get description => _description;
  set description(String value) {
    _description = value;
    notifyListeners();
  }

  String get content => _content;
  set content(String value) {
    _content = value;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    context?.attributes.put(this);
  }

  final baseNodeParent = ToOne<BaseNode>();
  final parent = ToOne<AttributeComponent>();
  @Backlink('parent')
  final children = ToMany<AttributeComponent>();

  dynamic getParent() {
    final target = parent.target ?? baseNodeParent.target;
    if (target is AttributeComponent) {
      target.context = context;
    } else if (target is BaseNode) {
      target.context = context;
    }
    return target;
  }

  void setParent(dynamic p) {
    if (p is AttributeComponent) {
      parent.target = p;
    } else if (p is BaseNode) {
      baseNodeParent.target = p;
    }
    notifyListeners();
  }

  List<AttributeComponent> getChildren() {
    return children.map((e) {
      e.context = context!;
      e.parent.target = this;
      return e;
    }).toList();
  }

  @Transient()
  RPContext? context;

  AttributeComponent();

  AttributeComponent copy(
      AttributeComponent? aparent, BaseNode? abaseNodeParent) {
    final newAttribute = AttributeComponent();
    newAttribute.name = name;
    newAttribute.description = description;
    newAttribute.content = content;
    newAttribute.attributePosition = attributePosition;
    newAttribute.parent.target = aparent;
    newAttribute.baseNodeParent.target = abaseNodeParent;
    for (final child in getChildren()) {
      newAttribute.children.add(child.copy(newAttribute, null));
    }
    newAttribute.id = context!.attributes.put(newAttribute);
    newAttribute.context = context!;
    context!.notifyListeners();
    return newAttribute;
  }

  String toXML() {
    final xml = StringBuffer();
    final tagName = sanitizeTagName(name);
    xml.writeln('<$tagName>');
    xml.writeln('\t$content');
    for (final child in getChildren()) {
      xml.writeln('\t${child.toXML()}');
    }
    xml.writeln('</$tagName>');
    return xml.toString();
  }
}
