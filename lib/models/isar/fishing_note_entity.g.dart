// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fishing_note_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFishingNoteEntityCollection on Isar {
  IsarCollection<FishingNoteEntity> get fishingNoteEntitys => this.collection();
}

const FishingNoteEntitySchema = CollectionSchema(
  name: r'FishingNoteEntity',
  id: -5543011519468996937,
  properties: {
    r'aiPrediction': PropertySchema(
      id: 0,
      name: r'aiPrediction',
      type: IsarType.object,
      target: r'AiPredictionEntity',
    ),
    r'baitProgramIds': PropertySchema(
      id: 1,
      name: r'baitProgramIds',
      type: IsarType.stringList,
    ),
    r'biteRecords': PropertySchema(
      id: 2,
      name: r'biteRecords',
      type: IsarType.objectList,
      target: r'BiteRecordEntity',
    ),
    r'createdAt': PropertySchema(
      id: 3,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 4,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'endDate': PropertySchema(
      id: 6,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'firebaseId': PropertySchema(
      id: 7,
      name: r'firebaseId',
      type: IsarType.string,
    ),
    r'fishingType': PropertySchema(
      id: 8,
      name: r'fishingType',
      type: IsarType.string,
    ),
    r'isMultiDay': PropertySchema(
      id: 9,
      name: r'isMultiDay',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 10,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'latitude': PropertySchema(
      id: 11,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'location': PropertySchema(
      id: 12,
      name: r'location',
      type: IsarType.string,
    ),
    r'longitude': PropertySchema(
      id: 13,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'mapMarkersJson': PropertySchema(
      id: 14,
      name: r'mapMarkersJson',
      type: IsarType.string,
    ),
    r'markedForDeletion': PropertySchema(
      id: 15,
      name: r'markedForDeletion',
      type: IsarType.bool,
    ),
    r'notes': PropertySchema(
      id: 16,
      name: r'notes',
      type: IsarType.string,
    ),
    r'photoUrls': PropertySchema(
      id: 17,
      name: r'photoUrls',
      type: IsarType.stringList,
    ),
    r'tackle': PropertySchema(
      id: 18,
      name: r'tackle',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 19,
      name: r'title',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 20,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 21,
      name: r'userId',
      type: IsarType.string,
    ),
    r'weatherData': PropertySchema(
      id: 22,
      name: r'weatherData',
      type: IsarType.object,
      target: r'WeatherDataEntity',
    )
  },
  estimateSize: _fishingNoteEntityEstimateSize,
  serialize: _fishingNoteEntitySerialize,
  deserialize: _fishingNoteEntityDeserialize,
  deserializeProp: _fishingNoteEntityDeserializeProp,
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
    ),
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'markedForDeletion': IndexSchema(
      id: 4789654020591589618,
      name: r'markedForDeletion',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'markedForDeletion',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'AiPredictionEntity': AiPredictionEntitySchema,
    r'WeatherDataEntity': WeatherDataEntitySchema,
    r'BiteRecordEntity': BiteRecordEntitySchema
  },
  getId: _fishingNoteEntityGetId,
  getLinks: _fishingNoteEntityGetLinks,
  attach: _fishingNoteEntityAttach,
  version: '3.1.0+1',
);

int _fishingNoteEntityEstimateSize(
  FishingNoteEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.aiPrediction;
    if (value != null) {
      bytesCount += 3 +
          AiPredictionEntitySchema.estimateSize(
              value, allOffsets[AiPredictionEntity]!, allOffsets);
    }
  }
  bytesCount += 3 + object.baitProgramIds.length * 3;
  {
    for (var i = 0; i < object.baitProgramIds.length; i++) {
      final value = object.baitProgramIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.biteRecords.length * 3;
  {
    final offsets = allOffsets[BiteRecordEntity]!;
    for (var i = 0; i < object.biteRecords.length; i++) {
      final value = object.biteRecords[i];
      bytesCount +=
          BiteRecordEntitySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.firebaseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fishingType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.location;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mapMarkersJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.photoUrls.length * 3;
  {
    for (var i = 0; i < object.photoUrls.length; i++) {
      final value = object.photoUrls[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.tackle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  {
    final value = object.weatherData;
    if (value != null) {
      bytesCount += 3 +
          WeatherDataEntitySchema.estimateSize(
              value, allOffsets[WeatherDataEntity]!, allOffsets);
    }
  }
  return bytesCount;
}

void _fishingNoteEntitySerialize(
  FishingNoteEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<AiPredictionEntity>(
    offsets[0],
    allOffsets,
    AiPredictionEntitySchema.serialize,
    object.aiPrediction,
  );
  writer.writeStringList(offsets[1], object.baitProgramIds);
  writer.writeObjectList<BiteRecordEntity>(
    offsets[2],
    allOffsets,
    BiteRecordEntitySchema.serialize,
    object.biteRecords,
  );
  writer.writeDateTime(offsets[3], object.createdAt);
  writer.writeDateTime(offsets[4], object.date);
  writer.writeString(offsets[5], object.description);
  writer.writeDateTime(offsets[6], object.endDate);
  writer.writeString(offsets[7], object.firebaseId);
  writer.writeString(offsets[8], object.fishingType);
  writer.writeBool(offsets[9], object.isMultiDay);
  writer.writeBool(offsets[10], object.isSynced);
  writer.writeDouble(offsets[11], object.latitude);
  writer.writeString(offsets[12], object.location);
  writer.writeDouble(offsets[13], object.longitude);
  writer.writeString(offsets[14], object.mapMarkersJson);
  writer.writeBool(offsets[15], object.markedForDeletion);
  writer.writeString(offsets[16], object.notes);
  writer.writeStringList(offsets[17], object.photoUrls);
  writer.writeString(offsets[18], object.tackle);
  writer.writeString(offsets[19], object.title);
  writer.writeDateTime(offsets[20], object.updatedAt);
  writer.writeString(offsets[21], object.userId);
  writer.writeObject<WeatherDataEntity>(
    offsets[22],
    allOffsets,
    WeatherDataEntitySchema.serialize,
    object.weatherData,
  );
}

FishingNoteEntity _fishingNoteEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FishingNoteEntity();
  object.aiPrediction = reader.readObjectOrNull<AiPredictionEntity>(
    offsets[0],
    AiPredictionEntitySchema.deserialize,
    allOffsets,
  );
  object.baitProgramIds = reader.readStringList(offsets[1]) ?? [];
  object.biteRecords = reader.readObjectList<BiteRecordEntity>(
        offsets[2],
        BiteRecordEntitySchema.deserialize,
        allOffsets,
        BiteRecordEntity(),
      ) ??
      [];
  object.createdAt = reader.readDateTime(offsets[3]);
  object.date = reader.readDateTime(offsets[4]);
  object.description = reader.readStringOrNull(offsets[5]);
  object.endDate = reader.readDateTimeOrNull(offsets[6]);
  object.firebaseId = reader.readStringOrNull(offsets[7]);
  object.fishingType = reader.readStringOrNull(offsets[8]);
  object.id = id;
  object.isMultiDay = reader.readBool(offsets[9]);
  object.isSynced = reader.readBool(offsets[10]);
  object.latitude = reader.readDoubleOrNull(offsets[11]);
  object.location = reader.readStringOrNull(offsets[12]);
  object.longitude = reader.readDoubleOrNull(offsets[13]);
  object.mapMarkersJson = reader.readStringOrNull(offsets[14]);
  object.markedForDeletion = reader.readBool(offsets[15]);
  object.notes = reader.readStringOrNull(offsets[16]);
  object.photoUrls = reader.readStringList(offsets[17]) ?? [];
  object.tackle = reader.readStringOrNull(offsets[18]);
  object.title = reader.readString(offsets[19]);
  object.updatedAt = reader.readDateTime(offsets[20]);
  object.userId = reader.readString(offsets[21]);
  object.weatherData = reader.readObjectOrNull<WeatherDataEntity>(
    offsets[22],
    WeatherDataEntitySchema.deserialize,
    allOffsets,
  );
  return object;
}

P _fishingNoteEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<AiPredictionEntity>(
        offset,
        AiPredictionEntitySchema.deserialize,
        allOffsets,
      )) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readObjectList<BiteRecordEntity>(
            offset,
            BiteRecordEntitySchema.deserialize,
            allOffsets,
            BiteRecordEntity(),
          ) ??
          []) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringList(offset) ?? []) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    case 20:
      return (reader.readDateTime(offset)) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readObjectOrNull<WeatherDataEntity>(
        offset,
        WeatherDataEntitySchema.deserialize,
        allOffsets,
      )) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _fishingNoteEntityGetId(FishingNoteEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _fishingNoteEntityGetLinks(
    FishingNoteEntity object) {
  return [];
}

void _fishingNoteEntityAttach(
    IsarCollection<dynamic> col, Id id, FishingNoteEntity object) {
  object.id = id;
}

extension FishingNoteEntityByIndex on IsarCollection<FishingNoteEntity> {
  Future<FishingNoteEntity?> getByFirebaseId(String? firebaseId) {
    return getByIndex(r'firebaseId', [firebaseId]);
  }

  FishingNoteEntity? getByFirebaseIdSync(String? firebaseId) {
    return getByIndexSync(r'firebaseId', [firebaseId]);
  }

  Future<bool> deleteByFirebaseId(String? firebaseId) {
    return deleteByIndex(r'firebaseId', [firebaseId]);
  }

  bool deleteByFirebaseIdSync(String? firebaseId) {
    return deleteByIndexSync(r'firebaseId', [firebaseId]);
  }

  Future<List<FishingNoteEntity?>> getAllByFirebaseId(
      List<String?> firebaseIdValues) {
    final values = firebaseIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'firebaseId', values);
  }

  List<FishingNoteEntity?> getAllByFirebaseIdSync(
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

  Future<Id> putByFirebaseId(FishingNoteEntity object) {
    return putByIndex(r'firebaseId', object);
  }

  Id putByFirebaseIdSync(FishingNoteEntity object, {bool saveLinks = true}) {
    return putByIndexSync(r'firebaseId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFirebaseId(List<FishingNoteEntity> objects) {
    return putAllByIndex(r'firebaseId', objects);
  }

  List<Id> putAllByFirebaseIdSync(List<FishingNoteEntity> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'firebaseId', objects, saveLinks: saveLinks);
  }
}

extension FishingNoteEntityQueryWhereSort
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QWhere> {
  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhere>
      anyMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'markedForDeletion'),
      );
    });
  }
}

extension FishingNoteEntityQueryWhere
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QWhereClause> {
  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      firebaseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firebaseId',
        value: [null],
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      firebaseIdEqualTo(String? firebaseId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'firebaseId',
        value: [firebaseId],
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      userIdEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      userIdNotEqualTo(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      markedForDeletionEqualTo(bool markedForDeletion) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'markedForDeletion',
        value: [markedForDeletion],
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterWhereClause>
      markedForDeletionNotEqualTo(bool markedForDeletion) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'markedForDeletion',
              lower: [],
              upper: [markedForDeletion],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'markedForDeletion',
              lower: [markedForDeletion],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'markedForDeletion',
              lower: [markedForDeletion],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'markedForDeletion',
              lower: [],
              upper: [markedForDeletion],
              includeUpper: false,
            ));
      }
    });
  }
}

