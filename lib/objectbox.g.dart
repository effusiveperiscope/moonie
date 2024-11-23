// GENERATED CODE - DO NOT MODIFY BY HAND
// This code was generated by ObjectBox. To update it run the generator again
// with `dart run build_runner build`.
// See also https://docs.objectbox.io/getting-started#generate-objectbox-code

// ignore_for_file: camel_case_types, depend_on_referenced_packages
// coverage:ignore-file

import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'
    as obx_int; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart' as obx;

import 'activities/roleplay/chat_entities.dart';
import 'activities/roleplay/scenario_entities.dart';
import 'modules/rp_entities.dart';

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
      ]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(4, 3282090211557049256),
      name: 'RPChat',
      lastPropertyId: const obx_int.IdUid(3, 1669855966729632464),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 7152136574589467017),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 8091468834881721331),
            name: 'created',
            type: 10,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 1669855966729632464),
            name: 'scenarioId',
            type: 11,
            flags: 520,
            indexId: const obx_int.IdUid(5, 9144486380016293467),
            relationTarget: 'Scenario')
      ],
      relations: <obx_int.ModelRelation>[
        obx_int.ModelRelation(
            id: const obx_int.IdUid(3, 8351717491709240776),
            name: 'fills',
            targetId: const obx_int.IdUid(8, 2211366243110903590))
      ],
      backlinks: <obx_int.ModelBacklink>[
        obx_int.ModelBacklink(
            name: 'messages', srcEntity: 'RPChatMessage', srcField: 'chat')
      ]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(5, 511921411842288960),
      name: 'RPChatMessage',
      lastPropertyId: const obx_int.IdUid(8, 8056134531063793538),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 78964320017614895),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 625961826070715997),
            name: 'chatId',
            type: 11,
            flags: 520,
            indexId: const obx_int.IdUid(3, 5906729401673455253),
            relationTarget: 'RPChat'),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 3396515535393987406),
            name: 'type',
            type: 6,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 5401280511708130726),
            name: 'text',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 8244150442921025964),
            name: 'complete',
            type: 1,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 5398496801857295952),
            name: 'model',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 1773150720023693248),
            name: 'imageFile',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(8, 8056134531063793538),
            name: 'imageBase64',
            type: 9,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(6, 3437152827243650063),
      name: 'Scenario',
      lastPropertyId: const obx_int.IdUid(6, 6322375816734078315),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 867616263981151958),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 840811417770736007),
            name: 'created',
            type: 10,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 6790151879368114499),
            name: 'modified',
            type: 10,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 4129207706312321032),
            name: 'name',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 6971865851957906699),
            name: 'description',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 6322375816734078315),
            name: 'imagePath',
            type: 9,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[
        obx_int.ModelRelation(
            id: const obx_int.IdUid(2, 2908409073072139381),
            name: 'chats',
            targetId: const obx_int.IdUid(4, 3282090211557049256)),
        obx_int.ModelRelation(
            id: const obx_int.IdUid(4, 8341153981932459170),
            name: 'slots',
            targetId: const obx_int.IdUid(7, 3798956690027680554))
      ],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(7, 3798956690027680554),
      name: 'NodeSlot',
      lastPropertyId: const obx_int.IdUid(7, 1994096065274067563),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 6968857406583217591),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 2064520848058214732),
            name: 'defaultFillId',
            type: 11,
            flags: 520,
            indexId: const obx_int.IdUid(4, 5729036034711493949),
            relationTarget: 'SlotFill'),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 6530597446765479775),
            name: 'defaultStringFill',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 5172191515377516785),
            name: 'isStringSlot',
            type: 1,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(5, 8164644701498533613),
            name: 'tag',
            type: 9,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(6, 2519945762232208513),
            name: 'allowsMultiple',
            type: 1,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(7, 1994096065274067563),
            name: 'role',
            type: 6,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[]),
  obx_int.ModelEntity(
      id: const obx_int.IdUid(8, 2211366243110903590),
      name: 'SlotFill',
      lastPropertyId: const obx_int.IdUid(3, 1813809698706916541),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 4009389784590241433),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 1585388554469843925),
            name: 'slotId',
            type: 11,
            flags: 520,
            indexId: const obx_int.IdUid(6, 4945596999143365656),
            relationTarget: 'NodeSlot'),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 1813809698706916541),
            name: 'content',
            type: 9,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[
        obx_int.ModelRelation(
            id: const obx_int.IdUid(5, 5792161197792742413),
            name: 'nodes',
            targetId: const obx_int.IdUid(3, 7450678709023556741))
      ],
      backlinks: <obx_int.ModelBacklink>[])
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
      lastEntityId: const obx_int.IdUid(8, 2211366243110903590),
      lastIndexId: const obx_int.IdUid(6, 4945596999143365656),
      lastRelationId: const obx_int.IdUid(5, 5792161197792742413),
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
      retiredRelationUids: const [7681578514651760447],
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
        }),
    RPChat: obx_int.EntityDefinition<RPChat>(
        model: _entities[2],
        toOneRelations: (RPChat object) => [object.scenario],
        toManyRelations: (RPChat object) => {
              obx_int.RelInfo<RPChat>.toMany(3, object.id): object.fills,
              obx_int.RelInfo<RPChatMessage>.toOneBacklink(2, object.id,
                  (RPChatMessage srcObject) => srcObject.chat): object.messages
            },
        getId: (RPChat object) => object.id,
        setId: (RPChat object, int id) {
          object.id = id;
        },
        objectToFB: (RPChat object, fb.Builder fbb) {
          fbb.startTable(4);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.created?.millisecondsSinceEpoch);
          fbb.addInt64(2, object.scenario.targetId);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final createdValue =
              const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 6);
          final object = RPChat()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..created = createdValue == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(createdValue);
          object.scenario.targetId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0);
          object.scenario.attach(store);
          obx_int.InternalToManyAccess.setRelInfo<RPChat>(object.fills, store,
              obx_int.RelInfo<RPChat>.toMany(3, object.id));
          obx_int.InternalToManyAccess.setRelInfo<RPChat>(
              object.messages,
              store,
              obx_int.RelInfo<RPChatMessage>.toOneBacklink(
                  2, object.id, (RPChatMessage srcObject) => srcObject.chat));
          return object;
        }),
    RPChatMessage: obx_int.EntityDefinition<RPChatMessage>(
        model: _entities[3],
        toOneRelations: (RPChatMessage object) => [object.chat],
        toManyRelations: (RPChatMessage object) => {},
        getId: (RPChatMessage object) => object.id,
        setId: (RPChatMessage object, int id) {
          object.id = id;
        },
        objectToFB: (RPChatMessage object, fb.Builder fbb) {
          final textOffset = fbb.writeString(object.text);
          final modelOffset =
              object.model == null ? null : fbb.writeString(object.model!);
          final imageFileOffset = object.imageFile == null
              ? null
              : fbb.writeString(object.imageFile!);
          final imageBase64Offset = object.imageBase64 == null
              ? null
              : fbb.writeString(object.imageBase64!);
          fbb.startTable(9);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.chat.targetId);
          fbb.addInt64(2, object.type);
          fbb.addOffset(3, textOffset);
          fbb.addBool(4, object.complete);
          fbb.addOffset(5, modelOffset);
          fbb.addOffset(6, imageFileOffset);
          fbb.addOffset(7, imageBase64Offset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = RPChatMessage()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..type = const fb.Int64Reader().vTableGet(buffer, rootOffset, 8, 0)
            ..text = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 10, '')
            ..complete =
                const fb.BoolReader().vTableGet(buffer, rootOffset, 12, false)
            ..model = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 14)
            ..imageFile = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 16)
            ..imageBase64 = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 18);
          object.chat.targetId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0);
          object.chat.attach(store);
          return object;
        }),
    Scenario: obx_int.EntityDefinition<Scenario>(
        model: _entities[4],
        toOneRelations: (Scenario object) => [],
        toManyRelations: (Scenario object) => {
              obx_int.RelInfo<Scenario>.toMany(2, object.id): object.chats,
              obx_int.RelInfo<Scenario>.toMany(4, object.id): object.slots
            },
        getId: (Scenario object) => object.id,
        setId: (Scenario object, int id) {
          object.id = id;
        },
        objectToFB: (Scenario object, fb.Builder fbb) {
          final nameOffset = fbb.writeString(object.name);
          final descriptionOffset = object.description == null
              ? null
              : fbb.writeString(object.description!);
          final imagePathOffset = object.imagePath == null
              ? null
              : fbb.writeString(object.imagePath!);
          fbb.startTable(7);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.created?.millisecondsSinceEpoch);
          fbb.addInt64(2, object.modified?.millisecondsSinceEpoch);
          fbb.addOffset(3, nameOffset);
          fbb.addOffset(4, descriptionOffset);
          fbb.addOffset(5, imagePathOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final createdValue =
              const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 6);
          final modifiedValue =
              const fb.Int64Reader().vTableGetNullable(buffer, rootOffset, 8);
          final object = Scenario()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..created = createdValue == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(createdValue)
            ..modified = modifiedValue == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(modifiedValue)
            ..name = const fb.StringReader(asciiOptimization: true)
                .vTableGet(buffer, rootOffset, 10, '')
            ..description = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 12)
            ..imagePath = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 14);
          obx_int.InternalToManyAccess.setRelInfo<Scenario>(object.chats, store,
              obx_int.RelInfo<Scenario>.toMany(2, object.id));
          obx_int.InternalToManyAccess.setRelInfo<Scenario>(object.slots, store,
              obx_int.RelInfo<Scenario>.toMany(4, object.id));
          return object;
        }),
    NodeSlot: obx_int.EntityDefinition<NodeSlot>(
        model: _entities[5],
        toOneRelations: (NodeSlot object) => [object.defaultFill],
        toManyRelations: (NodeSlot object) => {},
        getId: (NodeSlot object) => object.id,
        setId: (NodeSlot object, int id) {
          object.id = id;
        },
        objectToFB: (NodeSlot object, fb.Builder fbb) {
          final defaultStringFillOffset = object.defaultStringFill == null
              ? null
              : fbb.writeString(object.defaultStringFill!);
          final tagOffset =
              object.tag == null ? null : fbb.writeString(object.tag!);
          fbb.startTable(8);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.defaultFill.targetId);
          fbb.addOffset(2, defaultStringFillOffset);
          fbb.addBool(3, object.isStringSlot);
          fbb.addOffset(4, tagOffset);
          fbb.addBool(5, object.allowsMultiple);
          fbb.addInt64(6, object.role);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = NodeSlot()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..defaultStringFill = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 8)
            ..isStringSlot =
                const fb.BoolReader().vTableGet(buffer, rootOffset, 10, false)
            ..tag = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 12)
            ..allowsMultiple =
                const fb.BoolReader().vTableGet(buffer, rootOffset, 14, false)
            ..role =
                const fb.Int64Reader().vTableGet(buffer, rootOffset, 16, 0);
          object.defaultFill.targetId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0);
          object.defaultFill.attach(store);
          return object;
        }),
    SlotFill: obx_int.EntityDefinition<SlotFill>(
        model: _entities[6],
        toOneRelations: (SlotFill object) => [object.slot],
        toManyRelations: (SlotFill object) =>
            {obx_int.RelInfo<SlotFill>.toMany(5, object.id): object.nodes},
        getId: (SlotFill object) => object.id,
        setId: (SlotFill object, int id) {
          object.id = id;
        },
        objectToFB: (SlotFill object, fb.Builder fbb) {
          final contentOffset =
              object.content == null ? null : fbb.writeString(object.content!);
          fbb.startTable(4);
          fbb.addInt64(0, object.id);
          fbb.addInt64(1, object.slot.targetId);
          fbb.addOffset(2, contentOffset);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);

          final object = SlotFill()
            ..id = const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0)
            ..content = const fb.StringReader(asciiOptimization: true)
                .vTableGetNullable(buffer, rootOffset, 8);
          object.slot.targetId =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 6, 0);
          object.slot.attach(store);
          obx_int.InternalToManyAccess.setRelInfo<SlotFill>(object.nodes, store,
              obx_int.RelInfo<SlotFill>.toMany(5, object.id));
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

