// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_data_poco.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppDataPocoCollection on Isar {
  IsarCollection<AppDataPoco> get appDataPocos => this.collection();
}

const AppDataPocoSchema = CollectionSchema(
  name: r'AppDataPoco',
  id: 5065663873387038939,
  properties: {
    r'keyName': PropertySchema(
      id: 0,
      name: r'keyName',
      type: IsarType.string,
    ),
    r'valueStr': PropertySchema(
      id: 1,
      name: r'valueStr',
      type: IsarType.string,
    ),
    r'valueType': PropertySchema(
      id: 2,
      name: r'valueType',
      type: IsarType.string,
    )
  },
  estimateSize: _appDataPocoEstimateSize,
  serialize: _appDataPocoSerialize,
  deserialize: _appDataPocoDeserialize,
  deserializeProp: _appDataPocoDeserializeProp,
  idName: r'id',
  indexes: {
    r'keyName': IndexSchema(
      id: 4039708622426230326,
      name: r'keyName',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'keyName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _appDataPocoGetId,
  getLinks: _appDataPocoGetLinks,
  attach: _appDataPocoAttach,
  version: '3.1.0+1',
);

int _appDataPocoEstimateSize(
  AppDataPoco object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.keyName.length * 3;
  bytesCount += 3 + object.valueStr.length * 3;
  bytesCount += 3 + object.valueType.length * 3;
  return bytesCount;
}

void _appDataPocoSerialize(
  AppDataPoco object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.keyName);
  writer.writeString(offsets[1], object.valueStr);
  writer.writeString(offsets[2], object.valueType);
}

AppDataPoco _appDataPocoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppDataPoco(
    id: id,
    keyName: reader.readString(offsets[0]),
    valueStr: reader.readString(offsets[1]),
    valueType: reader.readString(offsets[2]),
  );
  return object;
}

P _appDataPocoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appDataPocoGetId(AppDataPoco object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appDataPocoGetLinks(AppDataPoco object) {
  return [];
}

void _appDataPocoAttach(
    IsarCollection<dynamic> col, Id id, AppDataPoco object) {
  object.id = id;
}

extension AppDataPocoByIndex on IsarCollection<AppDataPoco> {
  Future<AppDataPoco?> getByKeyName(String keyName) {
    return getByIndex(r'keyName', [keyName]);
  }

  AppDataPoco? getByKeyNameSync(String keyName) {
    return getByIndexSync(r'keyName', [keyName]);
  }

  Future<bool> deleteByKeyName(String keyName) {
    return deleteByIndex(r'keyName', [keyName]);
  }

  bool deleteByKeyNameSync(String keyName) {
    return deleteByIndexSync(r'keyName', [keyName]);
  }

  Future<List<AppDataPoco?>> getAllByKeyName(List<String> keyNameValues) {
    final values = keyNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'keyName', values);
  }

  List<AppDataPoco?> getAllByKeyNameSync(List<String> keyNameValues) {
    final values = keyNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'keyName', values);
  }

  Future<int> deleteAllByKeyName(List<String> keyNameValues) {
    final values = keyNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'keyName', values);
  }

  int deleteAllByKeyNameSync(List<String> keyNameValues) {
    final values = keyNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'keyName', values);
  }

  Future<Id> putByKeyName(AppDataPoco object) {
    return putByIndex(r'keyName', object);
  }

  Id putByKeyNameSync(AppDataPoco object, {bool saveLinks = true}) {
    return putByIndexSync(r'keyName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKeyName(List<AppDataPoco> objects) {
    return putAllByIndex(r'keyName', objects);
  }

  List<Id> putAllByKeyNameSync(List<AppDataPoco> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'keyName', objects, saveLinks: saveLinks);
  }
}

extension AppDataPocoQueryWhereSort
    on QueryBuilder<AppDataPoco, AppDataPoco, QWhere> {
  QueryBuilder<AppDataPoco, AppDataPoco, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppDataPocoQueryWhere
    on QueryBuilder<AppDataPoco, AppDataPoco, QWhereClause> {
  QueryBuilder<AppDataPoco, AppDataPoco, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterWhereClause> idBetween(
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

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterWhereClause> keyNameEqualTo(
      String keyName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'keyName',
        value: [keyName],
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterWhereClause> keyNameNotEqualTo(
      String keyName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyName',
              lower: [],
              upper: [keyName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyName',
              lower: [keyName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyName',
              lower: [keyName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'keyName',
              lower: [],
              upper: [keyName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension AppDataPocoQueryFilter
    on QueryBuilder<AppDataPoco, AppDataPoco, QFilterCondition> {
  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> idBetween(
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

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> keyNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      keyNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'keyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> keyNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'keyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> keyNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'keyName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      keyNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'keyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> keyNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'keyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> keyNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'keyName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> keyNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'keyName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      keyNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'keyName',
        value: '',
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      keyNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'keyName',
        value: '',
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> valueStrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueStrGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'valueStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueStrLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'valueStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> valueStrBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'valueStr',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueStrStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'valueStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueStrEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'valueStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueStrContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'valueStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition> valueStrMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'valueStr',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueStrIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueStr',
        value: '',
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueStrIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'valueStr',
        value: '',
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'valueType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'valueType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'valueType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'valueType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'valueType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'valueType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'valueType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueType',
        value: '',
      ));
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterFilterCondition>
      valueTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'valueType',
        value: '',
      ));
    });
  }
}

extension AppDataPocoQueryObject
    on QueryBuilder<AppDataPoco, AppDataPoco, QFilterCondition> {}

extension AppDataPocoQueryLinks
    on QueryBuilder<AppDataPoco, AppDataPoco, QFilterCondition> {}

extension AppDataPocoQuerySortBy
    on QueryBuilder<AppDataPoco, AppDataPoco, QSortBy> {
  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> sortByKeyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyName', Sort.asc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> sortByKeyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyName', Sort.desc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> sortByValueStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueStr', Sort.asc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> sortByValueStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueStr', Sort.desc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> sortByValueType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueType', Sort.asc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> sortByValueTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueType', Sort.desc);
    });
  }
}

extension AppDataPocoQuerySortThenBy
    on QueryBuilder<AppDataPoco, AppDataPoco, QSortThenBy> {
  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> thenByKeyName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyName', Sort.asc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> thenByKeyNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyName', Sort.desc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> thenByValueStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueStr', Sort.asc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> thenByValueStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueStr', Sort.desc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> thenByValueType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueType', Sort.asc);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QAfterSortBy> thenByValueTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueType', Sort.desc);
    });
  }
}

extension AppDataPocoQueryWhereDistinct
    on QueryBuilder<AppDataPoco, AppDataPoco, QDistinct> {
  QueryBuilder<AppDataPoco, AppDataPoco, QDistinct> distinctByKeyName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keyName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QDistinct> distinctByValueStr(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valueStr', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppDataPoco, AppDataPoco, QDistinct> distinctByValueType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valueType', caseSensitive: caseSensitive);
    });
  }
}

extension AppDataPocoQueryProperty
    on QueryBuilder<AppDataPoco, AppDataPoco, QQueryProperty> {
  QueryBuilder<AppDataPoco, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppDataPoco, String, QQueryOperations> keyNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyName');
    });
  }

  QueryBuilder<AppDataPoco, String, QQueryOperations> valueStrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valueStr');
    });
  }

  QueryBuilder<AppDataPoco, String, QQueryOperations> valueTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valueType');
    });
  }
}