extension FishingNoteEntityQueryFilter
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QFilterCondition> {
  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      aiPredictionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aiPrediction',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      aiPredictionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aiPrediction',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baitProgramIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baitProgramIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baitProgramIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baitProgramIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'baitProgramIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'baitProgramIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'baitProgramIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'baitProgramIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baitProgramIds',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'baitProgramIds',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'baitProgramIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'baitProgramIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'baitProgramIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'baitProgramIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'baitProgramIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      baitProgramIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'baitProgramIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      biteRecordsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'biteRecords',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      biteRecordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'biteRecords',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      biteRecordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'biteRecords',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      biteRecordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'biteRecords',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      biteRecordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'biteRecords',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      biteRecordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'biteRecords',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      endDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      endDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      endDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      endDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      firebaseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firebaseId',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      firebaseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firebaseId',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      firebaseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'firebaseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      firebaseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'firebaseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      firebaseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firebaseId',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      firebaseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'firebaseId',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fishingType',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fishingType',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fishingType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fishingType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishingType',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      fishingTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fishingType',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      isMultiDayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMultiDay',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'latitude',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'latitude',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      latitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      latitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      latitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'latitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      latitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'latitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'location',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'location',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'location',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'location',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'location',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      locationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'location',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'longitude',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'longitude',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      longitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      longitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      longitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'longitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      longitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'longitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mapMarkersJson',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mapMarkersJson',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mapMarkersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mapMarkersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mapMarkersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mapMarkersJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mapMarkersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mapMarkersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mapMarkersJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mapMarkersJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mapMarkersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      mapMarkersJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mapMarkersJson',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      markedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markedForDeletion',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoUrls',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoUrls',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoUrls',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoUrls',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      photoUrlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tackle',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tackle',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tackle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tackle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tackle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tackle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tackle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tackle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tackle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tackle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tackle',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      tackleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tackle',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
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

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      weatherDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weatherData',
      ));
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      weatherDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weatherData',
      ));
    });
  }
}