/// [RPChat] entity fields to define ObjectBox queries.
class RPChat_ {
  /// See [RPChat.id].
  static final id =
      obx.QueryIntegerProperty<RPChat>(_entities[2].properties[0]);

  /// See [RPChat.created].
  static final created =
      obx.QueryDateProperty<RPChat>(_entities[2].properties[1]);

  /// See [RPChat.scenario].
  static final scenario =
      obx.QueryRelationToOne<RPChat, Scenario>(_entities[2].properties[2]);

  /// see [RPChat.fills]
  static final fills =
      obx.QueryRelationToMany<RPChat, SlotFill>(_entities[2].relations[0]);

  /// see [RPChat.messages]
  static final messages =
      obx.QueryBacklinkToMany<RPChatMessage, RPChat>(RPChatMessage_.chat);
}

/// [RPChatMessage] entity fields to define ObjectBox queries.
class RPChatMessage_ {
  /// See [RPChatMessage.id].
  static final id =
      obx.QueryIntegerProperty<RPChatMessage>(_entities[3].properties[0]);

  /// See [RPChatMessage.chat].
  static final chat =
      obx.QueryRelationToOne<RPChatMessage, RPChat>(_entities[3].properties[1]);

  /// See [RPChatMessage.type].
  static final type =
      obx.QueryIntegerProperty<RPChatMessage>(_entities[3].properties[2]);

