// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marker_map_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMarkerMapEntityCollection on Isar {
  IsarCollection<MarkerMapEntity> get markerMapEntitys => this.collection();
}

const MarkerMapEntitySchema = CollectionSchema(
  name: r'MarkerMapEntity',
  id: 6420463118047562027,
  properties: {
    r'attachedNotesText': PropertySchema(
      id: 0,
      name: r'attachedNotesText',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 2,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'firebaseId': PropertySchema(
      id: 3,
      name: r'firebaseId',
      type: IsarType.string,
    ),
    r'hasMarkers': PropertySchema(
      id: 4,
      name: r'hasMarkers',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 5,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'markedForDeletion': PropertySchema(
      id: 6,
      name: r'markedForDeletion',
      type: IsarType.bool,
    ),
    r'markersCount': PropertySchema(
      id: 7,
      name: r'markersCount',
      type: IsarType.long,
    ),
    r'markersJson': PropertySchema(
      id: 8,
      name: r'markersJson',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 9,
      name: r'name',
      type: IsarType.string,
    ),
    r'noteId': PropertySchema(
      id: 10,
      name: r'noteId',
      type: IsarType.string,
    ),
    r'noteIds': PropertySchema(
      id: 11,
      name: r'noteIds',
      type: IsarType.stringList,
    ),
    r'noteName': PropertySchema(
      id: 12,
      name: r'noteName',
      type: IsarType.string,
    ),
    r'noteNames': PropertySchema(
      id: 13,
      name: r'noteNames',
      type: IsarType.stringList,
    ),
    r'sector': PropertySchema(
      id: 14,
      name: r'sector',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 15,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 16,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _markerMapEntityEstimateSize,
  serialize: _markerMapEntitySerialize,
  deserialize: _markerMapEntityDeserialize,
  deserializeProp: _markerMapEntityDeserializeProp,
  idName: r'id',
  indexes: {
    r'firebaseId': IndexSchema(
      id: -334079192014120732,
      name: r'firebaseId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'firebaseId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _markerMapEntityGetId,
  getLinks: _markerMapEntityGetLinks,
  attach: _markerMapEntityAttach,
  version: '3.1.0+1',
);

int _markerMapEntityEstimateSize(
  MarkerMapEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.attachedNotesText.length * 3;
  {
    final value = object.firebaseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.markersJson.length * 3;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.noteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.noteIds.length * 3;
  {
    for (var i = 0; i < object.noteIds.length; i++) {
      final value = object.noteIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.noteName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.noteNames.length * 3;
  {
    for (var i = 0; i < object.noteNames.length; i++) {
      final value = object.noteNames[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.sector;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _markerMapEntitySerialize(
  MarkerMapEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.attachedNotesText);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.date);
  writer.writeString(offsets[3], object.firebaseId);
  writer.writeBool(offsets[4], object.hasMarkers);
  writer.writeBool(offsets[5], object.isSynced);
  writer.writeBool(offsets[6], object.markedForDeletion);
  writer.writeLong(offsets[7], object.markersCount);
  writer.writeString(offsets[8], object.markersJson);
  writer.writeString(offsets[9], object.name);
  writer.writeString(offsets[10], object.noteId);
  writer.writeStringList(offsets[11], object.noteIds);
  writer.writeString(offsets[12], object.noteName);
  writer.writeStringList(offsets[13], object.noteNames);
  writer.writeString(offsets[14], object.sector);
  writer.writeDateTime(offsets[15], object.updatedAt);
  writer.writeString(offsets[16], object.userId);
}

MarkerMapEntity _markerMapEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MarkerMapEntity();
  object.createdAt = reader.readDateTime(offsets[1]);
  object.date = reader.readDateTime(offsets[2]);
  object.firebaseId = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[5]);
  object.markedForDeletion = reader.readBool(offsets[6]);
  object.markersJson = reader.readString(offsets[8]);
  object.name = reader.readString(offsets[9]);
  object.noteIds = reader.readStringList(offsets[11]) ?? [];
  object.noteNames = reader.readStringList(offsets[13]) ?? [];
  object.sector = reader.readStringOrNull(offsets[14]);
  object.updatedAt = reader.readDateTime(offsets[15]);
  object.userId = reader.readString(offsets[16]);
  return object;
}

P _markerMapEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringList(offset) ?? []) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringList(offset) ?? []) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _markerMapEntityGetId(MarkerMapEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _markerMapEntityGetLinks(MarkerMapEntity object) {
  return [];
}

void _markerMapEntityAttach(
    IsarCollection<dynamic> col, Id id, MarkerMapEntity object) {
  object.id = id;
}

extension MarkerMapEntityByIndex on IsarCollection<MarkerMapEntity> {
  Future<MarkerMapEntity?> getByFirebaseId(String? firebaseId) {
    return getByIndex(r'firebaseId', [firebaseId]);
  }

  MarkerMapEntity? getByFirebaseIdSync(String? firebaseId) {
    return getByIndexSync(r'firebaseId', [firebaseId]);
  }

  Future<bool> deleteByFirebaseId(String? firebaseId) {
    return deleteByIndex(r'firebaseId', [firebaseId]);
  }

  bool deleteByFirebaseIdSync(String? firebaseId) {
    return deleteByIndexSync(r'firebaseId', [firebaseId]);
  }

  Future<List<MarkerMapEntity?>> getAllByFirebaseId(
      List<String?> firebaseIdValues) {
    final values = firebaseIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'firebaseId', values);
  }

  List<MarkerMapEntity?> getAllByFirebaseIdSync(
      List<String?> firebaseIdValues) {
    final values = firebaseIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'firebaseId', values);
  }

  Future<int> deleteAllByFirebaseId(List<String?> firebaseIdValues) {
    final values = firebaseIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'firebaseId', values);
  }

  int deleteAllByFirebaseIdSync(List<String?> firebaseIdValues) {
    final values = firebaseIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'firebaseId', values);
  }

  Future<Id> putByFirebaseId(MarkerMapEntity object) {
    return putByIndex(r'firebaseId', object);
  }

  Id putByFirebaseIdSync(MarkerMapEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'firebaseId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFirebaseId(List<MarkerMapEntity> objects) {
    return putAllByIndex(r'firebaseId', objects);
  }

  List<Id> putAllByFirebaseIdSync(List<MarkerMapEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'firebaseId', objects, saveLinks: saveLinks);
  }
}

extension MarkerMapEntityQueryWhereSort
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QWhere> {
  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MarkerMapEntityQueryWhere
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QWhereClause> {
  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause>
      firebaseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firebaseId',
        value: [null],
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause>
      firebaseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'firebaseId',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause>
      firebaseIdEqualTo(String? firebaseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firebaseId',
        value: [firebaseId],
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterWhereClause>
      firebaseIdNotEqualTo(String? firebaseId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firebaseId',
              lower: [],
              upper: [firebaseId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firebaseId',
              lower: [firebaseId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firebaseId',
              lower: [firebaseId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'firebaseId',
              lower: [],
              upper: [firebaseId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MarkerMapEntityQueryFilter
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QFilterCondition> {
  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachedNotesText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachedNotesText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachedNotesText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachedNotesText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attachedNotesText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attachedNotesText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attachedNotesText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attachedNotesText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachedNotesText',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      attachedNotesTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attachedNotesText',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firebaseId',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firebaseId',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firebaseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firebaseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firebaseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firebaseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'firebaseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'firebaseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'firebaseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'firebaseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firebaseId',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      firebaseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'firebaseId',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      hasMarkersEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasMarkers',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markedForDeletion',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markersCount',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'markersCount',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'markersCount',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'markersCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'markersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'markersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'markersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'markersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'markersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'markersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'markersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      markersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'markersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'noteId',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'noteId',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteId',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noteId',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noteIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noteIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noteIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noteIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noteIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noteIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noteIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteIds',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noteIds',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'noteName',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'noteName',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noteName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noteName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noteName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noteName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noteName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noteName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noteName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteName',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noteName',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noteNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noteNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noteNames',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noteNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noteNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noteNames',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noteNames',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteNames',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noteNames',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteNames',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteNames',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteNames',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteNames',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteNames',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      noteNamesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'noteNames',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sector',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sector',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sector',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sector',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sector',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sector',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sector',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sector',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sector',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sector',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sector',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      sectorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sector',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension MarkerMapEntityQueryObject
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QFilterCondition> {}

extension MarkerMapEntityQueryLinks
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QFilterCondition> {}

extension MarkerMapEntityQuerySortBy
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QSortBy> {
  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByAttachedNotesText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachedNotesText', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByAttachedNotesTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachedNotesText', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByFirebaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByFirebaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByHasMarkers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasMarkers', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByHasMarkersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasMarkers', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByMarkersCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markersCount', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByMarkersCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markersCount', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByMarkersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markersJson', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByMarkersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markersJson', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> sortByNoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteId', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByNoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteId', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByNoteName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteName', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByNoteNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteName', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> sortBySector() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sector', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortBySectorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sector', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension MarkerMapEntityQuerySortThenBy
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QSortThenBy> {
  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByAttachedNotesText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachedNotesText', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByAttachedNotesTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachedNotesText', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByFirebaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByFirebaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByHasMarkers() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasMarkers', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByHasMarkersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasMarkers', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByMarkersCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markersCount', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByMarkersCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markersCount', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByMarkersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markersJson', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByMarkersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markersJson', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> thenByNoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteId', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByNoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteId', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByNoteName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteName', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByNoteNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteName', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> thenBySector() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sector', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenBySectorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sector', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension MarkerMapEntityQueryWhereDistinct
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct> {
  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByAttachedNotesText({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attachedNotesText',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByFirebaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firebaseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByHasMarkers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasMarkers');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'markedForDeletion');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByMarkersCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'markersCount');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByMarkersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'markersJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct> distinctByNoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByNoteIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteIds');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct> distinctByNoteName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByNoteNames() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteNames');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct> distinctBySector(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sector', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<MarkerMapEntity, MarkerMapEntity, QDistinct> distinctByUserId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension MarkerMapEntityQueryProperty
    on QueryBuilder<MarkerMapEntity, MarkerMapEntity, QQueryProperty> {
  QueryBuilder<MarkerMapEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MarkerMapEntity, String, QQueryOperations>
      attachedNotesTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachedNotesText');
    });
  }

  QueryBuilder<MarkerMapEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<MarkerMapEntity, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<MarkerMapEntity, String?, QQueryOperations>
      firebaseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firebaseId');
    });
  }

  QueryBuilder<MarkerMapEntity, bool, QQueryOperations> hasMarkersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasMarkers');
    });
  }

  QueryBuilder<MarkerMapEntity, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<MarkerMapEntity, bool, QQueryOperations>
      markedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'markedForDeletion');
    });
  }

  QueryBuilder<MarkerMapEntity, int, QQueryOperations> markersCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'markersCount');
    });
  }

  QueryBuilder<MarkerMapEntity, String, QQueryOperations>
      markersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'markersJson');
    });
  }

  QueryBuilder<MarkerMapEntity, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<MarkerMapEntity, String?, QQueryOperations> noteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteId');
    });
  }

  QueryBuilder<MarkerMapEntity, List<String>, QQueryOperations>
      noteIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteIds');
    });
  }

  QueryBuilder<MarkerMapEntity, String?, QQueryOperations> noteNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteName');
    });
  }

  QueryBuilder<MarkerMapEntity, List<String>, QQueryOperations>
      noteNamesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteNames');
    });
  }

  QueryBuilder<MarkerMapEntity, String?, QQueryOperations> sectorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sector');
    });
  }

  QueryBuilder<MarkerMapEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<MarkerMapEntity, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