extension FishingNoteEntityQueryObject
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QFilterCondition> {
  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      aiPrediction(FilterQuery<AiPredictionEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'aiPrediction');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      biteRecordsElement(FilterQuery<BiteRecordEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'biteRecords');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterFilterCondition>
      weatherData(FilterQuery<WeatherDataEntity> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'weatherData');
    });
  }
}

extension FishingNoteEntityQueryLinks
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QFilterCondition> {}

extension FishingNoteEntityQuerySortBy
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QSortBy> {
  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByFirebaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByFirebaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByFishingType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fishingType', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByFishingTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fishingType', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByIsMultiDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMultiDay', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByIsMultiDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMultiDay', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByMapMarkersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapMarkersJson', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByMapMarkersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapMarkersJson', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByTackle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tackle', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByTackleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tackle', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension FishingNoteEntityQuerySortThenBy
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QSortThenBy> {
  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByFirebaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByFirebaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByFishingType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fishingType', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByFishingTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fishingType', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByIsMultiDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMultiDay', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByIsMultiDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMultiDay', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByMapMarkersJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapMarkersJson', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByMapMarkersJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mapMarkersJson', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByTackle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tackle', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByTackleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tackle', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension FishingNoteEntityQueryWhereDistinct
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct> {
  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByBaitProgramIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baitProgramIds');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByFirebaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firebaseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByFishingType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fishingType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByIsMultiDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMultiDay');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'location', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByMapMarkersJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mapMarkersJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'markedForDeletion');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByPhotoUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'photoUrls');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByTackle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tackle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<FishingNoteEntity, FishingNoteEntity, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension FishingNoteEntityQueryProperty
    on QueryBuilder<FishingNoteEntity, FishingNoteEntity, QQueryProperty> {
  QueryBuilder<FishingNoteEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FishingNoteEntity, AiPredictionEntity?, QQueryOperations>
      aiPredictionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aiPrediction');
    });
  }

  QueryBuilder<FishingNoteEntity, List<String>, QQueryOperations>
      baitProgramIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baitProgramIds');
    });
  }

  QueryBuilder<FishingNoteEntity, List<BiteRecordEntity>, QQueryOperations>
      biteRecordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'biteRecords');
    });
  }

  QueryBuilder<FishingNoteEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<FishingNoteEntity, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<FishingNoteEntity, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<FishingNoteEntity, DateTime?, QQueryOperations>
      endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<FishingNoteEntity, String?, QQueryOperations>
      firebaseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firebaseId');
    });
  }

  QueryBuilder<FishingNoteEntity, String?, QQueryOperations>
      fishingTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fishingType');
    });
  }

  QueryBuilder<FishingNoteEntity, bool, QQueryOperations> isMultiDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMultiDay');
    });
  }

  QueryBuilder<FishingNoteEntity, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<FishingNoteEntity, double?, QQueryOperations>
      latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<FishingNoteEntity, String?, QQueryOperations>
      locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'location');
    });
  }

  QueryBuilder<FishingNoteEntity, double?, QQueryOperations>
      longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<FishingNoteEntity, String?, QQueryOperations>
      mapMarkersJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mapMarkersJson');
    });
  }

  QueryBuilder<FishingNoteEntity, bool, QQueryOperations>
      markedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'markedForDeletion');
    });
  }

  QueryBuilder<FishingNoteEntity, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<FishingNoteEntity, List<String>, QQueryOperations>
      photoUrlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'photoUrls');
    });
  }

  QueryBuilder<FishingNoteEntity, String?, QQueryOperations> tackleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tackle');
    });
  }

  QueryBuilder<FishingNoteEntity, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<FishingNoteEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<FishingNoteEntity, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<FishingNoteEntity, WeatherDataEntity?, QQueryOperations>
      weatherDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weatherData');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const WeatherDataEntitySchema = Schema(
  name: r'WeatherDataEntity',
  id: 4250361158499786831,
  properties: {
    r'cloudCover': PropertySchema(
      id: 0,
      name: r'cloudCover',
      type: IsarType.double,
    ),
    r'condition': PropertySchema(
      id: 1,
      name: r'condition',
      type: IsarType.string,
    ),
    r'feelsLike': PropertySchema(
      id: 2,
      name: r'feelsLike',
      type: IsarType.double,
    ),
    r'humidity': PropertySchema(
      id: 3,
      name: r'humidity',
      type: IsarType.double,
    ),
    r'isDay': PropertySchema(
      id: 4,
      name: r'isDay',
      type: IsarType.bool,
    ),
    r'pressure': PropertySchema(
      id: 5,
      name: r'pressure',
      type: IsarType.double,
    ),
    r'recordedAt': PropertySchema(
      id: 6,
      name: r'recordedAt',
      type: IsarType.dateTime,
    ),
    r'sunrise': PropertySchema(
      id: 7,
      name: r'sunrise',
      type: IsarType.string,
    ),
    r'sunset': PropertySchema(
      id: 8,
      name: r'sunset',
      type: IsarType.string,
    ),
    r'temperature': PropertySchema(
      id: 9,
      name: r'temperature',
      type: IsarType.double,
    ),
    r'timestamp': PropertySchema(
      id: 10,
      name: r'timestamp',
      type: IsarType.long,
    ),
    r'windDirection': PropertySchema(
      id: 11,
      name: r'windDirection',
      type: IsarType.string,
    ),
    r'windSpeed': PropertySchema(
      id: 12,
      name: r'windSpeed',
      type: IsarType.double,
    )
  },
  estimateSize: _weatherDataEntityEstimateSize,
  serialize: _weatherDataEntitySerialize,
  deserialize: _weatherDataEntityDeserialize,
  deserializeProp: _weatherDataEntityDeserializeProp,
);

