// GENERATED CODE - DO NOT MODIFY BY HAND
// This code was generated by ObjectBox. To update it run the generator again
// with `dart run build_runner build`.
// See also https://docs.objectbox.io/getting-started#generate-objectbox-code

// ignore_for_file: camel_case_types, depend_on_referenced_packages
// coverage:ignore-file

import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:moonie/modules/rp_entities.dart';
import 'package:moonie/modules/rp_entities.dart';
import 'package:objectbox/internal.dart'
    as obx_int; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart' as obx;

import 'modules/rp_context.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

final _entities = <obx_int.ModelEntity>[
  obx_int.ModelEntity(
      id: const obx_int.IdUid(2, 8781206216458749294),
      name: 'AttributeComponent',
      lastPropertyId: const obx_int.IdUid(7, 8639802489852452644),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 2256817025145172423),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 3336829245333597189),
            name: 'name',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 4148496082309907179),
            name: 'description',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 6153601873044450129),
            name: 'content',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 1092453818179745223),
            name: 'baseNodeParentId',
            type: 11,
            flags: 520,
            indexId: const obx_int.IdUid(1, 2588732074116543526),
            relationTarget: 'BaseNode'),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 7536571769663539683),
            name: 'parentId',
            type: 11,
            flags: 520,
            indexId: const obx_int.IdUid(2, 1641280788405409404),
            relationTarget: 'AttributeComponent'),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 8639802489852452644),
            name: 'attributePosition',
            type: 6,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[
        obx_int.ModelBacklink(
            name: 'children',
            srcEntity: 'AttributeComponent',
            srcField: 'parent')
      ]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(3, 7450678709023556741),
      name: 'BaseNode',
      lastPropertyId: const obx_int.IdUid(7, 657730921674049911),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 2134903819162713902),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 2326734674649690203),
            name: 'role',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 8235273265341004),
            name: 'name',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 706878819240799355),
            name: 'description',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 6056420063037614984),
            name: 'created',
            type: 10,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 2238188088287426116),
            name: 'modified',
            type: 10,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 657730921674049911),
            name: 'imagePath',
            type: 9,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[
        obx_int.ModelBacklink(
            name: 'attributes',
            srcEntity: 'AttributeComponent',
            srcField: 'baseNodeParent')
      ])
];

/// Shortcut for [obx.Store.new] that passes [getObjectBoxModel] and for Flutter
/// apps by default a [directory] using `defaultStoreDirectory()` from the
/// ObjectBox Flutter library.
///
/// Note: for desktop apps it is recommended to specify a unique [directory].
///
/// See [obx.Store.new] for an explanation of all parameters.
///
/// For Flutter apps, also calls `loadObjectBoxLibraryAndroidCompat()` from
/// the ObjectBox Flutter library to fix loading the native ObjectBox library
/// on Android 6 and older.
obx.Store openStore(
    {String? directory,
    int? maxDBSizeInKB,
    int? maxDataSizeInKB,
    int? fileMode,
    int? maxReaders,
    bool queriesCaseSensitiveDefault = true,
    String? macosApplicationGroup}) {
  return obx.Store(getObjectBoxModel(),
      directory: directory,
      maxDBSizeInKB: maxDBSizeInKB,
      maxDataSizeInKB: maxDataSizeInKB,
      fileMode: fileMode,
      maxReaders: maxReaders,
      queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
      macosApplicationGroup: macosApplicationGroup);
}

