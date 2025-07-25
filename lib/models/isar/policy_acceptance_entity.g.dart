// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy_acceptance_entity.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPolicyAcceptanceEntityCollection on Isar {
  IsarCollection<PolicyAcceptanceEntity> get policyAcceptanceEntitys =>
      this.collection();
}

const PolicyAcceptanceEntitySchema = CollectionSchema(
  name: r'PolicyAcceptanceEntity',
  id: 4001357437709433004,
  properties: {
    r'consentLanguage': PropertySchema(
      id: 0,
      name: r'consentLanguage',
      type: IsarType.string,
    ),
    r'consentTimestamp': PropertySchema(
      id: 1,
      name: r'consentTimestamp',
      type: IsarType.dateTime,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
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
    r'lastSyncAt': PropertySchema(
      id: 5,
      name: r'lastSyncAt',
      type: IsarType.dateTime,
    ),
    r'markedForDeletion': PropertySchema(
      id: 6,
      name: r'markedForDeletion',
      type: IsarType.bool,
    ),
    r'privacyPolicyAccepted': PropertySchema(
      id: 7,
      name: r'privacyPolicyAccepted',
      type: IsarType.bool,
    ),
    r'privacyPolicyHash': PropertySchema(
      id: 8,
      name: r'privacyPolicyHash',
      type: IsarType.string,
    ),
    r'privacyPolicyVersion': PropertySchema(
      id: 9,
      name: r'privacyPolicyVersion',
      type: IsarType.string,
    ),
    r'termsOfServiceAccepted': PropertySchema(
      id: 10,
      name: r'termsOfServiceAccepted',
      type: IsarType.bool,
    ),
    r'termsOfServiceHash': PropertySchema(
      id: 11,
      name: r'termsOfServiceHash',
      type: IsarType.string,
    ),
    r'termsOfServiceVersion': PropertySchema(
      id: 12,
      name: r'termsOfServiceVersion',
      type: IsarType.string,
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
  estimateSize: _policyAcceptanceEntityEstimateSize,
  serialize: _policyAcceptanceEntitySerialize,
  deserialize: _policyAcceptanceEntityDeserialize,
  deserializeProp: _policyAcceptanceEntityDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _policyAcceptanceEntityGetId,
  getLinks: _policyAcceptanceEntityGetLinks,
  attach: _policyAcceptanceEntityAttach,
  version: '3.1.0+1',
);

int _policyAcceptanceEntityEstimateSize(
  PolicyAcceptanceEntity object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.consentLanguage.length * 3;
  {
    final value = object.firebaseId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.privacyPolicyHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.privacyPolicyVersion.length * 3;
  {
    final value = object.termsOfServiceHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.termsOfServiceVersion.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _policyAcceptanceEntitySerialize(
  PolicyAcceptanceEntity object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.consentLanguage);
  writer.writeDateTime(offsets[1], object.consentTimestamp);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.firebaseId);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeDateTime(offsets[5], object.lastSyncAt);
  writer.writeBool(offsets[6], object.markedForDeletion);
  writer.writeBool(offsets[7], object.privacyPolicyAccepted);
  writer.writeString(offsets[8], object.privacyPolicyHash);
  writer.writeString(offsets[9], object.privacyPolicyVersion);
  writer.writeBool(offsets[10], object.termsOfServiceAccepted);
  writer.writeString(offsets[11], object.termsOfServiceHash);
  writer.writeString(offsets[12], object.termsOfServiceVersion);
  writer.writeDateTime(offsets[13], object.updatedAt);
  writer.writeString(offsets[14], object.userId);
}

PolicyAcceptanceEntity _policyAcceptanceEntityDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PolicyAcceptanceEntity();
  object.consentLanguage = reader.readString(offsets[0]);
  object.consentTimestamp = reader.readDateTimeOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.firebaseId = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[4]);
  object.lastSyncAt = reader.readDateTimeOrNull(offsets[5]);
  object.markedForDeletion = reader.readBool(offsets[6]);
  object.privacyPolicyAccepted = reader.readBool(offsets[7]);
  object.privacyPolicyHash = reader.readStringOrNull(offsets[8]);
  object.privacyPolicyVersion = reader.readString(offsets[9]);
  object.termsOfServiceAccepted = reader.readBool(offsets[10]);
  object.termsOfServiceHash = reader.readStringOrNull(offsets[11]);
  object.termsOfServiceVersion = reader.readString(offsets[12]);
  object.updatedAt = reader.readDateTime(offsets[13]);
  object.userId = reader.readString(offsets[14]);
  return object;
}

P _policyAcceptanceEntityDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _policyAcceptanceEntityGetId(PolicyAcceptanceEntity object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _policyAcceptanceEntityGetLinks(
    PolicyAcceptanceEntity object) {
  return [];
}

void _policyAcceptanceEntityAttach(
    IsarCollection<dynamic> col, Id id, PolicyAcceptanceEntity object) {
  object.id = id;
}

extension PolicyAcceptanceEntityQueryWhereSort
    on QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QWhere> {
  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PolicyAcceptanceEntityQueryWhere on QueryBuilder<
    PolicyAcceptanceEntity, PolicyAcceptanceEntity, QWhereClause> {
  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterWhereClause> idBetween(
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

extension PolicyAcceptanceEntityQueryFilter on QueryBuilder<
    PolicyAcceptanceEntity, PolicyAcceptanceEntity, QFilterCondition> {
  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentLanguageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consentLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentLanguageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'consentLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentLanguageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'consentLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentLanguageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'consentLanguage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentLanguageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'consentLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentLanguageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'consentLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      consentLanguageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'consentLanguage',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      consentLanguageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'consentLanguage',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentLanguageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consentLanguage',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentLanguageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'consentLanguage',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentTimestampIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'consentTimestamp',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentTimestampIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'consentTimestamp',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentTimestampEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consentTimestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentTimestampGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'consentTimestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentTimestampLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'consentTimestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> consentTimestampBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'consentTimestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> firebaseIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'firebaseId',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> firebaseIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'firebaseId',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> firebaseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firebaseId',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> firebaseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'firebaseId',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> lastSyncAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> lastSyncAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncAt',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> lastSyncAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> markedForDeletionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'markedForDeletion',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyAcceptedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privacyPolicyAccepted',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'privacyPolicyHash',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'privacyPolicyHash',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privacyPolicyHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'privacyPolicyHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'privacyPolicyHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'privacyPolicyHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'privacyPolicyHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'privacyPolicyHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      privacyPolicyHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'privacyPolicyHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      privacyPolicyHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'privacyPolicyHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privacyPolicyHash',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'privacyPolicyHash',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyVersionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privacyPolicyVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyVersionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'privacyPolicyVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyVersionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'privacyPolicyVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyVersionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'privacyPolicyVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'privacyPolicyVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'privacyPolicyVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      privacyPolicyVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'privacyPolicyVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      privacyPolicyVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'privacyPolicyVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'privacyPolicyVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> privacyPolicyVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'privacyPolicyVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceAcceptedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'termsOfServiceAccepted',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'termsOfServiceHash',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'termsOfServiceHash',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'termsOfServiceHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'termsOfServiceHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'termsOfServiceHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'termsOfServiceHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'termsOfServiceHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'termsOfServiceHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      termsOfServiceHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'termsOfServiceHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      termsOfServiceHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'termsOfServiceHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'termsOfServiceHash',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'termsOfServiceHash',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceVersionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'termsOfServiceVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceVersionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'termsOfServiceVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceVersionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'termsOfServiceVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceVersionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'termsOfServiceVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'termsOfServiceVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'termsOfServiceVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      termsOfServiceVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'termsOfServiceVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
          QAfterFilterCondition>
      termsOfServiceVersionMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'termsOfServiceVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'termsOfServiceVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> termsOfServiceVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'termsOfServiceVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
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

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: '',
      ));
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity,
      QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userId',
        value: '',
      ));
    });
  }
}

