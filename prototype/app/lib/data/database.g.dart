// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class Business extends Table with TableInfo<Business, BusinessData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Business(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _participantCodeMeta = const VerificationMeta(
    'participantCode',
  );
  late final GeneratedColumn<String> participantCode = GeneratedColumn<String>(
    'participant_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE CHECK (length(participant_code) BETWEEN 4 AND 12)',
  );
  static const VerificationMeta _businessTypeMeta = const VerificationMeta(
    'businessType',
  );
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
    'business_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    participantCode,
    businessType,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('participant_code')) {
      context.handle(
        _participantCodeMeta,
        participantCode.isAcceptableOrUnknown(
          data['participant_code']!,
          _participantCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantCodeMeta);
    }
    if (data.containsKey('business_type')) {
      context.handle(
        _businessTypeMeta,
        businessType.isAcceptableOrUnknown(
          data['business_type']!,
          _businessTypeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      participantCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_code'],
      )!,
      businessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Business createAlias(String alias) {
    return Business(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class BusinessData extends DataClass implements Insertable<BusinessData> {
  final String? id;
  final String participantCode;
  final String? businessType;
  final int createdAt;
  const BusinessData({
    this.id,
    required this.participantCode,
    this.businessType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['participant_code'] = Variable<String>(participantCode);
    if (!nullToAbsent || businessType != null) {
      map['business_type'] = Variable<String>(businessType);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BusinessCompanion toCompanion(bool nullToAbsent) {
    return BusinessCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      participantCode: Value(participantCode),
      businessType: businessType == null && nullToAbsent
          ? const Value.absent()
          : Value(businessType),
      createdAt: Value(createdAt),
    );
  }

  factory BusinessData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessData(
      id: serializer.fromJson<String?>(json['id']),
      participantCode: serializer.fromJson<String>(json['participant_code']),
      businessType: serializer.fromJson<String?>(json['business_type']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'participant_code': serializer.toJson<String>(participantCode),
      'business_type': serializer.toJson<String?>(businessType),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  BusinessData copyWith({
    Value<String?> id = const Value.absent(),
    String? participantCode,
    Value<String?> businessType = const Value.absent(),
    int? createdAt,
  }) => BusinessData(
    id: id.present ? id.value : this.id,
    participantCode: participantCode ?? this.participantCode,
    businessType: businessType.present ? businessType.value : this.businessType,
    createdAt: createdAt ?? this.createdAt,
  );
  BusinessData copyWithCompanion(BusinessCompanion data) {
    return BusinessData(
      id: data.id.present ? data.id.value : this.id,
      participantCode: data.participantCode.present
          ? data.participantCode.value
          : this.participantCode,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessData(')
          ..write('id: $id, ')
          ..write('participantCode: $participantCode, ')
          ..write('businessType: $businessType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, participantCode, businessType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessData &&
          other.id == this.id &&
          other.participantCode == this.participantCode &&
          other.businessType == this.businessType &&
          other.createdAt == this.createdAt);
}

class BusinessCompanion extends UpdateCompanion<BusinessData> {
  final Value<String?> id;
  final Value<String> participantCode;
  final Value<String?> businessType;
  final Value<int> createdAt;
  final Value<int> rowid;
  const BusinessCompanion({
    this.id = const Value.absent(),
    this.participantCode = const Value.absent(),
    this.businessType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessCompanion.insert({
    this.id = const Value.absent(),
    required String participantCode,
    this.businessType = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : participantCode = Value(participantCode),
       createdAt = Value(createdAt);
  static Insertable<BusinessData> custom({
    Expression<String>? id,
    Expression<String>? participantCode,
    Expression<String>? businessType,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (participantCode != null) 'participant_code': participantCode,
      if (businessType != null) 'business_type': businessType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessCompanion copyWith({
    Value<String?>? id,
    Value<String>? participantCode,
    Value<String?>? businessType,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return BusinessCompanion(
      id: id ?? this.id,
      participantCode: participantCode ?? this.participantCode,
      businessType: businessType ?? this.businessType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (participantCode.present) {
      map['participant_code'] = Variable<String>(participantCode.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessCompanion(')
          ..write('id: $id, ')
          ..write('participantCode: $participantCode, ')
          ..write('businessType: $businessType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Category extends Table with TableInfo<Category, CategoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Category(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'income\', \'expense\'))',
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [code, name, kind, icon, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  CategoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryData(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  Category createAlias(String alias) {
    return Category(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CategoryData extends DataClass implements Insertable<CategoryData> {
  final String? code;
  final String name;
  final String kind;
  final String icon;
  final int sortOrder;
  const CategoryData({
    this.code,
    required this.name,
    required this.kind,
    required this.icon,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['icon'] = Variable<String>(icon);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoryCompanion toCompanion(bool nullToAbsent) {
    return CategoryCompanion(
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      name: Value(name),
      kind: Value(kind),
      icon: Value(icon),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryData(
      code: serializer.fromJson<String?>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      icon: serializer.fromJson<String>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sort_order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String?>(code),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'icon': serializer.toJson<String>(icon),
      'sort_order': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryData copyWith({
    Value<String?> code = const Value.absent(),
    String? name,
    String? kind,
    String? icon,
    int? sortOrder,
  }) => CategoryData(
    code: code.present ? code.value : this.code,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    icon: icon ?? this.icon,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CategoryData copyWithCompanion(CategoryCompanion data) {
    return CategoryData(
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryData(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, name, kind, icon, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryData &&
          other.code == this.code &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder);
}

class CategoryCompanion extends UpdateCompanion<CategoryData> {
  final Value<String?> code;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> icon;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoryCompanion({
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryCompanion.insert({
    this.code = const Value.absent(),
    required String name,
    required String kind,
    required String icon,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind),
       icon = Value(icon);
  static Insertable<CategoryData> custom({
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryCompanion copyWith({
    Value<String?>? code,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? icon,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoryCompanion(
      code: code ?? this.code,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryCompanion(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Product extends Table with TableInfo<Product, ProductData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Product(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES business(id)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) > 0)',
  );
  static const VerificationMeta _unitPriceNgweeMeta = const VerificationMeta(
    'unitPriceNgwee',
  );
  late final GeneratedColumn<int> unitPriceNgwee = GeneratedColumn<int>(
    'unit_price_ngwee',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (unit_price_ngwee >= 0)',
  );
  static const VerificationMeta _reorderLevelMeta = const VerificationMeta(
    'reorderLevel',
  );
  late final GeneratedColumn<int> reorderLevel = GeneratedColumn<int>(
    'reorder_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (reorder_level >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  late final GeneratedColumn<int> isActive = GeneratedColumn<int>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    name,
    unitPriceNgwee,
    reorderLevel,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit_price_ngwee')) {
      context.handle(
        _unitPriceNgweeMeta,
        unitPriceNgwee.isAcceptableOrUnknown(
          data['unit_price_ngwee']!,
          _unitPriceNgweeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceNgweeMeta);
    }
    if (data.containsKey('reorder_level')) {
      context.handle(
        _reorderLevelMeta,
        reorderLevel.isAcceptableOrUnknown(
          data['reorder_level']!,
          _reorderLevelMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {businessId, name},
  ];
  @override
  ProductData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unitPriceNgwee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_ngwee'],
      )!,
      reorderLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reorder_level'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Product createAlias(String alias) {
    return Product(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(business_id, name)'];
  @override
  bool get dontWriteConstraints => true;
}

class ProductData extends DataClass implements Insertable<ProductData> {
  final String? id;
  final String businessId;
  final String name;
  final int unitPriceNgwee;
  final int reorderLevel;
  final int isActive;
  final int createdAt;
  final int updatedAt;
  const ProductData({
    this.id,
    required this.businessId,
    required this.name,
    required this.unitPriceNgwee,
    required this.reorderLevel,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    map['unit_price_ngwee'] = Variable<int>(unitPriceNgwee);
    map['reorder_level'] = Variable<int>(reorderLevel);
    map['is_active'] = Variable<int>(isActive);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProductCompanion toCompanion(bool nullToAbsent) {
    return ProductCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      businessId: Value(businessId),
      name: Value(name),
      unitPriceNgwee: Value(unitPriceNgwee),
      reorderLevel: Value(reorderLevel),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductData(
      id: serializer.fromJson<String?>(json['id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      name: serializer.fromJson<String>(json['name']),
      unitPriceNgwee: serializer.fromJson<int>(json['unit_price_ngwee']),
      reorderLevel: serializer.fromJson<int>(json['reorder_level']),
      isActive: serializer.fromJson<int>(json['is_active']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'business_id': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'unit_price_ngwee': serializer.toJson<int>(unitPriceNgwee),
      'reorder_level': serializer.toJson<int>(reorderLevel),
      'is_active': serializer.toJson<int>(isActive),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  ProductData copyWith({
    Value<String?> id = const Value.absent(),
    String? businessId,
    String? name,
    int? unitPriceNgwee,
    int? reorderLevel,
    int? isActive,
    int? createdAt,
    int? updatedAt,
  }) => ProductData(
    id: id.present ? id.value : this.id,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    unitPriceNgwee: unitPriceNgwee ?? this.unitPriceNgwee,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProductData copyWithCompanion(ProductCompanion data) {
    return ProductData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      unitPriceNgwee: data.unitPriceNgwee.present
          ? data.unitPriceNgwee.value
          : this.unitPriceNgwee,
      reorderLevel: data.reorderLevel.present
          ? data.reorderLevel.value
          : this.reorderLevel,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('unitPriceNgwee: $unitPriceNgwee, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    name,
    unitPriceNgwee,
    reorderLevel,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.unitPriceNgwee == this.unitPriceNgwee &&
          other.reorderLevel == this.reorderLevel &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductCompanion extends UpdateCompanion<ProductData> {
  final Value<String?> id;
  final Value<String> businessId;
  final Value<String> name;
  final Value<int> unitPriceNgwee;
  final Value<int> reorderLevel;
  final Value<int> isActive;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProductCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.unitPriceNgwee = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductCompanion.insert({
    this.id = const Value.absent(),
    required String businessId,
    required String name,
    required int unitPriceNgwee,
    this.reorderLevel = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       name = Value(name),
       unitPriceNgwee = Value(unitPriceNgwee),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProductData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<int>? unitPriceNgwee,
    Expression<int>? reorderLevel,
    Expression<int>? isActive,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (unitPriceNgwee != null) 'unit_price_ngwee': unitPriceNgwee,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductCompanion copyWith({
    Value<String?>? id,
    Value<String>? businessId,
    Value<String>? name,
    Value<int>? unitPriceNgwee,
    Value<int>? reorderLevel,
    Value<int>? isActive,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      unitPriceNgwee: unitPriceNgwee ?? this.unitPriceNgwee,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unitPriceNgwee.present) {
      map['unit_price_ngwee'] = Variable<int>(unitPriceNgwee.value);
    }
    if (reorderLevel.present) {
      map['reorder_level'] = Variable<int>(reorderLevel.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<int>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('unitPriceNgwee: $unitPriceNgwee, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LedgerEntry extends Table with TableInfo<LedgerEntry, LedgerEntryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LedgerEntry(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES business(id)',
  );
  static const VerificationMeta _entryTypeMeta = const VerificationMeta(
    'entryType',
  );
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
    'entry_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (entry_type IN (\'sale\', \'expense\'))',
  );
  static const VerificationMeta _amountNgweeMeta = const VerificationMeta(
    'amountNgwee',
  );
  late final GeneratedColumn<int> amountNgwee = GeneratedColumn<int>(
    'amount_ngwee',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'\' CHECK (length(description) <= 120)',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'cash\' CHECK (payment_method IN (\'cash\', \'mobile_money\'))',
    defaultValue: const CustomExpression('\'cash\''),
  );
  static const VerificationMeta _predictedCategoryMeta = const VerificationMeta(
    'predictedCategory',
  );
  late final GeneratedColumn<String> predictedCategory =
      GeneratedColumn<String>(
        'predicted_category',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES category(code)',
      );
  static const VerificationMeta _categoryConfidenceMeta =
      const VerificationMeta('categoryConfidence');
  late final GeneratedColumn<double> categoryConfidence =
      GeneratedColumn<double>(
        'category_confidence',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        $customConstraints: 'CHECK (category_confidence BETWEEN 0 AND 1)',
      );
  static const VerificationMeta _finalCategoryMeta = const VerificationMeta(
    'finalCategory',
  );
  late final GeneratedColumn<String> finalCategory = GeneratedColumn<String>(
    'final_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES category(code)',
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _anomalyScoreMeta = const VerificationMeta(
    'anomalyScore',
  );
  late final GeneratedColumn<double> anomalyScore = GeneratedColumn<double>(
    'anomaly_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _anomalyFlagMeta = const VerificationMeta(
    'anomalyFlag',
  );
  late final GeneratedColumn<int> anomalyFlag = GeneratedColumn<int>(
    'anomaly_flag',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (anomaly_flag IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _anomalyReviewedAtMeta = const VerificationMeta(
    'anomalyReviewedAt',
  );
  late final GeneratedColumn<int> anomalyReviewedAt = GeneratedColumn<int>(
    'anomaly_reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _reversesIdMeta = const VerificationMeta(
    'reversesId',
  );
  late final GeneratedColumn<String> reversesId = GeneratedColumn<String>(
    'reverses_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'UNIQUE REFERENCES ledger_entry(id)',
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessId,
    entryType,
    amountNgwee,
    description,
    paymentMethod,
    predictedCategory,
    categoryConfidence,
    finalCategory,
    modelVersion,
    anomalyScore,
    anomalyFlag,
    anomalyReviewedAt,
    reversesId,
    occurredAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entry';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerEntryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('entry_type')) {
      context.handle(
        _entryTypeMeta,
        entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('amount_ngwee')) {
      context.handle(
        _amountNgweeMeta,
        amountNgwee.isAcceptableOrUnknown(
          data['amount_ngwee']!,
          _amountNgweeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountNgweeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('predicted_category')) {
      context.handle(
        _predictedCategoryMeta,
        predictedCategory.isAcceptableOrUnknown(
          data['predicted_category']!,
          _predictedCategoryMeta,
        ),
      );
    }
    if (data.containsKey('category_confidence')) {
      context.handle(
        _categoryConfidenceMeta,
        categoryConfidence.isAcceptableOrUnknown(
          data['category_confidence']!,
          _categoryConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('final_category')) {
      context.handle(
        _finalCategoryMeta,
        finalCategory.isAcceptableOrUnknown(
          data['final_category']!,
          _finalCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_finalCategoryMeta);
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    }
    if (data.containsKey('anomaly_score')) {
      context.handle(
        _anomalyScoreMeta,
        anomalyScore.isAcceptableOrUnknown(
          data['anomaly_score']!,
          _anomalyScoreMeta,
        ),
      );
    }
    if (data.containsKey('anomaly_flag')) {
      context.handle(
        _anomalyFlagMeta,
        anomalyFlag.isAcceptableOrUnknown(
          data['anomaly_flag']!,
          _anomalyFlagMeta,
        ),
      );
    }
    if (data.containsKey('anomaly_reviewed_at')) {
      context.handle(
        _anomalyReviewedAtMeta,
        anomalyReviewedAt.isAcceptableOrUnknown(
          data['anomaly_reviewed_at']!,
          _anomalyReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('reverses_id')) {
      context.handle(
        _reversesIdMeta,
        reversesId.isAcceptableOrUnknown(data['reverses_id']!, _reversesIdMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      entryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_type'],
      )!,
      amountNgwee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ngwee'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      predictedCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}predicted_category'],
      ),
      categoryConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}category_confidence'],
      ),
      finalCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_category'],
      )!,
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      ),
      anomalyScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}anomaly_score'],
      ),
      anomalyFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anomaly_flag'],
      )!,
      anomalyReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anomaly_reviewed_at'],
      ),
      reversesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reverses_id'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  LedgerEntry createAlias(String alias) {
    return LedgerEntry(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK(entry_type = \'sale\' OR length(trim(description)) > 0)',
    'CHECK((reverses_id IS NULL AND amount_ngwee > 0)OR(reverses_id IS NOT NULL AND amount_ngwee < 0))',
    'CHECK((predicted_category IS NULL)=(category_confidence IS NULL))',
    'CHECK(anomaly_flag = 0 OR anomaly_score IS NOT NULL)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LedgerEntryData extends DataClass implements Insertable<LedgerEntryData> {
  final String? id;
  final String businessId;
  final String entryType;
  final int amountNgwee;
  final String description;
  final String paymentMethod;
  final String? predictedCategory;
  final double? categoryConfidence;
  final String finalCategory;
  final String? modelVersion;
  final double? anomalyScore;
  final int anomalyFlag;
  final int? anomalyReviewedAt;
  final String? reversesId;
  final int occurredAt;
  final int createdAt;
  final int updatedAt;
  const LedgerEntryData({
    this.id,
    required this.businessId,
    required this.entryType,
    required this.amountNgwee,
    required this.description,
    required this.paymentMethod,
    this.predictedCategory,
    this.categoryConfidence,
    required this.finalCategory,
    this.modelVersion,
    this.anomalyScore,
    required this.anomalyFlag,
    this.anomalyReviewedAt,
    this.reversesId,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['business_id'] = Variable<String>(businessId);
    map['entry_type'] = Variable<String>(entryType);
    map['amount_ngwee'] = Variable<int>(amountNgwee);
    map['description'] = Variable<String>(description);
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || predictedCategory != null) {
      map['predicted_category'] = Variable<String>(predictedCategory);
    }
    if (!nullToAbsent || categoryConfidence != null) {
      map['category_confidence'] = Variable<double>(categoryConfidence);
    }
    map['final_category'] = Variable<String>(finalCategory);
    if (!nullToAbsent || modelVersion != null) {
      map['model_version'] = Variable<String>(modelVersion);
    }
    if (!nullToAbsent || anomalyScore != null) {
      map['anomaly_score'] = Variable<double>(anomalyScore);
    }
    map['anomaly_flag'] = Variable<int>(anomalyFlag);
    if (!nullToAbsent || anomalyReviewedAt != null) {
      map['anomaly_reviewed_at'] = Variable<int>(anomalyReviewedAt);
    }
    if (!nullToAbsent || reversesId != null) {
      map['reverses_id'] = Variable<String>(reversesId);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LedgerEntryCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntryCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      businessId: Value(businessId),
      entryType: Value(entryType),
      amountNgwee: Value(amountNgwee),
      description: Value(description),
      paymentMethod: Value(paymentMethod),
      predictedCategory: predictedCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(predictedCategory),
      categoryConfidence: categoryConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryConfidence),
      finalCategory: Value(finalCategory),
      modelVersion: modelVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(modelVersion),
      anomalyScore: anomalyScore == null && nullToAbsent
          ? const Value.absent()
          : Value(anomalyScore),
      anomalyFlag: Value(anomalyFlag),
      anomalyReviewedAt: anomalyReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(anomalyReviewedAt),
      reversesId: reversesId == null && nullToAbsent
          ? const Value.absent()
          : Value(reversesId),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LedgerEntryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntryData(
      id: serializer.fromJson<String?>(json['id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      entryType: serializer.fromJson<String>(json['entry_type']),
      amountNgwee: serializer.fromJson<int>(json['amount_ngwee']),
      description: serializer.fromJson<String>(json['description']),
      paymentMethod: serializer.fromJson<String>(json['payment_method']),
      predictedCategory: serializer.fromJson<String?>(
        json['predicted_category'],
      ),
      categoryConfidence: serializer.fromJson<double?>(
        json['category_confidence'],
      ),
      finalCategory: serializer.fromJson<String>(json['final_category']),
      modelVersion: serializer.fromJson<String?>(json['model_version']),
      anomalyScore: serializer.fromJson<double?>(json['anomaly_score']),
      anomalyFlag: serializer.fromJson<int>(json['anomaly_flag']),
      anomalyReviewedAt: serializer.fromJson<int?>(json['anomaly_reviewed_at']),
      reversesId: serializer.fromJson<String?>(json['reverses_id']),
      occurredAt: serializer.fromJson<int>(json['occurred_at']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'business_id': serializer.toJson<String>(businessId),
      'entry_type': serializer.toJson<String>(entryType),
      'amount_ngwee': serializer.toJson<int>(amountNgwee),
      'description': serializer.toJson<String>(description),
      'payment_method': serializer.toJson<String>(paymentMethod),
      'predicted_category': serializer.toJson<String?>(predictedCategory),
      'category_confidence': serializer.toJson<double?>(categoryConfidence),
      'final_category': serializer.toJson<String>(finalCategory),
      'model_version': serializer.toJson<String?>(modelVersion),
      'anomaly_score': serializer.toJson<double?>(anomalyScore),
      'anomaly_flag': serializer.toJson<int>(anomalyFlag),
      'anomaly_reviewed_at': serializer.toJson<int?>(anomalyReviewedAt),
      'reverses_id': serializer.toJson<String?>(reversesId),
      'occurred_at': serializer.toJson<int>(occurredAt),
      'created_at': serializer.toJson<int>(createdAt),
      'updated_at': serializer.toJson<int>(updatedAt),
    };
  }

  LedgerEntryData copyWith({
    Value<String?> id = const Value.absent(),
    String? businessId,
    String? entryType,
    int? amountNgwee,
    String? description,
    String? paymentMethod,
    Value<String?> predictedCategory = const Value.absent(),
    Value<double?> categoryConfidence = const Value.absent(),
    String? finalCategory,
    Value<String?> modelVersion = const Value.absent(),
    Value<double?> anomalyScore = const Value.absent(),
    int? anomalyFlag,
    Value<int?> anomalyReviewedAt = const Value.absent(),
    Value<String?> reversesId = const Value.absent(),
    int? occurredAt,
    int? createdAt,
    int? updatedAt,
  }) => LedgerEntryData(
    id: id.present ? id.value : this.id,
    businessId: businessId ?? this.businessId,
    entryType: entryType ?? this.entryType,
    amountNgwee: amountNgwee ?? this.amountNgwee,
    description: description ?? this.description,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    predictedCategory: predictedCategory.present
        ? predictedCategory.value
        : this.predictedCategory,
    categoryConfidence: categoryConfidence.present
        ? categoryConfidence.value
        : this.categoryConfidence,
    finalCategory: finalCategory ?? this.finalCategory,
    modelVersion: modelVersion.present ? modelVersion.value : this.modelVersion,
    anomalyScore: anomalyScore.present ? anomalyScore.value : this.anomalyScore,
    anomalyFlag: anomalyFlag ?? this.anomalyFlag,
    anomalyReviewedAt: anomalyReviewedAt.present
        ? anomalyReviewedAt.value
        : this.anomalyReviewedAt,
    reversesId: reversesId.present ? reversesId.value : this.reversesId,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LedgerEntryData copyWithCompanion(LedgerEntryCompanion data) {
    return LedgerEntryData(
      id: data.id.present ? data.id.value : this.id,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      amountNgwee: data.amountNgwee.present
          ? data.amountNgwee.value
          : this.amountNgwee,
      description: data.description.present
          ? data.description.value
          : this.description,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      predictedCategory: data.predictedCategory.present
          ? data.predictedCategory.value
          : this.predictedCategory,
      categoryConfidence: data.categoryConfidence.present
          ? data.categoryConfidence.value
          : this.categoryConfidence,
      finalCategory: data.finalCategory.present
          ? data.finalCategory.value
          : this.finalCategory,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      anomalyScore: data.anomalyScore.present
          ? data.anomalyScore.value
          : this.anomalyScore,
      anomalyFlag: data.anomalyFlag.present
          ? data.anomalyFlag.value
          : this.anomalyFlag,
      anomalyReviewedAt: data.anomalyReviewedAt.present
          ? data.anomalyReviewedAt.value
          : this.anomalyReviewedAt,
      reversesId: data.reversesId.present
          ? data.reversesId.value
          : this.reversesId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntryData(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('entryType: $entryType, ')
          ..write('amountNgwee: $amountNgwee, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('predictedCategory: $predictedCategory, ')
          ..write('categoryConfidence: $categoryConfidence, ')
          ..write('finalCategory: $finalCategory, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('anomalyScore: $anomalyScore, ')
          ..write('anomalyFlag: $anomalyFlag, ')
          ..write('anomalyReviewedAt: $anomalyReviewedAt, ')
          ..write('reversesId: $reversesId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessId,
    entryType,
    amountNgwee,
    description,
    paymentMethod,
    predictedCategory,
    categoryConfidence,
    finalCategory,
    modelVersion,
    anomalyScore,
    anomalyFlag,
    anomalyReviewedAt,
    reversesId,
    occurredAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntryData &&
          other.id == this.id &&
          other.businessId == this.businessId &&
          other.entryType == this.entryType &&
          other.amountNgwee == this.amountNgwee &&
          other.description == this.description &&
          other.paymentMethod == this.paymentMethod &&
          other.predictedCategory == this.predictedCategory &&
          other.categoryConfidence == this.categoryConfidence &&
          other.finalCategory == this.finalCategory &&
          other.modelVersion == this.modelVersion &&
          other.anomalyScore == this.anomalyScore &&
          other.anomalyFlag == this.anomalyFlag &&
          other.anomalyReviewedAt == this.anomalyReviewedAt &&
          other.reversesId == this.reversesId &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LedgerEntryCompanion extends UpdateCompanion<LedgerEntryData> {
  final Value<String?> id;
  final Value<String> businessId;
  final Value<String> entryType;
  final Value<int> amountNgwee;
  final Value<String> description;
  final Value<String> paymentMethod;
  final Value<String?> predictedCategory;
  final Value<double?> categoryConfidence;
  final Value<String> finalCategory;
  final Value<String?> modelVersion;
  final Value<double?> anomalyScore;
  final Value<int> anomalyFlag;
  final Value<int?> anomalyReviewedAt;
  final Value<String?> reversesId;
  final Value<int> occurredAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LedgerEntryCompanion({
    this.id = const Value.absent(),
    this.businessId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.amountNgwee = const Value.absent(),
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.predictedCategory = const Value.absent(),
    this.categoryConfidence = const Value.absent(),
    this.finalCategory = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.anomalyScore = const Value.absent(),
    this.anomalyFlag = const Value.absent(),
    this.anomalyReviewedAt = const Value.absent(),
    this.reversesId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntryCompanion.insert({
    this.id = const Value.absent(),
    required String businessId,
    required String entryType,
    required int amountNgwee,
    this.description = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.predictedCategory = const Value.absent(),
    this.categoryConfidence = const Value.absent(),
    required String finalCategory,
    this.modelVersion = const Value.absent(),
    this.anomalyScore = const Value.absent(),
    this.anomalyFlag = const Value.absent(),
    this.anomalyReviewedAt = const Value.absent(),
    this.reversesId = const Value.absent(),
    required int occurredAt,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       entryType = Value(entryType),
       amountNgwee = Value(amountNgwee),
       finalCategory = Value(finalCategory),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LedgerEntryData> custom({
    Expression<String>? id,
    Expression<String>? businessId,
    Expression<String>? entryType,
    Expression<int>? amountNgwee,
    Expression<String>? description,
    Expression<String>? paymentMethod,
    Expression<String>? predictedCategory,
    Expression<double>? categoryConfidence,
    Expression<String>? finalCategory,
    Expression<String>? modelVersion,
    Expression<double>? anomalyScore,
    Expression<int>? anomalyFlag,
    Expression<int>? anomalyReviewedAt,
    Expression<String>? reversesId,
    Expression<int>? occurredAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessId != null) 'business_id': businessId,
      if (entryType != null) 'entry_type': entryType,
      if (amountNgwee != null) 'amount_ngwee': amountNgwee,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (predictedCategory != null) 'predicted_category': predictedCategory,
      if (categoryConfidence != null) 'category_confidence': categoryConfidence,
      if (finalCategory != null) 'final_category': finalCategory,
      if (modelVersion != null) 'model_version': modelVersion,
      if (anomalyScore != null) 'anomaly_score': anomalyScore,
      if (anomalyFlag != null) 'anomaly_flag': anomalyFlag,
      if (anomalyReviewedAt != null) 'anomaly_reviewed_at': anomalyReviewedAt,
      if (reversesId != null) 'reverses_id': reversesId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntryCompanion copyWith({
    Value<String?>? id,
    Value<String>? businessId,
    Value<String>? entryType,
    Value<int>? amountNgwee,
    Value<String>? description,
    Value<String>? paymentMethod,
    Value<String?>? predictedCategory,
    Value<double?>? categoryConfidence,
    Value<String>? finalCategory,
    Value<String?>? modelVersion,
    Value<double?>? anomalyScore,
    Value<int>? anomalyFlag,
    Value<int?>? anomalyReviewedAt,
    Value<String?>? reversesId,
    Value<int>? occurredAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return LedgerEntryCompanion(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      entryType: entryType ?? this.entryType,
      amountNgwee: amountNgwee ?? this.amountNgwee,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      predictedCategory: predictedCategory ?? this.predictedCategory,
      categoryConfidence: categoryConfidence ?? this.categoryConfidence,
      finalCategory: finalCategory ?? this.finalCategory,
      modelVersion: modelVersion ?? this.modelVersion,
      anomalyScore: anomalyScore ?? this.anomalyScore,
      anomalyFlag: anomalyFlag ?? this.anomalyFlag,
      anomalyReviewedAt: anomalyReviewedAt ?? this.anomalyReviewedAt,
      reversesId: reversesId ?? this.reversesId,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (amountNgwee.present) {
      map['amount_ngwee'] = Variable<int>(amountNgwee.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (predictedCategory.present) {
      map['predicted_category'] = Variable<String>(predictedCategory.value);
    }
    if (categoryConfidence.present) {
      map['category_confidence'] = Variable<double>(categoryConfidence.value);
    }
    if (finalCategory.present) {
      map['final_category'] = Variable<String>(finalCategory.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (anomalyScore.present) {
      map['anomaly_score'] = Variable<double>(anomalyScore.value);
    }
    if (anomalyFlag.present) {
      map['anomaly_flag'] = Variable<int>(anomalyFlag.value);
    }
    if (anomalyReviewedAt.present) {
      map['anomaly_reviewed_at'] = Variable<int>(anomalyReviewedAt.value);
    }
    if (reversesId.present) {
      map['reverses_id'] = Variable<String>(reversesId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntryCompanion(')
          ..write('id: $id, ')
          ..write('businessId: $businessId, ')
          ..write('entryType: $entryType, ')
          ..write('amountNgwee: $amountNgwee, ')
          ..write('description: $description, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('predictedCategory: $predictedCategory, ')
          ..write('categoryConfidence: $categoryConfidence, ')
          ..write('finalCategory: $finalCategory, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('anomalyScore: $anomalyScore, ')
          ..write('anomalyFlag: $anomalyFlag, ')
          ..write('anomalyReviewedAt: $anomalyReviewedAt, ')
          ..write('reversesId: $reversesId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class EntryItem extends Table with TableInfo<EntryItem, EntryItemData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EntryItem(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES ledger_entry(id)',
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES product(id)',
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (quantity <> 0)',
  );
  static const VerificationMeta _unitPriceNgweeMeta = const VerificationMeta(
    'unitPriceNgwee',
  );
  late final GeneratedColumn<int> unitPriceNgwee = GeneratedColumn<int>(
    'unit_price_ngwee',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (unit_price_ngwee >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryId,
    productId,
    quantity,
    unitPriceNgwee,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryItemData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price_ngwee')) {
      context.handle(
        _unitPriceNgweeMeta,
        unitPriceNgwee.isAcceptableOrUnknown(
          data['unit_price_ngwee']!,
          _unitPriceNgweeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceNgweeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entryId, productId},
  ];
  @override
  EntryItemData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryItemData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPriceNgwee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_ngwee'],
      )!,
    );
  }

  @override
  EntryItem createAlias(String alias) {
    return EntryItem(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(entry_id, product_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class EntryItemData extends DataClass implements Insertable<EntryItemData> {
  final String? id;
  final String entryId;
  final String productId;
  final int quantity;
  final int unitPriceNgwee;
  const EntryItemData({
    this.id,
    required this.entryId,
    required this.productId,
    required this.quantity,
    required this.unitPriceNgwee,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['entry_id'] = Variable<String>(entryId);
    map['product_id'] = Variable<String>(productId);
    map['quantity'] = Variable<int>(quantity);
    map['unit_price_ngwee'] = Variable<int>(unitPriceNgwee);
    return map;
  }

  EntryItemCompanion toCompanion(bool nullToAbsent) {
    return EntryItemCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      entryId: Value(entryId),
      productId: Value(productId),
      quantity: Value(quantity),
      unitPriceNgwee: Value(unitPriceNgwee),
    );
  }

  factory EntryItemData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryItemData(
      id: serializer.fromJson<String?>(json['id']),
      entryId: serializer.fromJson<String>(json['entry_id']),
      productId: serializer.fromJson<String>(json['product_id']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPriceNgwee: serializer.fromJson<int>(json['unit_price_ngwee']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'entry_id': serializer.toJson<String>(entryId),
      'product_id': serializer.toJson<String>(productId),
      'quantity': serializer.toJson<int>(quantity),
      'unit_price_ngwee': serializer.toJson<int>(unitPriceNgwee),
    };
  }

  EntryItemData copyWith({
    Value<String?> id = const Value.absent(),
    String? entryId,
    String? productId,
    int? quantity,
    int? unitPriceNgwee,
  }) => EntryItemData(
    id: id.present ? id.value : this.id,
    entryId: entryId ?? this.entryId,
    productId: productId ?? this.productId,
    quantity: quantity ?? this.quantity,
    unitPriceNgwee: unitPriceNgwee ?? this.unitPriceNgwee,
  );
  EntryItemData copyWithCompanion(EntryItemCompanion data) {
    return EntryItemData(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPriceNgwee: data.unitPriceNgwee.present
          ? data.unitPriceNgwee.value
          : this.unitPriceNgwee,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryItemData(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPriceNgwee: $unitPriceNgwee')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entryId, productId, quantity, unitPriceNgwee);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryItemData &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.productId == this.productId &&
          other.quantity == this.quantity &&
          other.unitPriceNgwee == this.unitPriceNgwee);
}

class EntryItemCompanion extends UpdateCompanion<EntryItemData> {
  final Value<String?> id;
  final Value<String> entryId;
  final Value<String> productId;
  final Value<int> quantity;
  final Value<int> unitPriceNgwee;
  final Value<int> rowid;
  const EntryItemCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPriceNgwee = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryItemCompanion.insert({
    this.id = const Value.absent(),
    required String entryId,
    required String productId,
    required int quantity,
    required int unitPriceNgwee,
    this.rowid = const Value.absent(),
  }) : entryId = Value(entryId),
       productId = Value(productId),
       quantity = Value(quantity),
       unitPriceNgwee = Value(unitPriceNgwee);
  static Insertable<EntryItemData> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? productId,
    Expression<int>? quantity,
    Expression<int>? unitPriceNgwee,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (productId != null) 'product_id': productId,
      if (quantity != null) 'quantity': quantity,
      if (unitPriceNgwee != null) 'unit_price_ngwee': unitPriceNgwee,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryItemCompanion copyWith({
    Value<String?>? id,
    Value<String>? entryId,
    Value<String>? productId,
    Value<int>? quantity,
    Value<int>? unitPriceNgwee,
    Value<int>? rowid,
  }) {
    return EntryItemCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPriceNgwee: unitPriceNgwee ?? this.unitPriceNgwee,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPriceNgwee.present) {
      map['unit_price_ngwee'] = Variable<int>(unitPriceNgwee.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryItemCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('productId: $productId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPriceNgwee: $unitPriceNgwee, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StockAdjustment extends Table
    with TableInfo<StockAdjustment, StockAdjustmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StockAdjustment(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES product(id)',
  );
  static const VerificationMeta _quantityDeltaMeta = const VerificationMeta(
    'quantityDelta',
  );
  late final GeneratedColumn<int> quantityDelta = GeneratedColumn<int>(
    'quantity_delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (quantity_delta <> 0)',
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (reason IN (\'opening\', \'count\', \'damage\', \'other\'))',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    quantityDelta,
    reason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_adjustment';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockAdjustmentData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity_delta')) {
      context.handle(
        _quantityDeltaMeta,
        quantityDelta.isAcceptableOrUnknown(
          data['quantity_delta']!,
          _quantityDeltaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityDeltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockAdjustmentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockAdjustmentData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantityDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_delta'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  StockAdjustment createAlias(String alias) {
    return StockAdjustment(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class StockAdjustmentData extends DataClass
    implements Insertable<StockAdjustmentData> {
  final String? id;
  final String productId;
  final int quantityDelta;
  final String reason;
  final int createdAt;
  const StockAdjustmentData({
    this.id,
    required this.productId,
    required this.quantityDelta,
    required this.reason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['product_id'] = Variable<String>(productId);
    map['quantity_delta'] = Variable<int>(quantityDelta);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  StockAdjustmentCompanion toCompanion(bool nullToAbsent) {
    return StockAdjustmentCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      productId: Value(productId),
      quantityDelta: Value(quantityDelta),
      reason: Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory StockAdjustmentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockAdjustmentData(
      id: serializer.fromJson<String?>(json['id']),
      productId: serializer.fromJson<String>(json['product_id']),
      quantityDelta: serializer.fromJson<int>(json['quantity_delta']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'product_id': serializer.toJson<String>(productId),
      'quantity_delta': serializer.toJson<int>(quantityDelta),
      'reason': serializer.toJson<String>(reason),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  StockAdjustmentData copyWith({
    Value<String?> id = const Value.absent(),
    String? productId,
    int? quantityDelta,
    String? reason,
    int? createdAt,
  }) => StockAdjustmentData(
    id: id.present ? id.value : this.id,
    productId: productId ?? this.productId,
    quantityDelta: quantityDelta ?? this.quantityDelta,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
  );
  StockAdjustmentData copyWithCompanion(StockAdjustmentCompanion data) {
    return StockAdjustmentData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantityDelta: data.quantityDelta.present
          ? data.quantityDelta.value
          : this.quantityDelta,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockAdjustmentData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, quantityDelta, reason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockAdjustmentData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.quantityDelta == this.quantityDelta &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class StockAdjustmentCompanion extends UpdateCompanion<StockAdjustmentData> {
  final Value<String?> id;
  final Value<String> productId;
  final Value<int> quantityDelta;
  final Value<String> reason;
  final Value<int> createdAt;
  final Value<int> rowid;
  const StockAdjustmentCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantityDelta = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockAdjustmentCompanion.insert({
    this.id = const Value.absent(),
    required String productId,
    required int quantityDelta,
    required String reason,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       quantityDelta = Value(quantityDelta),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<StockAdjustmentData> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<int>? quantityDelta,
    Expression<String>? reason,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (quantityDelta != null) 'quantity_delta': quantityDelta,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockAdjustmentCompanion copyWith({
    Value<String?>? id,
    Value<String>? productId,
    Value<int>? quantityDelta,
    Value<String>? reason,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return StockAdjustmentCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantityDelta.present) {
      map['quantity_delta'] = Variable<int>(quantityDelta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockAdjustmentCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncRecord extends Table with TableInfo<SyncRecord, SyncRecordData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncRecord(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _entityTableMeta = const VerificationMeta(
    'entityTable',
  );
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
    'entity_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (entity_table IN (\'business\', \'product\', \'ledger_entry\', \'entry_item\', \'stock_adjustment\'))',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (operation IN (\'insert\', \'update\'))',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'pending\' CHECK (status IN (\'pending\', \'in_flight\', \'acked\', \'failed\'))',
    defaultValue: const CustomExpression('\'pending\''),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (attempts >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ackedAtMeta = const VerificationMeta(
    'ackedAt',
  );
  late final GeneratedColumn<int> ackedAt = GeneratedColumn<int>(
    'acked_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityTable,
    entityId,
    operation,
    status,
    attempts,
    lastError,
    createdAt,
    lastAttemptAt,
    ackedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_record';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRecordData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_table')) {
      context.handle(
        _entityTableMeta,
        entityTable.isAcceptableOrUnknown(
          data['entity_table']!,
          _entityTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('acked_at')) {
      context.handle(
        _ackedAtMeta,
        ackedAt.isAcceptableOrUnknown(data['acked_at']!, _ackedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncRecordData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRecordData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entityTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_table'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_attempt_at'],
      ),
      ackedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}acked_at'],
      ),
    );
  }

  @override
  SyncRecord createAlias(String alias) {
    return SyncRecord(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((status = \'acked\')=(acked_at IS NOT NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SyncRecordData extends DataClass implements Insertable<SyncRecordData> {
  final int id;
  final String entityTable;
  final String entityId;
  final String operation;
  final String status;
  final int attempts;
  final String? lastError;
  final int createdAt;
  final int? lastAttemptAt;
  final int? ackedAt;
  const SyncRecordData({
    required this.id,
    required this.entityTable,
    required this.entityId,
    required this.operation,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
    this.lastAttemptAt,
    this.ackedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    if (!nullToAbsent || ackedAt != null) {
      map['acked_at'] = Variable<int>(ackedAt);
    }
    return map;
  }

  SyncRecordCompanion toCompanion(bool nullToAbsent) {
    return SyncRecordCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      entityId: Value(entityId),
      operation: Value(operation),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      ackedAt: ackedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(ackedAt),
    );
  }

  factory SyncRecordData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRecordData(
      id: serializer.fromJson<int>(json['id']),
      entityTable: serializer.fromJson<String>(json['entity_table']),
      entityId: serializer.fromJson<String>(json['entity_id']),
      operation: serializer.fromJson<String>(json['operation']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['last_error']),
      createdAt: serializer.fromJson<int>(json['created_at']),
      lastAttemptAt: serializer.fromJson<int?>(json['last_attempt_at']),
      ackedAt: serializer.fromJson<int?>(json['acked_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entity_table': serializer.toJson<String>(entityTable),
      'entity_id': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'last_error': serializer.toJson<String?>(lastError),
      'created_at': serializer.toJson<int>(createdAt),
      'last_attempt_at': serializer.toJson<int?>(lastAttemptAt),
      'acked_at': serializer.toJson<int?>(ackedAt),
    };
  }

  SyncRecordData copyWith({
    int? id,
    String? entityTable,
    String? entityId,
    String? operation,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    int? createdAt,
    Value<int?> lastAttemptAt = const Value.absent(),
    Value<int?> ackedAt = const Value.absent(),
  }) => SyncRecordData(
    id: id ?? this.id,
    entityTable: entityTable ?? this.entityTable,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    ackedAt: ackedAt.present ? ackedAt.value : this.ackedAt,
  );
  SyncRecordData copyWithCompanion(SyncRecordCompanion data) {
    return SyncRecordData(
      id: data.id.present ? data.id.value : this.id,
      entityTable: data.entityTable.present
          ? data.entityTable.value
          : this.entityTable,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      ackedAt: data.ackedAt.present ? data.ackedAt.value : this.ackedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordData(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('ackedAt: $ackedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityTable,
    entityId,
    operation,
    status,
    attempts,
    lastError,
    createdAt,
    lastAttemptAt,
    ackedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRecordData &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.ackedAt == this.ackedAt);
}

class SyncRecordCompanion extends UpdateCompanion<SyncRecordData> {
  final Value<int> id;
  final Value<String> entityTable;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> createdAt;
  final Value<int?> lastAttemptAt;
  final Value<int?> ackedAt;
  const SyncRecordCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.ackedAt = const Value.absent(),
  });
  SyncRecordCompanion.insert({
    this.id = const Value.absent(),
    required String entityTable,
    required String entityId,
    required String operation,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required int createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.ackedAt = const Value.absent(),
  }) : entityTable = Value(entityTable),
       entityId = Value(entityId),
       operation = Value(operation),
       createdAt = Value(createdAt);
  static Insertable<SyncRecordData> custom({
    Expression<int>? id,
    Expression<String>? entityTable,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? createdAt,
    Expression<int>? lastAttemptAt,
    Expression<int>? ackedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (ackedAt != null) 'acked_at': ackedAt,
    });
  }

  SyncRecordCompanion copyWith({
    Value<int>? id,
    Value<String>? entityTable,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? createdAt,
    Value<int?>? lastAttemptAt,
    Value<int?>? ackedAt,
  }) {
    return SyncRecordCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      ackedAt: ackedAt ?? this.ackedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (ackedAt.present) {
      map['acked_at'] = Variable<int>(ackedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRecordCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('ackedAt: $ackedAt')
          ..write(')'))
        .toString();
  }
}

class VStockLevelData extends DataClass {
  final String? productId;
  final String businessId;
  final String name;
  final int reorderLevel;
  final int stockQty;
  const VStockLevelData({
    this.productId,
    required this.businessId,
    required this.name,
    required this.reorderLevel,
    required this.stockQty,
  });
  factory VStockLevelData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VStockLevelData(
      productId: serializer.fromJson<String?>(json['product_id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      name: serializer.fromJson<String>(json['name']),
      reorderLevel: serializer.fromJson<int>(json['reorder_level']),
      stockQty: serializer.fromJson<int>(json['stock_qty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'product_id': serializer.toJson<String?>(productId),
      'business_id': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'reorder_level': serializer.toJson<int>(reorderLevel),
      'stock_qty': serializer.toJson<int>(stockQty),
    };
  }

  VStockLevelData copyWith({
    Value<String?> productId = const Value.absent(),
    String? businessId,
    String? name,
    int? reorderLevel,
    int? stockQty,
  }) => VStockLevelData(
    productId: productId.present ? productId.value : this.productId,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    stockQty: stockQty ?? this.stockQty,
  );
  @override
  String toString() {
    return (StringBuffer('VStockLevelData(')
          ..write('productId: $productId, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('stockQty: $stockQty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(productId, businessId, name, reorderLevel, stockQty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VStockLevelData &&
          other.productId == this.productId &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.reorderLevel == this.reorderLevel &&
          other.stockQty == this.stockQty);
}

class VStockLevel extends ViewInfo<VStockLevel, VStockLevelData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  VStockLevel(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    businessId,
    name,
    reorderLevel,
    stockQty,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'v_stock_level';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite:
        'CREATE VIEW v_stock_level AS SELECT p.id AS product_id, p.business_id, p.name, p.reorder_level, COALESCE((SELECT SUM(CASE e.entry_type WHEN \'expense\' THEN i.quantity ELSE -i.quantity END) FROM entry_item AS i JOIN ledger_entry AS e ON e.id = i.entry_id WHERE i.product_id = p.id), 0) + COALESCE((SELECT SUM(a.quantity_delta) FROM stock_adjustment AS a WHERE a.product_id = p.id), 0) AS stock_qty FROM product AS p WHERE p.is_active = 1',
  };
  @override
  VStockLevel get asDslTable => this;
  @override
  VStockLevelData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VStockLevelData(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      reorderLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reorder_level'],
      )!,
      stockQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_qty'],
      )!,
    );
  }

  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> reorderLevel = GeneratedColumn<int>(
    'reorder_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> stockQty = GeneratedColumn<int>(
    'stock_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  @override
  VStockLevel createAlias(String alias) {
    return VStockLevel(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {
    'product',
    'entry_item',
    'ledger_entry',
    'stock_adjustment',
  };
}

class VLowStockData extends DataClass {
  final String? productId;
  final String businessId;
  final String name;
  final int reorderLevel;
  final int stockQty;
  const VLowStockData({
    this.productId,
    required this.businessId,
    required this.name,
    required this.reorderLevel,
    required this.stockQty,
  });
  factory VLowStockData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VLowStockData(
      productId: serializer.fromJson<String?>(json['product_id']),
      businessId: serializer.fromJson<String>(json['business_id']),
      name: serializer.fromJson<String>(json['name']),
      reorderLevel: serializer.fromJson<int>(json['reorder_level']),
      stockQty: serializer.fromJson<int>(json['stock_qty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'product_id': serializer.toJson<String?>(productId),
      'business_id': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'reorder_level': serializer.toJson<int>(reorderLevel),
      'stock_qty': serializer.toJson<int>(stockQty),
    };
  }

  VLowStockData copyWith({
    Value<String?> productId = const Value.absent(),
    String? businessId,
    String? name,
    int? reorderLevel,
    int? stockQty,
  }) => VLowStockData(
    productId: productId.present ? productId.value : this.productId,
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    stockQty: stockQty ?? this.stockQty,
  );
  @override
  String toString() {
    return (StringBuffer('VLowStockData(')
          ..write('productId: $productId, ')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('stockQty: $stockQty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(productId, businessId, name, reorderLevel, stockQty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VLowStockData &&
          other.productId == this.productId &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.reorderLevel == this.reorderLevel &&
          other.stockQty == this.stockQty);
}

class VLowStock extends ViewInfo<VLowStock, VLowStockData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  VLowStock(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    businessId,
    name,
    reorderLevel,
    stockQty,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'v_low_stock';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite:
        'CREATE VIEW v_low_stock AS SELECT * FROM v_stock_level WHERE stock_qty <= reorder_level',
  };
  @override
  VLowStock get asDslTable => this;
  @override
  VLowStockData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VLowStockData(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      reorderLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reorder_level'],
      )!,
      stockQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_qty'],
      )!,
    );
  }

  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> reorderLevel = GeneratedColumn<int>(
    'reorder_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> stockQty = GeneratedColumn<int>(
    'stock_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  @override
  VLowStock createAlias(String alias) {
    return VLowStock(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {
    'product',
    'entry_item',
    'ledger_entry',
    'stock_adjustment',
  };
}

class VDailySummaryData extends DataClass {
  final String businessId;
  final String day;
  final int? incomeNgwee;
  final int? expenseNgwee;
  final int? profitNgwee;
  const VDailySummaryData({
    required this.businessId,
    required this.day,
    this.incomeNgwee,
    this.expenseNgwee,
    this.profitNgwee,
  });
  factory VDailySummaryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VDailySummaryData(
      businessId: serializer.fromJson<String>(json['business_id']),
      day: serializer.fromJson<String>(json['day']),
      incomeNgwee: serializer.fromJson<int?>(json['income_ngwee']),
      expenseNgwee: serializer.fromJson<int?>(json['expense_ngwee']),
      profitNgwee: serializer.fromJson<int?>(json['profit_ngwee']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'business_id': serializer.toJson<String>(businessId),
      'day': serializer.toJson<String>(day),
      'income_ngwee': serializer.toJson<int?>(incomeNgwee),
      'expense_ngwee': serializer.toJson<int?>(expenseNgwee),
      'profit_ngwee': serializer.toJson<int?>(profitNgwee),
    };
  }

  VDailySummaryData copyWith({
    String? businessId,
    String? day,
    Value<int?> incomeNgwee = const Value.absent(),
    Value<int?> expenseNgwee = const Value.absent(),
    Value<int?> profitNgwee = const Value.absent(),
  }) => VDailySummaryData(
    businessId: businessId ?? this.businessId,
    day: day ?? this.day,
    incomeNgwee: incomeNgwee.present ? incomeNgwee.value : this.incomeNgwee,
    expenseNgwee: expenseNgwee.present ? expenseNgwee.value : this.expenseNgwee,
    profitNgwee: profitNgwee.present ? profitNgwee.value : this.profitNgwee,
  );
  @override
  String toString() {
    return (StringBuffer('VDailySummaryData(')
          ..write('businessId: $businessId, ')
          ..write('day: $day, ')
          ..write('incomeNgwee: $incomeNgwee, ')
          ..write('expenseNgwee: $expenseNgwee, ')
          ..write('profitNgwee: $profitNgwee')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(businessId, day, incomeNgwee, expenseNgwee, profitNgwee);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VDailySummaryData &&
          other.businessId == this.businessId &&
          other.day == this.day &&
          other.incomeNgwee == this.incomeNgwee &&
          other.expenseNgwee == this.expenseNgwee &&
          other.profitNgwee == this.profitNgwee);
}

class VDailySummary extends ViewInfo<VDailySummary, VDailySummaryData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  VDailySummary(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [
    businessId,
    day,
    incomeNgwee,
    expenseNgwee,
    profitNgwee,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'v_daily_summary';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite:
        'CREATE VIEW v_daily_summary AS SELECT business_id, date(occurred_at / 1000, \'unixepoch\', \'+2 hours\') AS day, SUM(CASE WHEN entry_type = \'sale\' THEN amount_ngwee ELSE 0 END) AS income_ngwee, SUM(CASE WHEN entry_type = \'expense\' THEN amount_ngwee ELSE 0 END) AS expense_ngwee, SUM(CASE WHEN entry_type = \'sale\' THEN amount_ngwee ELSE -amount_ngwee END) AS profit_ngwee FROM ledger_entry GROUP BY business_id, day',
  };
  @override
  VDailySummary get asDslTable => this;
  @override
  VDailySummaryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VDailySummaryData(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      incomeNgwee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}income_ngwee'],
      ),
      expenseNgwee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expense_ngwee'],
      ),
      profitNgwee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profit_ngwee'],
      ),
    );
  }

  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> incomeNgwee = GeneratedColumn<int>(
    'income_ngwee',
    aliasedName,
    true,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> expenseNgwee = GeneratedColumn<int>(
    'expense_ngwee',
    aliasedName,
    true,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<int> profitNgwee = GeneratedColumn<int>(
    'profit_ngwee',
    aliasedName,
    true,
    type: DriftSqlType.int,
  );
  @override
  VDailySummary createAlias(String alias) {
    return VDailySummary(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {'ledger_entry'};
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Business business = Business(this);
  late final Category category = Category(this);
  late final Product product = Product(this);
  late final LedgerEntry ledgerEntry = LedgerEntry(this);
  late final EntryItem entryItem = EntryItem(this);
  late final StockAdjustment stockAdjustment = StockAdjustment(this);
  late final SyncRecord syncRecord = SyncRecord(this);
  late final Index ixEntryBusinessTime = Index(
    'ix_entry_business_time',
    'CREATE INDEX ix_entry_business_time ON ledger_entry (business_id, occurred_at)',
  );
  late final Index ixEntryCategory = Index(
    'ix_entry_category',
    'CREATE INDEX ix_entry_category ON ledger_entry (final_category)',
  );
  late final Index ixItemEntry = Index(
    'ix_item_entry',
    'CREATE INDEX ix_item_entry ON entry_item (entry_id)',
  );
  late final Index ixItemProduct = Index(
    'ix_item_product',
    'CREATE INDEX ix_item_product ON entry_item (product_id)',
  );
  late final Index ixAdjustProduct = Index(
    'ix_adjust_product',
    'CREATE INDEX ix_adjust_product ON stock_adjustment (product_id)',
  );
  late final Index ixSyncQueue = Index(
    'ix_sync_queue',
    'CREATE INDEX ix_sync_queue ON sync_record (status, id)',
  );
  late final Trigger trgEntryNoDelete = Trigger(
    'CREATE TRIGGER trg_entry_no_delete BEFORE DELETE ON ledger_entry BEGIN SELECT RAISE (ABORT, \'ledger entries are append-only: post a reversal\');END',
    'trg_entry_no_delete',
  );
  late final Trigger trgEntryNoFinancialUpdate = Trigger(
    'CREATE TRIGGER trg_entry_no_financial_update BEFORE UPDATE OF business_id, entry_type, amount_ngwee, payment_method, reverses_id, occurred_at, created_at ON ledger_entry BEGIN SELECT RAISE (ABORT, \'financial fields are immutable: post a reversal\');END',
    'trg_entry_no_financial_update',
  );
  late final Trigger trgItemNoChange = Trigger(
    'CREATE TRIGGER trg_item_no_change BEFORE UPDATE ON entry_item BEGIN SELECT RAISE (ABORT, \'entry items are immutable\');END',
    'trg_item_no_change',
  );
  late final Trigger trgItemNoDelete = Trigger(
    'CREATE TRIGGER trg_item_no_delete BEFORE DELETE ON entry_item BEGIN SELECT RAISE (ABORT, \'entry items are immutable\');END',
    'trg_item_no_delete',
  );
  late final Trigger trgReversalMatches = Trigger(
    'CREATE TRIGGER trg_reversal_matches BEFORE INSERT ON ledger_entry WHEN NEW.reverses_id IS NOT NULL BEGIN SELECT RAISE (ABORT, \'reversal must cancel the original exactly\') WHERE NOT EXISTS (SELECT 1 FROM ledger_entry AS o WHERE o.id = NEW.reverses_id AND o.reverses_id IS NULL AND o.entry_type = NEW.entry_type AND o.amount_ngwee = -NEW.amount_ngwee AND o.business_id = NEW.business_id);END',
    'trg_reversal_matches',
  );
  late final Trigger trgQBusinessIns = Trigger(
    'CREATE TRIGGER trg_q_business_ins AFTER INSERT ON business BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES (\'business\', NEW.id, \'insert\', NEW.created_at);END',
    'trg_q_business_ins',
  );
  late final Trigger trgQProductIns = Trigger(
    'CREATE TRIGGER trg_q_product_ins AFTER INSERT ON product BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES (\'product\', NEW.id, \'insert\', NEW.created_at);END',
    'trg_q_product_ins',
  );
  late final Trigger trgQProductUpd = Trigger(
    'CREATE TRIGGER trg_q_product_upd AFTER UPDATE ON product BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES (\'product\', NEW.id, \'update\', NEW.updated_at);END',
    'trg_q_product_upd',
  );
  late final Trigger trgQEntryIns = Trigger(
    'CREATE TRIGGER trg_q_entry_ins AFTER INSERT ON ledger_entry BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES (\'ledger_entry\', NEW.id, \'insert\', NEW.created_at);END',
    'trg_q_entry_ins',
  );
  late final Trigger trgQEntryUpd = Trigger(
    'CREATE TRIGGER trg_q_entry_upd AFTER UPDATE ON ledger_entry BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES (\'ledger_entry\', NEW.id, \'update\', NEW.updated_at);END',
    'trg_q_entry_upd',
  );
  late final Trigger trgQItemIns = Trigger(
    'CREATE TRIGGER trg_q_item_ins AFTER INSERT ON entry_item BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES (\'entry_item\', NEW.id, \'insert\', (SELECT created_at FROM ledger_entry WHERE id = NEW.entry_id));END',
    'trg_q_item_ins',
  );
  late final Trigger trgQAdjustIns = Trigger(
    'CREATE TRIGGER trg_q_adjust_ins AFTER INSERT ON stock_adjustment BEGIN INSERT INTO sync_record (entity_table, entity_id, operation, created_at) VALUES (\'stock_adjustment\', NEW.id, \'insert\', NEW.created_at);END',
    'trg_q_adjust_ins',
  );
  late final VStockLevel vStockLevel = VStockLevel(this);
  late final VLowStock vLowStock = VLowStock(this);
  late final VDailySummary vDailySummary = VDailySummary(this);
  late final Trigger trgCategoryKind = Trigger(
    'CREATE TRIGGER trg_category_kind BEFORE INSERT ON ledger_entry BEGIN SELECT RAISE (ABORT, \'category kind does not match entry type\') WHERE (SELECT kind FROM category WHERE code = NEW.final_category) <> CASE NEW.entry_type WHEN \'sale\' THEN \'income\' ELSE \'expense\' END;END',
    'trg_category_kind',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    business,
    category,
    product,
    ledgerEntry,
    entryItem,
    stockAdjustment,
    syncRecord,
    ixEntryBusinessTime,
    ixEntryCategory,
    ixItemEntry,
    ixItemProduct,
    ixAdjustProduct,
    ixSyncQueue,
    trgEntryNoDelete,
    trgEntryNoFinancialUpdate,
    trgItemNoChange,
    trgItemNoDelete,
    trgReversalMatches,
    trgQBusinessIns,
    trgQProductIns,
    trgQProductUpd,
    trgQEntryIns,
    trgQEntryUpd,
    trgQItemIns,
    trgQAdjustIns,
    vStockLevel,
    vLowStock,
    vDailySummary,
    trgCategoryKind,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entry',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entry',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry_item',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry_item',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entry',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'business',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_record', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'product',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_record', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'product',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_record', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entry',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_record', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entry',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('sync_record', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'entry_item',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_record', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stock_adjustment',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('sync_record', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ledger_entry',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
  ]);
}

typedef $BusinessCreateCompanionBuilder =
    BusinessCompanion Function({
      Value<String?> id,
      required String participantCode,
      Value<String?> businessType,
      required int createdAt,
      Value<int> rowid,
    });
typedef $BusinessUpdateCompanionBuilder =
    BusinessCompanion Function({
      Value<String?> id,
      Value<String> participantCode,
      Value<String?> businessType,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $BusinessReferences
    extends BaseReferences<_$AppDatabase, Business, BusinessData> {
  $BusinessReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Product, List<ProductData>> _productRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.product,
    aliasName: 'business__id__product__business_id',
  );

  $ProductProcessedTableManager get productRefs {
    final manager = $ProductTableManager(
      $_db,
      $_db.product,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_productRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<LedgerEntry, List<LedgerEntryData>>
  _ledgerEntryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntry,
    aliasName: 'business__id__ledger_entry__business_id',
  );

  $LedgerEntryProcessedTableManager get ledgerEntryRefs {
    final manager = $LedgerEntryTableManager(
      $_db,
      $_db.ledgerEntry,
    ).filter((f) => f.businessId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_ledgerEntryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $BusinessFilterComposer extends Composer<_$AppDatabase, Business> {
  $BusinessFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantCode => $composableBuilder(
    column: $table.participantCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productRefs(
    Expression<bool> Function($ProductFilterComposer f) f,
  ) {
    final $ProductFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.product,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductFilterComposer(
            $db: $db,
            $table: $db.product,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerEntryRefs(
    Expression<bool> Function($LedgerEntryFilterComposer f) f,
  ) {
    final $LedgerEntryFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntry,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntryFilterComposer(
            $db: $db,
            $table: $db.ledgerEntry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $BusinessOrderingComposer extends Composer<_$AppDatabase, Business> {
  $BusinessOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantCode => $composableBuilder(
    column: $table.participantCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $BusinessAnnotationComposer extends Composer<_$AppDatabase, Business> {
  $BusinessAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get participantCode => $composableBuilder(
    column: $table.participantCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> productRefs<T extends Object>(
    Expression<T> Function($ProductAnnotationComposer a) f,
  ) {
    final $ProductAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.product,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductAnnotationComposer(
            $db: $db,
            $table: $db.product,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerEntryRefs<T extends Object>(
    Expression<T> Function($LedgerEntryAnnotationComposer a) f,
  ) {
    final $LedgerEntryAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntry,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntryAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $BusinessTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Business,
          BusinessData,
          $BusinessFilterComposer,
          $BusinessOrderingComposer,
          $BusinessAnnotationComposer,
          $BusinessCreateCompanionBuilder,
          $BusinessUpdateCompanionBuilder,
          (BusinessData, $BusinessReferences),
          BusinessData,
          PrefetchHooks Function({bool productRefs, bool ledgerEntryRefs})
        > {
  $BusinessTableManager(_$AppDatabase db, Business table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BusinessFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BusinessOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BusinessAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> participantCode = const Value.absent(),
                Value<String?> businessType = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessCompanion(
                id: id,
                participantCode: participantCode,
                businessType: businessType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String participantCode,
                Value<String?> businessType = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BusinessCompanion.insert(
                id: id,
                participantCode: participantCode,
                businessType: businessType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $BusinessReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({productRefs = false, ledgerEntryRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productRefs) db.product,
                    if (ledgerEntryRefs) db.ledgerEntry,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productRefs)
                        await $_getPrefetchedData<
                          BusinessData,
                          Business,
                          ProductData
                        >(
                          currentTable: table,
                          referencedTable: $BusinessReferences
                              ._productRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $BusinessReferences(db, table, p0).productRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ledgerEntryRefs)
                        await $_getPrefetchedData<
                          BusinessData,
                          Business,
                          LedgerEntryData
                        >(
                          currentTable: table,
                          referencedTable: $BusinessReferences
                              ._ledgerEntryRefsTable(db),
                          managerFromTypedResult: (p0) => $BusinessReferences(
                            db,
                            table,
                            p0,
                          ).ledgerEntryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.businessId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $BusinessProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Business,
      BusinessData,
      $BusinessFilterComposer,
      $BusinessOrderingComposer,
      $BusinessAnnotationComposer,
      $BusinessCreateCompanionBuilder,
      $BusinessUpdateCompanionBuilder,
      (BusinessData, $BusinessReferences),
      BusinessData,
      PrefetchHooks Function({bool productRefs, bool ledgerEntryRefs})
    >;
typedef $CategoryCreateCompanionBuilder =
    CategoryCompanion Function({
      Value<String?> code,
      required String name,
      required String kind,
      required String icon,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $CategoryUpdateCompanionBuilder =
    CategoryCompanion Function({
      Value<String?> code,
      Value<String> name,
      Value<String> kind,
      Value<String> icon,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $CategoryFilterComposer extends Composer<_$AppDatabase, Category> {
  $CategoryFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $CategoryOrderingComposer extends Composer<_$AppDatabase, Category> {
  $CategoryOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CategoryAnnotationComposer extends Composer<_$AppDatabase, Category> {
  $CategoryAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $CategoryTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Category,
          CategoryData,
          $CategoryFilterComposer,
          $CategoryOrderingComposer,
          $CategoryAnnotationComposer,
          $CategoryCreateCompanionBuilder,
          $CategoryUpdateCompanionBuilder,
          (CategoryData, BaseReferences<_$AppDatabase, Category, CategoryData>),
          CategoryData,
          PrefetchHooks Function()
        > {
  $CategoryTableManager(_$AppDatabase db, Category table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CategoryFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CategoryOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CategoryAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryCompanion(
                code: code,
                name: name,
                kind: kind,
                icon: icon,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> code = const Value.absent(),
                required String name,
                required String kind,
                required String icon,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryCompanion.insert(
                code: code,
                name: name,
                kind: kind,
                icon: icon,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CategoryProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Category,
      CategoryData,
      $CategoryFilterComposer,
      $CategoryOrderingComposer,
      $CategoryAnnotationComposer,
      $CategoryCreateCompanionBuilder,
      $CategoryUpdateCompanionBuilder,
      (CategoryData, BaseReferences<_$AppDatabase, Category, CategoryData>),
      CategoryData,
      PrefetchHooks Function()
    >;
typedef $ProductCreateCompanionBuilder =
    ProductCompanion Function({
      Value<String?> id,
      required String businessId,
      required String name,
      required int unitPriceNgwee,
      Value<int> reorderLevel,
      Value<int> isActive,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $ProductUpdateCompanionBuilder =
    ProductCompanion Function({
      Value<String?> id,
      Value<String> businessId,
      Value<String> name,
      Value<int> unitPriceNgwee,
      Value<int> reorderLevel,
      Value<int> isActive,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $ProductReferences
    extends BaseReferences<_$AppDatabase, Product, ProductData> {
  $ProductReferences(super.$_db, super.$_table, super.$_typedResult);

  static Business _businessIdTable(_$AppDatabase db) =>
      db.business.createAlias('product__business_id__business__id');

  $BusinessProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $BusinessTableManager(
      $_db,
      $_db.business,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<EntryItem, List<EntryItemData>>
  _entryItemRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryItem,
    aliasName: 'product__id__entry_item__product_id',
  );

  $EntryItemProcessedTableManager get entryItemRefs {
    final manager = $EntryItemTableManager(
      $_db,
      $_db.entryItem,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_entryItemRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<StockAdjustment, List<StockAdjustmentData>>
  _stockAdjustmentRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stockAdjustment,
    aliasName: 'product__id__stock_adjustment__product_id',
  );

  $StockAdjustmentProcessedTableManager get stockAdjustmentRefs {
    final manager = $StockAdjustmentTableManager(
      $_db,
      $_db.stockAdjustment,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(
      _stockAdjustmentRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ProductFilterComposer extends Composer<_$AppDatabase, Product> {
  $ProductFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceNgwee => $composableBuilder(
    column: $table.unitPriceNgwee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $BusinessFilterComposer get businessId {
    final $BusinessFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.business,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BusinessFilterComposer(
            $db: $db,
            $table: $db.business,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entryItemRefs(
    Expression<bool> Function($EntryItemFilterComposer f) f,
  ) {
    final $EntryItemFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryItem,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryItemFilterComposer(
            $db: $db,
            $table: $db.entryItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stockAdjustmentRefs(
    Expression<bool> Function($StockAdjustmentFilterComposer f) f,
  ) {
    final $StockAdjustmentFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockAdjustment,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StockAdjustmentFilterComposer(
            $db: $db,
            $table: $db.stockAdjustment,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ProductOrderingComposer extends Composer<_$AppDatabase, Product> {
  $ProductOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceNgwee => $composableBuilder(
    column: $table.unitPriceNgwee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $BusinessOrderingComposer get businessId {
    final $BusinessOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.business,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BusinessOrderingComposer(
            $db: $db,
            $table: $db.business,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ProductAnnotationComposer extends Composer<_$AppDatabase, Product> {
  $ProductAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get unitPriceNgwee => $composableBuilder(
    column: $table.unitPriceNgwee,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $BusinessAnnotationComposer get businessId {
    final $BusinessAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.business,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BusinessAnnotationComposer(
            $db: $db,
            $table: $db.business,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entryItemRefs<T extends Object>(
    Expression<T> Function($EntryItemAnnotationComposer a) f,
  ) {
    final $EntryItemAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryItem,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryItemAnnotationComposer(
            $db: $db,
            $table: $db.entryItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stockAdjustmentRefs<T extends Object>(
    Expression<T> Function($StockAdjustmentAnnotationComposer a) f,
  ) {
    final $StockAdjustmentAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockAdjustment,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StockAdjustmentAnnotationComposer(
            $db: $db,
            $table: $db.stockAdjustment,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ProductTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Product,
          ProductData,
          $ProductFilterComposer,
          $ProductOrderingComposer,
          $ProductAnnotationComposer,
          $ProductCreateCompanionBuilder,
          $ProductUpdateCompanionBuilder,
          (ProductData, $ProductReferences),
          ProductData,
          PrefetchHooks Function({
            bool businessId,
            bool entryItemRefs,
            bool stockAdjustmentRefs,
          })
        > {
  $ProductTableManager(_$AppDatabase db, Product table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ProductFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ProductOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ProductAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> unitPriceNgwee = const Value.absent(),
                Value<int> reorderLevel = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductCompanion(
                id: id,
                businessId: businessId,
                name: name,
                unitPriceNgwee: unitPriceNgwee,
                reorderLevel: reorderLevel,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String businessId,
                required String name,
                required int unitPriceNgwee,
                Value<int> reorderLevel = const Value.absent(),
                Value<int> isActive = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductCompanion.insert(
                id: id,
                businessId: businessId,
                name: name,
                unitPriceNgwee: unitPriceNgwee,
                reorderLevel: reorderLevel,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $ProductReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                businessId = false,
                entryItemRefs = false,
                stockAdjustmentRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (entryItemRefs) db.entryItem,
                    if (stockAdjustmentRefs) db.stockAdjustment,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable: $ProductReferences
                                        ._businessIdTable(db),
                                    referencedColumn: $ProductReferences
                                        ._businessIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entryItemRefs)
                        await $_getPrefetchedData<
                          ProductData,
                          Product,
                          EntryItemData
                        >(
                          currentTable: table,
                          referencedTable: $ProductReferences
                              ._entryItemRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ProductReferences(db, table, p0).entryItemRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stockAdjustmentRefs)
                        await $_getPrefetchedData<
                          ProductData,
                          Product,
                          StockAdjustmentData
                        >(
                          currentTable: table,
                          referencedTable: $ProductReferences
                              ._stockAdjustmentRefsTable(db),
                          managerFromTypedResult: (p0) => $ProductReferences(
                            db,
                            table,
                            p0,
                          ).stockAdjustmentRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ProductProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Product,
      ProductData,
      $ProductFilterComposer,
      $ProductOrderingComposer,
      $ProductAnnotationComposer,
      $ProductCreateCompanionBuilder,
      $ProductUpdateCompanionBuilder,
      (ProductData, $ProductReferences),
      ProductData,
      PrefetchHooks Function({
        bool businessId,
        bool entryItemRefs,
        bool stockAdjustmentRefs,
      })
    >;
typedef $LedgerEntryCreateCompanionBuilder =
    LedgerEntryCompanion Function({
      Value<String?> id,
      required String businessId,
      required String entryType,
      required int amountNgwee,
      Value<String> description,
      Value<String> paymentMethod,
      Value<String?> predictedCategory,
      Value<double?> categoryConfidence,
      required String finalCategory,
      Value<String?> modelVersion,
      Value<double?> anomalyScore,
      Value<int> anomalyFlag,
      Value<int?> anomalyReviewedAt,
      Value<String?> reversesId,
      required int occurredAt,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $LedgerEntryUpdateCompanionBuilder =
    LedgerEntryCompanion Function({
      Value<String?> id,
      Value<String> businessId,
      Value<String> entryType,
      Value<int> amountNgwee,
      Value<String> description,
      Value<String> paymentMethod,
      Value<String?> predictedCategory,
      Value<double?> categoryConfidence,
      Value<String> finalCategory,
      Value<String?> modelVersion,
      Value<double?> anomalyScore,
      Value<int> anomalyFlag,
      Value<int?> anomalyReviewedAt,
      Value<String?> reversesId,
      Value<int> occurredAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $LedgerEntryReferences
    extends BaseReferences<_$AppDatabase, LedgerEntry, LedgerEntryData> {
  $LedgerEntryReferences(super.$_db, super.$_table, super.$_typedResult);

  static Business _businessIdTable(_$AppDatabase db) =>
      db.business.createAlias('ledger_entry__business_id__business__id');

  $BusinessProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $BusinessTableManager(
      $_db,
      $_db.business,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Category _predictedCategoryTable(_$AppDatabase db) => db.category
      .createAlias('ledger_entry__predicted_category__category__code');

  $CategoryProcessedTableManager? get predictedCategory {
    final $_column = $_itemColumn<String>('predicted_category');
    if ($_column == null) return null;
    final manager = $CategoryTableManager(
      $_db,
      $_db.category,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_predictedCategoryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Category _finalCategoryTable(_$AppDatabase db) =>
      db.category.createAlias('ledger_entry__final_category__category__code');

  $CategoryProcessedTableManager get finalCategory {
    final $_column = $_itemColumn<String>('final_category')!;

    final manager = $CategoryTableManager(
      $_db,
      $_db.category,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_finalCategoryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<EntryItem, List<EntryItemData>>
  _entryItemRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.entryItem,
    aliasName: 'ledger_entry__id__entry_item__entry_id',
  );

  $EntryItemProcessedTableManager get entryItemRefs {
    final manager = $EntryItemTableManager(
      $_db,
      $_db.entryItem,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_entryItemRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $LedgerEntryFilterComposer extends Composer<_$AppDatabase, LedgerEntry> {
  $LedgerEntryFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountNgwee => $composableBuilder(
    column: $table.amountNgwee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get categoryConfidence => $composableBuilder(
    column: $table.categoryConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get anomalyScore => $composableBuilder(
    column: $table.anomalyScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anomalyFlag => $composableBuilder(
    column: $table.anomalyFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anomalyReviewedAt => $composableBuilder(
    column: $table.anomalyReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reversesId => $composableBuilder(
    column: $table.reversesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $BusinessFilterComposer get businessId {
    final $BusinessFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.business,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BusinessFilterComposer(
            $db: $db,
            $table: $db.business,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CategoryFilterComposer get predictedCategory {
    final $CategoryFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.predictedCategory,
      referencedTable: $db.category,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoryFilterComposer(
            $db: $db,
            $table: $db.category,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CategoryFilterComposer get finalCategory {
    final $CategoryFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.finalCategory,
      referencedTable: $db.category,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoryFilterComposer(
            $db: $db,
            $table: $db.category,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> entryItemRefs(
    Expression<bool> Function($EntryItemFilterComposer f) f,
  ) {
    final $EntryItemFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryItem,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryItemFilterComposer(
            $db: $db,
            $table: $db.entryItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $LedgerEntryOrderingComposer
    extends Composer<_$AppDatabase, LedgerEntry> {
  $LedgerEntryOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountNgwee => $composableBuilder(
    column: $table.amountNgwee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get categoryConfidence => $composableBuilder(
    column: $table.categoryConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get anomalyScore => $composableBuilder(
    column: $table.anomalyScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anomalyFlag => $composableBuilder(
    column: $table.anomalyFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anomalyReviewedAt => $composableBuilder(
    column: $table.anomalyReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reversesId => $composableBuilder(
    column: $table.reversesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $BusinessOrderingComposer get businessId {
    final $BusinessOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.business,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BusinessOrderingComposer(
            $db: $db,
            $table: $db.business,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CategoryOrderingComposer get predictedCategory {
    final $CategoryOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.predictedCategory,
      referencedTable: $db.category,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoryOrderingComposer(
            $db: $db,
            $table: $db.category,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CategoryOrderingComposer get finalCategory {
    final $CategoryOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.finalCategory,
      referencedTable: $db.category,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoryOrderingComposer(
            $db: $db,
            $table: $db.category,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $LedgerEntryAnnotationComposer
    extends Composer<_$AppDatabase, LedgerEntry> {
  $LedgerEntryAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<int> get amountNgwee => $composableBuilder(
    column: $table.amountNgwee,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get categoryConfidence => $composableBuilder(
    column: $table.categoryConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<double> get anomalyScore => $composableBuilder(
    column: $table.anomalyScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get anomalyFlag => $composableBuilder(
    column: $table.anomalyFlag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get anomalyReviewedAt => $composableBuilder(
    column: $table.anomalyReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reversesId => $composableBuilder(
    column: $table.reversesId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $BusinessAnnotationComposer get businessId {
    final $BusinessAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.business,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BusinessAnnotationComposer(
            $db: $db,
            $table: $db.business,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CategoryAnnotationComposer get predictedCategory {
    final $CategoryAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.predictedCategory,
      referencedTable: $db.category,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoryAnnotationComposer(
            $db: $db,
            $table: $db.category,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CategoryAnnotationComposer get finalCategory {
    final $CategoryAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.finalCategory,
      referencedTable: $db.category,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoryAnnotationComposer(
            $db: $db,
            $table: $db.category,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> entryItemRefs<T extends Object>(
    Expression<T> Function($EntryItemAnnotationComposer a) f,
  ) {
    final $EntryItemAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryItem,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EntryItemAnnotationComposer(
            $db: $db,
            $table: $db.entryItem,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $LedgerEntryTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          LedgerEntry,
          LedgerEntryData,
          $LedgerEntryFilterComposer,
          $LedgerEntryOrderingComposer,
          $LedgerEntryAnnotationComposer,
          $LedgerEntryCreateCompanionBuilder,
          $LedgerEntryUpdateCompanionBuilder,
          (LedgerEntryData, $LedgerEntryReferences),
          LedgerEntryData,
          PrefetchHooks Function({
            bool businessId,
            bool predictedCategory,
            bool finalCategory,
            bool entryItemRefs,
          })
        > {
  $LedgerEntryTableManager(_$AppDatabase db, LedgerEntry table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LedgerEntryFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LedgerEntryOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LedgerEntryAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String> entryType = const Value.absent(),
                Value<int> amountNgwee = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> predictedCategory = const Value.absent(),
                Value<double?> categoryConfidence = const Value.absent(),
                Value<String> finalCategory = const Value.absent(),
                Value<String?> modelVersion = const Value.absent(),
                Value<double?> anomalyScore = const Value.absent(),
                Value<int> anomalyFlag = const Value.absent(),
                Value<int?> anomalyReviewedAt = const Value.absent(),
                Value<String?> reversesId = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntryCompanion(
                id: id,
                businessId: businessId,
                entryType: entryType,
                amountNgwee: amountNgwee,
                description: description,
                paymentMethod: paymentMethod,
                predictedCategory: predictedCategory,
                categoryConfidence: categoryConfidence,
                finalCategory: finalCategory,
                modelVersion: modelVersion,
                anomalyScore: anomalyScore,
                anomalyFlag: anomalyFlag,
                anomalyReviewedAt: anomalyReviewedAt,
                reversesId: reversesId,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String businessId,
                required String entryType,
                required int amountNgwee,
                Value<String> description = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> predictedCategory = const Value.absent(),
                Value<double?> categoryConfidence = const Value.absent(),
                required String finalCategory,
                Value<String?> modelVersion = const Value.absent(),
                Value<double?> anomalyScore = const Value.absent(),
                Value<int> anomalyFlag = const Value.absent(),
                Value<int?> anomalyReviewedAt = const Value.absent(),
                Value<String?> reversesId = const Value.absent(),
                required int occurredAt,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntryCompanion.insert(
                id: id,
                businessId: businessId,
                entryType: entryType,
                amountNgwee: amountNgwee,
                description: description,
                paymentMethod: paymentMethod,
                predictedCategory: predictedCategory,
                categoryConfidence: categoryConfidence,
                finalCategory: finalCategory,
                modelVersion: modelVersion,
                anomalyScore: anomalyScore,
                anomalyFlag: anomalyFlag,
                anomalyReviewedAt: anomalyReviewedAt,
                reversesId: reversesId,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $LedgerEntryReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                businessId = false,
                predictedCategory = false,
                finalCategory = false,
                entryItemRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (entryItemRefs) db.entryItem],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable: $LedgerEntryReferences
                                        ._businessIdTable(db),
                                    referencedColumn: $LedgerEntryReferences
                                        ._businessIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (predictedCategory) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.predictedCategory,
                                    referencedTable: $LedgerEntryReferences
                                        ._predictedCategoryTable(db),
                                    referencedColumn: $LedgerEntryReferences
                                        ._predictedCategoryTable(db)
                                        .code,
                                  )
                                  as T;
                        }
                        if (finalCategory) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.finalCategory,
                                    referencedTable: $LedgerEntryReferences
                                        ._finalCategoryTable(db),
                                    referencedColumn: $LedgerEntryReferences
                                        ._finalCategoryTable(db)
                                        .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (entryItemRefs)
                        await $_getPrefetchedData<
                          LedgerEntryData,
                          LedgerEntry,
                          EntryItemData
                        >(
                          currentTable: table,
                          referencedTable: $LedgerEntryReferences
                              ._entryItemRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $LedgerEntryReferences(
                                db,
                                table,
                                p0,
                              ).entryItemRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $LedgerEntryProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      LedgerEntry,
      LedgerEntryData,
      $LedgerEntryFilterComposer,
      $LedgerEntryOrderingComposer,
      $LedgerEntryAnnotationComposer,
      $LedgerEntryCreateCompanionBuilder,
      $LedgerEntryUpdateCompanionBuilder,
      (LedgerEntryData, $LedgerEntryReferences),
      LedgerEntryData,
      PrefetchHooks Function({
        bool businessId,
        bool predictedCategory,
        bool finalCategory,
        bool entryItemRefs,
      })
    >;
typedef $EntryItemCreateCompanionBuilder =
    EntryItemCompanion Function({
      Value<String?> id,
      required String entryId,
      required String productId,
      required int quantity,
      required int unitPriceNgwee,
      Value<int> rowid,
    });
typedef $EntryItemUpdateCompanionBuilder =
    EntryItemCompanion Function({
      Value<String?> id,
      Value<String> entryId,
      Value<String> productId,
      Value<int> quantity,
      Value<int> unitPriceNgwee,
      Value<int> rowid,
    });

final class $EntryItemReferences
    extends BaseReferences<_$AppDatabase, EntryItem, EntryItemData> {
  $EntryItemReferences(super.$_db, super.$_table, super.$_typedResult);

  static LedgerEntry _entryIdTable(_$AppDatabase db) =>
      db.ledgerEntry.createAlias('entry_item__entry_id__ledger_entry__id');

  $LedgerEntryProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $LedgerEntryTableManager(
      $_db,
      $_db.ledgerEntry,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Product _productIdTable(_$AppDatabase db) =>
      db.product.createAlias('entry_item__product_id__product__id');

  $ProductProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $ProductTableManager(
      $_db,
      $_db.product,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $EntryItemFilterComposer extends Composer<_$AppDatabase, EntryItem> {
  $EntryItemFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceNgwee => $composableBuilder(
    column: $table.unitPriceNgwee,
    builder: (column) => ColumnFilters(column),
  );

  $LedgerEntryFilterComposer get entryId {
    final $LedgerEntryFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.ledgerEntry,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntryFilterComposer(
            $db: $db,
            $table: $db.ledgerEntry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ProductFilterComposer get productId {
    final $ProductFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.product,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductFilterComposer(
            $db: $db,
            $table: $db.product,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntryItemOrderingComposer extends Composer<_$AppDatabase, EntryItem> {
  $EntryItemOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceNgwee => $composableBuilder(
    column: $table.unitPriceNgwee,
    builder: (column) => ColumnOrderings(column),
  );

  $LedgerEntryOrderingComposer get entryId {
    final $LedgerEntryOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.ledgerEntry,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntryOrderingComposer(
            $db: $db,
            $table: $db.ledgerEntry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ProductOrderingComposer get productId {
    final $ProductOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.product,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductOrderingComposer(
            $db: $db,
            $table: $db.product,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntryItemAnnotationComposer extends Composer<_$AppDatabase, EntryItem> {
  $EntryItemAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unitPriceNgwee => $composableBuilder(
    column: $table.unitPriceNgwee,
    builder: (column) => column,
  );

  $LedgerEntryAnnotationComposer get entryId {
    final $LedgerEntryAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.ledgerEntry,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LedgerEntryAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntry,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ProductAnnotationComposer get productId {
    final $ProductAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.product,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductAnnotationComposer(
            $db: $db,
            $table: $db.product,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EntryItemTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          EntryItem,
          EntryItemData,
          $EntryItemFilterComposer,
          $EntryItemOrderingComposer,
          $EntryItemAnnotationComposer,
          $EntryItemCreateCompanionBuilder,
          $EntryItemUpdateCompanionBuilder,
          (EntryItemData, $EntryItemReferences),
          EntryItemData,
          PrefetchHooks Function({bool entryId, bool productId})
        > {
  $EntryItemTableManager(_$AppDatabase db, EntryItem table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EntryItemFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EntryItemOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EntryItemAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> unitPriceNgwee = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryItemCompanion(
                id: id,
                entryId: entryId,
                productId: productId,
                quantity: quantity,
                unitPriceNgwee: unitPriceNgwee,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String entryId,
                required String productId,
                required int quantity,
                required int unitPriceNgwee,
                Value<int> rowid = const Value.absent(),
              }) => EntryItemCompanion.insert(
                id: id,
                entryId: entryId,
                productId: productId,
                quantity: quantity,
                unitPriceNgwee: unitPriceNgwee,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $EntryItemReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false, productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable: $EntryItemReferences
                                    ._entryIdTable(db),
                                referencedColumn: $EntryItemReferences
                                    ._entryIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $EntryItemReferences
                                    ._productIdTable(db),
                                referencedColumn: $EntryItemReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $EntryItemProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      EntryItem,
      EntryItemData,
      $EntryItemFilterComposer,
      $EntryItemOrderingComposer,
      $EntryItemAnnotationComposer,
      $EntryItemCreateCompanionBuilder,
      $EntryItemUpdateCompanionBuilder,
      (EntryItemData, $EntryItemReferences),
      EntryItemData,
      PrefetchHooks Function({bool entryId, bool productId})
    >;
typedef $StockAdjustmentCreateCompanionBuilder =
    StockAdjustmentCompanion Function({
      Value<String?> id,
      required String productId,
      required int quantityDelta,
      required String reason,
      required int createdAt,
      Value<int> rowid,
    });
typedef $StockAdjustmentUpdateCompanionBuilder =
    StockAdjustmentCompanion Function({
      Value<String?> id,
      Value<String> productId,
      Value<int> quantityDelta,
      Value<String> reason,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $StockAdjustmentReferences
    extends
        BaseReferences<_$AppDatabase, StockAdjustment, StockAdjustmentData> {
  $StockAdjustmentReferences(super.$_db, super.$_table, super.$_typedResult);

  static Product _productIdTable(_$AppDatabase db) =>
      db.product.createAlias('stock_adjustment__product_id__product__id');

  $ProductProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $ProductTableManager(
      $_db,
      $_db.product,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $StockAdjustmentFilterComposer
    extends Composer<_$AppDatabase, StockAdjustment> {
  $StockAdjustmentFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $ProductFilterComposer get productId {
    final $ProductFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.product,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductFilterComposer(
            $db: $db,
            $table: $db.product,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StockAdjustmentOrderingComposer
    extends Composer<_$AppDatabase, StockAdjustment> {
  $StockAdjustmentOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ProductOrderingComposer get productId {
    final $ProductOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.product,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductOrderingComposer(
            $db: $db,
            $table: $db.product,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StockAdjustmentAnnotationComposer
    extends Composer<_$AppDatabase, StockAdjustment> {
  $StockAdjustmentAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $ProductAnnotationComposer get productId {
    final $ProductAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.product,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductAnnotationComposer(
            $db: $db,
            $table: $db.product,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StockAdjustmentTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          StockAdjustment,
          StockAdjustmentData,
          $StockAdjustmentFilterComposer,
          $StockAdjustmentOrderingComposer,
          $StockAdjustmentAnnotationComposer,
          $StockAdjustmentCreateCompanionBuilder,
          $StockAdjustmentUpdateCompanionBuilder,
          (StockAdjustmentData, $StockAdjustmentReferences),
          StockAdjustmentData,
          PrefetchHooks Function({bool productId})
        > {
  $StockAdjustmentTableManager(_$AppDatabase db, StockAdjustment table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $StockAdjustmentFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $StockAdjustmentOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $StockAdjustmentAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantityDelta = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockAdjustmentCompanion(
                id: id,
                productId: productId,
                quantityDelta: quantityDelta,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String productId,
                required int quantityDelta,
                required String reason,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StockAdjustmentCompanion.insert(
                id: id,
                productId: productId,
                quantityDelta: quantityDelta,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $StockAdjustmentReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable: $StockAdjustmentReferences
                                    ._productIdTable(db),
                                referencedColumn: $StockAdjustmentReferences
                                    ._productIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $StockAdjustmentProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      StockAdjustment,
      StockAdjustmentData,
      $StockAdjustmentFilterComposer,
      $StockAdjustmentOrderingComposer,
      $StockAdjustmentAnnotationComposer,
      $StockAdjustmentCreateCompanionBuilder,
      $StockAdjustmentUpdateCompanionBuilder,
      (StockAdjustmentData, $StockAdjustmentReferences),
      StockAdjustmentData,
      PrefetchHooks Function({bool productId})
    >;
typedef $SyncRecordCreateCompanionBuilder =
    SyncRecordCompanion Function({
      Value<int> id,
      required String entityTable,
      required String entityId,
      required String operation,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      required int createdAt,
      Value<int?> lastAttemptAt,
      Value<int?> ackedAt,
    });
typedef $SyncRecordUpdateCompanionBuilder =
    SyncRecordCompanion Function({
      Value<int> id,
      Value<String> entityTable,
      Value<String> entityId,
      Value<String> operation,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> createdAt,
      Value<int?> lastAttemptAt,
      Value<int?> ackedAt,
    });

class $SyncRecordFilterComposer extends Composer<_$AppDatabase, SyncRecord> {
  $SyncRecordFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ackedAt => $composableBuilder(
    column: $table.ackedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncRecordOrderingComposer extends Composer<_$AppDatabase, SyncRecord> {
  $SyncRecordOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ackedAt => $composableBuilder(
    column: $table.ackedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncRecordAnnotationComposer
    extends Composer<_$AppDatabase, SyncRecord> {
  $SyncRecordAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ackedAt =>
      $composableBuilder(column: $table.ackedAt, builder: (column) => column);
}

class $SyncRecordTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncRecord,
          SyncRecordData,
          $SyncRecordFilterComposer,
          $SyncRecordOrderingComposer,
          $SyncRecordAnnotationComposer,
          $SyncRecordCreateCompanionBuilder,
          $SyncRecordUpdateCompanionBuilder,
          (
            SyncRecordData,
            BaseReferences<_$AppDatabase, SyncRecord, SyncRecordData>,
          ),
          SyncRecordData,
          PrefetchHooks Function()
        > {
  $SyncRecordTableManager(_$AppDatabase db, SyncRecord table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncRecordFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncRecordOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncRecordAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entityTable = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int?> ackedAt = const Value.absent(),
              }) => SyncRecordCompanion(
                id: id,
                entityTable: entityTable,
                entityId: entityId,
                operation: operation,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                ackedAt: ackedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entityTable,
                required String entityId,
                required String operation,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required int createdAt,
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int?> ackedAt = const Value.absent(),
              }) => SyncRecordCompanion.insert(
                id: id,
                entityTable: entityTable,
                entityId: entityId,
                operation: operation,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                ackedAt: ackedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncRecordProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncRecord,
      SyncRecordData,
      $SyncRecordFilterComposer,
      $SyncRecordOrderingComposer,
      $SyncRecordAnnotationComposer,
      $SyncRecordCreateCompanionBuilder,
      $SyncRecordUpdateCompanionBuilder,
      (
        SyncRecordData,
        BaseReferences<_$AppDatabase, SyncRecord, SyncRecordData>,
      ),
      SyncRecordData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $BusinessTableManager get business =>
      $BusinessTableManager(_db, _db.business);
  $CategoryTableManager get category =>
      $CategoryTableManager(_db, _db.category);
  $ProductTableManager get product => $ProductTableManager(_db, _db.product);
  $LedgerEntryTableManager get ledgerEntry =>
      $LedgerEntryTableManager(_db, _db.ledgerEntry);
  $EntryItemTableManager get entryItem =>
      $EntryItemTableManager(_db, _db.entryItem);
  $StockAdjustmentTableManager get stockAdjustment =>
      $StockAdjustmentTableManager(_db, _db.stockAdjustment);
  $SyncRecordTableManager get syncRecord =>
      $SyncRecordTableManager(_db, _db.syncRecord);
}