/// Returns the ObjectBox model definition for this project for use with
/// [obx.Store.new].
obx_int.ModelDefinition getObjectBoxModel() {
  final model = obx_int.ModelInfo(
      entities: _entities,
      lastEntityId: const obx_int.IdUid(3, 7450678709023556741),
      lastIndexId: const obx_int.IdUid(2, 1641280788405409404),
      lastRelationId: const obx_int.IdUid(0, 0),
      lastSequenceId: const obx_int.IdUid(0, 0),
      retiredEntityUids: const [100189409228318002],
      retiredIndexUids: const [],
      retiredPropertyUids: const [
        6317656229038089175,
        1248549026383601242,
        4944932276346646936,
        7399582237831664813,
        920284700552311724
      ],
      retiredRelationUids: const [],
      modelVersion: 5,
      modelVersionParserMinimum: 5,
      version: 1);

  final bindings = <Type, obx_int.EntityDefinition>{
    AttributeComponent: obx_int.EntityDefinition<AttributeComponent>(
        model: _entities[0],
        toOneRelations: (AttributeComponent object) =>
            [object.baseNodeParent, object.parent],
        toManyRelations: (AttributeComponent object) => {
              obx_int.RelInfo<AttributeComponent>.toOneBacklink(6, object.id,
                      (AttributeComponent srcObject) => srcObject.parent):
                  object.children
            },
        getId: (AttributeComponent object) => object.id,
        setId: (AttributeComponent object, int id) {
          object.id = id;
        },
        objectToFB: (AttributeComponent object, fb.Builder fbb) {
          final nameOffset = fbb.writeString(object.name);
          final descriptionOffset = fbb.writeString(object.description);
          final contentOffset = fbb.writeString(object.content);
          fbb.startTable(8);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, nameOffset);
          fbb.addOffset(2, descriptionOffset);
          fbb.addOffset(3, contentOffset);
          fbb.addInt64(4, object.baseNodeParent.targetId);
          fbb.addInt64(5, object.parent.targetId);
          fbb.addInt64(6, object.attributePosition);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = AttributeComponent()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..name = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 6, '')
            ..description = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 8, '')
            ..content = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 10, '')
            ..attributePosition = const fb.Int64Reader()
                .vTableGetNullable(buffer, rootOffset, 16);
          object.baseNodeParent.targetId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 12, 0);
          object.baseNodeParent.attach(store);
          object.parent.targetId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 14, 0);
          object.parent.attach(store);
          obx_int.InternalToManyAccess.setRelInfo<AttributeComponent>(
              object.children,
              store,
              obx_int.RelInfo<AttributeComponent>.toOneBacklink(6, object.id,
                  (AttributeComponent srcObject) => srcObject.parent));
          return object;
        }),
    BaseNode: obx_int.EntityDefinition<BaseNode>(
        model: _entities[1],
        toOneRelations: (BaseNode object) => [],
        toManyRelations: (BaseNode object) => {
              obx_int.RelInfo<AttributeComponent>.toOneBacklink(
                  5,
                  object.id,
                  (AttributeComponent srcObject) =>
                      srcObject.baseNodeParent): object.attributes
            },
        getId: (BaseNode object) => object.id,
        setId: (BaseNode object, int id) {
          object.id = id;
        },
        objectToFB: (BaseNode object, fb.Builder fbb) {
          final nameOffset = fbb.writeString(object.name);
          final descriptionOffset = fbb.writeString(object.description);
          final imagePathOffset = fbb.writeString(object.imagePath);
          fbb.startTable(8);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.role);
          fbb.addOffset(2, nameOffset);
          fbb.addOffset(3, descriptionOffset);
          fbb.addInt64(4, object.created?.millisecondsSinceEpoch);
          fbb.addInt64(5, object.modified?.millisecondsSinceEpoch);
          fbb.addOffset(6, imagePathOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final createdValue =
              const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 12);
          final modifiedValue =
              const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 14);
          final object = BaseNode()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..role = const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0)
            ..name = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 8, '')
            ..description = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 10, '')
            ..created = createdValue == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(createdValue)
            ..modified = modifiedValue == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(modifiedValue)
            ..imagePath = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 16, '');
          obx_int.InternalToManyAccess.setRelInfo<BaseNode>(
              object.attributes,
              store,
              obx_int.RelInfo<AttributeComponent>.toOneBacklink(5, object.id,
                  (AttributeComponent srcObject) => srcObject.baseNodeParent));
          return object;
        })
  };

  return obx_int.ModelDefinition(model, bindings);
}

/// [AttributeComponent] entity fields to define ObjectBox queries.
class AttributeComponent_ {
  /// See [AttributeComponent.id].
  static final id =
      obx.QueryIntegerProperty<AttributeComponent>(_entities[0].properties[0]);

  /// See [AttributeComponent.name].
  static final name =
      obx.QueryStringProperty<AttributeComponent>(_entities[0].properties[1]);

  /// See [AttributeComponent.description].
  static final description =
      obx.QueryStringProperty<AttributeComponent>(_entities[0].properties[2]);

  /// See [AttributeComponent.content].
  static final content =
      obx.QueryStringProperty<AttributeComponent>(_entities[0].properties[3]);

  /// See [AttributeComponent.baseNodeParent].
  static final baseNodeParent =
      obx.QueryRelationToOne<AttributeComponent, BaseNode>(
          _entities[0].properties[4]);

  /// See [AttributeComponent.parent].
  static final parent =
      obx.QueryRelationToOne<AttributeComponent, AttributeComponent>(
          _entities[0].properties[5]);

  /// See [AttributeComponent.attributePosition].
  static final attributePosition =
      obx.QueryIntegerProperty<AttributeComponent>(_entities[0].properties[6]);

  /// see [AttributeComponent.children]
  static final children =
      obx.QueryBacklinkToMany<AttributeComponent, AttributeComponent>(
          AttributeComponent_.parent);
}

/// [BaseNode] entity fields to define ObjectBox queries.
class BaseNode_ {
  /// See [BaseNode.id].
  static final id =
      obx.QueryIntegerProperty<BaseNode>(_entities[1].properties[0]);

  /// See [BaseNode.role].
  static final role =
      obx.QueryIntegerProperty<BaseNode>(_entities[1].properties[1]);

  /// See [BaseNode.name].
  static final name =
      obx.QueryStringProperty<BaseNode>(_entities[1].properties[2]);

  /// See [BaseNode.description].
  static final description =
      obx.QueryStringProperty<BaseNode>(_entities[1].properties[3]);

  /// See [BaseNode.created].
  static final created =
      obx.QueryDateProperty<BaseNode>(_entities[1].properties[4]);

  /// See [BaseNode.modified].
  static final modified =
      obx.QueryDateProperty<BaseNode>(_entities[1].properties[5]);

  /// See [BaseNode.imagePath].
  static final imagePath =
      obx.QueryStringProperty<BaseNode>(_entities[1].properties[6]);

  /// see [BaseNode.attributes]
  static final attributes =
      obx.QueryBacklinkToMany<AttributeComponent, BaseNode>(
          AttributeComponent_.baseNodeParent);
}