extension PolicyAcceptanceEntityQueryObject on QueryBuilder<
    PolicyAcceptanceEntity, PolicyAcceptanceEntity, QFilterCondition> {}

extension PolicyAcceptanceEntityQueryLinks on QueryBuilder<
    PolicyAcceptanceEntity, PolicyAcceptanceEntity, QFilterCondition> {}

extension PolicyAcceptanceEntityQuerySortBy
    on QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QSortBy> {
  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByConsentLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentLanguage', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByConsentLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentLanguage', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByConsentTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentTimestamp', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByConsentTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentTimestamp', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByFirebaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByFirebaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByPrivacyPolicyAccepted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyAccepted', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByPrivacyPolicyAcceptedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyAccepted', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByPrivacyPolicyHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyHash', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByPrivacyPolicyHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyHash', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByPrivacyPolicyVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyVersion', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByPrivacyPolicyVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyVersion', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByTermsOfServiceAccepted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceAccepted', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByTermsOfServiceAcceptedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceAccepted', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByTermsOfServiceHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceHash', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByTermsOfServiceHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceHash', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByTermsOfServiceVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceVersion', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByTermsOfServiceVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceVersion', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PolicyAcceptanceEntityQuerySortThenBy on QueryBuilder<
    PolicyAcceptanceEntity, PolicyAcceptanceEntity, QSortThenBy> {
  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByConsentLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentLanguage', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByConsentLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentLanguage', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByConsentTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentTimestamp', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByConsentTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentTimestamp', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByFirebaseId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByFirebaseIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firebaseId', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByLastSyncAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncAt', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByMarkedForDeletionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'markedForDeletion', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByPrivacyPolicyAccepted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyAccepted', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByPrivacyPolicyAcceptedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyAccepted', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByPrivacyPolicyHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyHash', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByPrivacyPolicyHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyHash', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByPrivacyPolicyVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyVersion', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByPrivacyPolicyVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'privacyPolicyVersion', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByTermsOfServiceAccepted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceAccepted', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByTermsOfServiceAcceptedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceAccepted', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByTermsOfServiceHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceHash', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByTermsOfServiceHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceHash', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByTermsOfServiceVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceVersion', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByTermsOfServiceVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'termsOfServiceVersion', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QAfterSortBy>
      thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PolicyAcceptanceEntityQueryWhereDistinct
    on QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct> {
  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByConsentLanguage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'consentLanguage',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByConsentTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'consentTimestamp');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByFirebaseId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firebaseId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByLastSyncAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncAt');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByMarkedForDeletion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'markedForDeletion');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByPrivacyPolicyAccepted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privacyPolicyAccepted');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByPrivacyPolicyHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privacyPolicyHash',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByPrivacyPolicyVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'privacyPolicyVersion',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByTermsOfServiceAccepted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'termsOfServiceAccepted');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByTermsOfServiceHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'termsOfServiceHash',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByTermsOfServiceVersion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'termsOfServiceVersion',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, PolicyAcceptanceEntity, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension PolicyAcceptanceEntityQueryProperty on QueryBuilder<
    PolicyAcceptanceEntity, PolicyAcceptanceEntity, QQueryProperty> {
  QueryBuilder<PolicyAcceptanceEntity, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, String, QQueryOperations>
      consentLanguageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'consentLanguage');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, DateTime?, QQueryOperations>
      consentTimestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'consentTimestamp');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, String?, QQueryOperations>
      firebaseIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firebaseId');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, bool, QQueryOperations>
      isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, DateTime?, QQueryOperations>
      lastSyncAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncAt');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, bool, QQueryOperations>
      markedForDeletionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'markedForDeletion');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, bool, QQueryOperations>
      privacyPolicyAcceptedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privacyPolicyAccepted');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, String?, QQueryOperations>
      privacyPolicyHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privacyPolicyHash');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, String, QQueryOperations>
      privacyPolicyVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'privacyPolicyVersion');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, bool, QQueryOperations>
      termsOfServiceAcceptedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'termsOfServiceAccepted');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, String?, QQueryOperations>
      termsOfServiceHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'termsOfServiceHash');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, String, QQueryOperations>
      termsOfServiceVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'termsOfServiceVersion');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<PolicyAcceptanceEntity, String, QQueryOperations>
      userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
