// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_usage_limits_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserUsageLimitsEntityCollection on Isar {
  IsarCollection<UserUsageLimitsEntity> get userUsageLimitsEntitys =>
      this.collection();
}

const UserUsageLimitsEntitySchema = CollectionSchema(
  name: r'UserUsageLimitsEntity',
  id: -8127568047139230292,
  properties: {
    r'budgetNotesCount': PropertySchema(
      id: 0,
      name: r'budgetNotesCount',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'expensesCount': PropertySchema(
      id: 2,
      name: r'expensesCount',
      type: IsarType.long,
    ),
    r'firebaseId': PropertySchema(
      id: 3,
      name: r'firebaseId',
      type: IsarType.string,
    ),
    r'isSynced': PropertySchema(
      id: 4,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastResetDate': PropertySchema(
      id: 5,
      name: r'lastResetDate',
      type: IsarType.string,
    ),
    r'lastSyncAt': PropertySchema(
      id: 6,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'markedForDeletion': PropertySchema(
      id: 7,
      name: r'markedForDeletion',
      type: IsarType.bool,
    ),
    r'markerMapsCount': PropertySchema(
      id: 8,
      name: r'markerMapsCount',
      type: IsarType.long,
    ),
    r'notesCount': PropertySchema(
      id: 9,
      name: r'notesCount',
      type: IsarType.long,
    ),
    r'recalculatedAt': PropertySchema(
      id: 10,
      name: r'recalculatedAt',
      type: IsarType.string,
    ),
    r'recalculationType': PropertySchema(
      id: 11,
      name: r'recalculationType',
      type: IsarType.string,
    ),
    r'tripsCount': PropertySchema(
      id: 12,
      name: r'tripsCount',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'userId': PropertySchema(
      id: 14,
      name: r'userId',
      type: IsarType.string,
    )
  },
  estimateSize: _userUsageLimitsEntityEstimateSize,
  serialize: _userUsageLimitsEntitySerialize,
  deserialize: _userUsageLimitsEntityDeserialize,
  deserializeProp: _userUsageLimitsEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _userUsageLimitsEntityGetId,
  getLinks: _userUsageLimitsEntityGetLinks,
  attach: _userUsageLimitsEntityAttach,
  version: '3.1.0+1',
);

int _userUsageLimitsEntityEstimateSize(
  UserUsageLimitsEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.firebaseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastResetDate;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recalculatedAt;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.recalculationType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _userUsageLimitsEntitySerialize(
  UserUsageLimitsEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.budgetNotesCount);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.expensesCount);
  writer.writeString(offsets[3], object.firebaseId);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeString(offsets[5], object.lastResetDate);
  writer.writeDateTime(offsets[6], object.lastSyncAt);
  writer.writeBool(offsets[7], object.markedForDeletion);
  writer.writeLong(offsets[8], object.markerMapsCount);
  writer.writeLong(offsets[9], object.notesCount);
  writer.writeString(offsets[10], object.recalculatedAt);
  writer.writeString(offsets[11], object.recalculationType);
  writer.writeLong(offsets[12], object.tripsCount);
  writer.writeDateTime(offsets[13], object.updatedAt);
  writer.writeString(offsets[14], object.userId);
}

UserUsageLimitsEntity _userUsageLimitsEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserUsageLimitsEntity();
  object.budgetNotesCount = reader.readLong(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.expensesCount = reader.readLong(offsets[2]);
  object.firebaseId = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[4]);
  object.lastResetDate = reader.readStringOrNull(offsets[5]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[6]);
  object.markedForDeletion = reader.readBool(offsets[7]);
  object.markerMapsCount = reader.readLong(offsets[8]);
  object.notesCount = reader.readLong(offsets[9]);
  object.recalculatedAt = reader.readStringOrNull(offsets[10]);
  object.recalculationType = reader.readStringOrNull(offsets[11]);
  object.tripsCount = reader.readLong(offsets[12]);
  object.updatedAt = reader.readDateTime(offsets[13]);
  object.userId = reader.readString(offsets[14]);
  return object;
}

P _userUsageLimitsEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userUsageLimitsEntityGetId(UserUsageLimitsEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userUsageLimitsEntityGetLinks(
    UserUsageLimitsEntity object) {
  return [];
}

void _userUsageLimitsEntityAttach(
    IsarCollection<dynamic> col, Id id, UserUsageLimitsEntity object) {
  object.id = id;
}

extension UserUsageLimitsEntityQueryWhereSort
    on QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QWhere> {
  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserUsageLimitsEntityQueryWhere on QueryBuilder<UserUsageLimitsEntity,
    UserUsageLimitsEntity, QWhereClause> {
  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterWhereClause>
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterWhereClause>
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
}

extension UserUsageLimitsEntityQueryFilter on QueryBuilder<
    UserUsageLimitsEntity, UserUsageLimitsEntity, QFilterCondition> {
  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> budgetNotesCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'budgetNotesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> budgetNotesCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'budgetNotesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> budgetNotesCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'budgetNotesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> budgetNotesCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'budgetNotesCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> expensesCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expensesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> expensesCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expensesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> expensesCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expensesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> expensesCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expensesCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firebaseId',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firebaseId',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdEqualTo(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdGreaterThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdLessThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdBetween(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdStartsWith(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdEndsWith(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      firebaseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'firebaseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      firebaseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'firebaseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firebaseId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> firebaseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'firebaseId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastResetDate',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastResetDate',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastResetDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastResetDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastResetDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastResetDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastResetDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastResetDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      lastResetDateContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastResetDate',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      lastResetDateMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastResetDate',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastResetDate',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastResetDateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastResetDate',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastSyncAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastSyncAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> lastSyncAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> markedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markedForDeletion',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> markerMapsCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markerMapsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> markerMapsCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'markerMapsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> markerMapsCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'markerMapsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> markerMapsCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'markerMapsCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> notesCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> notesCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> notesCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notesCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> notesCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notesCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recalculatedAt',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recalculatedAt',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recalculatedAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recalculatedAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recalculatedAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recalculatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recalculatedAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recalculatedAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      recalculatedAtContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recalculatedAt',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      recalculatedAtMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recalculatedAt',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recalculatedAt',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculatedAtIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recalculatedAt',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recalculationType',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recalculationType',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recalculationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recalculationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recalculationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recalculationType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recalculationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recalculationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      recalculationTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recalculationType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      recalculationTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recalculationType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recalculationType',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> recalculationTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recalculationType',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> tripsCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tripsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> tripsCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tripsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> tripsCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tripsCount',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> tripsCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tripsCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> userIdEqualTo(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> userIdGreaterThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> userIdLessThan(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> userIdBetween(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> userIdStartsWith(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> userIdEndsWith(
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

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
          QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity,
      QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension UserUsageLimitsEntityQueryObject on QueryBuilder<
    UserUsageLimitsEntity, UserUsageLimitsEntity, QFilterCondition> {}

extension UserUsageLimitsEntityQueryLinks on QueryBuilder<UserUsageLimitsEntity,
    UserUsageLimitsEntity, QFilterCondition> {}

extension UserUsageLimitsEntityQuerySortBy
    on QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QSortBy> {
  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByBudgetNotesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetNotesCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByBudgetNotesCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetNotesCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByExpensesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expensesCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByExpensesCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expensesCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByFirebaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByFirebaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByLastResetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastResetDate', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByLastResetDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastResetDate', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByMarkerMapsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markerMapsCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByMarkerMapsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markerMapsCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByNotesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notesCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByNotesCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notesCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByRecalculatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recalculatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByRecalculatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recalculatedAt', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByRecalculationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recalculationType', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByRecalculationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recalculationType', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByTripsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tripsCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByTripsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tripsCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension UserUsageLimitsEntityQuerySortThenBy
    on QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QSortThenBy> {
  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByBudgetNotesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetNotesCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByBudgetNotesCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'budgetNotesCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByExpensesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expensesCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByExpensesCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expensesCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByFirebaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByFirebaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByLastResetDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastResetDate', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByLastResetDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastResetDate', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByMarkerMapsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markerMapsCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByMarkerMapsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markerMapsCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByNotesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notesCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByNotesCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notesCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByRecalculatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recalculatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByRecalculatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recalculatedAt', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByRecalculationType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recalculationType', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByRecalculationTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recalculationType', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByTripsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tripsCount', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByTripsCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tripsCount', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension UserUsageLimitsEntityQueryWhereDistinct
    on QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct> {
  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByBudgetNotesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'budgetNotesCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByExpensesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expensesCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByFirebaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firebaseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByLastResetDate({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastResetDate',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'markedForDeletion');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByMarkerMapsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'markerMapsCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByNotesCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notesCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByRecalculatedAt({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recalculatedAt',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByRecalculationType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recalculationType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByTripsCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tripsCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, UserUsageLimitsEntity, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension UserUsageLimitsEntityQueryProperty on QueryBuilder<
    UserUsageLimitsEntity, UserUsageLimitsEntity, QQueryProperty> {
  QueryBuilder<UserUsageLimitsEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, int, QQueryOperations>
      budgetNotesCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'budgetNotesCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, int, QQueryOperations>
      expensesCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expensesCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, String?, QQueryOperations>
      firebaseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firebaseId');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, bool, QQueryOperations>
      isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, String?, QQueryOperations>
      lastResetDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastResetDate');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, bool, QQueryOperations>
      markedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'markedForDeletion');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, int, QQueryOperations>
      markerMapsCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'markerMapsCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, int, QQueryOperations>
      notesCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notesCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, String?, QQueryOperations>
      recalculatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recalculatedAt');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, String?, QQueryOperations>
      recalculationTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recalculationType');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, int, QQueryOperations>
      tripsCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tripsCount');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<UserUsageLimitsEntity, String, QQueryOperations>
      userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