int _weatherDataEntityEstimateSize(
  WeatherDataEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.condition;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sunrise;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sunset;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.windDirection;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _weatherDataEntitySerialize(
  WeatherDataEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.cloudCover);
  writer.writeString(offsets[1], object.condition);
  writer.writeDouble(offsets[2], object.feelsLike);
  writer.writeDouble(offsets[3], object.humidity);
  writer.writeBool(offsets[4], object.isDay);
  writer.writeDouble(offsets[5], object.pressure);
  writer.writeDateTime(offsets[6], object.recordedAt);
  writer.writeString(offsets[7], object.sunrise);
  writer.writeString(offsets[8], object.sunset);
  writer.writeDouble(offsets[9], object.temperature);
  writer.writeLong(offsets[10], object.timestamp);
  writer.writeString(offsets[11], object.windDirection);
  writer.writeDouble(offsets[12], object.windSpeed);
}

WeatherDataEntity _weatherDataEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WeatherDataEntity();
  object.cloudCover = reader.readDoubleOrNull(offsets[0]);
  object.condition = reader.readStringOrNull(offsets[1]);
  object.feelsLike = reader.readDoubleOrNull(offsets[2]);
  object.humidity = reader.readDoubleOrNull(offsets[3]);
  object.isDay = reader.readBool(offsets[4]);
  object.pressure = reader.readDoubleOrNull(offsets[5]);
  object.recordedAt = reader.readDateTimeOrNull(offsets[6]);
  object.sunrise = reader.readStringOrNull(offsets[7]);
  object.sunset = reader.readStringOrNull(offsets[8]);
  object.temperature = reader.readDoubleOrNull(offsets[9]);
  object.timestamp = reader.readLongOrNull(offsets[10]);
  object.windDirection = reader.readStringOrNull(offsets[11]);
  object.windSpeed = reader.readDoubleOrNull(offsets[12]);
  return object;
}