  /// See [RPChatMessage.text].
  static final text =
      obx.QueryStringProperty<RPChatMessage>(_entities[3].properties[3]);

  /// See [RPChatMessage.complete].
  static final complete =
      obx.QueryBooleanProperty<RPChatMessage>(_entities[3].properties[4]);

  /// See [RPChatMessage.model].
  static final model =
      obx.QueryStringProperty<RPChatMessage>(_entities[3].properties[5]);

  /// See [RPChatMessage.imageFile].
  static final imageFile =
      obx.QueryStringProperty<RPChatMessage>(_entities[3].properties[6]);

  /// See [RPChatMessage.imageBase64].
  static final imageBase64 =
      obx.QueryStringProperty<RPChatMessage>(_entities[3].properties[7]);
}

/// [Scenario] entity fields to define ObjectBox queries.
class Scenario_ {
  /// See [Scenario.id].
  static final id =
      obx.QueryIntegerProperty<Scenario>(_entities[4].properties[0]);

  /// See [Scenario.created].
  static final created =
      obx.QueryDateProperty<Scenario>(_entities[4].properties[1]);

  /// See [Scenario.modified].
  static final modified =
      obx.QueryDateProperty<Scenario>(_entities[4].properties[2]);

  /// See [Scenario.name].
  static final name =
      obx.QueryStringProperty<Scenario>(_entities[4].properties[3]);

  /// See [Scenario.description].
  static final description =
      obx.QueryStringProperty<Scenario>(_entities[4].properties[4]);

  /// See [Scenario.imagePath].
  static final imagePath =
      obx.QueryStringProperty<Scenario>(_entities[4].properties[5]);

  /// see [Scenario.chats]
  static final chats =
      obx.QueryRelationToMany<Scenario, RPChat>(_entities[4].relations[0]);

  /// see [Scenario.slots]
  static final slots =
      obx.QueryRelationToMany<Scenario, NodeSlot>(_entities[4].relations[1]);
}

/// [NodeSlot] entity fields to define ObjectBox queries.
class NodeSlot_ {
  /// See [NodeSlot.id].
  static final id =
      obx.QueryIntegerProperty<NodeSlot>(_entities[5].properties[0]);

  /// See [NodeSlot.defaultFill].
  static final defaultFill =
      obx.QueryRelationToOne<NodeSlot, SlotFill>(_entities[5].properties[1]);

  /// See [NodeSlot.defaultStringFill].
  static final defaultStringFill =
      obx.QueryStringProperty<NodeSlot>(_entities[5].properties[2]);

  /// See [NodeSlot.isStringSlot].
  static final isStringSlot =
      obx.QueryBooleanProperty<NodeSlot>(_entities[5].properties[3]);

  /// See [NodeSlot.tag].
  static final tag =
      obx.QueryStringProperty<NodeSlot>(_entities[5].properties[4]);

  /// See [NodeSlot.allowsMultiple].
  static final allowsMultiple =
      obx.QueryBooleanProperty<NodeSlot>(_entities[5].properties[5]);

  /// See [NodeSlot.role].
  static final role =
      obx.QueryIntegerProperty<NodeSlot>(_entities[5].properties[6]);
}

/// [SlotFill] entity fields to define ObjectBox queries.
class SlotFill_ {
  /// See [SlotFill.id].
  static final id =
      obx.QueryIntegerProperty<SlotFill>(_entities[6].properties[0]);

  /// See [SlotFill.slot].
  static final slot =
      obx.QueryRelationToOne<SlotFill, NodeSlot>(_entities[6].properties[1]);

  /// See [SlotFill.content].
  static final content =
      obx.QueryStringProperty<SlotFill>(_entities[6].properties[2]);

  /// see [SlotFill.nodes]
  static final nodes =
      obx.QueryRelationToMany<SlotFill, BaseNode>(_entities[6].relations[0]);
}