P _weatherDataEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension WeatherDataEntityQueryFilter
    on QueryBuilder<WeatherDataEntity, WeatherDataEntity, QFilterCondition> {
  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      cloudCoverIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cloudCover',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      cloudCoverIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cloudCover',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      cloudCoverEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cloudCover',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      cloudCoverGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cloudCover',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      cloudCoverLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cloudCover',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      cloudCoverBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cloudCover',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'condition',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'condition',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'condition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'condition',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'condition',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'condition',
        value: '',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      conditionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'condition',
        value: '',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      feelsLikeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'feelsLike',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      feelsLikeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'feelsLike',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      feelsLikeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'feelsLike',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      feelsLikeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'feelsLike',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      feelsLikeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'feelsLike',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      feelsLikeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'feelsLike',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      humidityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'humidity',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      humidityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'humidity',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      humidityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'humidity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      humidityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'humidity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      humidityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'humidity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      humidityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'humidity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      isDayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDay',
        value: value,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      pressureIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pressure',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      pressureIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pressure',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      pressureEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pressure',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      pressureGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pressure',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      pressureLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pressure',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      pressureBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pressure',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      recordedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recordedAt',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      recordedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recordedAt',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      recordedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      recordedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      recordedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recordedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      recordedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recordedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sunrise',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sunrise',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sunrise',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sunrise',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sunrise',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sunrise',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sunrise',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sunrise',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sunrise',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sunrise',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sunrise',
        value: '',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunriseIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sunrise',
        value: '',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sunset',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sunset',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sunset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sunset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sunset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sunset',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sunset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sunset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sunset',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sunset',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sunset',
        value: '',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      sunsetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sunset',
        value: '',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      temperatureIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'temperature',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      temperatureIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'temperature',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      temperatureEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'temperature',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      temperatureGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'temperature',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      temperatureLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'temperature',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      temperatureBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'temperature',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      timestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timestamp',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      timestampIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timestamp',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      timestampEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      timestampGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      timestampLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      timestampBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'windDirection',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'windDirection',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'windDirection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'windDirection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'windDirection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'windDirection',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'windDirection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'windDirection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'windDirection',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'windDirection',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'windDirection',
        value: '',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windDirectionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'windDirection',
        value: '',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windSpeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'windSpeed',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windSpeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'windSpeed',
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windSpeedEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'windSpeed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windSpeedGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'windSpeed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windSpeedLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'windSpeed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WeatherDataEntity, WeatherDataEntity, QAfterFilterCondition>
      windSpeedBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'windSpeed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension WeatherDataEntityQueryObject
    on QueryBuilder<WeatherDataEntity, WeatherDataEntity, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const BiteRecordEntitySchema = Schema(
  name: r'BiteRecordEntity',
  id: 3826637295479299095,
  properties: {
    r'baitUsed': PropertySchema(
      id: 0,
      name: r'baitUsed',
      type: IsarType.string,
    ),
    r'biteId': PropertySchema(
      id: 1,
      name: r'biteId',
      type: IsarType.string,
    ),
    r'dayIndex': PropertySchema(
      id: 2,
      name: r'dayIndex',
      type: IsarType.long,
    ),
    r'fishLength': PropertySchema(
      id: 3,
      name: r'fishLength',
      type: IsarType.double,
    ),
    r'fishType': PropertySchema(
      id: 4,
      name: r'fishType',
      type: IsarType.string,
    ),
    r'fishWeight': PropertySchema(
      id: 5,
      name: r'fishWeight',
      type: IsarType.double,
    ),
    r'notes': PropertySchema(
      id: 6,
      name: r'notes',
      type: IsarType.string,
    ),
    r'photoUrls': PropertySchema(
      id: 7,
      name: r'photoUrls',
      type: IsarType.stringList,
    ),
    r'spotIndex': PropertySchema(
      id: 8,
      name: r'spotIndex',
      type: IsarType.long,
    ),
    r'success': PropertySchema(
      id: 9,
      name: r'success',
      type: IsarType.bool,
    ),
    r'time': PropertySchema(
      id: 10,
      name: r'time',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _biteRecordEntityEstimateSize,
  serialize: _biteRecordEntitySerialize,
  deserialize: _biteRecordEntityDeserialize,
  deserializeProp: _biteRecordEntityDeserializeProp,
);

int _biteRecordEntityEstimateSize(
  BiteRecordEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.baitUsed;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.biteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fishType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.photoUrls.length * 3;
  {
    for (var i = 0; i < object.photoUrls.length; i++) {
      final value = object.photoUrls[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _biteRecordEntitySerialize(
  BiteRecordEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.baitUsed);
  writer.writeString(offsets[1], object.biteId);
  writer.writeLong(offsets[2], object.dayIndex);
  writer.writeDouble(offsets[3], object.fishLength);
  writer.writeString(offsets[4], object.fishType);
  writer.writeDouble(offsets[5], object.fishWeight);
  writer.writeString(offsets[6], object.notes);
  writer.writeStringList(offsets[7], object.photoUrls);
  writer.writeLong(offsets[8], object.spotIndex);
  writer.writeBool(offsets[9], object.success);
  writer.writeDateTime(offsets[10], object.time);
}

BiteRecordEntity _biteRecordEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BiteRecordEntity();
  object.baitUsed = reader.readStringOrNull(offsets[0]);
  object.biteId = reader.readStringOrNull(offsets[1]);
  object.dayIndex = reader.readLong(offsets[2]);
  object.fishLength = reader.readDoubleOrNull(offsets[3]);
  object.fishType = reader.readStringOrNull(offsets[4]);
  object.fishWeight = reader.readDoubleOrNull(offsets[5]);
  object.notes = reader.readStringOrNull(offsets[6]);
  object.photoUrls = reader.readStringList(offsets[7]) ?? [];
  object.spotIndex = reader.readLong(offsets[8]);
  object.success = reader.readBool(offsets[9]);
  object.time = reader.readDateTimeOrNull(offsets[10]);
  return object;
}

P _biteRecordEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension BiteRecordEntityQueryFilter
    on QueryBuilder<BiteRecordEntity, BiteRecordEntity, QFilterCondition> {
  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'baitUsed',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'baitUsed',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baitUsed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baitUsed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baitUsed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baitUsed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'baitUsed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'baitUsed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'baitUsed',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'baitUsed',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baitUsed',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      baitUsedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'baitUsed',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'biteId',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'biteId',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'biteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'biteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'biteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'biteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'biteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'biteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'biteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'biteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'biteId',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      biteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'biteId',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      dayIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      dayIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      dayIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      dayIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishLengthIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fishLength',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishLengthIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fishLength',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishLengthEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishLength',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishLengthGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fishLength',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishLengthLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fishLength',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishLengthBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fishLength',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fishType',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fishType',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fishType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fishType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fishType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fishType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fishType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fishType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fishType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishType',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fishType',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishWeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fishWeight',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishWeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fishWeight',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishWeightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishWeightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fishWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishWeightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fishWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      fishWeightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fishWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'photoUrls',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'photoUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'photoUrls',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'photoUrls',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'photoUrls',
        value: '',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      photoUrlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'photoUrls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      spotIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spotIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      spotIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spotIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      spotIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spotIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      spotIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spotIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      successEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'success',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      timeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'time',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      timeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'time',
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      timeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      timeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      timeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<BiteRecordEntity, BiteRecordEntity, QAfterFilterCondition>
      timeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'time',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BiteRecordEntityQueryObject
    on QueryBuilder<BiteRecordEntity, BiteRecordEntity, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const AiPredictionEntitySchema = Schema(
  name: r'AiPredictionEntity',
  id: 1112873105394866684,
  properties: {
    r'activityLevel': PropertySchema(
      id: 0,
      name: r'activityLevel',
      type: IsarType.string,
    ),
    r'confidencePercent': PropertySchema(
      id: 1,
      name: r'confidencePercent',
      type: IsarType.long,
    ),
    r'fishingType': PropertySchema(
      id: 2,
      name: r'fishingType',
      type: IsarType.string,
    ),
    r'overallScore': PropertySchema(
      id: 3,
      name: r'overallScore',
      type: IsarType.long,
    ),
    r'recommendation': PropertySchema(
      id: 4,
      name: r'recommendation',
      type: IsarType.string,
    ),
    r'timestamp': PropertySchema(
      id: 5,
      name: r'timestamp',
      type: IsarType.long,
    ),
    r'tipsJson': PropertySchema(
      id: 6,
      name: r'tipsJson',
      type: IsarType.string,
    )
  },
  estimateSize: _aiPredictionEntityEstimateSize,
  serialize: _aiPredictionEntitySerialize,
  deserialize: _aiPredictionEntityDeserialize,
  deserializeProp: _aiPredictionEntityDeserializeProp,
);

int _aiPredictionEntityEstimateSize(
  AiPredictionEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.activityLevel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fishingType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recommendation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.tipsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _aiPredictionEntitySerialize(
  AiPredictionEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.activityLevel);
  writer.writeLong(offsets[1], object.confidencePercent);
  writer.writeString(offsets[2], object.fishingType);
  writer.writeLong(offsets[3], object.overallScore);
  writer.writeString(offsets[4], object.recommendation);
  writer.writeLong(offsets[5], object.timestamp);
  writer.writeString(offsets[6], object.tipsJson);
}

AiPredictionEntity _aiPredictionEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AiPredictionEntity();
  object.activityLevel = reader.readStringOrNull(offsets[0]);
  object.confidencePercent = reader.readLongOrNull(offsets[1]);
  object.fishingType = reader.readStringOrNull(offsets[2]);
  object.overallScore = reader.readLongOrNull(offsets[3]);
  object.recommendation = reader.readStringOrNull(offsets[4]);
  object.timestamp = reader.readLongOrNull(offsets[5]);
  object.tipsJson = reader.readStringOrNull(offsets[6]);
  return object;
}

P _aiPredictionEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension AiPredictionEntityQueryFilter
    on QueryBuilder<AiPredictionEntity, AiPredictionEntity, QFilterCondition> {
  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'activityLevel',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'activityLevel',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activityLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'activityLevel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'activityLevel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activityLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      activityLevelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'activityLevel',
        value: '',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      confidencePercentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'confidencePercent',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      confidencePercentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'confidencePercent',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      confidencePercentEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'confidencePercent',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      confidencePercentGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'confidencePercent',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      confidencePercentLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'confidencePercent',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      confidencePercentBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'confidencePercent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fishingType',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fishingType',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fishingType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fishingType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fishingType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fishingType',
        value: '',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      fishingTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fishingType',
        value: '',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      overallScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'overallScore',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      overallScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'overallScore',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      overallScoreEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'overallScore',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      overallScoreGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'overallScore',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      overallScoreLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'overallScore',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      overallScoreBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'overallScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recommendation',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recommendation',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recommendation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recommendation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recommendation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recommendation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recommendation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recommendation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recommendation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recommendation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recommendation',
        value: '',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      recommendationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recommendation',
        value: '',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      timestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timestamp',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      timestampIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timestamp',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      timestampEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      timestampGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      timestampLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      timestampBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tipsJson',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tipsJson',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tipsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tipsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tipsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tipsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<AiPredictionEntity, AiPredictionEntity, QAfterFilterCondition>
      tipsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tipsJson',
        value: '',
      ));
    });
  }
}

extension AiPredictionEntityQueryObject
    on QueryBuilder<AiPredictionEntity, AiPredictionEntity, QFilterCondition> {}
