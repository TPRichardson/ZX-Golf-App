// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EventTypeRefsTable extends EventTypeRefs
    with TableInfo<$EventTypeRefsTable, EventTypeRef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventTypeRefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventTypeIdMeta = const VerificationMeta(
    'eventTypeId',
  );
  @override
  late final GeneratedColumn<String> eventTypeId = GeneratedColumn<String>(
    'EventTypeID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'Name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'Description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [eventTypeId, name, description];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'EventTypeRef';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventTypeRef> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('EventTypeID')) {
      context.handle(
        _eventTypeIdMeta,
        eventTypeId.isAcceptableOrUnknown(
          data['EventTypeID']!,
          _eventTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventTypeIdMeta);
    }
    if (data.containsKey('Name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['Name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('Description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['Description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventTypeId};
  @override
  EventTypeRef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventTypeRef(
      eventTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}EventTypeID'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Description'],
      ),
    );
  }

  @override
  $EventTypeRefsTable createAlias(String alias) {
    return $EventTypeRefsTable(attachedDatabase, alias);
  }
}

class EventTypeRef extends DataClass implements Insertable<EventTypeRef> {
  final String eventTypeId;
  final String name;
  final String? description;
  const EventTypeRef({
    required this.eventTypeId,
    required this.name,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['EventTypeID'] = Variable<String>(eventTypeId);
    map['Name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['Description'] = Variable<String>(description);
    }
    return map;
  }

  EventTypeRefsCompanion toCompanion(bool nullToAbsent) {
    return EventTypeRefsCompanion(
      eventTypeId: Value(eventTypeId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory EventTypeRef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventTypeRef(
      eventTypeId: serializer.fromJson<String>(json['eventTypeId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventTypeId': serializer.toJson<String>(eventTypeId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
    };
  }

  EventTypeRef copyWith({
    String? eventTypeId,
    String? name,
    Value<String?> description = const Value.absent(),
  }) => EventTypeRef(
    eventTypeId: eventTypeId ?? this.eventTypeId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
  );
  EventTypeRef copyWithCompanion(EventTypeRefsCompanion data) {
    return EventTypeRef(
      eventTypeId: data.eventTypeId.present
          ? data.eventTypeId.value
          : this.eventTypeId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventTypeRef(')
          ..write('eventTypeId: $eventTypeId, ')
          ..write('name: $name, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventTypeId, name, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventTypeRef &&
          other.eventTypeId == this.eventTypeId &&
          other.name == this.name &&
          other.description == this.description);
}

class EventTypeRefsCompanion extends UpdateCompanion<EventTypeRef> {
  final Value<String> eventTypeId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> rowid;
  const EventTypeRefsCompanion({
    this.eventTypeId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventTypeRefsCompanion.insert({
    required String eventTypeId,
    required String name,
    this.description = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventTypeId = Value(eventTypeId),
       name = Value(name);
  static Insertable<EventTypeRef> custom({
    Expression<String>? eventTypeId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventTypeId != null) 'EventTypeID': eventTypeId,
      if (name != null) 'Name': name,
      if (description != null) 'Description': description,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventTypeRefsCompanion copyWith({
    Value<String>? eventTypeId,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? rowid,
  }) {
    return EventTypeRefsCompanion(
      eventTypeId: eventTypeId ?? this.eventTypeId,
      name: name ?? this.name,
      description: description ?? this.description,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventTypeId.present) {
      map['EventTypeID'] = Variable<String>(eventTypeId.value);
    }
    if (name.present) {
      map['Name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['Description'] = Variable<String>(description.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventTypeRefsCompanion(')
          ..write('eventTypeId: $eventTypeId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetricSchemasTable extends MetricSchemas
    with TableInfo<$MetricSchemasTable, MetricSchema> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricSchemasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _metricSchemaIdMeta = const VerificationMeta(
    'metricSchemaId',
  );
  @override
  late final GeneratedColumn<String> metricSchemaId = GeneratedColumn<String>(
    'MetricSchemaID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'Name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<InputMode, String> inputMode =
      GeneratedColumn<String>(
        'InputMode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<InputMode>($MetricSchemasTable.$converterinputMode);
  static const VerificationMeta _hardMinInputMeta = const VerificationMeta(
    'hardMinInput',
  );
  @override
  late final GeneratedColumn<double> hardMinInput = GeneratedColumn<double>(
    'HardMinInput',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hardMaxInputMeta = const VerificationMeta(
    'hardMaxInput',
  );
  @override
  late final GeneratedColumn<double> hardMaxInput = GeneratedColumn<double>(
    'HardMaxInput',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _validationRulesMeta = const VerificationMeta(
    'validationRules',
  );
  @override
  late final GeneratedColumn<String> validationRules = GeneratedColumn<String>(
    'ValidationRules',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoringAdapterBindingMeta =
      const VerificationMeta('scoringAdapterBinding');
  @override
  late final GeneratedColumn<String> scoringAdapterBinding =
      GeneratedColumn<String>(
        'ScoringAdapterBinding',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    metricSchemaId,
    name,
    inputMode,
    hardMinInput,
    hardMaxInput,
    validationRules,
    scoringAdapterBinding,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MetricSchema';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetricSchema> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('MetricSchemaID')) {
      context.handle(
        _metricSchemaIdMeta,
        metricSchemaId.isAcceptableOrUnknown(
          data['MetricSchemaID']!,
          _metricSchemaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metricSchemaIdMeta);
    }
    if (data.containsKey('Name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['Name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('HardMinInput')) {
      context.handle(
        _hardMinInputMeta,
        hardMinInput.isAcceptableOrUnknown(
          data['HardMinInput']!,
          _hardMinInputMeta,
        ),
      );
    }
    if (data.containsKey('HardMaxInput')) {
      context.handle(
        _hardMaxInputMeta,
        hardMaxInput.isAcceptableOrUnknown(
          data['HardMaxInput']!,
          _hardMaxInputMeta,
        ),
      );
    }
    if (data.containsKey('ValidationRules')) {
      context.handle(
        _validationRulesMeta,
        validationRules.isAcceptableOrUnknown(
          data['ValidationRules']!,
          _validationRulesMeta,
        ),
      );
    }
    if (data.containsKey('ScoringAdapterBinding')) {
      context.handle(
        _scoringAdapterBindingMeta,
        scoringAdapterBinding.isAcceptableOrUnknown(
          data['ScoringAdapterBinding']!,
          _scoringAdapterBindingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoringAdapterBindingMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {metricSchemaId};
  @override
  MetricSchema map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetricSchema(
      metricSchemaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MetricSchemaID'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Name'],
      )!,
      inputMode: $MetricSchemasTable.$converterinputMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}InputMode'],
        )!,
      ),
      hardMinInput: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}HardMinInput'],
      ),
      hardMaxInput: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}HardMaxInput'],
      ),
      validationRules: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ValidationRules'],
      ),
      scoringAdapterBinding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ScoringAdapterBinding'],
      )!,
    );
  }

  @override
  $MetricSchemasTable createAlias(String alias) {
    return $MetricSchemasTable(attachedDatabase, alias);
  }

  static TypeConverter<InputMode, String> $converterinputMode =
      const InputModeConverter();
}

class MetricSchema extends DataClass implements Insertable<MetricSchema> {
  final String metricSchemaId;
  final String name;
  final InputMode inputMode;
  final double? hardMinInput;
  final double? hardMaxInput;
  final String? validationRules;
  final String scoringAdapterBinding;
  const MetricSchema({
    required this.metricSchemaId,
    required this.name,
    required this.inputMode,
    this.hardMinInput,
    this.hardMaxInput,
    this.validationRules,
    required this.scoringAdapterBinding,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['MetricSchemaID'] = Variable<String>(metricSchemaId);
    map['Name'] = Variable<String>(name);
    {
      map['InputMode'] = Variable<String>(
        $MetricSchemasTable.$converterinputMode.toSql(inputMode),
      );
    }
    if (!nullToAbsent || hardMinInput != null) {
      map['HardMinInput'] = Variable<double>(hardMinInput);
    }
    if (!nullToAbsent || hardMaxInput != null) {
      map['HardMaxInput'] = Variable<double>(hardMaxInput);
    }
    if (!nullToAbsent || validationRules != null) {
      map['ValidationRules'] = Variable<String>(validationRules);
    }
    map['ScoringAdapterBinding'] = Variable<String>(scoringAdapterBinding);
    return map;
  }

  MetricSchemasCompanion toCompanion(bool nullToAbsent) {
    return MetricSchemasCompanion(
      metricSchemaId: Value(metricSchemaId),
      name: Value(name),
      inputMode: Value(inputMode),
      hardMinInput: hardMinInput == null && nullToAbsent
          ? const Value.absent()
          : Value(hardMinInput),
      hardMaxInput: hardMaxInput == null && nullToAbsent
          ? const Value.absent()
          : Value(hardMaxInput),
      validationRules: validationRules == null && nullToAbsent
          ? const Value.absent()
          : Value(validationRules),
      scoringAdapterBinding: Value(scoringAdapterBinding),
    );
  }

  factory MetricSchema.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetricSchema(
      metricSchemaId: serializer.fromJson<String>(json['metricSchemaId']),
      name: serializer.fromJson<String>(json['name']),
      inputMode: serializer.fromJson<InputMode>(json['inputMode']),
      hardMinInput: serializer.fromJson<double?>(json['hardMinInput']),
      hardMaxInput: serializer.fromJson<double?>(json['hardMaxInput']),
      validationRules: serializer.fromJson<String?>(json['validationRules']),
      scoringAdapterBinding: serializer.fromJson<String>(
        json['scoringAdapterBinding'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'metricSchemaId': serializer.toJson<String>(metricSchemaId),
      'name': serializer.toJson<String>(name),
      'inputMode': serializer.toJson<InputMode>(inputMode),
      'hardMinInput': serializer.toJson<double?>(hardMinInput),
      'hardMaxInput': serializer.toJson<double?>(hardMaxInput),
      'validationRules': serializer.toJson<String?>(validationRules),
      'scoringAdapterBinding': serializer.toJson<String>(scoringAdapterBinding),
    };
  }

  MetricSchema copyWith({
    String? metricSchemaId,
    String? name,
    InputMode? inputMode,
    Value<double?> hardMinInput = const Value.absent(),
    Value<double?> hardMaxInput = const Value.absent(),
    Value<String?> validationRules = const Value.absent(),
    String? scoringAdapterBinding,
  }) => MetricSchema(
    metricSchemaId: metricSchemaId ?? this.metricSchemaId,
    name: name ?? this.name,
    inputMode: inputMode ?? this.inputMode,
    hardMinInput: hardMinInput.present ? hardMinInput.value : this.hardMinInput,
    hardMaxInput: hardMaxInput.present ? hardMaxInput.value : this.hardMaxInput,
    validationRules: validationRules.present
        ? validationRules.value
        : this.validationRules,
    scoringAdapterBinding: scoringAdapterBinding ?? this.scoringAdapterBinding,
  );
  MetricSchema copyWithCompanion(MetricSchemasCompanion data) {
    return MetricSchema(
      metricSchemaId: data.metricSchemaId.present
          ? data.metricSchemaId.value
          : this.metricSchemaId,
      name: data.name.present ? data.name.value : this.name,
      inputMode: data.inputMode.present ? data.inputMode.value : this.inputMode,
      hardMinInput: data.hardMinInput.present
          ? data.hardMinInput.value
          : this.hardMinInput,
      hardMaxInput: data.hardMaxInput.present
          ? data.hardMaxInput.value
          : this.hardMaxInput,
      validationRules: data.validationRules.present
          ? data.validationRules.value
          : this.validationRules,
      scoringAdapterBinding: data.scoringAdapterBinding.present
          ? data.scoringAdapterBinding.value
          : this.scoringAdapterBinding,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetricSchema(')
          ..write('metricSchemaId: $metricSchemaId, ')
          ..write('name: $name, ')
          ..write('inputMode: $inputMode, ')
          ..write('hardMinInput: $hardMinInput, ')
          ..write('hardMaxInput: $hardMaxInput, ')
          ..write('validationRules: $validationRules, ')
          ..write('scoringAdapterBinding: $scoringAdapterBinding')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    metricSchemaId,
    name,
    inputMode,
    hardMinInput,
    hardMaxInput,
    validationRules,
    scoringAdapterBinding,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricSchema &&
          other.metricSchemaId == this.metricSchemaId &&
          other.name == this.name &&
          other.inputMode == this.inputMode &&
          other.hardMinInput == this.hardMinInput &&
          other.hardMaxInput == this.hardMaxInput &&
          other.validationRules == this.validationRules &&
          other.scoringAdapterBinding == this.scoringAdapterBinding);
}

class MetricSchemasCompanion extends UpdateCompanion<MetricSchema> {
  final Value<String> metricSchemaId;
  final Value<String> name;
  final Value<InputMode> inputMode;
  final Value<double?> hardMinInput;
  final Value<double?> hardMaxInput;
  final Value<String?> validationRules;
  final Value<String> scoringAdapterBinding;
  final Value<int> rowid;
  const MetricSchemasCompanion({
    this.metricSchemaId = const Value.absent(),
    this.name = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.hardMinInput = const Value.absent(),
    this.hardMaxInput = const Value.absent(),
    this.validationRules = const Value.absent(),
    this.scoringAdapterBinding = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetricSchemasCompanion.insert({
    required String metricSchemaId,
    required String name,
    required InputMode inputMode,
    this.hardMinInput = const Value.absent(),
    this.hardMaxInput = const Value.absent(),
    this.validationRules = const Value.absent(),
    required String scoringAdapterBinding,
    this.rowid = const Value.absent(),
  }) : metricSchemaId = Value(metricSchemaId),
       name = Value(name),
       inputMode = Value(inputMode),
       scoringAdapterBinding = Value(scoringAdapterBinding);
  static Insertable<MetricSchema> custom({
    Expression<String>? metricSchemaId,
    Expression<String>? name,
    Expression<String>? inputMode,
    Expression<double>? hardMinInput,
    Expression<double>? hardMaxInput,
    Expression<String>? validationRules,
    Expression<String>? scoringAdapterBinding,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (metricSchemaId != null) 'MetricSchemaID': metricSchemaId,
      if (name != null) 'Name': name,
      if (inputMode != null) 'InputMode': inputMode,
      if (hardMinInput != null) 'HardMinInput': hardMinInput,
      if (hardMaxInput != null) 'HardMaxInput': hardMaxInput,
      if (validationRules != null) 'ValidationRules': validationRules,
      if (scoringAdapterBinding != null)
        'ScoringAdapterBinding': scoringAdapterBinding,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetricSchemasCompanion copyWith({
    Value<String>? metricSchemaId,
    Value<String>? name,
    Value<InputMode>? inputMode,
    Value<double?>? hardMinInput,
    Value<double?>? hardMaxInput,
    Value<String?>? validationRules,
    Value<String>? scoringAdapterBinding,
    Value<int>? rowid,
  }) {
    return MetricSchemasCompanion(
      metricSchemaId: metricSchemaId ?? this.metricSchemaId,
      name: name ?? this.name,
      inputMode: inputMode ?? this.inputMode,
      hardMinInput: hardMinInput ?? this.hardMinInput,
      hardMaxInput: hardMaxInput ?? this.hardMaxInput,
      validationRules: validationRules ?? this.validationRules,
      scoringAdapterBinding:
          scoringAdapterBinding ?? this.scoringAdapterBinding,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (metricSchemaId.present) {
      map['MetricSchemaID'] = Variable<String>(metricSchemaId.value);
    }
    if (name.present) {
      map['Name'] = Variable<String>(name.value);
    }
    if (inputMode.present) {
      map['InputMode'] = Variable<String>(
        $MetricSchemasTable.$converterinputMode.toSql(inputMode.value),
      );
    }
    if (hardMinInput.present) {
      map['HardMinInput'] = Variable<double>(hardMinInput.value);
    }
    if (hardMaxInput.present) {
      map['HardMaxInput'] = Variable<double>(hardMaxInput.value);
    }
    if (validationRules.present) {
      map['ValidationRules'] = Variable<String>(validationRules.value);
    }
    if (scoringAdapterBinding.present) {
      map['ScoringAdapterBinding'] = Variable<String>(
        scoringAdapterBinding.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricSchemasCompanion(')
          ..write('metricSchemaId: $metricSchemaId, ')
          ..write('name: $name, ')
          ..write('inputMode: $inputMode, ')
          ..write('hardMinInput: $hardMinInput, ')
          ..write('hardMaxInput: $hardMaxInput, ')
          ..write('validationRules: $validationRules, ')
          ..write('scoringAdapterBinding: $scoringAdapterBinding, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubskillRefsTable extends SubskillRefs
    with TableInfo<$SubskillRefsTable, SubskillRef> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubskillRefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subskillIdMeta = const VerificationMeta(
    'subskillId',
  );
  @override
  late final GeneratedColumn<String> subskillId = GeneratedColumn<String>(
    'SubskillID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SkillArea, String> skillArea =
      GeneratedColumn<String>(
        'SkillArea',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillArea>($SubskillRefsTable.$converterskillArea);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'Name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allocationMeta = const VerificationMeta(
    'allocation',
  );
  @override
  late final GeneratedColumn<int> allocation = GeneratedColumn<int>(
    'Allocation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowSizeMeta = const VerificationMeta(
    'windowSize',
  );
  @override
  late final GeneratedColumn<int> windowSize = GeneratedColumn<int>(
    'WindowSize',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  @override
  List<GeneratedColumn> get $columns => [
    subskillId,
    skillArea,
    name,
    allocation,
    windowSize,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SubskillRef';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubskillRef> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('SubskillID')) {
      context.handle(
        _subskillIdMeta,
        subskillId.isAcceptableOrUnknown(data['SubskillID']!, _subskillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subskillIdMeta);
    }
    if (data.containsKey('Name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['Name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('Allocation')) {
      context.handle(
        _allocationMeta,
        allocation.isAcceptableOrUnknown(data['Allocation']!, _allocationMeta),
      );
    } else if (isInserting) {
      context.missing(_allocationMeta);
    }
    if (data.containsKey('WindowSize')) {
      context.handle(
        _windowSizeMeta,
        windowSize.isAcceptableOrUnknown(data['WindowSize']!, _windowSizeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subskillId};
  @override
  SubskillRef map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubskillRef(
      subskillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SubskillID'],
      )!,
      skillArea: $SubskillRefsTable.$converterskillArea.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SkillArea'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Name'],
      )!,
      allocation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Allocation'],
      )!,
      windowSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}WindowSize'],
      )!,
    );
  }

  @override
  $SubskillRefsTable createAlias(String alias) {
    return $SubskillRefsTable(attachedDatabase, alias);
  }

  static TypeConverter<SkillArea, String> $converterskillArea =
      const SkillAreaConverter();
}

class SubskillRef extends DataClass implements Insertable<SubskillRef> {
  final String subskillId;
  final SkillArea skillArea;
  final String name;
  final int allocation;
  final int windowSize;
  const SubskillRef({
    required this.subskillId,
    required this.skillArea,
    required this.name,
    required this.allocation,
    required this.windowSize,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['SubskillID'] = Variable<String>(subskillId);
    {
      map['SkillArea'] = Variable<String>(
        $SubskillRefsTable.$converterskillArea.toSql(skillArea),
      );
    }
    map['Name'] = Variable<String>(name);
    map['Allocation'] = Variable<int>(allocation);
    map['WindowSize'] = Variable<int>(windowSize);
    return map;
  }

  SubskillRefsCompanion toCompanion(bool nullToAbsent) {
    return SubskillRefsCompanion(
      subskillId: Value(subskillId),
      skillArea: Value(skillArea),
      name: Value(name),
      allocation: Value(allocation),
      windowSize: Value(windowSize),
    );
  }

  factory SubskillRef.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubskillRef(
      subskillId: serializer.fromJson<String>(json['subskillId']),
      skillArea: serializer.fromJson<SkillArea>(json['skillArea']),
      name: serializer.fromJson<String>(json['name']),
      allocation: serializer.fromJson<int>(json['allocation']),
      windowSize: serializer.fromJson<int>(json['windowSize']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subskillId': serializer.toJson<String>(subskillId),
      'skillArea': serializer.toJson<SkillArea>(skillArea),
      'name': serializer.toJson<String>(name),
      'allocation': serializer.toJson<int>(allocation),
      'windowSize': serializer.toJson<int>(windowSize),
    };
  }

  SubskillRef copyWith({
    String? subskillId,
    SkillArea? skillArea,
    String? name,
    int? allocation,
    int? windowSize,
  }) => SubskillRef(
    subskillId: subskillId ?? this.subskillId,
    skillArea: skillArea ?? this.skillArea,
    name: name ?? this.name,
    allocation: allocation ?? this.allocation,
    windowSize: windowSize ?? this.windowSize,
  );
  SubskillRef copyWithCompanion(SubskillRefsCompanion data) {
    return SubskillRef(
      subskillId: data.subskillId.present
          ? data.subskillId.value
          : this.subskillId,
      skillArea: data.skillArea.present ? data.skillArea.value : this.skillArea,
      name: data.name.present ? data.name.value : this.name,
      allocation: data.allocation.present
          ? data.allocation.value
          : this.allocation,
      windowSize: data.windowSize.present
          ? data.windowSize.value
          : this.windowSize,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubskillRef(')
          ..write('subskillId: $subskillId, ')
          ..write('skillArea: $skillArea, ')
          ..write('name: $name, ')
          ..write('allocation: $allocation, ')
          ..write('windowSize: $windowSize')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(subskillId, skillArea, name, allocation, windowSize);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubskillRef &&
          other.subskillId == this.subskillId &&
          other.skillArea == this.skillArea &&
          other.name == this.name &&
          other.allocation == this.allocation &&
          other.windowSize == this.windowSize);
}

class SubskillRefsCompanion extends UpdateCompanion<SubskillRef> {
  final Value<String> subskillId;
  final Value<SkillArea> skillArea;
  final Value<String> name;
  final Value<int> allocation;
  final Value<int> windowSize;
  final Value<int> rowid;
  const SubskillRefsCompanion({
    this.subskillId = const Value.absent(),
    this.skillArea = const Value.absent(),
    this.name = const Value.absent(),
    this.allocation = const Value.absent(),
    this.windowSize = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubskillRefsCompanion.insert({
    required String subskillId,
    required SkillArea skillArea,
    required String name,
    required int allocation,
    this.windowSize = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : subskillId = Value(subskillId),
       skillArea = Value(skillArea),
       name = Value(name),
       allocation = Value(allocation);
  static Insertable<SubskillRef> custom({
    Expression<String>? subskillId,
    Expression<String>? skillArea,
    Expression<String>? name,
    Expression<int>? allocation,
    Expression<int>? windowSize,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subskillId != null) 'SubskillID': subskillId,
      if (skillArea != null) 'SkillArea': skillArea,
      if (name != null) 'Name': name,
      if (allocation != null) 'Allocation': allocation,
      if (windowSize != null) 'WindowSize': windowSize,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubskillRefsCompanion copyWith({
    Value<String>? subskillId,
    Value<SkillArea>? skillArea,
    Value<String>? name,
    Value<int>? allocation,
    Value<int>? windowSize,
    Value<int>? rowid,
  }) {
    return SubskillRefsCompanion(
      subskillId: subskillId ?? this.subskillId,
      skillArea: skillArea ?? this.skillArea,
      name: name ?? this.name,
      allocation: allocation ?? this.allocation,
      windowSize: windowSize ?? this.windowSize,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subskillId.present) {
      map['SubskillID'] = Variable<String>(subskillId.value);
    }
    if (skillArea.present) {
      map['SkillArea'] = Variable<String>(
        $SubskillRefsTable.$converterskillArea.toSql(skillArea.value),
      );
    }
    if (name.present) {
      map['Name'] = Variable<String>(name.value);
    }
    if (allocation.present) {
      map['Allocation'] = Variable<int>(allocation.value);
    }
    if (windowSize.present) {
      map['WindowSize'] = Variable<int>(windowSize.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubskillRefsCompanion(')
          ..write('subskillId: $subskillId, ')
          ..write('skillArea: $skillArea, ')
          ..write('name: $name, ')
          ..write('allocation: $allocation, ')
          ..write('windowSize: $windowSize, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'DisplayName',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'Email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'Timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UTC'),
  );
  static const VerificationMeta _weekStartDayMeta = const VerificationMeta(
    'weekStartDay',
  );
  @override
  late final GeneratedColumn<int> weekStartDay = GeneratedColumn<int>(
    'WeekStartDay',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitPreferencesMeta = const VerificationMeta(
    'unitPreferences',
  );
  @override
  late final GeneratedColumn<String> unitPreferences = GeneratedColumn<String>(
    'UnitPreferences',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    displayName,
    email,
    timezone,
    weekStartDay,
    unitPreferences,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'User';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('DisplayName')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['DisplayName']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('Email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['Email']!, _emailMeta),
      );
    }
    if (data.containsKey('Timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['Timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('WeekStartDay')) {
      context.handle(
        _weekStartDayMeta,
        weekStartDay.isAcceptableOrUnknown(
          data['WeekStartDay']!,
          _weekStartDayMeta,
        ),
      );
    }
    if (data.containsKey('UnitPreferences')) {
      context.handle(
        _unitPreferencesMeta,
        unitPreferences.isAcceptableOrUnknown(
          data['UnitPreferences']!,
          _unitPreferencesMeta,
        ),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DisplayName'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Email'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Timezone'],
      )!,
      weekStartDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}WeekStartDay'],
      )!,
      unitPreferences: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UnitPreferences'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String userId;
  final String? displayName;
  final String? email;
  final String timezone;
  final int weekStartDay;
  final String unitPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  const User({
    required this.userId,
    this.displayName,
    this.email,
    required this.timezone,
    required this.weekStartDay,
    required this.unitPreferences,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['UserID'] = Variable<String>(userId);
    if (!nullToAbsent || displayName != null) {
      map['DisplayName'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || email != null) {
      map['Email'] = Variable<String>(email);
    }
    map['Timezone'] = Variable<String>(timezone);
    map['WeekStartDay'] = Variable<int>(weekStartDay);
    map['UnitPreferences'] = Variable<String>(unitPreferences);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      userId: Value(userId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      timezone: Value(timezone),
      weekStartDay: Value(weekStartDay),
      unitPreferences: Value(unitPreferences),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      email: serializer.fromJson<String?>(json['email']),
      timezone: serializer.fromJson<String>(json['timezone']),
      weekStartDay: serializer.fromJson<int>(json['weekStartDay']),
      unitPreferences: serializer.fromJson<String>(json['unitPreferences']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String?>(displayName),
      'email': serializer.toJson<String?>(email),
      'timezone': serializer.toJson<String>(timezone),
      'weekStartDay': serializer.toJson<int>(weekStartDay),
      'unitPreferences': serializer.toJson<String>(unitPreferences),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  User copyWith({
    String? userId,
    Value<String?> displayName = const Value.absent(),
    Value<String?> email = const Value.absent(),
    String? timezone,
    int? weekStartDay,
    String? unitPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    userId: userId ?? this.userId,
    displayName: displayName.present ? displayName.value : this.displayName,
    email: email.present ? email.value : this.email,
    timezone: timezone ?? this.timezone,
    weekStartDay: weekStartDay ?? this.weekStartDay,
    unitPreferences: unitPreferences ?? this.unitPreferences,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      email: data.email.present ? data.email.value : this.email,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      weekStartDay: data.weekStartDay.present
          ? data.weekStartDay.value
          : this.weekStartDay,
      unitPreferences: data.unitPreferences.present
          ? data.unitPreferences.value
          : this.unitPreferences,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('timezone: $timezone, ')
          ..write('weekStartDay: $weekStartDay, ')
          ..write('unitPreferences: $unitPreferences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    displayName,
    email,
    timezone,
    weekStartDay,
    unitPreferences,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.email == this.email &&
          other.timezone == this.timezone &&
          other.weekStartDay == this.weekStartDay &&
          other.unitPreferences == this.unitPreferences &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> userId;
  final Value<String?> displayName;
  final Value<String?> email;
  final Value<String> timezone;
  final Value<int> weekStartDay;
  final Value<String> unitPreferences;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.timezone = const Value.absent(),
    this.weekStartDay = const Value.absent(),
    this.unitPreferences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String userId,
    this.displayName = const Value.absent(),
    this.email = const Value.absent(),
    this.timezone = const Value.absent(),
    this.weekStartDay = const Value.absent(),
    this.unitPreferences = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<User> custom({
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<String>? email,
    Expression<String>? timezone,
    Expression<int>? weekStartDay,
    Expression<String>? unitPreferences,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'UserID': userId,
      if (displayName != null) 'DisplayName': displayName,
      if (email != null) 'Email': email,
      if (timezone != null) 'Timezone': timezone,
      if (weekStartDay != null) 'WeekStartDay': weekStartDay,
      if (unitPreferences != null) 'UnitPreferences': unitPreferences,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? userId,
    Value<String?>? displayName,
    Value<String?>? email,
    Value<String>? timezone,
    Value<int>? weekStartDay,
    Value<String>? unitPreferences,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      timezone: timezone ?? this.timezone,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      unitPreferences: unitPreferences ?? this.unitPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['DisplayName'] = Variable<String>(displayName.value);
    }
    if (email.present) {
      map['Email'] = Variable<String>(email.value);
    }
    if (timezone.present) {
      map['Timezone'] = Variable<String>(timezone.value);
    }
    if (weekStartDay.present) {
      map['WeekStartDay'] = Variable<int>(weekStartDay.value);
    }
    if (unitPreferences.present) {
      map['UnitPreferences'] = Variable<String>(unitPreferences.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('email: $email, ')
          ..write('timezone: $timezone, ')
          ..write('weekStartDay: $weekStartDay, ')
          ..write('unitPreferences: $unitPreferences, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DrillsTable extends Drills with TableInfo<$DrillsTable, Drill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _drillIdMeta = const VerificationMeta(
    'drillId',
  );
  @override
  late final GeneratedColumn<String> drillId = GeneratedColumn<String>(
    'DrillID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'Name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SkillArea, String> skillArea =
      GeneratedColumn<String>(
        'SkillArea',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillArea>($DrillsTable.$converterskillArea);
  @override
  late final GeneratedColumnWithTypeConverter<DrillType, String> drillType =
      GeneratedColumn<String>(
        'DrillType',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DrillType>($DrillsTable.$converterdrillType);
  @override
  late final GeneratedColumnWithTypeConverter<ScoringMode?, String>
  scoringMode = GeneratedColumn<String>(
    'ScoringMode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ScoringMode?>($DrillsTable.$converterscoringModen);
  @override
  late final GeneratedColumnWithTypeConverter<InputMode, String> inputMode =
      GeneratedColumn<String>(
        'InputMode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<InputMode>($DrillsTable.$converterinputMode);
  static const VerificationMeta _metricSchemaIdMeta = const VerificationMeta(
    'metricSchemaId',
  );
  @override
  late final GeneratedColumn<String> metricSchemaId = GeneratedColumn<String>(
    'MetricSchemaID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GridType?, String> gridType =
      GeneratedColumn<String>(
        'GridType',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<GridType?>($DrillsTable.$convertergridTypen);
  static const VerificationMeta _subskillMappingMeta = const VerificationMeta(
    'subskillMapping',
  );
  @override
  late final GeneratedColumn<String> subskillMapping = GeneratedColumn<String>(
    'SubskillMapping',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ClubSelectionMode?, String>
  clubSelectionMode =
      GeneratedColumn<String>(
        'ClubSelectionMode',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ClubSelectionMode?>(
        $DrillsTable.$converterclubSelectionModen,
      );
  @override
  late final GeneratedColumnWithTypeConverter<TargetDistanceMode?, String>
  targetDistanceMode =
      GeneratedColumn<String>(
        'TargetDistanceMode',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TargetDistanceMode?>(
        $DrillsTable.$convertertargetDistanceModen,
      );
  static const VerificationMeta _targetDistanceValueMeta =
      const VerificationMeta('targetDistanceValue');
  @override
  late final GeneratedColumn<double> targetDistanceValue =
      GeneratedColumn<double>(
        'TargetDistanceValue',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<TargetSizeMode?, String>
  targetSizeMode = GeneratedColumn<String>(
    'TargetSizeMode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<TargetSizeMode?>($DrillsTable.$convertertargetSizeModen);
  static const VerificationMeta _targetSizeWidthMeta = const VerificationMeta(
    'targetSizeWidth',
  );
  @override
  late final GeneratedColumn<double> targetSizeWidth = GeneratedColumn<double>(
    'TargetSizeWidth',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetSizeDepthMeta = const VerificationMeta(
    'targetSizeDepth',
  );
  @override
  late final GeneratedColumn<double> targetSizeDepth = GeneratedColumn<double>(
    'TargetSizeDepth',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requiredSetCountMeta = const VerificationMeta(
    'requiredSetCount',
  );
  @override
  late final GeneratedColumn<int> requiredSetCount = GeneratedColumn<int>(
    'RequiredSetCount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _requiredAttemptsPerSetMeta =
      const VerificationMeta('requiredAttemptsPerSet');
  @override
  late final GeneratedColumn<int> requiredAttemptsPerSet = GeneratedColumn<int>(
    'RequiredAttemptsPerSet',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anchorsMeta = const VerificationMeta(
    'anchors',
  );
  @override
  late final GeneratedColumn<String> anchors = GeneratedColumn<String>(
    'Anchors',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<double> target = GeneratedColumn<double>(
    'Target',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'Description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DrillLengthUnit?, String>
  targetDistanceUnit = GeneratedColumn<String>(
    'TargetDistanceUnit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DrillLengthUnit?>($DrillsTable.$convertertargetDistanceUnitn);
  @override
  late final GeneratedColumnWithTypeConverter<DrillLengthUnit?, String>
  targetSizeUnit = GeneratedColumn<String>(
    'TargetSizeUnit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<DrillLengthUnit?>($DrillsTable.$convertertargetSizeUnitn);
  @override
  late final GeneratedColumnWithTypeConverter<DrillOrigin, String> origin =
      GeneratedColumn<String>(
        'Origin',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DrillOrigin>($DrillsTable.$converterorigin);
  @override
  late final GeneratedColumnWithTypeConverter<DrillStatus, String> status =
      GeneratedColumn<String>(
        'Status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Active'),
      ).withConverter<DrillStatus>($DrillsTable.$converterstatus);
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    drillId,
    userId,
    name,
    skillArea,
    drillType,
    scoringMode,
    inputMode,
    metricSchemaId,
    gridType,
    subskillMapping,
    clubSelectionMode,
    targetDistanceMode,
    targetDistanceValue,
    targetSizeMode,
    targetSizeWidth,
    targetSizeDepth,
    requiredSetCount,
    requiredAttemptsPerSet,
    anchors,
    target,
    description,
    targetDistanceUnit,
    targetSizeUnit,
    origin,
    status,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Drill';
  @override
  VerificationContext validateIntegrity(
    Insertable<Drill> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('DrillID')) {
      context.handle(
        _drillIdMeta,
        drillId.isAcceptableOrUnknown(data['DrillID']!, _drillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_drillIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    }
    if (data.containsKey('Name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['Name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('MetricSchemaID')) {
      context.handle(
        _metricSchemaIdMeta,
        metricSchemaId.isAcceptableOrUnknown(
          data['MetricSchemaID']!,
          _metricSchemaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metricSchemaIdMeta);
    }
    if (data.containsKey('SubskillMapping')) {
      context.handle(
        _subskillMappingMeta,
        subskillMapping.isAcceptableOrUnknown(
          data['SubskillMapping']!,
          _subskillMappingMeta,
        ),
      );
    }
    if (data.containsKey('TargetDistanceValue')) {
      context.handle(
        _targetDistanceValueMeta,
        targetDistanceValue.isAcceptableOrUnknown(
          data['TargetDistanceValue']!,
          _targetDistanceValueMeta,
        ),
      );
    }
    if (data.containsKey('TargetSizeWidth')) {
      context.handle(
        _targetSizeWidthMeta,
        targetSizeWidth.isAcceptableOrUnknown(
          data['TargetSizeWidth']!,
          _targetSizeWidthMeta,
        ),
      );
    }
    if (data.containsKey('TargetSizeDepth')) {
      context.handle(
        _targetSizeDepthMeta,
        targetSizeDepth.isAcceptableOrUnknown(
          data['TargetSizeDepth']!,
          _targetSizeDepthMeta,
        ),
      );
    }
    if (data.containsKey('RequiredSetCount')) {
      context.handle(
        _requiredSetCountMeta,
        requiredSetCount.isAcceptableOrUnknown(
          data['RequiredSetCount']!,
          _requiredSetCountMeta,
        ),
      );
    }
    if (data.containsKey('RequiredAttemptsPerSet')) {
      context.handle(
        _requiredAttemptsPerSetMeta,
        requiredAttemptsPerSet.isAcceptableOrUnknown(
          data['RequiredAttemptsPerSet']!,
          _requiredAttemptsPerSetMeta,
        ),
      );
    }
    if (data.containsKey('Anchors')) {
      context.handle(
        _anchorsMeta,
        anchors.isAcceptableOrUnknown(data['Anchors']!, _anchorsMeta),
      );
    }
    if (data.containsKey('Target')) {
      context.handle(
        _targetMeta,
        target.isAcceptableOrUnknown(data['Target']!, _targetMeta),
      );
    }
    if (data.containsKey('Description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['Description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {drillId};
  @override
  Drill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Drill(
      drillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DrillID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Name'],
      )!,
      skillArea: $DrillsTable.$converterskillArea.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SkillArea'],
        )!,
      ),
      drillType: $DrillsTable.$converterdrillType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}DrillType'],
        )!,
      ),
      scoringMode: $DrillsTable.$converterscoringModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ScoringMode'],
        ),
      ),
      inputMode: $DrillsTable.$converterinputMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}InputMode'],
        )!,
      ),
      metricSchemaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MetricSchemaID'],
      )!,
      gridType: $DrillsTable.$convertergridTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}GridType'],
        ),
      ),
      subskillMapping: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SubskillMapping'],
      )!,
      clubSelectionMode: $DrillsTable.$converterclubSelectionModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ClubSelectionMode'],
        ),
      ),
      targetDistanceMode: $DrillsTable.$convertertargetDistanceModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}TargetDistanceMode'],
        ),
      ),
      targetDistanceValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}TargetDistanceValue'],
      ),
      targetSizeMode: $DrillsTable.$convertertargetSizeModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}TargetSizeMode'],
        ),
      ),
      targetSizeWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}TargetSizeWidth'],
      ),
      targetSizeDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}TargetSizeDepth'],
      ),
      requiredSetCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}RequiredSetCount'],
      )!,
      requiredAttemptsPerSet: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}RequiredAttemptsPerSet'],
      ),
      anchors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Anchors'],
      )!,
      target: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}Target'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Description'],
      ),
      targetDistanceUnit: $DrillsTable.$convertertargetDistanceUnitn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}TargetDistanceUnit'],
        ),
      ),
      targetSizeUnit: $DrillsTable.$convertertargetSizeUnitn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}TargetSizeUnit'],
        ),
      ),
      origin: $DrillsTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}Origin'],
        )!,
      ),
      status: $DrillsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}Status'],
        )!,
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $DrillsTable createAlias(String alias) {
    return $DrillsTable(attachedDatabase, alias);
  }

  static TypeConverter<SkillArea, String> $converterskillArea =
      const SkillAreaConverter();
  static TypeConverter<DrillType, String> $converterdrillType =
      const DrillTypeConverter();
  static TypeConverter<ScoringMode, String> $converterscoringMode =
      const ScoringModeConverter();
  static TypeConverter<ScoringMode?, String?> $converterscoringModen =
      NullAwareTypeConverter.wrap($converterscoringMode);
  static TypeConverter<InputMode, String> $converterinputMode =
      const InputModeConverter();
  static TypeConverter<GridType, String> $convertergridType =
      const GridTypeConverter();
  static TypeConverter<GridType?, String?> $convertergridTypen =
      NullAwareTypeConverter.wrap($convertergridType);
  static TypeConverter<ClubSelectionMode, String> $converterclubSelectionMode =
      const ClubSelectionModeConverter();
  static TypeConverter<ClubSelectionMode?, String?>
  $converterclubSelectionModen = NullAwareTypeConverter.wrap(
    $converterclubSelectionMode,
  );
  static TypeConverter<TargetDistanceMode, String>
  $convertertargetDistanceMode = const TargetDistanceModeConverter();
  static TypeConverter<TargetDistanceMode?, String?>
  $convertertargetDistanceModen = NullAwareTypeConverter.wrap(
    $convertertargetDistanceMode,
  );
  static TypeConverter<TargetSizeMode, String> $convertertargetSizeMode =
      const TargetSizeModeConverter();
  static TypeConverter<TargetSizeMode?, String?> $convertertargetSizeModen =
      NullAwareTypeConverter.wrap($convertertargetSizeMode);
  static TypeConverter<DrillLengthUnit, String> $convertertargetDistanceUnit =
      const DrillLengthUnitConverter();
  static TypeConverter<DrillLengthUnit?, String?>
  $convertertargetDistanceUnitn = NullAwareTypeConverter.wrap(
    $convertertargetDistanceUnit,
  );
  static TypeConverter<DrillLengthUnit, String> $convertertargetSizeUnit =
      const DrillLengthUnitConverter();
  static TypeConverter<DrillLengthUnit?, String?> $convertertargetSizeUnitn =
      NullAwareTypeConverter.wrap($convertertargetSizeUnit);
  static TypeConverter<DrillOrigin, String> $converterorigin =
      const DrillOriginConverter();
  static TypeConverter<DrillStatus, String> $converterstatus =
      const DrillStatusConverter();
}

class Drill extends DataClass implements Insertable<Drill> {
  final String drillId;
  final String? userId;
  final String name;
  final SkillArea skillArea;
  final DrillType drillType;
  final ScoringMode? scoringMode;
  final InputMode inputMode;
  final String metricSchemaId;
  final GridType? gridType;
  final String subskillMapping;
  final ClubSelectionMode? clubSelectionMode;
  final TargetDistanceMode? targetDistanceMode;
  final double? targetDistanceValue;
  final TargetSizeMode? targetSizeMode;
  final double? targetSizeWidth;
  final double? targetSizeDepth;
  final int requiredSetCount;
  final int? requiredAttemptsPerSet;
  final String anchors;
  final double? target;
  final String? description;
  final DrillLengthUnit? targetDistanceUnit;
  final DrillLengthUnit? targetSizeUnit;
  final DrillOrigin origin;
  final DrillStatus status;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Drill({
    required this.drillId,
    this.userId,
    required this.name,
    required this.skillArea,
    required this.drillType,
    this.scoringMode,
    required this.inputMode,
    required this.metricSchemaId,
    this.gridType,
    required this.subskillMapping,
    this.clubSelectionMode,
    this.targetDistanceMode,
    this.targetDistanceValue,
    this.targetSizeMode,
    this.targetSizeWidth,
    this.targetSizeDepth,
    required this.requiredSetCount,
    this.requiredAttemptsPerSet,
    required this.anchors,
    this.target,
    this.description,
    this.targetDistanceUnit,
    this.targetSizeUnit,
    required this.origin,
    required this.status,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['DrillID'] = Variable<String>(drillId);
    if (!nullToAbsent || userId != null) {
      map['UserID'] = Variable<String>(userId);
    }
    map['Name'] = Variable<String>(name);
    {
      map['SkillArea'] = Variable<String>(
        $DrillsTable.$converterskillArea.toSql(skillArea),
      );
    }
    {
      map['DrillType'] = Variable<String>(
        $DrillsTable.$converterdrillType.toSql(drillType),
      );
    }
    if (!nullToAbsent || scoringMode != null) {
      map['ScoringMode'] = Variable<String>(
        $DrillsTable.$converterscoringModen.toSql(scoringMode),
      );
    }
    {
      map['InputMode'] = Variable<String>(
        $DrillsTable.$converterinputMode.toSql(inputMode),
      );
    }
    map['MetricSchemaID'] = Variable<String>(metricSchemaId);
    if (!nullToAbsent || gridType != null) {
      map['GridType'] = Variable<String>(
        $DrillsTable.$convertergridTypen.toSql(gridType),
      );
    }
    map['SubskillMapping'] = Variable<String>(subskillMapping);
    if (!nullToAbsent || clubSelectionMode != null) {
      map['ClubSelectionMode'] = Variable<String>(
        $DrillsTable.$converterclubSelectionModen.toSql(clubSelectionMode),
      );
    }
    if (!nullToAbsent || targetDistanceMode != null) {
      map['TargetDistanceMode'] = Variable<String>(
        $DrillsTable.$convertertargetDistanceModen.toSql(targetDistanceMode),
      );
    }
    if (!nullToAbsent || targetDistanceValue != null) {
      map['TargetDistanceValue'] = Variable<double>(targetDistanceValue);
    }
    if (!nullToAbsent || targetSizeMode != null) {
      map['TargetSizeMode'] = Variable<String>(
        $DrillsTable.$convertertargetSizeModen.toSql(targetSizeMode),
      );
    }
    if (!nullToAbsent || targetSizeWidth != null) {
      map['TargetSizeWidth'] = Variable<double>(targetSizeWidth);
    }
    if (!nullToAbsent || targetSizeDepth != null) {
      map['TargetSizeDepth'] = Variable<double>(targetSizeDepth);
    }
    map['RequiredSetCount'] = Variable<int>(requiredSetCount);
    if (!nullToAbsent || requiredAttemptsPerSet != null) {
      map['RequiredAttemptsPerSet'] = Variable<int>(requiredAttemptsPerSet);
    }
    map['Anchors'] = Variable<String>(anchors);
    if (!nullToAbsent || target != null) {
      map['Target'] = Variable<double>(target);
    }
    if (!nullToAbsent || description != null) {
      map['Description'] = Variable<String>(description);
    }
    if (!nullToAbsent || targetDistanceUnit != null) {
      map['TargetDistanceUnit'] = Variable<String>(
        $DrillsTable.$convertertargetDistanceUnitn.toSql(targetDistanceUnit),
      );
    }
    if (!nullToAbsent || targetSizeUnit != null) {
      map['TargetSizeUnit'] = Variable<String>(
        $DrillsTable.$convertertargetSizeUnitn.toSql(targetSizeUnit),
      );
    }
    {
      map['Origin'] = Variable<String>(
        $DrillsTable.$converterorigin.toSql(origin),
      );
    }
    {
      map['Status'] = Variable<String>(
        $DrillsTable.$converterstatus.toSql(status),
      );
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DrillsCompanion toCompanion(bool nullToAbsent) {
    return DrillsCompanion(
      drillId: Value(drillId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      name: Value(name),
      skillArea: Value(skillArea),
      drillType: Value(drillType),
      scoringMode: scoringMode == null && nullToAbsent
          ? const Value.absent()
          : Value(scoringMode),
      inputMode: Value(inputMode),
      metricSchemaId: Value(metricSchemaId),
      gridType: gridType == null && nullToAbsent
          ? const Value.absent()
          : Value(gridType),
      subskillMapping: Value(subskillMapping),
      clubSelectionMode: clubSelectionMode == null && nullToAbsent
          ? const Value.absent()
          : Value(clubSelectionMode),
      targetDistanceMode: targetDistanceMode == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDistanceMode),
      targetDistanceValue: targetDistanceValue == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDistanceValue),
      targetSizeMode: targetSizeMode == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSizeMode),
      targetSizeWidth: targetSizeWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSizeWidth),
      targetSizeDepth: targetSizeDepth == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSizeDepth),
      requiredSetCount: Value(requiredSetCount),
      requiredAttemptsPerSet: requiredAttemptsPerSet == null && nullToAbsent
          ? const Value.absent()
          : Value(requiredAttemptsPerSet),
      anchors: Value(anchors),
      target: target == null && nullToAbsent
          ? const Value.absent()
          : Value(target),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      targetDistanceUnit: targetDistanceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDistanceUnit),
      targetSizeUnit: targetSizeUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSizeUnit),
      origin: Value(origin),
      status: Value(status),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Drill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Drill(
      drillId: serializer.fromJson<String>(json['drillId']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      skillArea: serializer.fromJson<SkillArea>(json['skillArea']),
      drillType: serializer.fromJson<DrillType>(json['drillType']),
      scoringMode: serializer.fromJson<ScoringMode?>(json['scoringMode']),
      inputMode: serializer.fromJson<InputMode>(json['inputMode']),
      metricSchemaId: serializer.fromJson<String>(json['metricSchemaId']),
      gridType: serializer.fromJson<GridType?>(json['gridType']),
      subskillMapping: serializer.fromJson<String>(json['subskillMapping']),
      clubSelectionMode: serializer.fromJson<ClubSelectionMode?>(
        json['clubSelectionMode'],
      ),
      targetDistanceMode: serializer.fromJson<TargetDistanceMode?>(
        json['targetDistanceMode'],
      ),
      targetDistanceValue: serializer.fromJson<double?>(
        json['targetDistanceValue'],
      ),
      targetSizeMode: serializer.fromJson<TargetSizeMode?>(
        json['targetSizeMode'],
      ),
      targetSizeWidth: serializer.fromJson<double?>(json['targetSizeWidth']),
      targetSizeDepth: serializer.fromJson<double?>(json['targetSizeDepth']),
      requiredSetCount: serializer.fromJson<int>(json['requiredSetCount']),
      requiredAttemptsPerSet: serializer.fromJson<int?>(
        json['requiredAttemptsPerSet'],
      ),
      anchors: serializer.fromJson<String>(json['anchors']),
      target: serializer.fromJson<double?>(json['target']),
      description: serializer.fromJson<String?>(json['description']),
      targetDistanceUnit: serializer.fromJson<DrillLengthUnit?>(
        json['targetDistanceUnit'],
      ),
      targetSizeUnit: serializer.fromJson<DrillLengthUnit?>(
        json['targetSizeUnit'],
      ),
      origin: serializer.fromJson<DrillOrigin>(json['origin']),
      status: serializer.fromJson<DrillStatus>(json['status']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'drillId': serializer.toJson<String>(drillId),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'skillArea': serializer.toJson<SkillArea>(skillArea),
      'drillType': serializer.toJson<DrillType>(drillType),
      'scoringMode': serializer.toJson<ScoringMode?>(scoringMode),
      'inputMode': serializer.toJson<InputMode>(inputMode),
      'metricSchemaId': serializer.toJson<String>(metricSchemaId),
      'gridType': serializer.toJson<GridType?>(gridType),
      'subskillMapping': serializer.toJson<String>(subskillMapping),
      'clubSelectionMode': serializer.toJson<ClubSelectionMode?>(
        clubSelectionMode,
      ),
      'targetDistanceMode': serializer.toJson<TargetDistanceMode?>(
        targetDistanceMode,
      ),
      'targetDistanceValue': serializer.toJson<double?>(targetDistanceValue),
      'targetSizeMode': serializer.toJson<TargetSizeMode?>(targetSizeMode),
      'targetSizeWidth': serializer.toJson<double?>(targetSizeWidth),
      'targetSizeDepth': serializer.toJson<double?>(targetSizeDepth),
      'requiredSetCount': serializer.toJson<int>(requiredSetCount),
      'requiredAttemptsPerSet': serializer.toJson<int?>(requiredAttemptsPerSet),
      'anchors': serializer.toJson<String>(anchors),
      'target': serializer.toJson<double?>(target),
      'description': serializer.toJson<String?>(description),
      'targetDistanceUnit': serializer.toJson<DrillLengthUnit?>(
        targetDistanceUnit,
      ),
      'targetSizeUnit': serializer.toJson<DrillLengthUnit?>(targetSizeUnit),
      'origin': serializer.toJson<DrillOrigin>(origin),
      'status': serializer.toJson<DrillStatus>(status),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Drill copyWith({
    String? drillId,
    Value<String?> userId = const Value.absent(),
    String? name,
    SkillArea? skillArea,
    DrillType? drillType,
    Value<ScoringMode?> scoringMode = const Value.absent(),
    InputMode? inputMode,
    String? metricSchemaId,
    Value<GridType?> gridType = const Value.absent(),
    String? subskillMapping,
    Value<ClubSelectionMode?> clubSelectionMode = const Value.absent(),
    Value<TargetDistanceMode?> targetDistanceMode = const Value.absent(),
    Value<double?> targetDistanceValue = const Value.absent(),
    Value<TargetSizeMode?> targetSizeMode = const Value.absent(),
    Value<double?> targetSizeWidth = const Value.absent(),
    Value<double?> targetSizeDepth = const Value.absent(),
    int? requiredSetCount,
    Value<int?> requiredAttemptsPerSet = const Value.absent(),
    String? anchors,
    Value<double?> target = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<DrillLengthUnit?> targetDistanceUnit = const Value.absent(),
    Value<DrillLengthUnit?> targetSizeUnit = const Value.absent(),
    DrillOrigin? origin,
    DrillStatus? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Drill(
    drillId: drillId ?? this.drillId,
    userId: userId.present ? userId.value : this.userId,
    name: name ?? this.name,
    skillArea: skillArea ?? this.skillArea,
    drillType: drillType ?? this.drillType,
    scoringMode: scoringMode.present ? scoringMode.value : this.scoringMode,
    inputMode: inputMode ?? this.inputMode,
    metricSchemaId: metricSchemaId ?? this.metricSchemaId,
    gridType: gridType.present ? gridType.value : this.gridType,
    subskillMapping: subskillMapping ?? this.subskillMapping,
    clubSelectionMode: clubSelectionMode.present
        ? clubSelectionMode.value
        : this.clubSelectionMode,
    targetDistanceMode: targetDistanceMode.present
        ? targetDistanceMode.value
        : this.targetDistanceMode,
    targetDistanceValue: targetDistanceValue.present
        ? targetDistanceValue.value
        : this.targetDistanceValue,
    targetSizeMode: targetSizeMode.present
        ? targetSizeMode.value
        : this.targetSizeMode,
    targetSizeWidth: targetSizeWidth.present
        ? targetSizeWidth.value
        : this.targetSizeWidth,
    targetSizeDepth: targetSizeDepth.present
        ? targetSizeDepth.value
        : this.targetSizeDepth,
    requiredSetCount: requiredSetCount ?? this.requiredSetCount,
    requiredAttemptsPerSet: requiredAttemptsPerSet.present
        ? requiredAttemptsPerSet.value
        : this.requiredAttemptsPerSet,
    anchors: anchors ?? this.anchors,
    target: target.present ? target.value : this.target,
    description: description.present ? description.value : this.description,
    targetDistanceUnit: targetDistanceUnit.present
        ? targetDistanceUnit.value
        : this.targetDistanceUnit,
    targetSizeUnit: targetSizeUnit.present
        ? targetSizeUnit.value
        : this.targetSizeUnit,
    origin: origin ?? this.origin,
    status: status ?? this.status,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Drill copyWithCompanion(DrillsCompanion data) {
    return Drill(
      drillId: data.drillId.present ? data.drillId.value : this.drillId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      skillArea: data.skillArea.present ? data.skillArea.value : this.skillArea,
      drillType: data.drillType.present ? data.drillType.value : this.drillType,
      scoringMode: data.scoringMode.present
          ? data.scoringMode.value
          : this.scoringMode,
      inputMode: data.inputMode.present ? data.inputMode.value : this.inputMode,
      metricSchemaId: data.metricSchemaId.present
          ? data.metricSchemaId.value
          : this.metricSchemaId,
      gridType: data.gridType.present ? data.gridType.value : this.gridType,
      subskillMapping: data.subskillMapping.present
          ? data.subskillMapping.value
          : this.subskillMapping,
      clubSelectionMode: data.clubSelectionMode.present
          ? data.clubSelectionMode.value
          : this.clubSelectionMode,
      targetDistanceMode: data.targetDistanceMode.present
          ? data.targetDistanceMode.value
          : this.targetDistanceMode,
      targetDistanceValue: data.targetDistanceValue.present
          ? data.targetDistanceValue.value
          : this.targetDistanceValue,
      targetSizeMode: data.targetSizeMode.present
          ? data.targetSizeMode.value
          : this.targetSizeMode,
      targetSizeWidth: data.targetSizeWidth.present
          ? data.targetSizeWidth.value
          : this.targetSizeWidth,
      targetSizeDepth: data.targetSizeDepth.present
          ? data.targetSizeDepth.value
          : this.targetSizeDepth,
      requiredSetCount: data.requiredSetCount.present
          ? data.requiredSetCount.value
          : this.requiredSetCount,
      requiredAttemptsPerSet: data.requiredAttemptsPerSet.present
          ? data.requiredAttemptsPerSet.value
          : this.requiredAttemptsPerSet,
      anchors: data.anchors.present ? data.anchors.value : this.anchors,
      target: data.target.present ? data.target.value : this.target,
      description: data.description.present
          ? data.description.value
          : this.description,
      targetDistanceUnit: data.targetDistanceUnit.present
          ? data.targetDistanceUnit.value
          : this.targetDistanceUnit,
      targetSizeUnit: data.targetSizeUnit.present
          ? data.targetSizeUnit.value
          : this.targetSizeUnit,
      origin: data.origin.present ? data.origin.value : this.origin,
      status: data.status.present ? data.status.value : this.status,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Drill(')
          ..write('drillId: $drillId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('skillArea: $skillArea, ')
          ..write('drillType: $drillType, ')
          ..write('scoringMode: $scoringMode, ')
          ..write('inputMode: $inputMode, ')
          ..write('metricSchemaId: $metricSchemaId, ')
          ..write('gridType: $gridType, ')
          ..write('subskillMapping: $subskillMapping, ')
          ..write('clubSelectionMode: $clubSelectionMode, ')
          ..write('targetDistanceMode: $targetDistanceMode, ')
          ..write('targetDistanceValue: $targetDistanceValue, ')
          ..write('targetSizeMode: $targetSizeMode, ')
          ..write('targetSizeWidth: $targetSizeWidth, ')
          ..write('targetSizeDepth: $targetSizeDepth, ')
          ..write('requiredSetCount: $requiredSetCount, ')
          ..write('requiredAttemptsPerSet: $requiredAttemptsPerSet, ')
          ..write('anchors: $anchors, ')
          ..write('target: $target, ')
          ..write('description: $description, ')
          ..write('targetDistanceUnit: $targetDistanceUnit, ')
          ..write('targetSizeUnit: $targetSizeUnit, ')
          ..write('origin: $origin, ')
          ..write('status: $status, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    drillId,
    userId,
    name,
    skillArea,
    drillType,
    scoringMode,
    inputMode,
    metricSchemaId,
    gridType,
    subskillMapping,
    clubSelectionMode,
    targetDistanceMode,
    targetDistanceValue,
    targetSizeMode,
    targetSizeWidth,
    targetSizeDepth,
    requiredSetCount,
    requiredAttemptsPerSet,
    anchors,
    target,
    description,
    targetDistanceUnit,
    targetSizeUnit,
    origin,
    status,
    isDeleted,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Drill &&
          other.drillId == this.drillId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.skillArea == this.skillArea &&
          other.drillType == this.drillType &&
          other.scoringMode == this.scoringMode &&
          other.inputMode == this.inputMode &&
          other.metricSchemaId == this.metricSchemaId &&
          other.gridType == this.gridType &&
          other.subskillMapping == this.subskillMapping &&
          other.clubSelectionMode == this.clubSelectionMode &&
          other.targetDistanceMode == this.targetDistanceMode &&
          other.targetDistanceValue == this.targetDistanceValue &&
          other.targetSizeMode == this.targetSizeMode &&
          other.targetSizeWidth == this.targetSizeWidth &&
          other.targetSizeDepth == this.targetSizeDepth &&
          other.requiredSetCount == this.requiredSetCount &&
          other.requiredAttemptsPerSet == this.requiredAttemptsPerSet &&
          other.anchors == this.anchors &&
          other.target == this.target &&
          other.description == this.description &&
          other.targetDistanceUnit == this.targetDistanceUnit &&
          other.targetSizeUnit == this.targetSizeUnit &&
          other.origin == this.origin &&
          other.status == this.status &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DrillsCompanion extends UpdateCompanion<Drill> {
  final Value<String> drillId;
  final Value<String?> userId;
  final Value<String> name;
  final Value<SkillArea> skillArea;
  final Value<DrillType> drillType;
  final Value<ScoringMode?> scoringMode;
  final Value<InputMode> inputMode;
  final Value<String> metricSchemaId;
  final Value<GridType?> gridType;
  final Value<String> subskillMapping;
  final Value<ClubSelectionMode?> clubSelectionMode;
  final Value<TargetDistanceMode?> targetDistanceMode;
  final Value<double?> targetDistanceValue;
  final Value<TargetSizeMode?> targetSizeMode;
  final Value<double?> targetSizeWidth;
  final Value<double?> targetSizeDepth;
  final Value<int> requiredSetCount;
  final Value<int?> requiredAttemptsPerSet;
  final Value<String> anchors;
  final Value<double?> target;
  final Value<String?> description;
  final Value<DrillLengthUnit?> targetDistanceUnit;
  final Value<DrillLengthUnit?> targetSizeUnit;
  final Value<DrillOrigin> origin;
  final Value<DrillStatus> status;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DrillsCompanion({
    this.drillId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.skillArea = const Value.absent(),
    this.drillType = const Value.absent(),
    this.scoringMode = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.metricSchemaId = const Value.absent(),
    this.gridType = const Value.absent(),
    this.subskillMapping = const Value.absent(),
    this.clubSelectionMode = const Value.absent(),
    this.targetDistanceMode = const Value.absent(),
    this.targetDistanceValue = const Value.absent(),
    this.targetSizeMode = const Value.absent(),
    this.targetSizeWidth = const Value.absent(),
    this.targetSizeDepth = const Value.absent(),
    this.requiredSetCount = const Value.absent(),
    this.requiredAttemptsPerSet = const Value.absent(),
    this.anchors = const Value.absent(),
    this.target = const Value.absent(),
    this.description = const Value.absent(),
    this.targetDistanceUnit = const Value.absent(),
    this.targetSizeUnit = const Value.absent(),
    this.origin = const Value.absent(),
    this.status = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DrillsCompanion.insert({
    required String drillId,
    this.userId = const Value.absent(),
    required String name,
    required SkillArea skillArea,
    required DrillType drillType,
    this.scoringMode = const Value.absent(),
    required InputMode inputMode,
    required String metricSchemaId,
    this.gridType = const Value.absent(),
    this.subskillMapping = const Value.absent(),
    this.clubSelectionMode = const Value.absent(),
    this.targetDistanceMode = const Value.absent(),
    this.targetDistanceValue = const Value.absent(),
    this.targetSizeMode = const Value.absent(),
    this.targetSizeWidth = const Value.absent(),
    this.targetSizeDepth = const Value.absent(),
    this.requiredSetCount = const Value.absent(),
    this.requiredAttemptsPerSet = const Value.absent(),
    this.anchors = const Value.absent(),
    this.target = const Value.absent(),
    this.description = const Value.absent(),
    this.targetDistanceUnit = const Value.absent(),
    this.targetSizeUnit = const Value.absent(),
    required DrillOrigin origin,
    this.status = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : drillId = Value(drillId),
       name = Value(name),
       skillArea = Value(skillArea),
       drillType = Value(drillType),
       inputMode = Value(inputMode),
       metricSchemaId = Value(metricSchemaId),
       origin = Value(origin);
  static Insertable<Drill> custom({
    Expression<String>? drillId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? skillArea,
    Expression<String>? drillType,
    Expression<String>? scoringMode,
    Expression<String>? inputMode,
    Expression<String>? metricSchemaId,
    Expression<String>? gridType,
    Expression<String>? subskillMapping,
    Expression<String>? clubSelectionMode,
    Expression<String>? targetDistanceMode,
    Expression<double>? targetDistanceValue,
    Expression<String>? targetSizeMode,
    Expression<double>? targetSizeWidth,
    Expression<double>? targetSizeDepth,
    Expression<int>? requiredSetCount,
    Expression<int>? requiredAttemptsPerSet,
    Expression<String>? anchors,
    Expression<double>? target,
    Expression<String>? description,
    Expression<String>? targetDistanceUnit,
    Expression<String>? targetSizeUnit,
    Expression<String>? origin,
    Expression<String>? status,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (drillId != null) 'DrillID': drillId,
      if (userId != null) 'UserID': userId,
      if (name != null) 'Name': name,
      if (skillArea != null) 'SkillArea': skillArea,
      if (drillType != null) 'DrillType': drillType,
      if (scoringMode != null) 'ScoringMode': scoringMode,
      if (inputMode != null) 'InputMode': inputMode,
      if (metricSchemaId != null) 'MetricSchemaID': metricSchemaId,
      if (gridType != null) 'GridType': gridType,
      if (subskillMapping != null) 'SubskillMapping': subskillMapping,
      if (clubSelectionMode != null) 'ClubSelectionMode': clubSelectionMode,
      if (targetDistanceMode != null) 'TargetDistanceMode': targetDistanceMode,
      if (targetDistanceValue != null)
        'TargetDistanceValue': targetDistanceValue,
      if (targetSizeMode != null) 'TargetSizeMode': targetSizeMode,
      if (targetSizeWidth != null) 'TargetSizeWidth': targetSizeWidth,
      if (targetSizeDepth != null) 'TargetSizeDepth': targetSizeDepth,
      if (requiredSetCount != null) 'RequiredSetCount': requiredSetCount,
      if (requiredAttemptsPerSet != null)
        'RequiredAttemptsPerSet': requiredAttemptsPerSet,
      if (anchors != null) 'Anchors': anchors,
      if (target != null) 'Target': target,
      if (description != null) 'Description': description,
      if (targetDistanceUnit != null) 'TargetDistanceUnit': targetDistanceUnit,
      if (targetSizeUnit != null) 'TargetSizeUnit': targetSizeUnit,
      if (origin != null) 'Origin': origin,
      if (status != null) 'Status': status,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DrillsCompanion copyWith({
    Value<String>? drillId,
    Value<String?>? userId,
    Value<String>? name,
    Value<SkillArea>? skillArea,
    Value<DrillType>? drillType,
    Value<ScoringMode?>? scoringMode,
    Value<InputMode>? inputMode,
    Value<String>? metricSchemaId,
    Value<GridType?>? gridType,
    Value<String>? subskillMapping,
    Value<ClubSelectionMode?>? clubSelectionMode,
    Value<TargetDistanceMode?>? targetDistanceMode,
    Value<double?>? targetDistanceValue,
    Value<TargetSizeMode?>? targetSizeMode,
    Value<double?>? targetSizeWidth,
    Value<double?>? targetSizeDepth,
    Value<int>? requiredSetCount,
    Value<int?>? requiredAttemptsPerSet,
    Value<String>? anchors,
    Value<double?>? target,
    Value<String?>? description,
    Value<DrillLengthUnit?>? targetDistanceUnit,
    Value<DrillLengthUnit?>? targetSizeUnit,
    Value<DrillOrigin>? origin,
    Value<DrillStatus>? status,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DrillsCompanion(
      drillId: drillId ?? this.drillId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      skillArea: skillArea ?? this.skillArea,
      drillType: drillType ?? this.drillType,
      scoringMode: scoringMode ?? this.scoringMode,
      inputMode: inputMode ?? this.inputMode,
      metricSchemaId: metricSchemaId ?? this.metricSchemaId,
      gridType: gridType ?? this.gridType,
      subskillMapping: subskillMapping ?? this.subskillMapping,
      clubSelectionMode: clubSelectionMode ?? this.clubSelectionMode,
      targetDistanceMode: targetDistanceMode ?? this.targetDistanceMode,
      targetDistanceValue: targetDistanceValue ?? this.targetDistanceValue,
      targetSizeMode: targetSizeMode ?? this.targetSizeMode,
      targetSizeWidth: targetSizeWidth ?? this.targetSizeWidth,
      targetSizeDepth: targetSizeDepth ?? this.targetSizeDepth,
      requiredSetCount: requiredSetCount ?? this.requiredSetCount,
      requiredAttemptsPerSet:
          requiredAttemptsPerSet ?? this.requiredAttemptsPerSet,
      anchors: anchors ?? this.anchors,
      target: target ?? this.target,
      description: description ?? this.description,
      targetDistanceUnit: targetDistanceUnit ?? this.targetDistanceUnit,
      targetSizeUnit: targetSizeUnit ?? this.targetSizeUnit,
      origin: origin ?? this.origin,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (drillId.present) {
      map['DrillID'] = Variable<String>(drillId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['Name'] = Variable<String>(name.value);
    }
    if (skillArea.present) {
      map['SkillArea'] = Variable<String>(
        $DrillsTable.$converterskillArea.toSql(skillArea.value),
      );
    }
    if (drillType.present) {
      map['DrillType'] = Variable<String>(
        $DrillsTable.$converterdrillType.toSql(drillType.value),
      );
    }
    if (scoringMode.present) {
      map['ScoringMode'] = Variable<String>(
        $DrillsTable.$converterscoringModen.toSql(scoringMode.value),
      );
    }
    if (inputMode.present) {
      map['InputMode'] = Variable<String>(
        $DrillsTable.$converterinputMode.toSql(inputMode.value),
      );
    }
    if (metricSchemaId.present) {
      map['MetricSchemaID'] = Variable<String>(metricSchemaId.value);
    }
    if (gridType.present) {
      map['GridType'] = Variable<String>(
        $DrillsTable.$convertergridTypen.toSql(gridType.value),
      );
    }
    if (subskillMapping.present) {
      map['SubskillMapping'] = Variable<String>(subskillMapping.value);
    }
    if (clubSelectionMode.present) {
      map['ClubSelectionMode'] = Variable<String>(
        $DrillsTable.$converterclubSelectionModen.toSql(
          clubSelectionMode.value,
        ),
      );
    }
    if (targetDistanceMode.present) {
      map['TargetDistanceMode'] = Variable<String>(
        $DrillsTable.$convertertargetDistanceModen.toSql(
          targetDistanceMode.value,
        ),
      );
    }
    if (targetDistanceValue.present) {
      map['TargetDistanceValue'] = Variable<double>(targetDistanceValue.value);
    }
    if (targetSizeMode.present) {
      map['TargetSizeMode'] = Variable<String>(
        $DrillsTable.$convertertargetSizeModen.toSql(targetSizeMode.value),
      );
    }
    if (targetSizeWidth.present) {
      map['TargetSizeWidth'] = Variable<double>(targetSizeWidth.value);
    }
    if (targetSizeDepth.present) {
      map['TargetSizeDepth'] = Variable<double>(targetSizeDepth.value);
    }
    if (requiredSetCount.present) {
      map['RequiredSetCount'] = Variable<int>(requiredSetCount.value);
    }
    if (requiredAttemptsPerSet.present) {
      map['RequiredAttemptsPerSet'] = Variable<int>(
        requiredAttemptsPerSet.value,
      );
    }
    if (anchors.present) {
      map['Anchors'] = Variable<String>(anchors.value);
    }
    if (target.present) {
      map['Target'] = Variable<double>(target.value);
    }
    if (description.present) {
      map['Description'] = Variable<String>(description.value);
    }
    if (targetDistanceUnit.present) {
      map['TargetDistanceUnit'] = Variable<String>(
        $DrillsTable.$convertertargetDistanceUnitn.toSql(
          targetDistanceUnit.value,
        ),
      );
    }
    if (targetSizeUnit.present) {
      map['TargetSizeUnit'] = Variable<String>(
        $DrillsTable.$convertertargetSizeUnitn.toSql(targetSizeUnit.value),
      );
    }
    if (origin.present) {
      map['Origin'] = Variable<String>(
        $DrillsTable.$converterorigin.toSql(origin.value),
      );
    }
    if (status.present) {
      map['Status'] = Variable<String>(
        $DrillsTable.$converterstatus.toSql(status.value),
      );
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrillsCompanion(')
          ..write('drillId: $drillId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('skillArea: $skillArea, ')
          ..write('drillType: $drillType, ')
          ..write('scoringMode: $scoringMode, ')
          ..write('inputMode: $inputMode, ')
          ..write('metricSchemaId: $metricSchemaId, ')
          ..write('gridType: $gridType, ')
          ..write('subskillMapping: $subskillMapping, ')
          ..write('clubSelectionMode: $clubSelectionMode, ')
          ..write('targetDistanceMode: $targetDistanceMode, ')
          ..write('targetDistanceValue: $targetDistanceValue, ')
          ..write('targetSizeMode: $targetSizeMode, ')
          ..write('targetSizeWidth: $targetSizeWidth, ')
          ..write('targetSizeDepth: $targetSizeDepth, ')
          ..write('requiredSetCount: $requiredSetCount, ')
          ..write('requiredAttemptsPerSet: $requiredAttemptsPerSet, ')
          ..write('anchors: $anchors, ')
          ..write('target: $target, ')
          ..write('description: $description, ')
          ..write('targetDistanceUnit: $targetDistanceUnit, ')
          ..write('targetSizeUnit: $targetSizeUnit, ')
          ..write('origin: $origin, ')
          ..write('status: $status, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeBlocksTable extends PracticeBlocks
    with TableInfo<$PracticeBlocksTable, PracticeBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _practiceBlockIdMeta = const VerificationMeta(
    'practiceBlockId',
  );
  @override
  late final GeneratedColumn<String> practiceBlockId = GeneratedColumn<String>(
    'PracticeBlockID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRoutineIdMeta = const VerificationMeta(
    'sourceRoutineId',
  );
  @override
  late final GeneratedColumn<String> sourceRoutineId = GeneratedColumn<String>(
    'SourceRoutineID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _drillOrderMeta = const VerificationMeta(
    'drillOrder',
  );
  @override
  late final GeneratedColumn<String> drillOrder = GeneratedColumn<String>(
    'DrillOrder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _startTimestampMeta = const VerificationMeta(
    'startTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> startTimestamp =
      GeneratedColumn<DateTime>(
        'StartTimestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: () => DateTime.now(),
      );
  static const VerificationMeta _endTimestampMeta = const VerificationMeta(
    'endTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> endTimestamp = GeneratedColumn<DateTime>(
    'EndTimestamp',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EnvironmentType?, String>
  environmentType =
      GeneratedColumn<String>(
        'EnvironmentType',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<EnvironmentType?>(
        $PracticeBlocksTable.$converterenvironmentTypen,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SurfaceType?, String>
  surfaceType = GeneratedColumn<String>(
    'SurfaceType',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<SurfaceType?>($PracticeBlocksTable.$convertersurfaceTypen);
  @override
  late final GeneratedColumnWithTypeConverter<ClosureType?, String>
  closureType = GeneratedColumn<String>(
    'ClosureType',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ClosureType?>($PracticeBlocksTable.$converterclosureTypen);
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    practiceBlockId,
    userId,
    sourceRoutineId,
    drillOrder,
    startTimestamp,
    endTimestamp,
    environmentType,
    surfaceType,
    closureType,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'PracticeBlock';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeBlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('PracticeBlockID')) {
      context.handle(
        _practiceBlockIdMeta,
        practiceBlockId.isAcceptableOrUnknown(
          data['PracticeBlockID']!,
          _practiceBlockIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_practiceBlockIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('SourceRoutineID')) {
      context.handle(
        _sourceRoutineIdMeta,
        sourceRoutineId.isAcceptableOrUnknown(
          data['SourceRoutineID']!,
          _sourceRoutineIdMeta,
        ),
      );
    }
    if (data.containsKey('DrillOrder')) {
      context.handle(
        _drillOrderMeta,
        drillOrder.isAcceptableOrUnknown(data['DrillOrder']!, _drillOrderMeta),
      );
    }
    if (data.containsKey('StartTimestamp')) {
      context.handle(
        _startTimestampMeta,
        startTimestamp.isAcceptableOrUnknown(
          data['StartTimestamp']!,
          _startTimestampMeta,
        ),
      );
    }
    if (data.containsKey('EndTimestamp')) {
      context.handle(
        _endTimestampMeta,
        endTimestamp.isAcceptableOrUnknown(
          data['EndTimestamp']!,
          _endTimestampMeta,
        ),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {practiceBlockId};
  @override
  PracticeBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeBlock(
      practiceBlockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}PracticeBlockID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      sourceRoutineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SourceRoutineID'],
      ),
      drillOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DrillOrder'],
      )!,
      startTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}StartTimestamp'],
      )!,
      endTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}EndTimestamp'],
      ),
      environmentType: $PracticeBlocksTable.$converterenvironmentTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}EnvironmentType'],
        ),
      ),
      surfaceType: $PracticeBlocksTable.$convertersurfaceTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SurfaceType'],
        ),
      ),
      closureType: $PracticeBlocksTable.$converterclosureTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ClosureType'],
        ),
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $PracticeBlocksTable createAlias(String alias) {
    return $PracticeBlocksTable(attachedDatabase, alias);
  }

  static TypeConverter<EnvironmentType, String> $converterenvironmentType =
      const EnvironmentTypeConverter();
  static TypeConverter<EnvironmentType?, String?> $converterenvironmentTypen =
      NullAwareTypeConverter.wrap($converterenvironmentType);
  static TypeConverter<SurfaceType, String> $convertersurfaceType =
      const SurfaceTypeConverter();
  static TypeConverter<SurfaceType?, String?> $convertersurfaceTypen =
      NullAwareTypeConverter.wrap($convertersurfaceType);
  static TypeConverter<ClosureType, String> $converterclosureType =
      const ClosureTypeConverter();
  static TypeConverter<ClosureType?, String?> $converterclosureTypen =
      NullAwareTypeConverter.wrap($converterclosureType);
}

class PracticeBlock extends DataClass implements Insertable<PracticeBlock> {
  final String practiceBlockId;
  final String userId;
  final String? sourceRoutineId;
  final String drillOrder;
  final DateTime startTimestamp;
  final DateTime? endTimestamp;
  final EnvironmentType? environmentType;
  final SurfaceType? surfaceType;
  final ClosureType? closureType;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PracticeBlock({
    required this.practiceBlockId,
    required this.userId,
    this.sourceRoutineId,
    required this.drillOrder,
    required this.startTimestamp,
    this.endTimestamp,
    this.environmentType,
    this.surfaceType,
    this.closureType,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['PracticeBlockID'] = Variable<String>(practiceBlockId);
    map['UserID'] = Variable<String>(userId);
    if (!nullToAbsent || sourceRoutineId != null) {
      map['SourceRoutineID'] = Variable<String>(sourceRoutineId);
    }
    map['DrillOrder'] = Variable<String>(drillOrder);
    map['StartTimestamp'] = Variable<DateTime>(startTimestamp);
    if (!nullToAbsent || endTimestamp != null) {
      map['EndTimestamp'] = Variable<DateTime>(endTimestamp);
    }
    if (!nullToAbsent || environmentType != null) {
      map['EnvironmentType'] = Variable<String>(
        $PracticeBlocksTable.$converterenvironmentTypen.toSql(environmentType),
      );
    }
    if (!nullToAbsent || surfaceType != null) {
      map['SurfaceType'] = Variable<String>(
        $PracticeBlocksTable.$convertersurfaceTypen.toSql(surfaceType),
      );
    }
    if (!nullToAbsent || closureType != null) {
      map['ClosureType'] = Variable<String>(
        $PracticeBlocksTable.$converterclosureTypen.toSql(closureType),
      );
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PracticeBlocksCompanion toCompanion(bool nullToAbsent) {
    return PracticeBlocksCompanion(
      practiceBlockId: Value(practiceBlockId),
      userId: Value(userId),
      sourceRoutineId: sourceRoutineId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRoutineId),
      drillOrder: Value(drillOrder),
      startTimestamp: Value(startTimestamp),
      endTimestamp: endTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(endTimestamp),
      environmentType: environmentType == null && nullToAbsent
          ? const Value.absent()
          : Value(environmentType),
      surfaceType: surfaceType == null && nullToAbsent
          ? const Value.absent()
          : Value(surfaceType),
      closureType: closureType == null && nullToAbsent
          ? const Value.absent()
          : Value(closureType),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PracticeBlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeBlock(
      practiceBlockId: serializer.fromJson<String>(json['practiceBlockId']),
      userId: serializer.fromJson<String>(json['userId']),
      sourceRoutineId: serializer.fromJson<String?>(json['sourceRoutineId']),
      drillOrder: serializer.fromJson<String>(json['drillOrder']),
      startTimestamp: serializer.fromJson<DateTime>(json['startTimestamp']),
      endTimestamp: serializer.fromJson<DateTime?>(json['endTimestamp']),
      environmentType: serializer.fromJson<EnvironmentType?>(
        json['environmentType'],
      ),
      surfaceType: serializer.fromJson<SurfaceType?>(json['surfaceType']),
      closureType: serializer.fromJson<ClosureType?>(json['closureType']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'practiceBlockId': serializer.toJson<String>(practiceBlockId),
      'userId': serializer.toJson<String>(userId),
      'sourceRoutineId': serializer.toJson<String?>(sourceRoutineId),
      'drillOrder': serializer.toJson<String>(drillOrder),
      'startTimestamp': serializer.toJson<DateTime>(startTimestamp),
      'endTimestamp': serializer.toJson<DateTime?>(endTimestamp),
      'environmentType': serializer.toJson<EnvironmentType?>(environmentType),
      'surfaceType': serializer.toJson<SurfaceType?>(surfaceType),
      'closureType': serializer.toJson<ClosureType?>(closureType),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PracticeBlock copyWith({
    String? practiceBlockId,
    String? userId,
    Value<String?> sourceRoutineId = const Value.absent(),
    String? drillOrder,
    DateTime? startTimestamp,
    Value<DateTime?> endTimestamp = const Value.absent(),
    Value<EnvironmentType?> environmentType = const Value.absent(),
    Value<SurfaceType?> surfaceType = const Value.absent(),
    Value<ClosureType?> closureType = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PracticeBlock(
    practiceBlockId: practiceBlockId ?? this.practiceBlockId,
    userId: userId ?? this.userId,
    sourceRoutineId: sourceRoutineId.present
        ? sourceRoutineId.value
        : this.sourceRoutineId,
    drillOrder: drillOrder ?? this.drillOrder,
    startTimestamp: startTimestamp ?? this.startTimestamp,
    endTimestamp: endTimestamp.present ? endTimestamp.value : this.endTimestamp,
    environmentType: environmentType.present
        ? environmentType.value
        : this.environmentType,
    surfaceType: surfaceType.present ? surfaceType.value : this.surfaceType,
    closureType: closureType.present ? closureType.value : this.closureType,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PracticeBlock copyWithCompanion(PracticeBlocksCompanion data) {
    return PracticeBlock(
      practiceBlockId: data.practiceBlockId.present
          ? data.practiceBlockId.value
          : this.practiceBlockId,
      userId: data.userId.present ? data.userId.value : this.userId,
      sourceRoutineId: data.sourceRoutineId.present
          ? data.sourceRoutineId.value
          : this.sourceRoutineId,
      drillOrder: data.drillOrder.present
          ? data.drillOrder.value
          : this.drillOrder,
      startTimestamp: data.startTimestamp.present
          ? data.startTimestamp.value
          : this.startTimestamp,
      endTimestamp: data.endTimestamp.present
          ? data.endTimestamp.value
          : this.endTimestamp,
      environmentType: data.environmentType.present
          ? data.environmentType.value
          : this.environmentType,
      surfaceType: data.surfaceType.present
          ? data.surfaceType.value
          : this.surfaceType,
      closureType: data.closureType.present
          ? data.closureType.value
          : this.closureType,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeBlock(')
          ..write('practiceBlockId: $practiceBlockId, ')
          ..write('userId: $userId, ')
          ..write('sourceRoutineId: $sourceRoutineId, ')
          ..write('drillOrder: $drillOrder, ')
          ..write('startTimestamp: $startTimestamp, ')
          ..write('endTimestamp: $endTimestamp, ')
          ..write('environmentType: $environmentType, ')
          ..write('surfaceType: $surfaceType, ')
          ..write('closureType: $closureType, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    practiceBlockId,
    userId,
    sourceRoutineId,
    drillOrder,
    startTimestamp,
    endTimestamp,
    environmentType,
    surfaceType,
    closureType,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeBlock &&
          other.practiceBlockId == this.practiceBlockId &&
          other.userId == this.userId &&
          other.sourceRoutineId == this.sourceRoutineId &&
          other.drillOrder == this.drillOrder &&
          other.startTimestamp == this.startTimestamp &&
          other.endTimestamp == this.endTimestamp &&
          other.environmentType == this.environmentType &&
          other.surfaceType == this.surfaceType &&
          other.closureType == this.closureType &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PracticeBlocksCompanion extends UpdateCompanion<PracticeBlock> {
  final Value<String> practiceBlockId;
  final Value<String> userId;
  final Value<String?> sourceRoutineId;
  final Value<String> drillOrder;
  final Value<DateTime> startTimestamp;
  final Value<DateTime?> endTimestamp;
  final Value<EnvironmentType?> environmentType;
  final Value<SurfaceType?> surfaceType;
  final Value<ClosureType?> closureType;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PracticeBlocksCompanion({
    this.practiceBlockId = const Value.absent(),
    this.userId = const Value.absent(),
    this.sourceRoutineId = const Value.absent(),
    this.drillOrder = const Value.absent(),
    this.startTimestamp = const Value.absent(),
    this.endTimestamp = const Value.absent(),
    this.environmentType = const Value.absent(),
    this.surfaceType = const Value.absent(),
    this.closureType = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeBlocksCompanion.insert({
    required String practiceBlockId,
    required String userId,
    this.sourceRoutineId = const Value.absent(),
    this.drillOrder = const Value.absent(),
    this.startTimestamp = const Value.absent(),
    this.endTimestamp = const Value.absent(),
    this.environmentType = const Value.absent(),
    this.surfaceType = const Value.absent(),
    this.closureType = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : practiceBlockId = Value(practiceBlockId),
       userId = Value(userId);
  static Insertable<PracticeBlock> custom({
    Expression<String>? practiceBlockId,
    Expression<String>? userId,
    Expression<String>? sourceRoutineId,
    Expression<String>? drillOrder,
    Expression<DateTime>? startTimestamp,
    Expression<DateTime>? endTimestamp,
    Expression<String>? environmentType,
    Expression<String>? surfaceType,
    Expression<String>? closureType,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (practiceBlockId != null) 'PracticeBlockID': practiceBlockId,
      if (userId != null) 'UserID': userId,
      if (sourceRoutineId != null) 'SourceRoutineID': sourceRoutineId,
      if (drillOrder != null) 'DrillOrder': drillOrder,
      if (startTimestamp != null) 'StartTimestamp': startTimestamp,
      if (endTimestamp != null) 'EndTimestamp': endTimestamp,
      if (environmentType != null) 'EnvironmentType': environmentType,
      if (surfaceType != null) 'SurfaceType': surfaceType,
      if (closureType != null) 'ClosureType': closureType,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeBlocksCompanion copyWith({
    Value<String>? practiceBlockId,
    Value<String>? userId,
    Value<String?>? sourceRoutineId,
    Value<String>? drillOrder,
    Value<DateTime>? startTimestamp,
    Value<DateTime?>? endTimestamp,
    Value<EnvironmentType?>? environmentType,
    Value<SurfaceType?>? surfaceType,
    Value<ClosureType?>? closureType,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PracticeBlocksCompanion(
      practiceBlockId: practiceBlockId ?? this.practiceBlockId,
      userId: userId ?? this.userId,
      sourceRoutineId: sourceRoutineId ?? this.sourceRoutineId,
      drillOrder: drillOrder ?? this.drillOrder,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      environmentType: environmentType ?? this.environmentType,
      surfaceType: surfaceType ?? this.surfaceType,
      closureType: closureType ?? this.closureType,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (practiceBlockId.present) {
      map['PracticeBlockID'] = Variable<String>(practiceBlockId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (sourceRoutineId.present) {
      map['SourceRoutineID'] = Variable<String>(sourceRoutineId.value);
    }
    if (drillOrder.present) {
      map['DrillOrder'] = Variable<String>(drillOrder.value);
    }
    if (startTimestamp.present) {
      map['StartTimestamp'] = Variable<DateTime>(startTimestamp.value);
    }
    if (endTimestamp.present) {
      map['EndTimestamp'] = Variable<DateTime>(endTimestamp.value);
    }
    if (environmentType.present) {
      map['EnvironmentType'] = Variable<String>(
        $PracticeBlocksTable.$converterenvironmentTypen.toSql(
          environmentType.value,
        ),
      );
    }
    if (surfaceType.present) {
      map['SurfaceType'] = Variable<String>(
        $PracticeBlocksTable.$convertersurfaceTypen.toSql(surfaceType.value),
      );
    }
    if (closureType.present) {
      map['ClosureType'] = Variable<String>(
        $PracticeBlocksTable.$converterclosureTypen.toSql(closureType.value),
      );
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeBlocksCompanion(')
          ..write('practiceBlockId: $practiceBlockId, ')
          ..write('userId: $userId, ')
          ..write('sourceRoutineId: $sourceRoutineId, ')
          ..write('drillOrder: $drillOrder, ')
          ..write('startTimestamp: $startTimestamp, ')
          ..write('endTimestamp: $endTimestamp, ')
          ..write('environmentType: $environmentType, ')
          ..write('surfaceType: $surfaceType, ')
          ..write('closureType: $closureType, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'SessionID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drillIdMeta = const VerificationMeta(
    'drillId',
  );
  @override
  late final GeneratedColumn<String> drillId = GeneratedColumn<String>(
    'DrillID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _practiceBlockIdMeta = const VerificationMeta(
    'practiceBlockId',
  );
  @override
  late final GeneratedColumn<String> practiceBlockId = GeneratedColumn<String>(
    'PracticeBlockID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionTimestampMeta =
      const VerificationMeta('completionTimestamp');
  @override
  late final GeneratedColumn<DateTime> completionTimestamp =
      GeneratedColumn<DateTime>(
        'CompletionTimestamp',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SessionStatus, String> status =
      GeneratedColumn<String>(
        'Status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Active'),
      ).withConverter<SessionStatus>($SessionsTable.$converterstatus);
  static const VerificationMeta _integrityFlagMeta = const VerificationMeta(
    'integrityFlag',
  );
  @override
  late final GeneratedColumn<bool> integrityFlag = GeneratedColumn<bool>(
    'IntegrityFlag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IntegrityFlag" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _integritySuppressedMeta =
      const VerificationMeta('integritySuppressed');
  @override
  late final GeneratedColumn<bool> integritySuppressed = GeneratedColumn<bool>(
    'IntegritySuppressed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IntegritySuppressed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SurfaceType?, String>
  surfaceType = GeneratedColumn<String>(
    'SurfaceType',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<SurfaceType?>($SessionsTable.$convertersurfaceTypen);
  static const VerificationMeta _userDeclarationMeta = const VerificationMeta(
    'userDeclaration',
  );
  @override
  late final GeneratedColumn<String> userDeclaration = GeneratedColumn<String>(
    'UserDeclaration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionDurationMeta = const VerificationMeta(
    'sessionDuration',
  );
  @override
  late final GeneratedColumn<int> sessionDuration = GeneratedColumn<int>(
    'SessionDuration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    drillId,
    practiceBlockId,
    completionTimestamp,
    status,
    integrityFlag,
    integritySuppressed,
    surfaceType,
    userDeclaration,
    sessionDuration,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Session';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('SessionID')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['SessionID']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('DrillID')) {
      context.handle(
        _drillIdMeta,
        drillId.isAcceptableOrUnknown(data['DrillID']!, _drillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_drillIdMeta);
    }
    if (data.containsKey('PracticeBlockID')) {
      context.handle(
        _practiceBlockIdMeta,
        practiceBlockId.isAcceptableOrUnknown(
          data['PracticeBlockID']!,
          _practiceBlockIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_practiceBlockIdMeta);
    }
    if (data.containsKey('CompletionTimestamp')) {
      context.handle(
        _completionTimestampMeta,
        completionTimestamp.isAcceptableOrUnknown(
          data['CompletionTimestamp']!,
          _completionTimestampMeta,
        ),
      );
    }
    if (data.containsKey('IntegrityFlag')) {
      context.handle(
        _integrityFlagMeta,
        integrityFlag.isAcceptableOrUnknown(
          data['IntegrityFlag']!,
          _integrityFlagMeta,
        ),
      );
    }
    if (data.containsKey('IntegritySuppressed')) {
      context.handle(
        _integritySuppressedMeta,
        integritySuppressed.isAcceptableOrUnknown(
          data['IntegritySuppressed']!,
          _integritySuppressedMeta,
        ),
      );
    }
    if (data.containsKey('UserDeclaration')) {
      context.handle(
        _userDeclarationMeta,
        userDeclaration.isAcceptableOrUnknown(
          data['UserDeclaration']!,
          _userDeclarationMeta,
        ),
      );
    }
    if (data.containsKey('SessionDuration')) {
      context.handle(
        _sessionDurationMeta,
        sessionDuration.isAcceptableOrUnknown(
          data['SessionDuration']!,
          _sessionDurationMeta,
        ),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SessionID'],
      )!,
      drillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DrillID'],
      )!,
      practiceBlockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}PracticeBlockID'],
      )!,
      completionTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CompletionTimestamp'],
      ),
      status: $SessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}Status'],
        )!,
      ),
      integrityFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IntegrityFlag'],
      )!,
      integritySuppressed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IntegritySuppressed'],
      )!,
      surfaceType: $SessionsTable.$convertersurfaceTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SurfaceType'],
        ),
      ),
      userDeclaration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserDeclaration'],
      ),
      sessionDuration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}SessionDuration'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<SessionStatus, String> $converterstatus =
      const SessionStatusConverter();
  static TypeConverter<SurfaceType, String> $convertersurfaceType =
      const SurfaceTypeConverter();
  static TypeConverter<SurfaceType?, String?> $convertersurfaceTypen =
      NullAwareTypeConverter.wrap($convertersurfaceType);
}

class Session extends DataClass implements Insertable<Session> {
  final String sessionId;
  final String drillId;
  final String practiceBlockId;
  final DateTime? completionTimestamp;
  final SessionStatus status;
  final bool integrityFlag;
  final bool integritySuppressed;
  final SurfaceType? surfaceType;
  final String? userDeclaration;
  final int? sessionDuration;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Session({
    required this.sessionId,
    required this.drillId,
    required this.practiceBlockId,
    this.completionTimestamp,
    required this.status,
    required this.integrityFlag,
    required this.integritySuppressed,
    this.surfaceType,
    this.userDeclaration,
    this.sessionDuration,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['SessionID'] = Variable<String>(sessionId);
    map['DrillID'] = Variable<String>(drillId);
    map['PracticeBlockID'] = Variable<String>(practiceBlockId);
    if (!nullToAbsent || completionTimestamp != null) {
      map['CompletionTimestamp'] = Variable<DateTime>(completionTimestamp);
    }
    {
      map['Status'] = Variable<String>(
        $SessionsTable.$converterstatus.toSql(status),
      );
    }
    map['IntegrityFlag'] = Variable<bool>(integrityFlag);
    map['IntegritySuppressed'] = Variable<bool>(integritySuppressed);
    if (!nullToAbsent || surfaceType != null) {
      map['SurfaceType'] = Variable<String>(
        $SessionsTable.$convertersurfaceTypen.toSql(surfaceType),
      );
    }
    if (!nullToAbsent || userDeclaration != null) {
      map['UserDeclaration'] = Variable<String>(userDeclaration);
    }
    if (!nullToAbsent || sessionDuration != null) {
      map['SessionDuration'] = Variable<int>(sessionDuration);
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      sessionId: Value(sessionId),
      drillId: Value(drillId),
      practiceBlockId: Value(practiceBlockId),
      completionTimestamp: completionTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(completionTimestamp),
      status: Value(status),
      integrityFlag: Value(integrityFlag),
      integritySuppressed: Value(integritySuppressed),
      surfaceType: surfaceType == null && nullToAbsent
          ? const Value.absent()
          : Value(surfaceType),
      userDeclaration: userDeclaration == null && nullToAbsent
          ? const Value.absent()
          : Value(userDeclaration),
      sessionDuration: sessionDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionDuration),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      drillId: serializer.fromJson<String>(json['drillId']),
      practiceBlockId: serializer.fromJson<String>(json['practiceBlockId']),
      completionTimestamp: serializer.fromJson<DateTime?>(
        json['completionTimestamp'],
      ),
      status: serializer.fromJson<SessionStatus>(json['status']),
      integrityFlag: serializer.fromJson<bool>(json['integrityFlag']),
      integritySuppressed: serializer.fromJson<bool>(
        json['integritySuppressed'],
      ),
      surfaceType: serializer.fromJson<SurfaceType?>(json['surfaceType']),
      userDeclaration: serializer.fromJson<String?>(json['userDeclaration']),
      sessionDuration: serializer.fromJson<int?>(json['sessionDuration']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'drillId': serializer.toJson<String>(drillId),
      'practiceBlockId': serializer.toJson<String>(practiceBlockId),
      'completionTimestamp': serializer.toJson<DateTime?>(completionTimestamp),
      'status': serializer.toJson<SessionStatus>(status),
      'integrityFlag': serializer.toJson<bool>(integrityFlag),
      'integritySuppressed': serializer.toJson<bool>(integritySuppressed),
      'surfaceType': serializer.toJson<SurfaceType?>(surfaceType),
      'userDeclaration': serializer.toJson<String?>(userDeclaration),
      'sessionDuration': serializer.toJson<int?>(sessionDuration),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Session copyWith({
    String? sessionId,
    String? drillId,
    String? practiceBlockId,
    Value<DateTime?> completionTimestamp = const Value.absent(),
    SessionStatus? status,
    bool? integrityFlag,
    bool? integritySuppressed,
    Value<SurfaceType?> surfaceType = const Value.absent(),
    Value<String?> userDeclaration = const Value.absent(),
    Value<int?> sessionDuration = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Session(
    sessionId: sessionId ?? this.sessionId,
    drillId: drillId ?? this.drillId,
    practiceBlockId: practiceBlockId ?? this.practiceBlockId,
    completionTimestamp: completionTimestamp.present
        ? completionTimestamp.value
        : this.completionTimestamp,
    status: status ?? this.status,
    integrityFlag: integrityFlag ?? this.integrityFlag,
    integritySuppressed: integritySuppressed ?? this.integritySuppressed,
    surfaceType: surfaceType.present ? surfaceType.value : this.surfaceType,
    userDeclaration: userDeclaration.present
        ? userDeclaration.value
        : this.userDeclaration,
    sessionDuration: sessionDuration.present
        ? sessionDuration.value
        : this.sessionDuration,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      drillId: data.drillId.present ? data.drillId.value : this.drillId,
      practiceBlockId: data.practiceBlockId.present
          ? data.practiceBlockId.value
          : this.practiceBlockId,
      completionTimestamp: data.completionTimestamp.present
          ? data.completionTimestamp.value
          : this.completionTimestamp,
      status: data.status.present ? data.status.value : this.status,
      integrityFlag: data.integrityFlag.present
          ? data.integrityFlag.value
          : this.integrityFlag,
      integritySuppressed: data.integritySuppressed.present
          ? data.integritySuppressed.value
          : this.integritySuppressed,
      surfaceType: data.surfaceType.present
          ? data.surfaceType.value
          : this.surfaceType,
      userDeclaration: data.userDeclaration.present
          ? data.userDeclaration.value
          : this.userDeclaration,
      sessionDuration: data.sessionDuration.present
          ? data.sessionDuration.value
          : this.sessionDuration,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('sessionId: $sessionId, ')
          ..write('drillId: $drillId, ')
          ..write('practiceBlockId: $practiceBlockId, ')
          ..write('completionTimestamp: $completionTimestamp, ')
          ..write('status: $status, ')
          ..write('integrityFlag: $integrityFlag, ')
          ..write('integritySuppressed: $integritySuppressed, ')
          ..write('surfaceType: $surfaceType, ')
          ..write('userDeclaration: $userDeclaration, ')
          ..write('sessionDuration: $sessionDuration, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    drillId,
    practiceBlockId,
    completionTimestamp,
    status,
    integrityFlag,
    integritySuppressed,
    surfaceType,
    userDeclaration,
    sessionDuration,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.sessionId == this.sessionId &&
          other.drillId == this.drillId &&
          other.practiceBlockId == this.practiceBlockId &&
          other.completionTimestamp == this.completionTimestamp &&
          other.status == this.status &&
          other.integrityFlag == this.integrityFlag &&
          other.integritySuppressed == this.integritySuppressed &&
          other.surfaceType == this.surfaceType &&
          other.userDeclaration == this.userDeclaration &&
          other.sessionDuration == this.sessionDuration &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> sessionId;
  final Value<String> drillId;
  final Value<String> practiceBlockId;
  final Value<DateTime?> completionTimestamp;
  final Value<SessionStatus> status;
  final Value<bool> integrityFlag;
  final Value<bool> integritySuppressed;
  final Value<SurfaceType?> surfaceType;
  final Value<String?> userDeclaration;
  final Value<int?> sessionDuration;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SessionsCompanion({
    this.sessionId = const Value.absent(),
    this.drillId = const Value.absent(),
    this.practiceBlockId = const Value.absent(),
    this.completionTimestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.integrityFlag = const Value.absent(),
    this.integritySuppressed = const Value.absent(),
    this.surfaceType = const Value.absent(),
    this.userDeclaration = const Value.absent(),
    this.sessionDuration = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String sessionId,
    required String drillId,
    required String practiceBlockId,
    this.completionTimestamp = const Value.absent(),
    this.status = const Value.absent(),
    this.integrityFlag = const Value.absent(),
    this.integritySuppressed = const Value.absent(),
    this.surfaceType = const Value.absent(),
    this.userDeclaration = const Value.absent(),
    this.sessionDuration = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       drillId = Value(drillId),
       practiceBlockId = Value(practiceBlockId);
  static Insertable<Session> custom({
    Expression<String>? sessionId,
    Expression<String>? drillId,
    Expression<String>? practiceBlockId,
    Expression<DateTime>? completionTimestamp,
    Expression<String>? status,
    Expression<bool>? integrityFlag,
    Expression<bool>? integritySuppressed,
    Expression<String>? surfaceType,
    Expression<String>? userDeclaration,
    Expression<int>? sessionDuration,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'SessionID': sessionId,
      if (drillId != null) 'DrillID': drillId,
      if (practiceBlockId != null) 'PracticeBlockID': practiceBlockId,
      if (completionTimestamp != null)
        'CompletionTimestamp': completionTimestamp,
      if (status != null) 'Status': status,
      if (integrityFlag != null) 'IntegrityFlag': integrityFlag,
      if (integritySuppressed != null)
        'IntegritySuppressed': integritySuppressed,
      if (surfaceType != null) 'SurfaceType': surfaceType,
      if (userDeclaration != null) 'UserDeclaration': userDeclaration,
      if (sessionDuration != null) 'SessionDuration': sessionDuration,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? drillId,
    Value<String>? practiceBlockId,
    Value<DateTime?>? completionTimestamp,
    Value<SessionStatus>? status,
    Value<bool>? integrityFlag,
    Value<bool>? integritySuppressed,
    Value<SurfaceType?>? surfaceType,
    Value<String?>? userDeclaration,
    Value<int?>? sessionDuration,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      drillId: drillId ?? this.drillId,
      practiceBlockId: practiceBlockId ?? this.practiceBlockId,
      completionTimestamp: completionTimestamp ?? this.completionTimestamp,
      status: status ?? this.status,
      integrityFlag: integrityFlag ?? this.integrityFlag,
      integritySuppressed: integritySuppressed ?? this.integritySuppressed,
      surfaceType: surfaceType ?? this.surfaceType,
      userDeclaration: userDeclaration ?? this.userDeclaration,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['SessionID'] = Variable<String>(sessionId.value);
    }
    if (drillId.present) {
      map['DrillID'] = Variable<String>(drillId.value);
    }
    if (practiceBlockId.present) {
      map['PracticeBlockID'] = Variable<String>(practiceBlockId.value);
    }
    if (completionTimestamp.present) {
      map['CompletionTimestamp'] = Variable<DateTime>(
        completionTimestamp.value,
      );
    }
    if (status.present) {
      map['Status'] = Variable<String>(
        $SessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (integrityFlag.present) {
      map['IntegrityFlag'] = Variable<bool>(integrityFlag.value);
    }
    if (integritySuppressed.present) {
      map['IntegritySuppressed'] = Variable<bool>(integritySuppressed.value);
    }
    if (surfaceType.present) {
      map['SurfaceType'] = Variable<String>(
        $SessionsTable.$convertersurfaceTypen.toSql(surfaceType.value),
      );
    }
    if (userDeclaration.present) {
      map['UserDeclaration'] = Variable<String>(userDeclaration.value);
    }
    if (sessionDuration.present) {
      map['SessionDuration'] = Variable<int>(sessionDuration.value);
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('drillId: $drillId, ')
          ..write('practiceBlockId: $practiceBlockId, ')
          ..write('completionTimestamp: $completionTimestamp, ')
          ..write('status: $status, ')
          ..write('integrityFlag: $integrityFlag, ')
          ..write('integritySuppressed: $integritySuppressed, ')
          ..write('surfaceType: $surfaceType, ')
          ..write('userDeclaration: $userDeclaration, ')
          ..write('sessionDuration: $sessionDuration, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetsTable extends Sets with TableInfo<$SetsTable, PracticeSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
    'SetID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'SessionID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'SetIndex',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    setId,
    sessionId,
    setIndex,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Set';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('SetID')) {
      context.handle(
        _setIdMeta,
        setId.isAcceptableOrUnknown(data['SetID']!, _setIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('SessionID')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['SessionID']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('SetIndex')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['SetIndex']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {setId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sessionId, setIndex},
  ];
  @override
  PracticeSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSet(
      setId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SetID'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SessionID'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}SetIndex'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $SetsTable createAlias(String alias) {
    return $SetsTable(attachedDatabase, alias);
  }
}

class PracticeSet extends DataClass implements Insertable<PracticeSet> {
  final String setId;
  final String sessionId;
  final int setIndex;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PracticeSet({
    required this.setId,
    required this.sessionId,
    required this.setIndex,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['SetID'] = Variable<String>(setId);
    map['SessionID'] = Variable<String>(sessionId);
    map['SetIndex'] = Variable<int>(setIndex);
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SetsCompanion toCompanion(bool nullToAbsent) {
    return SetsCompanion(
      setId: Value(setId),
      sessionId: Value(sessionId),
      setIndex: Value(setIndex),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PracticeSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSet(
      setId: serializer.fromJson<String>(json['setId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setId': serializer.toJson<String>(setId),
      'sessionId': serializer.toJson<String>(sessionId),
      'setIndex': serializer.toJson<int>(setIndex),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PracticeSet copyWith({
    String? setId,
    String? sessionId,
    int? setIndex,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PracticeSet(
    setId: setId ?? this.setId,
    sessionId: sessionId ?? this.sessionId,
    setIndex: setIndex ?? this.setIndex,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PracticeSet copyWithCompanion(SetsCompanion data) {
    return PracticeSet(
      setId: data.setId.present ? data.setId.value : this.setId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSet(')
          ..write('setId: $setId, ')
          ..write('sessionId: $sessionId, ')
          ..write('setIndex: $setIndex, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(setId, sessionId, setIndex, isDeleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSet &&
          other.setId == this.setId &&
          other.sessionId == this.sessionId &&
          other.setIndex == this.setIndex &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SetsCompanion extends UpdateCompanion<PracticeSet> {
  final Value<String> setId;
  final Value<String> sessionId;
  final Value<int> setIndex;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SetsCompanion({
    this.setId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetsCompanion.insert({
    required String setId,
    required String sessionId,
    required int setIndex,
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : setId = Value(setId),
       sessionId = Value(sessionId),
       setIndex = Value(setIndex);
  static Insertable<PracticeSet> custom({
    Expression<String>? setId,
    Expression<String>? sessionId,
    Expression<int>? setIndex,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setId != null) 'SetID': setId,
      if (sessionId != null) 'SessionID': sessionId,
      if (setIndex != null) 'SetIndex': setIndex,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetsCompanion copyWith({
    Value<String>? setId,
    Value<String>? sessionId,
    Value<int>? setIndex,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SetsCompanion(
      setId: setId ?? this.setId,
      sessionId: sessionId ?? this.sessionId,
      setIndex: setIndex ?? this.setIndex,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setId.present) {
      map['SetID'] = Variable<String>(setId.value);
    }
    if (sessionId.present) {
      map['SessionID'] = Variable<String>(sessionId.value);
    }
    if (setIndex.present) {
      map['SetIndex'] = Variable<int>(setIndex.value);
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetsCompanion(')
          ..write('setId: $setId, ')
          ..write('sessionId: $sessionId, ')
          ..write('setIndex: $setIndex, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstancesTable extends Instances
    with TableInfo<$InstancesTable, Instance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  @override
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'InstanceID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
    'SetID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedClubMeta = const VerificationMeta(
    'selectedClub',
  );
  @override
  late final GeneratedColumn<String> selectedClub = GeneratedColumn<String>(
    'SelectedClub',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawMetricsMeta = const VerificationMeta(
    'rawMetrics',
  );
  @override
  late final GeneratedColumn<String> rawMetrics = GeneratedColumn<String>(
    'RawMetrics',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'Timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _resolvedTargetDistanceMeta =
      const VerificationMeta('resolvedTargetDistance');
  @override
  late final GeneratedColumn<double> resolvedTargetDistance =
      GeneratedColumn<double>(
        'ResolvedTargetDistance',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolvedTargetWidthMeta =
      const VerificationMeta('resolvedTargetWidth');
  @override
  late final GeneratedColumn<double> resolvedTargetWidth =
      GeneratedColumn<double>(
        'ResolvedTargetWidth',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolvedTargetDepthMeta =
      const VerificationMeta('resolvedTargetDepth');
  @override
  late final GeneratedColumn<double> resolvedTargetDepth =
      GeneratedColumn<double>(
        'ResolvedTargetDepth',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    instanceId,
    setId,
    selectedClub,
    rawMetrics,
    timestamp,
    resolvedTargetDistance,
    resolvedTargetWidth,
    resolvedTargetDepth,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Instance';
  @override
  VerificationContext validateIntegrity(
    Insertable<Instance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('InstanceID')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['InstanceID']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('SetID')) {
      context.handle(
        _setIdMeta,
        setId.isAcceptableOrUnknown(data['SetID']!, _setIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('SelectedClub')) {
      context.handle(
        _selectedClubMeta,
        selectedClub.isAcceptableOrUnknown(
          data['SelectedClub']!,
          _selectedClubMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedClubMeta);
    }
    if (data.containsKey('RawMetrics')) {
      context.handle(
        _rawMetricsMeta,
        rawMetrics.isAcceptableOrUnknown(data['RawMetrics']!, _rawMetricsMeta),
      );
    } else if (isInserting) {
      context.missing(_rawMetricsMeta);
    }
    if (data.containsKey('Timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['Timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('ResolvedTargetDistance')) {
      context.handle(
        _resolvedTargetDistanceMeta,
        resolvedTargetDistance.isAcceptableOrUnknown(
          data['ResolvedTargetDistance']!,
          _resolvedTargetDistanceMeta,
        ),
      );
    }
    if (data.containsKey('ResolvedTargetWidth')) {
      context.handle(
        _resolvedTargetWidthMeta,
        resolvedTargetWidth.isAcceptableOrUnknown(
          data['ResolvedTargetWidth']!,
          _resolvedTargetWidthMeta,
        ),
      );
    }
    if (data.containsKey('ResolvedTargetDepth')) {
      context.handle(
        _resolvedTargetDepthMeta,
        resolvedTargetDepth.isAcceptableOrUnknown(
          data['ResolvedTargetDepth']!,
          _resolvedTargetDepthMeta,
        ),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instanceId};
  @override
  Instance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Instance(
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}InstanceID'],
      )!,
      setId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SetID'],
      )!,
      selectedClub: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SelectedClub'],
      )!,
      rawMetrics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}RawMetrics'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}Timestamp'],
      )!,
      resolvedTargetDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ResolvedTargetDistance'],
      ),
      resolvedTargetWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ResolvedTargetWidth'],
      ),
      resolvedTargetDepth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ResolvedTargetDepth'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $InstancesTable createAlias(String alias) {
    return $InstancesTable(attachedDatabase, alias);
  }
}

class Instance extends DataClass implements Insertable<Instance> {
  final String instanceId;
  final String setId;
  final String selectedClub;
  final String rawMetrics;
  final DateTime timestamp;
  final double? resolvedTargetDistance;
  final double? resolvedTargetWidth;
  final double? resolvedTargetDepth;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Instance({
    required this.instanceId,
    required this.setId,
    required this.selectedClub,
    required this.rawMetrics,
    required this.timestamp,
    this.resolvedTargetDistance,
    this.resolvedTargetWidth,
    this.resolvedTargetDepth,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['InstanceID'] = Variable<String>(instanceId);
    map['SetID'] = Variable<String>(setId);
    map['SelectedClub'] = Variable<String>(selectedClub);
    map['RawMetrics'] = Variable<String>(rawMetrics);
    map['Timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || resolvedTargetDistance != null) {
      map['ResolvedTargetDistance'] = Variable<double>(resolvedTargetDistance);
    }
    if (!nullToAbsent || resolvedTargetWidth != null) {
      map['ResolvedTargetWidth'] = Variable<double>(resolvedTargetWidth);
    }
    if (!nullToAbsent || resolvedTargetDepth != null) {
      map['ResolvedTargetDepth'] = Variable<double>(resolvedTargetDepth);
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InstancesCompanion toCompanion(bool nullToAbsent) {
    return InstancesCompanion(
      instanceId: Value(instanceId),
      setId: Value(setId),
      selectedClub: Value(selectedClub),
      rawMetrics: Value(rawMetrics),
      timestamp: Value(timestamp),
      resolvedTargetDistance: resolvedTargetDistance == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedTargetDistance),
      resolvedTargetWidth: resolvedTargetWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedTargetWidth),
      resolvedTargetDepth: resolvedTargetDepth == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedTargetDepth),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Instance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Instance(
      instanceId: serializer.fromJson<String>(json['instanceId']),
      setId: serializer.fromJson<String>(json['setId']),
      selectedClub: serializer.fromJson<String>(json['selectedClub']),
      rawMetrics: serializer.fromJson<String>(json['rawMetrics']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      resolvedTargetDistance: serializer.fromJson<double?>(
        json['resolvedTargetDistance'],
      ),
      resolvedTargetWidth: serializer.fromJson<double?>(
        json['resolvedTargetWidth'],
      ),
      resolvedTargetDepth: serializer.fromJson<double?>(
        json['resolvedTargetDepth'],
      ),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instanceId': serializer.toJson<String>(instanceId),
      'setId': serializer.toJson<String>(setId),
      'selectedClub': serializer.toJson<String>(selectedClub),
      'rawMetrics': serializer.toJson<String>(rawMetrics),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'resolvedTargetDistance': serializer.toJson<double?>(
        resolvedTargetDistance,
      ),
      'resolvedTargetWidth': serializer.toJson<double?>(resolvedTargetWidth),
      'resolvedTargetDepth': serializer.toJson<double?>(resolvedTargetDepth),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Instance copyWith({
    String? instanceId,
    String? setId,
    String? selectedClub,
    String? rawMetrics,
    DateTime? timestamp,
    Value<double?> resolvedTargetDistance = const Value.absent(),
    Value<double?> resolvedTargetWidth = const Value.absent(),
    Value<double?> resolvedTargetDepth = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Instance(
    instanceId: instanceId ?? this.instanceId,
    setId: setId ?? this.setId,
    selectedClub: selectedClub ?? this.selectedClub,
    rawMetrics: rawMetrics ?? this.rawMetrics,
    timestamp: timestamp ?? this.timestamp,
    resolvedTargetDistance: resolvedTargetDistance.present
        ? resolvedTargetDistance.value
        : this.resolvedTargetDistance,
    resolvedTargetWidth: resolvedTargetWidth.present
        ? resolvedTargetWidth.value
        : this.resolvedTargetWidth,
    resolvedTargetDepth: resolvedTargetDepth.present
        ? resolvedTargetDepth.value
        : this.resolvedTargetDepth,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Instance copyWithCompanion(InstancesCompanion data) {
    return Instance(
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      setId: data.setId.present ? data.setId.value : this.setId,
      selectedClub: data.selectedClub.present
          ? data.selectedClub.value
          : this.selectedClub,
      rawMetrics: data.rawMetrics.present
          ? data.rawMetrics.value
          : this.rawMetrics,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      resolvedTargetDistance: data.resolvedTargetDistance.present
          ? data.resolvedTargetDistance.value
          : this.resolvedTargetDistance,
      resolvedTargetWidth: data.resolvedTargetWidth.present
          ? data.resolvedTargetWidth.value
          : this.resolvedTargetWidth,
      resolvedTargetDepth: data.resolvedTargetDepth.present
          ? data.resolvedTargetDepth.value
          : this.resolvedTargetDepth,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Instance(')
          ..write('instanceId: $instanceId, ')
          ..write('setId: $setId, ')
          ..write('selectedClub: $selectedClub, ')
          ..write('rawMetrics: $rawMetrics, ')
          ..write('timestamp: $timestamp, ')
          ..write('resolvedTargetDistance: $resolvedTargetDistance, ')
          ..write('resolvedTargetWidth: $resolvedTargetWidth, ')
          ..write('resolvedTargetDepth: $resolvedTargetDepth, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    instanceId,
    setId,
    selectedClub,
    rawMetrics,
    timestamp,
    resolvedTargetDistance,
    resolvedTargetWidth,
    resolvedTargetDepth,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Instance &&
          other.instanceId == this.instanceId &&
          other.setId == this.setId &&
          other.selectedClub == this.selectedClub &&
          other.rawMetrics == this.rawMetrics &&
          other.timestamp == this.timestamp &&
          other.resolvedTargetDistance == this.resolvedTargetDistance &&
          other.resolvedTargetWidth == this.resolvedTargetWidth &&
          other.resolvedTargetDepth == this.resolvedTargetDepth &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InstancesCompanion extends UpdateCompanion<Instance> {
  final Value<String> instanceId;
  final Value<String> setId;
  final Value<String> selectedClub;
  final Value<String> rawMetrics;
  final Value<DateTime> timestamp;
  final Value<double?> resolvedTargetDistance;
  final Value<double?> resolvedTargetWidth;
  final Value<double?> resolvedTargetDepth;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InstancesCompanion({
    this.instanceId = const Value.absent(),
    this.setId = const Value.absent(),
    this.selectedClub = const Value.absent(),
    this.rawMetrics = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.resolvedTargetDistance = const Value.absent(),
    this.resolvedTargetWidth = const Value.absent(),
    this.resolvedTargetDepth = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstancesCompanion.insert({
    required String instanceId,
    required String setId,
    required String selectedClub,
    required String rawMetrics,
    this.timestamp = const Value.absent(),
    this.resolvedTargetDistance = const Value.absent(),
    this.resolvedTargetWidth = const Value.absent(),
    this.resolvedTargetDepth = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : instanceId = Value(instanceId),
       setId = Value(setId),
       selectedClub = Value(selectedClub),
       rawMetrics = Value(rawMetrics);
  static Insertable<Instance> custom({
    Expression<String>? instanceId,
    Expression<String>? setId,
    Expression<String>? selectedClub,
    Expression<String>? rawMetrics,
    Expression<DateTime>? timestamp,
    Expression<double>? resolvedTargetDistance,
    Expression<double>? resolvedTargetWidth,
    Expression<double>? resolvedTargetDepth,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (instanceId != null) 'InstanceID': instanceId,
      if (setId != null) 'SetID': setId,
      if (selectedClub != null) 'SelectedClub': selectedClub,
      if (rawMetrics != null) 'RawMetrics': rawMetrics,
      if (timestamp != null) 'Timestamp': timestamp,
      if (resolvedTargetDistance != null)
        'ResolvedTargetDistance': resolvedTargetDistance,
      if (resolvedTargetWidth != null)
        'ResolvedTargetWidth': resolvedTargetWidth,
      if (resolvedTargetDepth != null)
        'ResolvedTargetDepth': resolvedTargetDepth,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstancesCompanion copyWith({
    Value<String>? instanceId,
    Value<String>? setId,
    Value<String>? selectedClub,
    Value<String>? rawMetrics,
    Value<DateTime>? timestamp,
    Value<double?>? resolvedTargetDistance,
    Value<double?>? resolvedTargetWidth,
    Value<double?>? resolvedTargetDepth,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InstancesCompanion(
      instanceId: instanceId ?? this.instanceId,
      setId: setId ?? this.setId,
      selectedClub: selectedClub ?? this.selectedClub,
      rawMetrics: rawMetrics ?? this.rawMetrics,
      timestamp: timestamp ?? this.timestamp,
      resolvedTargetDistance:
          resolvedTargetDistance ?? this.resolvedTargetDistance,
      resolvedTargetWidth: resolvedTargetWidth ?? this.resolvedTargetWidth,
      resolvedTargetDepth: resolvedTargetDepth ?? this.resolvedTargetDepth,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instanceId.present) {
      map['InstanceID'] = Variable<String>(instanceId.value);
    }
    if (setId.present) {
      map['SetID'] = Variable<String>(setId.value);
    }
    if (selectedClub.present) {
      map['SelectedClub'] = Variable<String>(selectedClub.value);
    }
    if (rawMetrics.present) {
      map['RawMetrics'] = Variable<String>(rawMetrics.value);
    }
    if (timestamp.present) {
      map['Timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (resolvedTargetDistance.present) {
      map['ResolvedTargetDistance'] = Variable<double>(
        resolvedTargetDistance.value,
      );
    }
    if (resolvedTargetWidth.present) {
      map['ResolvedTargetWidth'] = Variable<double>(resolvedTargetWidth.value);
    }
    if (resolvedTargetDepth.present) {
      map['ResolvedTargetDepth'] = Variable<double>(resolvedTargetDepth.value);
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstancesCompanion(')
          ..write('instanceId: $instanceId, ')
          ..write('setId: $setId, ')
          ..write('selectedClub: $selectedClub, ')
          ..write('rawMetrics: $rawMetrics, ')
          ..write('timestamp: $timestamp, ')
          ..write('resolvedTargetDistance: $resolvedTargetDistance, ')
          ..write('resolvedTargetWidth: $resolvedTargetWidth, ')
          ..write('resolvedTargetDepth: $resolvedTargetDepth, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeEntriesTable extends PracticeEntries
    with TableInfo<$PracticeEntriesTable, PracticeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _practiceEntryIdMeta = const VerificationMeta(
    'practiceEntryId',
  );
  @override
  late final GeneratedColumn<String> practiceEntryId = GeneratedColumn<String>(
    'PracticeEntryID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _practiceBlockIdMeta = const VerificationMeta(
    'practiceBlockId',
  );
  @override
  late final GeneratedColumn<String> practiceBlockId = GeneratedColumn<String>(
    'PracticeBlockID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drillIdMeta = const VerificationMeta(
    'drillId',
  );
  @override
  late final GeneratedColumn<String> drillId = GeneratedColumn<String>(
    'DrillID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'SessionID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PracticeEntryType, String>
  entryType = GeneratedColumn<String>(
    'EntryType',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PendingDrill'),
  ).withConverter<PracticeEntryType>($PracticeEntriesTable.$converterentryType);
  static const VerificationMeta _positionIndexMeta = const VerificationMeta(
    'positionIndex',
  );
  @override
  late final GeneratedColumn<int> positionIndex = GeneratedColumn<int>(
    'PositionIndex',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    practiceEntryId,
    practiceBlockId,
    drillId,
    sessionId,
    entryType,
    positionIndex,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'PracticeEntry';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('PracticeEntryID')) {
      context.handle(
        _practiceEntryIdMeta,
        practiceEntryId.isAcceptableOrUnknown(
          data['PracticeEntryID']!,
          _practiceEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_practiceEntryIdMeta);
    }
    if (data.containsKey('PracticeBlockID')) {
      context.handle(
        _practiceBlockIdMeta,
        practiceBlockId.isAcceptableOrUnknown(
          data['PracticeBlockID']!,
          _practiceBlockIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_practiceBlockIdMeta);
    }
    if (data.containsKey('DrillID')) {
      context.handle(
        _drillIdMeta,
        drillId.isAcceptableOrUnknown(data['DrillID']!, _drillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_drillIdMeta);
    }
    if (data.containsKey('SessionID')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['SessionID']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('PositionIndex')) {
      context.handle(
        _positionIndexMeta,
        positionIndex.isAcceptableOrUnknown(
          data['PositionIndex']!,
          _positionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionIndexMeta);
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {practiceEntryId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {practiceBlockId, positionIndex},
  ];
  @override
  PracticeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeEntry(
      practiceEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}PracticeEntryID'],
      )!,
      practiceBlockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}PracticeBlockID'],
      )!,
      drillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DrillID'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SessionID'],
      ),
      entryType: $PracticeEntriesTable.$converterentryType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}EntryType'],
        )!,
      ),
      positionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}PositionIndex'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $PracticeEntriesTable createAlias(String alias) {
    return $PracticeEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<PracticeEntryType, String> $converterentryType =
      const PracticeEntryTypeConverter();
}

class PracticeEntry extends DataClass implements Insertable<PracticeEntry> {
  final String practiceEntryId;
  final String practiceBlockId;
  final String drillId;
  final String? sessionId;
  final PracticeEntryType entryType;
  final int positionIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PracticeEntry({
    required this.practiceEntryId,
    required this.practiceBlockId,
    required this.drillId,
    this.sessionId,
    required this.entryType,
    required this.positionIndex,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['PracticeEntryID'] = Variable<String>(practiceEntryId);
    map['PracticeBlockID'] = Variable<String>(practiceBlockId);
    map['DrillID'] = Variable<String>(drillId);
    if (!nullToAbsent || sessionId != null) {
      map['SessionID'] = Variable<String>(sessionId);
    }
    {
      map['EntryType'] = Variable<String>(
        $PracticeEntriesTable.$converterentryType.toSql(entryType),
      );
    }
    map['PositionIndex'] = Variable<int>(positionIndex);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PracticeEntriesCompanion toCompanion(bool nullToAbsent) {
    return PracticeEntriesCompanion(
      practiceEntryId: Value(practiceEntryId),
      practiceBlockId: Value(practiceBlockId),
      drillId: Value(drillId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      entryType: Value(entryType),
      positionIndex: Value(positionIndex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PracticeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeEntry(
      practiceEntryId: serializer.fromJson<String>(json['practiceEntryId']),
      practiceBlockId: serializer.fromJson<String>(json['practiceBlockId']),
      drillId: serializer.fromJson<String>(json['drillId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      entryType: serializer.fromJson<PracticeEntryType>(json['entryType']),
      positionIndex: serializer.fromJson<int>(json['positionIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'practiceEntryId': serializer.toJson<String>(practiceEntryId),
      'practiceBlockId': serializer.toJson<String>(practiceBlockId),
      'drillId': serializer.toJson<String>(drillId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'entryType': serializer.toJson<PracticeEntryType>(entryType),
      'positionIndex': serializer.toJson<int>(positionIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PracticeEntry copyWith({
    String? practiceEntryId,
    String? practiceBlockId,
    String? drillId,
    Value<String?> sessionId = const Value.absent(),
    PracticeEntryType? entryType,
    int? positionIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PracticeEntry(
    practiceEntryId: practiceEntryId ?? this.practiceEntryId,
    practiceBlockId: practiceBlockId ?? this.practiceBlockId,
    drillId: drillId ?? this.drillId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    entryType: entryType ?? this.entryType,
    positionIndex: positionIndex ?? this.positionIndex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PracticeEntry copyWithCompanion(PracticeEntriesCompanion data) {
    return PracticeEntry(
      practiceEntryId: data.practiceEntryId.present
          ? data.practiceEntryId.value
          : this.practiceEntryId,
      practiceBlockId: data.practiceBlockId.present
          ? data.practiceBlockId.value
          : this.practiceBlockId,
      drillId: data.drillId.present ? data.drillId.value : this.drillId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      positionIndex: data.positionIndex.present
          ? data.positionIndex.value
          : this.positionIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeEntry(')
          ..write('practiceEntryId: $practiceEntryId, ')
          ..write('practiceBlockId: $practiceBlockId, ')
          ..write('drillId: $drillId, ')
          ..write('sessionId: $sessionId, ')
          ..write('entryType: $entryType, ')
          ..write('positionIndex: $positionIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    practiceEntryId,
    practiceBlockId,
    drillId,
    sessionId,
    entryType,
    positionIndex,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeEntry &&
          other.practiceEntryId == this.practiceEntryId &&
          other.practiceBlockId == this.practiceBlockId &&
          other.drillId == this.drillId &&
          other.sessionId == this.sessionId &&
          other.entryType == this.entryType &&
          other.positionIndex == this.positionIndex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PracticeEntriesCompanion extends UpdateCompanion<PracticeEntry> {
  final Value<String> practiceEntryId;
  final Value<String> practiceBlockId;
  final Value<String> drillId;
  final Value<String?> sessionId;
  final Value<PracticeEntryType> entryType;
  final Value<int> positionIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PracticeEntriesCompanion({
    this.practiceEntryId = const Value.absent(),
    this.practiceBlockId = const Value.absent(),
    this.drillId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.positionIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeEntriesCompanion.insert({
    required String practiceEntryId,
    required String practiceBlockId,
    required String drillId,
    this.sessionId = const Value.absent(),
    this.entryType = const Value.absent(),
    required int positionIndex,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : practiceEntryId = Value(practiceEntryId),
       practiceBlockId = Value(practiceBlockId),
       drillId = Value(drillId),
       positionIndex = Value(positionIndex);
  static Insertable<PracticeEntry> custom({
    Expression<String>? practiceEntryId,
    Expression<String>? practiceBlockId,
    Expression<String>? drillId,
    Expression<String>? sessionId,
    Expression<String>? entryType,
    Expression<int>? positionIndex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (practiceEntryId != null) 'PracticeEntryID': practiceEntryId,
      if (practiceBlockId != null) 'PracticeBlockID': practiceBlockId,
      if (drillId != null) 'DrillID': drillId,
      if (sessionId != null) 'SessionID': sessionId,
      if (entryType != null) 'EntryType': entryType,
      if (positionIndex != null) 'PositionIndex': positionIndex,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeEntriesCompanion copyWith({
    Value<String>? practiceEntryId,
    Value<String>? practiceBlockId,
    Value<String>? drillId,
    Value<String?>? sessionId,
    Value<PracticeEntryType>? entryType,
    Value<int>? positionIndex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PracticeEntriesCompanion(
      practiceEntryId: practiceEntryId ?? this.practiceEntryId,
      practiceBlockId: practiceBlockId ?? this.practiceBlockId,
      drillId: drillId ?? this.drillId,
      sessionId: sessionId ?? this.sessionId,
      entryType: entryType ?? this.entryType,
      positionIndex: positionIndex ?? this.positionIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (practiceEntryId.present) {
      map['PracticeEntryID'] = Variable<String>(practiceEntryId.value);
    }
    if (practiceBlockId.present) {
      map['PracticeBlockID'] = Variable<String>(practiceBlockId.value);
    }
    if (drillId.present) {
      map['DrillID'] = Variable<String>(drillId.value);
    }
    if (sessionId.present) {
      map['SessionID'] = Variable<String>(sessionId.value);
    }
    if (entryType.present) {
      map['EntryType'] = Variable<String>(
        $PracticeEntriesTable.$converterentryType.toSql(entryType.value),
      );
    }
    if (positionIndex.present) {
      map['PositionIndex'] = Variable<int>(positionIndex.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeEntriesCompanion(')
          ..write('practiceEntryId: $practiceEntryId, ')
          ..write('practiceBlockId: $practiceBlockId, ')
          ..write('drillId: $drillId, ')
          ..write('sessionId: $sessionId, ')
          ..write('entryType: $entryType, ')
          ..write('positionIndex: $positionIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserDrillAdoptionsTable extends UserDrillAdoptions
    with TableInfo<$UserDrillAdoptionsTable, UserDrillAdoption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserDrillAdoptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userDrillAdoptionIdMeta =
      const VerificationMeta('userDrillAdoptionId');
  @override
  late final GeneratedColumn<String> userDrillAdoptionId =
      GeneratedColumn<String>(
        'UserDrillAdoptionID',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drillIdMeta = const VerificationMeta(
    'drillId',
  );
  @override
  late final GeneratedColumn<String> drillId = GeneratedColumn<String>(
    'DrillID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AdoptionStatus, String> status =
      GeneratedColumn<String>(
        'Status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Active'),
      ).withConverter<AdoptionStatus>(
        $UserDrillAdoptionsTable.$converterstatus,
      );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasUnseenUpdateMeta = const VerificationMeta(
    'hasUnseenUpdate',
  );
  @override
  late final GeneratedColumn<bool> hasUnseenUpdate = GeneratedColumn<bool>(
    'HasUnseenUpdate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("HasUnseenUpdate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userDrillAdoptionId,
    userId,
    drillId,
    status,
    isDeleted,
    hasUnseenUpdate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'UserDrillAdoption';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserDrillAdoption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('UserDrillAdoptionID')) {
      context.handle(
        _userDrillAdoptionIdMeta,
        userDrillAdoptionId.isAcceptableOrUnknown(
          data['UserDrillAdoptionID']!,
          _userDrillAdoptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userDrillAdoptionIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('DrillID')) {
      context.handle(
        _drillIdMeta,
        drillId.isAcceptableOrUnknown(data['DrillID']!, _drillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_drillIdMeta);
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('HasUnseenUpdate')) {
      context.handle(
        _hasUnseenUpdateMeta,
        hasUnseenUpdate.isAcceptableOrUnknown(
          data['HasUnseenUpdate']!,
          _hasUnseenUpdateMeta,
        ),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userDrillAdoptionId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, drillId},
  ];
  @override
  UserDrillAdoption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserDrillAdoption(
      userDrillAdoptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserDrillAdoptionID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      drillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DrillID'],
      )!,
      status: $UserDrillAdoptionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}Status'],
        )!,
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      hasUnseenUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}HasUnseenUpdate'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $UserDrillAdoptionsTable createAlias(String alias) {
    return $UserDrillAdoptionsTable(attachedDatabase, alias);
  }

  static TypeConverter<AdoptionStatus, String> $converterstatus =
      const AdoptionStatusConverter();
}

class UserDrillAdoption extends DataClass
    implements Insertable<UserDrillAdoption> {
  final String userDrillAdoptionId;
  final String userId;
  final String drillId;
  final AdoptionStatus status;
  final bool isDeleted;
  final bool hasUnseenUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserDrillAdoption({
    required this.userDrillAdoptionId,
    required this.userId,
    required this.drillId,
    required this.status,
    required this.isDeleted,
    required this.hasUnseenUpdate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['UserDrillAdoptionID'] = Variable<String>(userDrillAdoptionId);
    map['UserID'] = Variable<String>(userId);
    map['DrillID'] = Variable<String>(drillId);
    {
      map['Status'] = Variable<String>(
        $UserDrillAdoptionsTable.$converterstatus.toSql(status),
      );
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['HasUnseenUpdate'] = Variable<bool>(hasUnseenUpdate);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserDrillAdoptionsCompanion toCompanion(bool nullToAbsent) {
    return UserDrillAdoptionsCompanion(
      userDrillAdoptionId: Value(userDrillAdoptionId),
      userId: Value(userId),
      drillId: Value(drillId),
      status: Value(status),
      isDeleted: Value(isDeleted),
      hasUnseenUpdate: Value(hasUnseenUpdate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserDrillAdoption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserDrillAdoption(
      userDrillAdoptionId: serializer.fromJson<String>(
        json['userDrillAdoptionId'],
      ),
      userId: serializer.fromJson<String>(json['userId']),
      drillId: serializer.fromJson<String>(json['drillId']),
      status: serializer.fromJson<AdoptionStatus>(json['status']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      hasUnseenUpdate: serializer.fromJson<bool>(json['hasUnseenUpdate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userDrillAdoptionId': serializer.toJson<String>(userDrillAdoptionId),
      'userId': serializer.toJson<String>(userId),
      'drillId': serializer.toJson<String>(drillId),
      'status': serializer.toJson<AdoptionStatus>(status),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'hasUnseenUpdate': serializer.toJson<bool>(hasUnseenUpdate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserDrillAdoption copyWith({
    String? userDrillAdoptionId,
    String? userId,
    String? drillId,
    AdoptionStatus? status,
    bool? isDeleted,
    bool? hasUnseenUpdate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserDrillAdoption(
    userDrillAdoptionId: userDrillAdoptionId ?? this.userDrillAdoptionId,
    userId: userId ?? this.userId,
    drillId: drillId ?? this.drillId,
    status: status ?? this.status,
    isDeleted: isDeleted ?? this.isDeleted,
    hasUnseenUpdate: hasUnseenUpdate ?? this.hasUnseenUpdate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserDrillAdoption copyWithCompanion(UserDrillAdoptionsCompanion data) {
    return UserDrillAdoption(
      userDrillAdoptionId: data.userDrillAdoptionId.present
          ? data.userDrillAdoptionId.value
          : this.userDrillAdoptionId,
      userId: data.userId.present ? data.userId.value : this.userId,
      drillId: data.drillId.present ? data.drillId.value : this.drillId,
      status: data.status.present ? data.status.value : this.status,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      hasUnseenUpdate: data.hasUnseenUpdate.present
          ? data.hasUnseenUpdate.value
          : this.hasUnseenUpdate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserDrillAdoption(')
          ..write('userDrillAdoptionId: $userDrillAdoptionId, ')
          ..write('userId: $userId, ')
          ..write('drillId: $drillId, ')
          ..write('status: $status, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('hasUnseenUpdate: $hasUnseenUpdate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userDrillAdoptionId,
    userId,
    drillId,
    status,
    isDeleted,
    hasUnseenUpdate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserDrillAdoption &&
          other.userDrillAdoptionId == this.userDrillAdoptionId &&
          other.userId == this.userId &&
          other.drillId == this.drillId &&
          other.status == this.status &&
          other.isDeleted == this.isDeleted &&
          other.hasUnseenUpdate == this.hasUnseenUpdate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserDrillAdoptionsCompanion extends UpdateCompanion<UserDrillAdoption> {
  final Value<String> userDrillAdoptionId;
  final Value<String> userId;
  final Value<String> drillId;
  final Value<AdoptionStatus> status;
  final Value<bool> isDeleted;
  final Value<bool> hasUnseenUpdate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserDrillAdoptionsCompanion({
    this.userDrillAdoptionId = const Value.absent(),
    this.userId = const Value.absent(),
    this.drillId = const Value.absent(),
    this.status = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.hasUnseenUpdate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserDrillAdoptionsCompanion.insert({
    required String userDrillAdoptionId,
    required String userId,
    required String drillId,
    this.status = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.hasUnseenUpdate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userDrillAdoptionId = Value(userDrillAdoptionId),
       userId = Value(userId),
       drillId = Value(drillId);
  static Insertable<UserDrillAdoption> custom({
    Expression<String>? userDrillAdoptionId,
    Expression<String>? userId,
    Expression<String>? drillId,
    Expression<String>? status,
    Expression<bool>? isDeleted,
    Expression<bool>? hasUnseenUpdate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userDrillAdoptionId != null)
        'UserDrillAdoptionID': userDrillAdoptionId,
      if (userId != null) 'UserID': userId,
      if (drillId != null) 'DrillID': drillId,
      if (status != null) 'Status': status,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (hasUnseenUpdate != null) 'HasUnseenUpdate': hasUnseenUpdate,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserDrillAdoptionsCompanion copyWith({
    Value<String>? userDrillAdoptionId,
    Value<String>? userId,
    Value<String>? drillId,
    Value<AdoptionStatus>? status,
    Value<bool>? isDeleted,
    Value<bool>? hasUnseenUpdate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserDrillAdoptionsCompanion(
      userDrillAdoptionId: userDrillAdoptionId ?? this.userDrillAdoptionId,
      userId: userId ?? this.userId,
      drillId: drillId ?? this.drillId,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      hasUnseenUpdate: hasUnseenUpdate ?? this.hasUnseenUpdate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userDrillAdoptionId.present) {
      map['UserDrillAdoptionID'] = Variable<String>(userDrillAdoptionId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (drillId.present) {
      map['DrillID'] = Variable<String>(drillId.value);
    }
    if (status.present) {
      map['Status'] = Variable<String>(
        $UserDrillAdoptionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (hasUnseenUpdate.present) {
      map['HasUnseenUpdate'] = Variable<bool>(hasUnseenUpdate.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserDrillAdoptionsCompanion(')
          ..write('userDrillAdoptionId: $userDrillAdoptionId, ')
          ..write('userId: $userId, ')
          ..write('drillId: $drillId, ')
          ..write('status: $status, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('hasUnseenUpdate: $hasUnseenUpdate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserClubsTable extends UserClubs
    with TableInfo<$UserClubsTable, UserClub> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserClubsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'ClubID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ClubType, String> clubType =
      GeneratedColumn<String>(
        'ClubType',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ClubType>($UserClubsTable.$converterclubType);
  static const VerificationMeta _makeMeta = const VerificationMeta('make');
  @override
  late final GeneratedColumn<String> make = GeneratedColumn<String>(
    'Make',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'Model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loftMeta = const VerificationMeta('loft');
  @override
  late final GeneratedColumn<double> loft = GeneratedColumn<double>(
    'Loft',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<UserClubStatus, String> status =
      GeneratedColumn<String>(
        'Status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Active'),
      ).withConverter<UserClubStatus>($UserClubsTable.$converterstatus);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clubId,
    userId,
    clubType,
    make,
    model,
    loft,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'UserClub';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserClub> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ClubID')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['ClubID']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('Make')) {
      context.handle(
        _makeMeta,
        make.isAcceptableOrUnknown(data['Make']!, _makeMeta),
      );
    }
    if (data.containsKey('Model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['Model']!, _modelMeta),
      );
    }
    if (data.containsKey('Loft')) {
      context.handle(
        _loftMeta,
        loft.isAcceptableOrUnknown(data['Loft']!, _loftMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clubId};
  @override
  UserClub map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserClub(
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ClubID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      clubType: $UserClubsTable.$converterclubType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ClubType'],
        )!,
      ),
      make: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Make'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Model'],
      ),
      loft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}Loft'],
      ),
      status: $UserClubsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}Status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $UserClubsTable createAlias(String alias) {
    return $UserClubsTable(attachedDatabase, alias);
  }

  static TypeConverter<ClubType, String> $converterclubType =
      const ClubTypeConverter();
  static TypeConverter<UserClubStatus, String> $converterstatus =
      const UserClubStatusConverter();
}

class UserClub extends DataClass implements Insertable<UserClub> {
  final String clubId;
  final String userId;
  final ClubType clubType;
  final String? make;
  final String? model;
  final double? loft;
  final UserClubStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserClub({
    required this.clubId,
    required this.userId,
    required this.clubType,
    this.make,
    this.model,
    this.loft,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ClubID'] = Variable<String>(clubId);
    map['UserID'] = Variable<String>(userId);
    {
      map['ClubType'] = Variable<String>(
        $UserClubsTable.$converterclubType.toSql(clubType),
      );
    }
    if (!nullToAbsent || make != null) {
      map['Make'] = Variable<String>(make);
    }
    if (!nullToAbsent || model != null) {
      map['Model'] = Variable<String>(model);
    }
    if (!nullToAbsent || loft != null) {
      map['Loft'] = Variable<double>(loft);
    }
    {
      map['Status'] = Variable<String>(
        $UserClubsTable.$converterstatus.toSql(status),
      );
    }
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserClubsCompanion toCompanion(bool nullToAbsent) {
    return UserClubsCompanion(
      clubId: Value(clubId),
      userId: Value(userId),
      clubType: Value(clubType),
      make: make == null && nullToAbsent ? const Value.absent() : Value(make),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      loft: loft == null && nullToAbsent ? const Value.absent() : Value(loft),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserClub.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserClub(
      clubId: serializer.fromJson<String>(json['clubId']),
      userId: serializer.fromJson<String>(json['userId']),
      clubType: serializer.fromJson<ClubType>(json['clubType']),
      make: serializer.fromJson<String?>(json['make']),
      model: serializer.fromJson<String?>(json['model']),
      loft: serializer.fromJson<double?>(json['loft']),
      status: serializer.fromJson<UserClubStatus>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clubId': serializer.toJson<String>(clubId),
      'userId': serializer.toJson<String>(userId),
      'clubType': serializer.toJson<ClubType>(clubType),
      'make': serializer.toJson<String?>(make),
      'model': serializer.toJson<String?>(model),
      'loft': serializer.toJson<double?>(loft),
      'status': serializer.toJson<UserClubStatus>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserClub copyWith({
    String? clubId,
    String? userId,
    ClubType? clubType,
    Value<String?> make = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<double?> loft = const Value.absent(),
    UserClubStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserClub(
    clubId: clubId ?? this.clubId,
    userId: userId ?? this.userId,
    clubType: clubType ?? this.clubType,
    make: make.present ? make.value : this.make,
    model: model.present ? model.value : this.model,
    loft: loft.present ? loft.value : this.loft,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserClub copyWithCompanion(UserClubsCompanion data) {
    return UserClub(
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      userId: data.userId.present ? data.userId.value : this.userId,
      clubType: data.clubType.present ? data.clubType.value : this.clubType,
      make: data.make.present ? data.make.value : this.make,
      model: data.model.present ? data.model.value : this.model,
      loft: data.loft.present ? data.loft.value : this.loft,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserClub(')
          ..write('clubId: $clubId, ')
          ..write('userId: $userId, ')
          ..write('clubType: $clubType, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('loft: $loft, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clubId,
    userId,
    clubType,
    make,
    model,
    loft,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserClub &&
          other.clubId == this.clubId &&
          other.userId == this.userId &&
          other.clubType == this.clubType &&
          other.make == this.make &&
          other.model == this.model &&
          other.loft == this.loft &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserClubsCompanion extends UpdateCompanion<UserClub> {
  final Value<String> clubId;
  final Value<String> userId;
  final Value<ClubType> clubType;
  final Value<String?> make;
  final Value<String?> model;
  final Value<double?> loft;
  final Value<UserClubStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserClubsCompanion({
    this.clubId = const Value.absent(),
    this.userId = const Value.absent(),
    this.clubType = const Value.absent(),
    this.make = const Value.absent(),
    this.model = const Value.absent(),
    this.loft = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserClubsCompanion.insert({
    required String clubId,
    required String userId,
    required ClubType clubType,
    this.make = const Value.absent(),
    this.model = const Value.absent(),
    this.loft = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clubId = Value(clubId),
       userId = Value(userId),
       clubType = Value(clubType);
  static Insertable<UserClub> custom({
    Expression<String>? clubId,
    Expression<String>? userId,
    Expression<String>? clubType,
    Expression<String>? make,
    Expression<String>? model,
    Expression<double>? loft,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clubId != null) 'ClubID': clubId,
      if (userId != null) 'UserID': userId,
      if (clubType != null) 'ClubType': clubType,
      if (make != null) 'Make': make,
      if (model != null) 'Model': model,
      if (loft != null) 'Loft': loft,
      if (status != null) 'Status': status,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserClubsCompanion copyWith({
    Value<String>? clubId,
    Value<String>? userId,
    Value<ClubType>? clubType,
    Value<String?>? make,
    Value<String?>? model,
    Value<double?>? loft,
    Value<UserClubStatus>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserClubsCompanion(
      clubId: clubId ?? this.clubId,
      userId: userId ?? this.userId,
      clubType: clubType ?? this.clubType,
      make: make ?? this.make,
      model: model ?? this.model,
      loft: loft ?? this.loft,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clubId.present) {
      map['ClubID'] = Variable<String>(clubId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (clubType.present) {
      map['ClubType'] = Variable<String>(
        $UserClubsTable.$converterclubType.toSql(clubType.value),
      );
    }
    if (make.present) {
      map['Make'] = Variable<String>(make.value);
    }
    if (model.present) {
      map['Model'] = Variable<String>(model.value);
    }
    if (loft.present) {
      map['Loft'] = Variable<double>(loft.value);
    }
    if (status.present) {
      map['Status'] = Variable<String>(
        $UserClubsTable.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserClubsCompanion(')
          ..write('clubId: $clubId, ')
          ..write('userId: $userId, ')
          ..write('clubType: $clubType, ')
          ..write('make: $make, ')
          ..write('model: $model, ')
          ..write('loft: $loft, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClubPerformanceProfilesTable extends ClubPerformanceProfiles
    with TableInfo<$ClubPerformanceProfilesTable, ClubPerformanceProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClubPerformanceProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'ProfileID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'ClubID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveFromDateMeta = const VerificationMeta(
    'effectiveFromDate',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveFromDate =
      GeneratedColumn<DateTime>(
        'EffectiveFromDate',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _carryDistanceMeta = const VerificationMeta(
    'carryDistance',
  );
  @override
  late final GeneratedColumn<double> carryDistance = GeneratedColumn<double>(
    'CarryDistance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalDistanceMeta = const VerificationMeta(
    'totalDistance',
  );
  @override
  late final GeneratedColumn<double> totalDistance = GeneratedColumn<double>(
    'TotalDistance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dispersionLeftMeta = const VerificationMeta(
    'dispersionLeft',
  );
  @override
  late final GeneratedColumn<double> dispersionLeft = GeneratedColumn<double>(
    'DispersionLeft',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dispersionRightMeta = const VerificationMeta(
    'dispersionRight',
  );
  @override
  late final GeneratedColumn<double> dispersionRight = GeneratedColumn<double>(
    'DispersionRight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dispersionShortMeta = const VerificationMeta(
    'dispersionShort',
  );
  @override
  late final GeneratedColumn<double> dispersionShort = GeneratedColumn<double>(
    'DispersionShort',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dispersionLongMeta = const VerificationMeta(
    'dispersionLong',
  );
  @override
  late final GeneratedColumn<double> dispersionLong = GeneratedColumn<double>(
    'DispersionLong',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    clubId,
    effectiveFromDate,
    carryDistance,
    totalDistance,
    dispersionLeft,
    dispersionRight,
    dispersionShort,
    dispersionLong,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ClubPerformanceProfile';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClubPerformanceProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ProfileID')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['ProfileID']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('ClubID')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['ClubID']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('EffectiveFromDate')) {
      context.handle(
        _effectiveFromDateMeta,
        effectiveFromDate.isAcceptableOrUnknown(
          data['EffectiveFromDate']!,
          _effectiveFromDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveFromDateMeta);
    }
    if (data.containsKey('CarryDistance')) {
      context.handle(
        _carryDistanceMeta,
        carryDistance.isAcceptableOrUnknown(
          data['CarryDistance']!,
          _carryDistanceMeta,
        ),
      );
    }
    if (data.containsKey('TotalDistance')) {
      context.handle(
        _totalDistanceMeta,
        totalDistance.isAcceptableOrUnknown(
          data['TotalDistance']!,
          _totalDistanceMeta,
        ),
      );
    }
    if (data.containsKey('DispersionLeft')) {
      context.handle(
        _dispersionLeftMeta,
        dispersionLeft.isAcceptableOrUnknown(
          data['DispersionLeft']!,
          _dispersionLeftMeta,
        ),
      );
    }
    if (data.containsKey('DispersionRight')) {
      context.handle(
        _dispersionRightMeta,
        dispersionRight.isAcceptableOrUnknown(
          data['DispersionRight']!,
          _dispersionRightMeta,
        ),
      );
    }
    if (data.containsKey('DispersionShort')) {
      context.handle(
        _dispersionShortMeta,
        dispersionShort.isAcceptableOrUnknown(
          data['DispersionShort']!,
          _dispersionShortMeta,
        ),
      );
    }
    if (data.containsKey('DispersionLong')) {
      context.handle(
        _dispersionLongMeta,
        dispersionLong.isAcceptableOrUnknown(
          data['DispersionLong']!,
          _dispersionLongMeta,
        ),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  ClubPerformanceProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClubPerformanceProfile(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ProfileID'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ClubID'],
      )!,
      effectiveFromDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}EffectiveFromDate'],
      )!,
      carryDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}CarryDistance'],
      ),
      totalDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}TotalDistance'],
      ),
      dispersionLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}DispersionLeft'],
      ),
      dispersionRight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}DispersionRight'],
      ),
      dispersionShort: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}DispersionShort'],
      ),
      dispersionLong: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}DispersionLong'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $ClubPerformanceProfilesTable createAlias(String alias) {
    return $ClubPerformanceProfilesTable(attachedDatabase, alias);
  }
}

class ClubPerformanceProfile extends DataClass
    implements Insertable<ClubPerformanceProfile> {
  final String profileId;
  final String clubId;
  final DateTime effectiveFromDate;
  final double? carryDistance;
  final double? totalDistance;
  final double? dispersionLeft;
  final double? dispersionRight;
  final double? dispersionShort;
  final double? dispersionLong;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ClubPerformanceProfile({
    required this.profileId,
    required this.clubId,
    required this.effectiveFromDate,
    this.carryDistance,
    this.totalDistance,
    this.dispersionLeft,
    this.dispersionRight,
    this.dispersionShort,
    this.dispersionLong,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ProfileID'] = Variable<String>(profileId);
    map['ClubID'] = Variable<String>(clubId);
    map['EffectiveFromDate'] = Variable<DateTime>(effectiveFromDate);
    if (!nullToAbsent || carryDistance != null) {
      map['CarryDistance'] = Variable<double>(carryDistance);
    }
    if (!nullToAbsent || totalDistance != null) {
      map['TotalDistance'] = Variable<double>(totalDistance);
    }
    if (!nullToAbsent || dispersionLeft != null) {
      map['DispersionLeft'] = Variable<double>(dispersionLeft);
    }
    if (!nullToAbsent || dispersionRight != null) {
      map['DispersionRight'] = Variable<double>(dispersionRight);
    }
    if (!nullToAbsent || dispersionShort != null) {
      map['DispersionShort'] = Variable<double>(dispersionShort);
    }
    if (!nullToAbsent || dispersionLong != null) {
      map['DispersionLong'] = Variable<double>(dispersionLong);
    }
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ClubPerformanceProfilesCompanion toCompanion(bool nullToAbsent) {
    return ClubPerformanceProfilesCompanion(
      profileId: Value(profileId),
      clubId: Value(clubId),
      effectiveFromDate: Value(effectiveFromDate),
      carryDistance: carryDistance == null && nullToAbsent
          ? const Value.absent()
          : Value(carryDistance),
      totalDistance: totalDistance == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDistance),
      dispersionLeft: dispersionLeft == null && nullToAbsent
          ? const Value.absent()
          : Value(dispersionLeft),
      dispersionRight: dispersionRight == null && nullToAbsent
          ? const Value.absent()
          : Value(dispersionRight),
      dispersionShort: dispersionShort == null && nullToAbsent
          ? const Value.absent()
          : Value(dispersionShort),
      dispersionLong: dispersionLong == null && nullToAbsent
          ? const Value.absent()
          : Value(dispersionLong),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClubPerformanceProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClubPerformanceProfile(
      profileId: serializer.fromJson<String>(json['profileId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      effectiveFromDate: serializer.fromJson<DateTime>(
        json['effectiveFromDate'],
      ),
      carryDistance: serializer.fromJson<double?>(json['carryDistance']),
      totalDistance: serializer.fromJson<double?>(json['totalDistance']),
      dispersionLeft: serializer.fromJson<double?>(json['dispersionLeft']),
      dispersionRight: serializer.fromJson<double?>(json['dispersionRight']),
      dispersionShort: serializer.fromJson<double?>(json['dispersionShort']),
      dispersionLong: serializer.fromJson<double?>(json['dispersionLong']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<String>(profileId),
      'clubId': serializer.toJson<String>(clubId),
      'effectiveFromDate': serializer.toJson<DateTime>(effectiveFromDate),
      'carryDistance': serializer.toJson<double?>(carryDistance),
      'totalDistance': serializer.toJson<double?>(totalDistance),
      'dispersionLeft': serializer.toJson<double?>(dispersionLeft),
      'dispersionRight': serializer.toJson<double?>(dispersionRight),
      'dispersionShort': serializer.toJson<double?>(dispersionShort),
      'dispersionLong': serializer.toJson<double?>(dispersionLong),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ClubPerformanceProfile copyWith({
    String? profileId,
    String? clubId,
    DateTime? effectiveFromDate,
    Value<double?> carryDistance = const Value.absent(),
    Value<double?> totalDistance = const Value.absent(),
    Value<double?> dispersionLeft = const Value.absent(),
    Value<double?> dispersionRight = const Value.absent(),
    Value<double?> dispersionShort = const Value.absent(),
    Value<double?> dispersionLong = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ClubPerformanceProfile(
    profileId: profileId ?? this.profileId,
    clubId: clubId ?? this.clubId,
    effectiveFromDate: effectiveFromDate ?? this.effectiveFromDate,
    carryDistance: carryDistance.present
        ? carryDistance.value
        : this.carryDistance,
    totalDistance: totalDistance.present
        ? totalDistance.value
        : this.totalDistance,
    dispersionLeft: dispersionLeft.present
        ? dispersionLeft.value
        : this.dispersionLeft,
    dispersionRight: dispersionRight.present
        ? dispersionRight.value
        : this.dispersionRight,
    dispersionShort: dispersionShort.present
        ? dispersionShort.value
        : this.dispersionShort,
    dispersionLong: dispersionLong.present
        ? dispersionLong.value
        : this.dispersionLong,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ClubPerformanceProfile copyWithCompanion(
    ClubPerformanceProfilesCompanion data,
  ) {
    return ClubPerformanceProfile(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      effectiveFromDate: data.effectiveFromDate.present
          ? data.effectiveFromDate.value
          : this.effectiveFromDate,
      carryDistance: data.carryDistance.present
          ? data.carryDistance.value
          : this.carryDistance,
      totalDistance: data.totalDistance.present
          ? data.totalDistance.value
          : this.totalDistance,
      dispersionLeft: data.dispersionLeft.present
          ? data.dispersionLeft.value
          : this.dispersionLeft,
      dispersionRight: data.dispersionRight.present
          ? data.dispersionRight.value
          : this.dispersionRight,
      dispersionShort: data.dispersionShort.present
          ? data.dispersionShort.value
          : this.dispersionShort,
      dispersionLong: data.dispersionLong.present
          ? data.dispersionLong.value
          : this.dispersionLong,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClubPerformanceProfile(')
          ..write('profileId: $profileId, ')
          ..write('clubId: $clubId, ')
          ..write('effectiveFromDate: $effectiveFromDate, ')
          ..write('carryDistance: $carryDistance, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('dispersionLeft: $dispersionLeft, ')
          ..write('dispersionRight: $dispersionRight, ')
          ..write('dispersionShort: $dispersionShort, ')
          ..write('dispersionLong: $dispersionLong, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    profileId,
    clubId,
    effectiveFromDate,
    carryDistance,
    totalDistance,
    dispersionLeft,
    dispersionRight,
    dispersionShort,
    dispersionLong,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClubPerformanceProfile &&
          other.profileId == this.profileId &&
          other.clubId == this.clubId &&
          other.effectiveFromDate == this.effectiveFromDate &&
          other.carryDistance == this.carryDistance &&
          other.totalDistance == this.totalDistance &&
          other.dispersionLeft == this.dispersionLeft &&
          other.dispersionRight == this.dispersionRight &&
          other.dispersionShort == this.dispersionShort &&
          other.dispersionLong == this.dispersionLong &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClubPerformanceProfilesCompanion
    extends UpdateCompanion<ClubPerformanceProfile> {
  final Value<String> profileId;
  final Value<String> clubId;
  final Value<DateTime> effectiveFromDate;
  final Value<double?> carryDistance;
  final Value<double?> totalDistance;
  final Value<double?> dispersionLeft;
  final Value<double?> dispersionRight;
  final Value<double?> dispersionShort;
  final Value<double?> dispersionLong;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ClubPerformanceProfilesCompanion({
    this.profileId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.effectiveFromDate = const Value.absent(),
    this.carryDistance = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.dispersionLeft = const Value.absent(),
    this.dispersionRight = const Value.absent(),
    this.dispersionShort = const Value.absent(),
    this.dispersionLong = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClubPerformanceProfilesCompanion.insert({
    required String profileId,
    required String clubId,
    required DateTime effectiveFromDate,
    this.carryDistance = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.dispersionLeft = const Value.absent(),
    this.dispersionRight = const Value.absent(),
    this.dispersionShort = const Value.absent(),
    this.dispersionLong = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       clubId = Value(clubId),
       effectiveFromDate = Value(effectiveFromDate);
  static Insertable<ClubPerformanceProfile> custom({
    Expression<String>? profileId,
    Expression<String>? clubId,
    Expression<DateTime>? effectiveFromDate,
    Expression<double>? carryDistance,
    Expression<double>? totalDistance,
    Expression<double>? dispersionLeft,
    Expression<double>? dispersionRight,
    Expression<double>? dispersionShort,
    Expression<double>? dispersionLong,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'ProfileID': profileId,
      if (clubId != null) 'ClubID': clubId,
      if (effectiveFromDate != null) 'EffectiveFromDate': effectiveFromDate,
      if (carryDistance != null) 'CarryDistance': carryDistance,
      if (totalDistance != null) 'TotalDistance': totalDistance,
      if (dispersionLeft != null) 'DispersionLeft': dispersionLeft,
      if (dispersionRight != null) 'DispersionRight': dispersionRight,
      if (dispersionShort != null) 'DispersionShort': dispersionShort,
      if (dispersionLong != null) 'DispersionLong': dispersionLong,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClubPerformanceProfilesCompanion copyWith({
    Value<String>? profileId,
    Value<String>? clubId,
    Value<DateTime>? effectiveFromDate,
    Value<double?>? carryDistance,
    Value<double?>? totalDistance,
    Value<double?>? dispersionLeft,
    Value<double?>? dispersionRight,
    Value<double?>? dispersionShort,
    Value<double?>? dispersionLong,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ClubPerformanceProfilesCompanion(
      profileId: profileId ?? this.profileId,
      clubId: clubId ?? this.clubId,
      effectiveFromDate: effectiveFromDate ?? this.effectiveFromDate,
      carryDistance: carryDistance ?? this.carryDistance,
      totalDistance: totalDistance ?? this.totalDistance,
      dispersionLeft: dispersionLeft ?? this.dispersionLeft,
      dispersionRight: dispersionRight ?? this.dispersionRight,
      dispersionShort: dispersionShort ?? this.dispersionShort,
      dispersionLong: dispersionLong ?? this.dispersionLong,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['ProfileID'] = Variable<String>(profileId.value);
    }
    if (clubId.present) {
      map['ClubID'] = Variable<String>(clubId.value);
    }
    if (effectiveFromDate.present) {
      map['EffectiveFromDate'] = Variable<DateTime>(effectiveFromDate.value);
    }
    if (carryDistance.present) {
      map['CarryDistance'] = Variable<double>(carryDistance.value);
    }
    if (totalDistance.present) {
      map['TotalDistance'] = Variable<double>(totalDistance.value);
    }
    if (dispersionLeft.present) {
      map['DispersionLeft'] = Variable<double>(dispersionLeft.value);
    }
    if (dispersionRight.present) {
      map['DispersionRight'] = Variable<double>(dispersionRight.value);
    }
    if (dispersionShort.present) {
      map['DispersionShort'] = Variable<double>(dispersionShort.value);
    }
    if (dispersionLong.present) {
      map['DispersionLong'] = Variable<double>(dispersionLong.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClubPerformanceProfilesCompanion(')
          ..write('profileId: $profileId, ')
          ..write('clubId: $clubId, ')
          ..write('effectiveFromDate: $effectiveFromDate, ')
          ..write('carryDistance: $carryDistance, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('dispersionLeft: $dispersionLeft, ')
          ..write('dispersionRight: $dispersionRight, ')
          ..write('dispersionShort: $dispersionShort, ')
          ..write('dispersionLong: $dispersionLong, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSkillAreaClubMappingsTable extends UserSkillAreaClubMappings
    with TableInfo<$UserSkillAreaClubMappingsTable, UserSkillAreaClubMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSkillAreaClubMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mappingIdMeta = const VerificationMeta(
    'mappingId',
  );
  @override
  late final GeneratedColumn<String> mappingId = GeneratedColumn<String>(
    'MappingID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ClubType, String> clubType =
      GeneratedColumn<String>(
        'ClubType',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ClubType>(
        $UserSkillAreaClubMappingsTable.$converterclubType,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SkillArea, String> skillArea =
      GeneratedColumn<String>(
        'SkillArea',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillArea>(
        $UserSkillAreaClubMappingsTable.$converterskillArea,
      );
  static const VerificationMeta _isMandatoryMeta = const VerificationMeta(
    'isMandatory',
  );
  @override
  late final GeneratedColumn<bool> isMandatory = GeneratedColumn<bool>(
    'IsMandatory',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsMandatory" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    mappingId,
    userId,
    clubType,
    skillArea,
    isMandatory,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'UserSkillAreaClubMapping';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSkillAreaClubMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('MappingID')) {
      context.handle(
        _mappingIdMeta,
        mappingId.isAcceptableOrUnknown(data['MappingID']!, _mappingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mappingIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('IsMandatory')) {
      context.handle(
        _isMandatoryMeta,
        isMandatory.isAcceptableOrUnknown(
          data['IsMandatory']!,
          _isMandatoryMeta,
        ),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mappingId};
  @override
  UserSkillAreaClubMapping map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSkillAreaClubMapping(
      mappingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MappingID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      clubType: $UserSkillAreaClubMappingsTable.$converterclubType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ClubType'],
        )!,
      ),
      skillArea: $UserSkillAreaClubMappingsTable.$converterskillArea.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SkillArea'],
        )!,
      ),
      isMandatory: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsMandatory'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $UserSkillAreaClubMappingsTable createAlias(String alias) {
    return $UserSkillAreaClubMappingsTable(attachedDatabase, alias);
  }

  static TypeConverter<ClubType, String> $converterclubType =
      const ClubTypeConverter();
  static TypeConverter<SkillArea, String> $converterskillArea =
      const SkillAreaConverter();
}

class UserSkillAreaClubMapping extends DataClass
    implements Insertable<UserSkillAreaClubMapping> {
  final String mappingId;
  final String userId;
  final ClubType clubType;
  final SkillArea skillArea;
  final bool isMandatory;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserSkillAreaClubMapping({
    required this.mappingId,
    required this.userId,
    required this.clubType,
    required this.skillArea,
    required this.isMandatory,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['MappingID'] = Variable<String>(mappingId);
    map['UserID'] = Variable<String>(userId);
    {
      map['ClubType'] = Variable<String>(
        $UserSkillAreaClubMappingsTable.$converterclubType.toSql(clubType),
      );
    }
    {
      map['SkillArea'] = Variable<String>(
        $UserSkillAreaClubMappingsTable.$converterskillArea.toSql(skillArea),
      );
    }
    map['IsMandatory'] = Variable<bool>(isMandatory);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserSkillAreaClubMappingsCompanion toCompanion(bool nullToAbsent) {
    return UserSkillAreaClubMappingsCompanion(
      mappingId: Value(mappingId),
      userId: Value(userId),
      clubType: Value(clubType),
      skillArea: Value(skillArea),
      isMandatory: Value(isMandatory),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserSkillAreaClubMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSkillAreaClubMapping(
      mappingId: serializer.fromJson<String>(json['mappingId']),
      userId: serializer.fromJson<String>(json['userId']),
      clubType: serializer.fromJson<ClubType>(json['clubType']),
      skillArea: serializer.fromJson<SkillArea>(json['skillArea']),
      isMandatory: serializer.fromJson<bool>(json['isMandatory']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mappingId': serializer.toJson<String>(mappingId),
      'userId': serializer.toJson<String>(userId),
      'clubType': serializer.toJson<ClubType>(clubType),
      'skillArea': serializer.toJson<SkillArea>(skillArea),
      'isMandatory': serializer.toJson<bool>(isMandatory),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserSkillAreaClubMapping copyWith({
    String? mappingId,
    String? userId,
    ClubType? clubType,
    SkillArea? skillArea,
    bool? isMandatory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserSkillAreaClubMapping(
    mappingId: mappingId ?? this.mappingId,
    userId: userId ?? this.userId,
    clubType: clubType ?? this.clubType,
    skillArea: skillArea ?? this.skillArea,
    isMandatory: isMandatory ?? this.isMandatory,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserSkillAreaClubMapping copyWithCompanion(
    UserSkillAreaClubMappingsCompanion data,
  ) {
    return UserSkillAreaClubMapping(
      mappingId: data.mappingId.present ? data.mappingId.value : this.mappingId,
      userId: data.userId.present ? data.userId.value : this.userId,
      clubType: data.clubType.present ? data.clubType.value : this.clubType,
      skillArea: data.skillArea.present ? data.skillArea.value : this.skillArea,
      isMandatory: data.isMandatory.present
          ? data.isMandatory.value
          : this.isMandatory,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSkillAreaClubMapping(')
          ..write('mappingId: $mappingId, ')
          ..write('userId: $userId, ')
          ..write('clubType: $clubType, ')
          ..write('skillArea: $skillArea, ')
          ..write('isMandatory: $isMandatory, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mappingId,
    userId,
    clubType,
    skillArea,
    isMandatory,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSkillAreaClubMapping &&
          other.mappingId == this.mappingId &&
          other.userId == this.userId &&
          other.clubType == this.clubType &&
          other.skillArea == this.skillArea &&
          other.isMandatory == this.isMandatory &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserSkillAreaClubMappingsCompanion
    extends UpdateCompanion<UserSkillAreaClubMapping> {
  final Value<String> mappingId;
  final Value<String> userId;
  final Value<ClubType> clubType;
  final Value<SkillArea> skillArea;
  final Value<bool> isMandatory;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserSkillAreaClubMappingsCompanion({
    this.mappingId = const Value.absent(),
    this.userId = const Value.absent(),
    this.clubType = const Value.absent(),
    this.skillArea = const Value.absent(),
    this.isMandatory = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserSkillAreaClubMappingsCompanion.insert({
    required String mappingId,
    required String userId,
    required ClubType clubType,
    required SkillArea skillArea,
    this.isMandatory = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mappingId = Value(mappingId),
       userId = Value(userId),
       clubType = Value(clubType),
       skillArea = Value(skillArea);
  static Insertable<UserSkillAreaClubMapping> custom({
    Expression<String>? mappingId,
    Expression<String>? userId,
    Expression<String>? clubType,
    Expression<String>? skillArea,
    Expression<bool>? isMandatory,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mappingId != null) 'MappingID': mappingId,
      if (userId != null) 'UserID': userId,
      if (clubType != null) 'ClubType': clubType,
      if (skillArea != null) 'SkillArea': skillArea,
      if (isMandatory != null) 'IsMandatory': isMandatory,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserSkillAreaClubMappingsCompanion copyWith({
    Value<String>? mappingId,
    Value<String>? userId,
    Value<ClubType>? clubType,
    Value<SkillArea>? skillArea,
    Value<bool>? isMandatory,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserSkillAreaClubMappingsCompanion(
      mappingId: mappingId ?? this.mappingId,
      userId: userId ?? this.userId,
      clubType: clubType ?? this.clubType,
      skillArea: skillArea ?? this.skillArea,
      isMandatory: isMandatory ?? this.isMandatory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mappingId.present) {
      map['MappingID'] = Variable<String>(mappingId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (clubType.present) {
      map['ClubType'] = Variable<String>(
        $UserSkillAreaClubMappingsTable.$converterclubType.toSql(
          clubType.value,
        ),
      );
    }
    if (skillArea.present) {
      map['SkillArea'] = Variable<String>(
        $UserSkillAreaClubMappingsTable.$converterskillArea.toSql(
          skillArea.value,
        ),
      );
    }
    if (isMandatory.present) {
      map['IsMandatory'] = Variable<bool>(isMandatory.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSkillAreaClubMappingsCompanion(')
          ..write('mappingId: $mappingId, ')
          ..write('userId: $userId, ')
          ..write('clubType: $clubType, ')
          ..write('skillArea: $skillArea, ')
          ..write('isMandatory: $isMandatory, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutinesTable extends Routines with TableInfo<$RoutinesTable, Routine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
    'RoutineID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'Name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entriesMeta = const VerificationMeta(
    'entries',
  );
  @override
  late final GeneratedColumn<String> entries = GeneratedColumn<String>(
    'Entries',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RoutineStatus, String> status =
      GeneratedColumn<String>(
        'Status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Active'),
      ).withConverter<RoutineStatus>($RoutinesTable.$converterstatus);
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _lastAppliedAtMeta = const VerificationMeta(
    'lastAppliedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAppliedAt =
      GeneratedColumn<DateTime>(
        'LastAppliedAt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    routineId,
    userId,
    name,
    entries,
    status,
    isDeleted,
    createdAt,
    updatedAt,
    lastAppliedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Routine';
  @override
  VerificationContext validateIntegrity(
    Insertable<Routine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('RoutineID')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['RoutineID']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('Name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['Name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('Entries')) {
      context.handle(
        _entriesMeta,
        entries.isAcceptableOrUnknown(data['Entries']!, _entriesMeta),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('LastAppliedAt')) {
      context.handle(
        _lastAppliedAtMeta,
        lastAppliedAt.isAcceptableOrUnknown(
          data['LastAppliedAt']!,
          _lastAppliedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routineId};
  @override
  Routine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Routine(
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}RoutineID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Name'],
      )!,
      entries: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Entries'],
      )!,
      status: $RoutinesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}Status'],
        )!,
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
      lastAppliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}LastAppliedAt'],
      ),
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }

  static TypeConverter<RoutineStatus, String> $converterstatus =
      const RoutineStatusConverter();
}

class Routine extends DataClass implements Insertable<Routine> {
  final String routineId;
  final String userId;
  final String name;
  final String entries;
  final RoutineStatus status;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAppliedAt;
  const Routine({
    required this.routineId,
    required this.userId,
    required this.name,
    required this.entries,
    required this.status,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.lastAppliedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['RoutineID'] = Variable<String>(routineId);
    map['UserID'] = Variable<String>(userId);
    map['Name'] = Variable<String>(name);
    map['Entries'] = Variable<String>(entries);
    {
      map['Status'] = Variable<String>(
        $RoutinesTable.$converterstatus.toSql(status),
      );
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastAppliedAt != null) {
      map['LastAppliedAt'] = Variable<DateTime>(lastAppliedAt);
    }
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      routineId: Value(routineId),
      userId: Value(userId),
      name: Value(name),
      entries: Value(entries),
      status: Value(status),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastAppliedAt: lastAppliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAppliedAt),
    );
  }

  factory Routine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Routine(
      routineId: serializer.fromJson<String>(json['routineId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      entries: serializer.fromJson<String>(json['entries']),
      status: serializer.fromJson<RoutineStatus>(json['status']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastAppliedAt: serializer.fromJson<DateTime?>(json['lastAppliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routineId': serializer.toJson<String>(routineId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'entries': serializer.toJson<String>(entries),
      'status': serializer.toJson<RoutineStatus>(status),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastAppliedAt': serializer.toJson<DateTime?>(lastAppliedAt),
    };
  }

  Routine copyWith({
    String? routineId,
    String? userId,
    String? name,
    String? entries,
    RoutineStatus? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastAppliedAt = const Value.absent(),
  }) => Routine(
    routineId: routineId ?? this.routineId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    entries: entries ?? this.entries,
    status: status ?? this.status,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastAppliedAt: lastAppliedAt.present
        ? lastAppliedAt.value
        : this.lastAppliedAt,
  );
  Routine copyWithCompanion(RoutinesCompanion data) {
    return Routine(
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      entries: data.entries.present ? data.entries.value : this.entries,
      status: data.status.present ? data.status.value : this.status,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastAppliedAt: data.lastAppliedAt.present
          ? data.lastAppliedAt.value
          : this.lastAppliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Routine(')
          ..write('routineId: $routineId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('entries: $entries, ')
          ..write('status: $status, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAppliedAt: $lastAppliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    routineId,
    userId,
    name,
    entries,
    status,
    isDeleted,
    createdAt,
    updatedAt,
    lastAppliedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Routine &&
          other.routineId == this.routineId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.entries == this.entries &&
          other.status == this.status &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastAppliedAt == this.lastAppliedAt);
}

class RoutinesCompanion extends UpdateCompanion<Routine> {
  final Value<String> routineId;
  final Value<String> userId;
  final Value<String> name;
  final Value<String> entries;
  final Value<RoutineStatus> status;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastAppliedAt;
  final Value<int> rowid;
  const RoutinesCompanion({
    this.routineId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.entries = const Value.absent(),
    this.status = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastAppliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutinesCompanion.insert({
    required String routineId,
    required String userId,
    required String name,
    this.entries = const Value.absent(),
    this.status = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastAppliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : routineId = Value(routineId),
       userId = Value(userId),
       name = Value(name);
  static Insertable<Routine> custom({
    Expression<String>? routineId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? entries,
    Expression<String>? status,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastAppliedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routineId != null) 'RoutineID': routineId,
      if (userId != null) 'UserID': userId,
      if (name != null) 'Name': name,
      if (entries != null) 'Entries': entries,
      if (status != null) 'Status': status,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (lastAppliedAt != null) 'LastAppliedAt': lastAppliedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutinesCompanion copyWith({
    Value<String>? routineId,
    Value<String>? userId,
    Value<String>? name,
    Value<String>? entries,
    Value<RoutineStatus>? status,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastAppliedAt,
    Value<int>? rowid,
  }) {
    return RoutinesCompanion(
      routineId: routineId ?? this.routineId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      entries: entries ?? this.entries,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAppliedAt: lastAppliedAt ?? this.lastAppliedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routineId.present) {
      map['RoutineID'] = Variable<String>(routineId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['Name'] = Variable<String>(name.value);
    }
    if (entries.present) {
      map['Entries'] = Variable<String>(entries.value);
    }
    if (status.present) {
      map['Status'] = Variable<String>(
        $RoutinesTable.$converterstatus.toSql(status.value),
      );
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastAppliedAt.present) {
      map['LastAppliedAt'] = Variable<DateTime>(lastAppliedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('routineId: $routineId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('entries: $entries, ')
          ..write('status: $status, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAppliedAt: $lastAppliedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTable extends Schedules
    with TableInfo<$SchedulesTable, Schedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'ScheduleID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'Name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScheduleAppMode, String>
  applicationMode = GeneratedColumn<String>(
    'ApplicationMode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ScheduleAppMode>($SchedulesTable.$converterapplicationMode);
  static const VerificationMeta _entriesMeta = const VerificationMeta(
    'entries',
  );
  @override
  late final GeneratedColumn<String> entries = GeneratedColumn<String>(
    'Entries',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScheduleStatus, String> status =
      GeneratedColumn<String>(
        'Status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Active'),
      ).withConverter<ScheduleStatus>($SchedulesTable.$converterstatus);
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    scheduleId,
    userId,
    name,
    applicationMode,
    entries,
    status,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'Schedule';
  @override
  VerificationContext validateIntegrity(
    Insertable<Schedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ScheduleID')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['ScheduleID']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('Name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['Name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('Entries')) {
      context.handle(
        _entriesMeta,
        entries.isAcceptableOrUnknown(data['Entries']!, _entriesMeta),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId};
  @override
  Schedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Schedule(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ScheduleID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Name'],
      )!,
      applicationMode: $SchedulesTable.$converterapplicationMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ApplicationMode'],
        )!,
      ),
      entries: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Entries'],
      )!,
      status: $SchedulesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}Status'],
        )!,
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $SchedulesTable createAlias(String alias) {
    return $SchedulesTable(attachedDatabase, alias);
  }

  static TypeConverter<ScheduleAppMode, String> $converterapplicationMode =
      const ScheduleAppModeConverter();
  static TypeConverter<ScheduleStatus, String> $converterstatus =
      const ScheduleStatusConverter();
}

class Schedule extends DataClass implements Insertable<Schedule> {
  final String scheduleId;
  final String userId;
  final String name;
  final ScheduleAppMode applicationMode;
  final String entries;
  final ScheduleStatus status;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Schedule({
    required this.scheduleId,
    required this.userId,
    required this.name,
    required this.applicationMode,
    required this.entries,
    required this.status,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ScheduleID'] = Variable<String>(scheduleId);
    map['UserID'] = Variable<String>(userId);
    map['Name'] = Variable<String>(name);
    {
      map['ApplicationMode'] = Variable<String>(
        $SchedulesTable.$converterapplicationMode.toSql(applicationMode),
      );
    }
    map['Entries'] = Variable<String>(entries);
    {
      map['Status'] = Variable<String>(
        $SchedulesTable.$converterstatus.toSql(status),
      );
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SchedulesCompanion toCompanion(bool nullToAbsent) {
    return SchedulesCompanion(
      scheduleId: Value(scheduleId),
      userId: Value(userId),
      name: Value(name),
      applicationMode: Value(applicationMode),
      entries: Value(entries),
      status: Value(status),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Schedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Schedule(
      scheduleId: serializer.fromJson<String>(json['scheduleId']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      applicationMode: serializer.fromJson<ScheduleAppMode>(
        json['applicationMode'],
      ),
      entries: serializer.fromJson<String>(json['entries']),
      status: serializer.fromJson<ScheduleStatus>(json['status']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scheduleId': serializer.toJson<String>(scheduleId),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'applicationMode': serializer.toJson<ScheduleAppMode>(applicationMode),
      'entries': serializer.toJson<String>(entries),
      'status': serializer.toJson<ScheduleStatus>(status),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Schedule copyWith({
    String? scheduleId,
    String? userId,
    String? name,
    ScheduleAppMode? applicationMode,
    String? entries,
    ScheduleStatus? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Schedule(
    scheduleId: scheduleId ?? this.scheduleId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    applicationMode: applicationMode ?? this.applicationMode,
    entries: entries ?? this.entries,
    status: status ?? this.status,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Schedule copyWithCompanion(SchedulesCompanion data) {
    return Schedule(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      applicationMode: data.applicationMode.present
          ? data.applicationMode.value
          : this.applicationMode,
      entries: data.entries.present ? data.entries.value : this.entries,
      status: data.status.present ? data.status.value : this.status,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Schedule(')
          ..write('scheduleId: $scheduleId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('applicationMode: $applicationMode, ')
          ..write('entries: $entries, ')
          ..write('status: $status, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    scheduleId,
    userId,
    name,
    applicationMode,
    entries,
    status,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Schedule &&
          other.scheduleId == this.scheduleId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.applicationMode == this.applicationMode &&
          other.entries == this.entries &&
          other.status == this.status &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SchedulesCompanion extends UpdateCompanion<Schedule> {
  final Value<String> scheduleId;
  final Value<String> userId;
  final Value<String> name;
  final Value<ScheduleAppMode> applicationMode;
  final Value<String> entries;
  final Value<ScheduleStatus> status;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SchedulesCompanion({
    this.scheduleId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.applicationMode = const Value.absent(),
    this.entries = const Value.absent(),
    this.status = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedulesCompanion.insert({
    required String scheduleId,
    required String userId,
    required String name,
    required ScheduleAppMode applicationMode,
    this.entries = const Value.absent(),
    this.status = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       userId = Value(userId),
       name = Value(name),
       applicationMode = Value(applicationMode);
  static Insertable<Schedule> custom({
    Expression<String>? scheduleId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? applicationMode,
    Expression<String>? entries,
    Expression<String>? status,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'ScheduleID': scheduleId,
      if (userId != null) 'UserID': userId,
      if (name != null) 'Name': name,
      if (applicationMode != null) 'ApplicationMode': applicationMode,
      if (entries != null) 'Entries': entries,
      if (status != null) 'Status': status,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchedulesCompanion copyWith({
    Value<String>? scheduleId,
    Value<String>? userId,
    Value<String>? name,
    Value<ScheduleAppMode>? applicationMode,
    Value<String>? entries,
    Value<ScheduleStatus>? status,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SchedulesCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      applicationMode: applicationMode ?? this.applicationMode,
      entries: entries ?? this.entries,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['ScheduleID'] = Variable<String>(scheduleId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['Name'] = Variable<String>(name.value);
    }
    if (applicationMode.present) {
      map['ApplicationMode'] = Variable<String>(
        $SchedulesTable.$converterapplicationMode.toSql(applicationMode.value),
      );
    }
    if (entries.present) {
      map['Entries'] = Variable<String>(entries.value);
    }
    if (status.present) {
      map['Status'] = Variable<String>(
        $SchedulesTable.$converterstatus.toSql(status.value),
      );
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('applicationMode: $applicationMode, ')
          ..write('entries: $entries, ')
          ..write('status: $status, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarDaysTable extends CalendarDays
    with TableInfo<$CalendarDaysTable, CalendarDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _calendarDayIdMeta = const VerificationMeta(
    'calendarDayId',
  );
  @override
  late final GeneratedColumn<String> calendarDayId = GeneratedColumn<String>(
    'CalendarDayID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'Date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotCapacityMeta = const VerificationMeta(
    'slotCapacity',
  );
  @override
  late final GeneratedColumn<int> slotCapacity = GeneratedColumn<int>(
    'SlotCapacity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _slotsMeta = const VerificationMeta('slots');
  @override
  late final GeneratedColumn<String> slots = GeneratedColumn<String>(
    'Slots',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    calendarDayId,
    userId,
    date,
    slotCapacity,
    slots,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'CalendarDay';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('CalendarDayID')) {
      context.handle(
        _calendarDayIdMeta,
        calendarDayId.isAcceptableOrUnknown(
          data['CalendarDayID']!,
          _calendarDayIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calendarDayIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('Date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['Date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('SlotCapacity')) {
      context.handle(
        _slotCapacityMeta,
        slotCapacity.isAcceptableOrUnknown(
          data['SlotCapacity']!,
          _slotCapacityMeta,
        ),
      );
    }
    if (data.containsKey('Slots')) {
      context.handle(
        _slotsMeta,
        slots.isAcceptableOrUnknown(data['Slots']!, _slotsMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {calendarDayId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, date},
  ];
  @override
  CalendarDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarDay(
      calendarDayId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}CalendarDayID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}Date'],
      )!,
      slotCapacity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}SlotCapacity'],
      )!,
      slots: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Slots'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $CalendarDaysTable createAlias(String alias) {
    return $CalendarDaysTable(attachedDatabase, alias);
  }
}

class CalendarDay extends DataClass implements Insertable<CalendarDay> {
  final String calendarDayId;
  final String userId;
  final DateTime date;
  final int slotCapacity;
  final String slots;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalendarDay({
    required this.calendarDayId,
    required this.userId,
    required this.date,
    required this.slotCapacity,
    required this.slots,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['CalendarDayID'] = Variable<String>(calendarDayId);
    map['UserID'] = Variable<String>(userId);
    map['Date'] = Variable<DateTime>(date);
    map['SlotCapacity'] = Variable<int>(slotCapacity);
    map['Slots'] = Variable<String>(slots);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalendarDaysCompanion toCompanion(bool nullToAbsent) {
    return CalendarDaysCompanion(
      calendarDayId: Value(calendarDayId),
      userId: Value(userId),
      date: Value(date),
      slotCapacity: Value(slotCapacity),
      slots: Value(slots),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalendarDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarDay(
      calendarDayId: serializer.fromJson<String>(json['calendarDayId']),
      userId: serializer.fromJson<String>(json['userId']),
      date: serializer.fromJson<DateTime>(json['date']),
      slotCapacity: serializer.fromJson<int>(json['slotCapacity']),
      slots: serializer.fromJson<String>(json['slots']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'calendarDayId': serializer.toJson<String>(calendarDayId),
      'userId': serializer.toJson<String>(userId),
      'date': serializer.toJson<DateTime>(date),
      'slotCapacity': serializer.toJson<int>(slotCapacity),
      'slots': serializer.toJson<String>(slots),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalendarDay copyWith({
    String? calendarDayId,
    String? userId,
    DateTime? date,
    int? slotCapacity,
    String? slots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CalendarDay(
    calendarDayId: calendarDayId ?? this.calendarDayId,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    slotCapacity: slotCapacity ?? this.slotCapacity,
    slots: slots ?? this.slots,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CalendarDay copyWithCompanion(CalendarDaysCompanion data) {
    return CalendarDay(
      calendarDayId: data.calendarDayId.present
          ? data.calendarDayId.value
          : this.calendarDayId,
      userId: data.userId.present ? data.userId.value : this.userId,
      date: data.date.present ? data.date.value : this.date,
      slotCapacity: data.slotCapacity.present
          ? data.slotCapacity.value
          : this.slotCapacity,
      slots: data.slots.present ? data.slots.value : this.slots,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarDay(')
          ..write('calendarDayId: $calendarDayId, ')
          ..write('userId: $userId, ')
          ..write('date: $date, ')
          ..write('slotCapacity: $slotCapacity, ')
          ..write('slots: $slots, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    calendarDayId,
    userId,
    date,
    slotCapacity,
    slots,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarDay &&
          other.calendarDayId == this.calendarDayId &&
          other.userId == this.userId &&
          other.date == this.date &&
          other.slotCapacity == this.slotCapacity &&
          other.slots == this.slots &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalendarDaysCompanion extends UpdateCompanion<CalendarDay> {
  final Value<String> calendarDayId;
  final Value<String> userId;
  final Value<DateTime> date;
  final Value<int> slotCapacity;
  final Value<String> slots;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CalendarDaysCompanion({
    this.calendarDayId = const Value.absent(),
    this.userId = const Value.absent(),
    this.date = const Value.absent(),
    this.slotCapacity = const Value.absent(),
    this.slots = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarDaysCompanion.insert({
    required String calendarDayId,
    required String userId,
    required DateTime date,
    this.slotCapacity = const Value.absent(),
    this.slots = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : calendarDayId = Value(calendarDayId),
       userId = Value(userId),
       date = Value(date);
  static Insertable<CalendarDay> custom({
    Expression<String>? calendarDayId,
    Expression<String>? userId,
    Expression<DateTime>? date,
    Expression<int>? slotCapacity,
    Expression<String>? slots,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (calendarDayId != null) 'CalendarDayID': calendarDayId,
      if (userId != null) 'UserID': userId,
      if (date != null) 'Date': date,
      if (slotCapacity != null) 'SlotCapacity': slotCapacity,
      if (slots != null) 'Slots': slots,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarDaysCompanion copyWith({
    Value<String>? calendarDayId,
    Value<String>? userId,
    Value<DateTime>? date,
    Value<int>? slotCapacity,
    Value<String>? slots,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CalendarDaysCompanion(
      calendarDayId: calendarDayId ?? this.calendarDayId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      slotCapacity: slotCapacity ?? this.slotCapacity,
      slots: slots ?? this.slots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (calendarDayId.present) {
      map['CalendarDayID'] = Variable<String>(calendarDayId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (date.present) {
      map['Date'] = Variable<DateTime>(date.value);
    }
    if (slotCapacity.present) {
      map['SlotCapacity'] = Variable<int>(slotCapacity.value);
    }
    if (slots.present) {
      map['Slots'] = Variable<String>(slots.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarDaysCompanion(')
          ..write('calendarDayId: $calendarDayId, ')
          ..write('userId: $userId, ')
          ..write('date: $date, ')
          ..write('slotCapacity: $slotCapacity, ')
          ..write('slots: $slots, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutineInstancesTable extends RoutineInstances
    with TableInfo<$RoutineInstancesTable, RoutineInstance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineInstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routineInstanceIdMeta = const VerificationMeta(
    'routineInstanceId',
  );
  @override
  late final GeneratedColumn<String> routineInstanceId =
      GeneratedColumn<String>(
        'RoutineInstanceID',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
    'RoutineID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calendarDayDateMeta = const VerificationMeta(
    'calendarDayDate',
  );
  @override
  late final GeneratedColumn<DateTime> calendarDayDate =
      GeneratedColumn<DateTime>(
        'CalendarDayDate',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _ownedSlotsMeta = const VerificationMeta(
    'ownedSlots',
  );
  @override
  late final GeneratedColumn<String> ownedSlots = GeneratedColumn<String>(
    'OwnedSlots',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    routineInstanceId,
    routineId,
    userId,
    calendarDayDate,
    ownedSlots,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'RoutineInstance';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutineInstance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('RoutineInstanceID')) {
      context.handle(
        _routineInstanceIdMeta,
        routineInstanceId.isAcceptableOrUnknown(
          data['RoutineInstanceID']!,
          _routineInstanceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_routineInstanceIdMeta);
    }
    if (data.containsKey('RoutineID')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['RoutineID']!, _routineIdMeta),
      );
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('CalendarDayDate')) {
      context.handle(
        _calendarDayDateMeta,
        calendarDayDate.isAcceptableOrUnknown(
          data['CalendarDayDate']!,
          _calendarDayDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calendarDayDateMeta);
    }
    if (data.containsKey('OwnedSlots')) {
      context.handle(
        _ownedSlotsMeta,
        ownedSlots.isAcceptableOrUnknown(data['OwnedSlots']!, _ownedSlotsMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {routineInstanceId};
  @override
  RoutineInstance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineInstance(
      routineInstanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}RoutineInstanceID'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}RoutineID'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      calendarDayDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CalendarDayDate'],
      )!,
      ownedSlots: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}OwnedSlots'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $RoutineInstancesTable createAlias(String alias) {
    return $RoutineInstancesTable(attachedDatabase, alias);
  }
}

class RoutineInstance extends DataClass implements Insertable<RoutineInstance> {
  final String routineInstanceId;
  final String? routineId;
  final String userId;
  final DateTime calendarDayDate;
  final String ownedSlots;
  final DateTime createdAt;
  final DateTime updatedAt;
  const RoutineInstance({
    required this.routineInstanceId,
    this.routineId,
    required this.userId,
    required this.calendarDayDate,
    required this.ownedSlots,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['RoutineInstanceID'] = Variable<String>(routineInstanceId);
    if (!nullToAbsent || routineId != null) {
      map['RoutineID'] = Variable<String>(routineId);
    }
    map['UserID'] = Variable<String>(userId);
    map['CalendarDayDate'] = Variable<DateTime>(calendarDayDate);
    map['OwnedSlots'] = Variable<String>(ownedSlots);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RoutineInstancesCompanion toCompanion(bool nullToAbsent) {
    return RoutineInstancesCompanion(
      routineInstanceId: Value(routineInstanceId),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      userId: Value(userId),
      calendarDayDate: Value(calendarDayDate),
      ownedSlots: Value(ownedSlots),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RoutineInstance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineInstance(
      routineInstanceId: serializer.fromJson<String>(json['routineInstanceId']),
      routineId: serializer.fromJson<String?>(json['routineId']),
      userId: serializer.fromJson<String>(json['userId']),
      calendarDayDate: serializer.fromJson<DateTime>(json['calendarDayDate']),
      ownedSlots: serializer.fromJson<String>(json['ownedSlots']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routineInstanceId': serializer.toJson<String>(routineInstanceId),
      'routineId': serializer.toJson<String?>(routineId),
      'userId': serializer.toJson<String>(userId),
      'calendarDayDate': serializer.toJson<DateTime>(calendarDayDate),
      'ownedSlots': serializer.toJson<String>(ownedSlots),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  RoutineInstance copyWith({
    String? routineInstanceId,
    Value<String?> routineId = const Value.absent(),
    String? userId,
    DateTime? calendarDayDate,
    String? ownedSlots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => RoutineInstance(
    routineInstanceId: routineInstanceId ?? this.routineInstanceId,
    routineId: routineId.present ? routineId.value : this.routineId,
    userId: userId ?? this.userId,
    calendarDayDate: calendarDayDate ?? this.calendarDayDate,
    ownedSlots: ownedSlots ?? this.ownedSlots,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RoutineInstance copyWithCompanion(RoutineInstancesCompanion data) {
    return RoutineInstance(
      routineInstanceId: data.routineInstanceId.present
          ? data.routineInstanceId.value
          : this.routineInstanceId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      userId: data.userId.present ? data.userId.value : this.userId,
      calendarDayDate: data.calendarDayDate.present
          ? data.calendarDayDate.value
          : this.calendarDayDate,
      ownedSlots: data.ownedSlots.present
          ? data.ownedSlots.value
          : this.ownedSlots,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineInstance(')
          ..write('routineInstanceId: $routineInstanceId, ')
          ..write('routineId: $routineId, ')
          ..write('userId: $userId, ')
          ..write('calendarDayDate: $calendarDayDate, ')
          ..write('ownedSlots: $ownedSlots, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    routineInstanceId,
    routineId,
    userId,
    calendarDayDate,
    ownedSlots,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineInstance &&
          other.routineInstanceId == this.routineInstanceId &&
          other.routineId == this.routineId &&
          other.userId == this.userId &&
          other.calendarDayDate == this.calendarDayDate &&
          other.ownedSlots == this.ownedSlots &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RoutineInstancesCompanion extends UpdateCompanion<RoutineInstance> {
  final Value<String> routineInstanceId;
  final Value<String?> routineId;
  final Value<String> userId;
  final Value<DateTime> calendarDayDate;
  final Value<String> ownedSlots;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RoutineInstancesCompanion({
    this.routineInstanceId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.userId = const Value.absent(),
    this.calendarDayDate = const Value.absent(),
    this.ownedSlots = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineInstancesCompanion.insert({
    required String routineInstanceId,
    this.routineId = const Value.absent(),
    required String userId,
    required DateTime calendarDayDate,
    this.ownedSlots = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : routineInstanceId = Value(routineInstanceId),
       userId = Value(userId),
       calendarDayDate = Value(calendarDayDate);
  static Insertable<RoutineInstance> custom({
    Expression<String>? routineInstanceId,
    Expression<String>? routineId,
    Expression<String>? userId,
    Expression<DateTime>? calendarDayDate,
    Expression<String>? ownedSlots,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routineInstanceId != null) 'RoutineInstanceID': routineInstanceId,
      if (routineId != null) 'RoutineID': routineId,
      if (userId != null) 'UserID': userId,
      if (calendarDayDate != null) 'CalendarDayDate': calendarDayDate,
      if (ownedSlots != null) 'OwnedSlots': ownedSlots,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineInstancesCompanion copyWith({
    Value<String>? routineInstanceId,
    Value<String?>? routineId,
    Value<String>? userId,
    Value<DateTime>? calendarDayDate,
    Value<String>? ownedSlots,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RoutineInstancesCompanion(
      routineInstanceId: routineInstanceId ?? this.routineInstanceId,
      routineId: routineId ?? this.routineId,
      userId: userId ?? this.userId,
      calendarDayDate: calendarDayDate ?? this.calendarDayDate,
      ownedSlots: ownedSlots ?? this.ownedSlots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routineInstanceId.present) {
      map['RoutineInstanceID'] = Variable<String>(routineInstanceId.value);
    }
    if (routineId.present) {
      map['RoutineID'] = Variable<String>(routineId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (calendarDayDate.present) {
      map['CalendarDayDate'] = Variable<DateTime>(calendarDayDate.value);
    }
    if (ownedSlots.present) {
      map['OwnedSlots'] = Variable<String>(ownedSlots.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineInstancesCompanion(')
          ..write('routineInstanceId: $routineInstanceId, ')
          ..write('routineId: $routineId, ')
          ..write('userId: $userId, ')
          ..write('calendarDayDate: $calendarDayDate, ')
          ..write('ownedSlots: $ownedSlots, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduleInstancesTable extends ScheduleInstances
    with TableInfo<$ScheduleInstancesTable, ScheduleInstance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleInstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleInstanceIdMeta =
      const VerificationMeta('scheduleInstanceId');
  @override
  late final GeneratedColumn<String> scheduleInstanceId =
      GeneratedColumn<String>(
        'ScheduleInstanceID',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'ScheduleID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'StartDate',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'EndDate',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownedSlotsMeta = const VerificationMeta(
    'ownedSlots',
  );
  @override
  late final GeneratedColumn<String> ownedSlots = GeneratedColumn<String>(
    'OwnedSlots',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    scheduleInstanceId,
    scheduleId,
    userId,
    startDate,
    endDate,
    ownedSlots,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ScheduleInstance';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleInstance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ScheduleInstanceID')) {
      context.handle(
        _scheduleInstanceIdMeta,
        scheduleInstanceId.isAcceptableOrUnknown(
          data['ScheduleInstanceID']!,
          _scheduleInstanceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleInstanceIdMeta);
    }
    if (data.containsKey('ScheduleID')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['ScheduleID']!, _scheduleIdMeta),
      );
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('StartDate')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['StartDate']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('EndDate')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['EndDate']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('OwnedSlots')) {
      context.handle(
        _ownedSlotsMeta,
        ownedSlots.isAcceptableOrUnknown(data['OwnedSlots']!, _ownedSlotsMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleInstanceId};
  @override
  ScheduleInstance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleInstance(
      scheduleInstanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ScheduleInstanceID'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ScheduleID'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}StartDate'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}EndDate'],
      )!,
      ownedSlots: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}OwnedSlots'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $ScheduleInstancesTable createAlias(String alias) {
    return $ScheduleInstancesTable(attachedDatabase, alias);
  }
}

class ScheduleInstance extends DataClass
    implements Insertable<ScheduleInstance> {
  final String scheduleInstanceId;
  final String? scheduleId;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String ownedSlots;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ScheduleInstance({
    required this.scheduleInstanceId,
    this.scheduleId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.ownedSlots,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ScheduleInstanceID'] = Variable<String>(scheduleInstanceId);
    if (!nullToAbsent || scheduleId != null) {
      map['ScheduleID'] = Variable<String>(scheduleId);
    }
    map['UserID'] = Variable<String>(userId);
    map['StartDate'] = Variable<DateTime>(startDate);
    map['EndDate'] = Variable<DateTime>(endDate);
    map['OwnedSlots'] = Variable<String>(ownedSlots);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ScheduleInstancesCompanion toCompanion(bool nullToAbsent) {
    return ScheduleInstancesCompanion(
      scheduleInstanceId: Value(scheduleInstanceId),
      scheduleId: scheduleId == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleId),
      userId: Value(userId),
      startDate: Value(startDate),
      endDate: Value(endDate),
      ownedSlots: Value(ownedSlots),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ScheduleInstance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleInstance(
      scheduleInstanceId: serializer.fromJson<String>(
        json['scheduleInstanceId'],
      ),
      scheduleId: serializer.fromJson<String?>(json['scheduleId']),
      userId: serializer.fromJson<String>(json['userId']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      ownedSlots: serializer.fromJson<String>(json['ownedSlots']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scheduleInstanceId': serializer.toJson<String>(scheduleInstanceId),
      'scheduleId': serializer.toJson<String?>(scheduleId),
      'userId': serializer.toJson<String>(userId),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'ownedSlots': serializer.toJson<String>(ownedSlots),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ScheduleInstance copyWith({
    String? scheduleInstanceId,
    Value<String?> scheduleId = const Value.absent(),
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? ownedSlots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ScheduleInstance(
    scheduleInstanceId: scheduleInstanceId ?? this.scheduleInstanceId,
    scheduleId: scheduleId.present ? scheduleId.value : this.scheduleId,
    userId: userId ?? this.userId,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    ownedSlots: ownedSlots ?? this.ownedSlots,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ScheduleInstance copyWithCompanion(ScheduleInstancesCompanion data) {
    return ScheduleInstance(
      scheduleInstanceId: data.scheduleInstanceId.present
          ? data.scheduleInstanceId.value
          : this.scheduleInstanceId,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      userId: data.userId.present ? data.userId.value : this.userId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      ownedSlots: data.ownedSlots.present
          ? data.ownedSlots.value
          : this.ownedSlots,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleInstance(')
          ..write('scheduleInstanceId: $scheduleInstanceId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('userId: $userId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('ownedSlots: $ownedSlots, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    scheduleInstanceId,
    scheduleId,
    userId,
    startDate,
    endDate,
    ownedSlots,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleInstance &&
          other.scheduleInstanceId == this.scheduleInstanceId &&
          other.scheduleId == this.scheduleId &&
          other.userId == this.userId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.ownedSlots == this.ownedSlots &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ScheduleInstancesCompanion extends UpdateCompanion<ScheduleInstance> {
  final Value<String> scheduleInstanceId;
  final Value<String?> scheduleId;
  final Value<String> userId;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String> ownedSlots;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ScheduleInstancesCompanion({
    this.scheduleInstanceId = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.userId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.ownedSlots = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduleInstancesCompanion.insert({
    required String scheduleInstanceId,
    this.scheduleId = const Value.absent(),
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    this.ownedSlots = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scheduleInstanceId = Value(scheduleInstanceId),
       userId = Value(userId),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<ScheduleInstance> custom({
    Expression<String>? scheduleInstanceId,
    Expression<String>? scheduleId,
    Expression<String>? userId,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? ownedSlots,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleInstanceId != null) 'ScheduleInstanceID': scheduleInstanceId,
      if (scheduleId != null) 'ScheduleID': scheduleId,
      if (userId != null) 'UserID': userId,
      if (startDate != null) 'StartDate': startDate,
      if (endDate != null) 'EndDate': endDate,
      if (ownedSlots != null) 'OwnedSlots': ownedSlots,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduleInstancesCompanion copyWith({
    Value<String>? scheduleInstanceId,
    Value<String?>? scheduleId,
    Value<String>? userId,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<String>? ownedSlots,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ScheduleInstancesCompanion(
      scheduleInstanceId: scheduleInstanceId ?? this.scheduleInstanceId,
      scheduleId: scheduleId ?? this.scheduleId,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ownedSlots: ownedSlots ?? this.ownedSlots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleInstanceId.present) {
      map['ScheduleInstanceID'] = Variable<String>(scheduleInstanceId.value);
    }
    if (scheduleId.present) {
      map['ScheduleID'] = Variable<String>(scheduleId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (startDate.present) {
      map['StartDate'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['EndDate'] = Variable<DateTime>(endDate.value);
    }
    if (ownedSlots.present) {
      map['OwnedSlots'] = Variable<String>(ownedSlots.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleInstancesCompanion(')
          ..write('scheduleInstanceId: $scheduleInstanceId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('userId: $userId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('ownedSlots: $ownedSlots, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialisedWindowStatesTable extends MaterialisedWindowStates
    with TableInfo<$MaterialisedWindowStatesTable, MaterialisedWindowState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialisedWindowStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SkillArea, String> skillArea =
      GeneratedColumn<String>(
        'SkillArea',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillArea>(
        $MaterialisedWindowStatesTable.$converterskillArea,
      );
  static const VerificationMeta _subskillMeta = const VerificationMeta(
    'subskill',
  );
  @override
  late final GeneratedColumn<String> subskill = GeneratedColumn<String>(
    'Subskill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DrillType, String> practiceType =
      GeneratedColumn<String>(
        'PracticeType',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DrillType>(
        $MaterialisedWindowStatesTable.$converterpracticeType,
      );
  static const VerificationMeta _entriesMeta = const VerificationMeta(
    'entries',
  );
  @override
  late final GeneratedColumn<String> entries = GeneratedColumn<String>(
    'Entries',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _totalOccupancyMeta = const VerificationMeta(
    'totalOccupancy',
  );
  @override
  late final GeneratedColumn<double> totalOccupancy = GeneratedColumn<double>(
    'TotalOccupancy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weightedSumMeta = const VerificationMeta(
    'weightedSum',
  );
  @override
  late final GeneratedColumn<double> weightedSum = GeneratedColumn<double>(
    'WeightedSum',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _windowAverageMeta = const VerificationMeta(
    'windowAverage',
  );
  @override
  late final GeneratedColumn<double> windowAverage = GeneratedColumn<double>(
    'WindowAverage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    skillArea,
    subskill,
    practiceType,
    entries,
    totalOccupancy,
    weightedSum,
    windowAverage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MaterialisedWindowState';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaterialisedWindowState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('Subskill')) {
      context.handle(
        _subskillMeta,
        subskill.isAcceptableOrUnknown(data['Subskill']!, _subskillMeta),
      );
    } else if (isInserting) {
      context.missing(_subskillMeta);
    }
    if (data.containsKey('Entries')) {
      context.handle(
        _entriesMeta,
        entries.isAcceptableOrUnknown(data['Entries']!, _entriesMeta),
      );
    }
    if (data.containsKey('TotalOccupancy')) {
      context.handle(
        _totalOccupancyMeta,
        totalOccupancy.isAcceptableOrUnknown(
          data['TotalOccupancy']!,
          _totalOccupancyMeta,
        ),
      );
    }
    if (data.containsKey('WeightedSum')) {
      context.handle(
        _weightedSumMeta,
        weightedSum.isAcceptableOrUnknown(
          data['WeightedSum']!,
          _weightedSumMeta,
        ),
      );
    }
    if (data.containsKey('WindowAverage')) {
      context.handle(
        _windowAverageMeta,
        windowAverage.isAcceptableOrUnknown(
          data['WindowAverage']!,
          _windowAverageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    userId,
    skillArea,
    subskill,
    practiceType,
  };
  @override
  MaterialisedWindowState map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialisedWindowState(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      skillArea: $MaterialisedWindowStatesTable.$converterskillArea.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SkillArea'],
        )!,
      ),
      subskill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Subskill'],
      )!,
      practiceType: $MaterialisedWindowStatesTable.$converterpracticeType
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}PracticeType'],
            )!,
          ),
      entries: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Entries'],
      )!,
      totalOccupancy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}TotalOccupancy'],
      )!,
      weightedSum: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}WeightedSum'],
      )!,
      windowAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}WindowAverage'],
      )!,
    );
  }

  @override
  $MaterialisedWindowStatesTable createAlias(String alias) {
    return $MaterialisedWindowStatesTable(attachedDatabase, alias);
  }

  static TypeConverter<SkillArea, String> $converterskillArea =
      const SkillAreaConverter();
  static TypeConverter<DrillType, String> $converterpracticeType =
      const DrillTypeConverter();
}

class MaterialisedWindowState extends DataClass
    implements Insertable<MaterialisedWindowState> {
  final String userId;
  final SkillArea skillArea;
  final String subskill;
  final DrillType practiceType;
  final String entries;
  final double totalOccupancy;
  final double weightedSum;
  final double windowAverage;
  const MaterialisedWindowState({
    required this.userId,
    required this.skillArea,
    required this.subskill,
    required this.practiceType,
    required this.entries,
    required this.totalOccupancy,
    required this.weightedSum,
    required this.windowAverage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['UserID'] = Variable<String>(userId);
    {
      map['SkillArea'] = Variable<String>(
        $MaterialisedWindowStatesTable.$converterskillArea.toSql(skillArea),
      );
    }
    map['Subskill'] = Variable<String>(subskill);
    {
      map['PracticeType'] = Variable<String>(
        $MaterialisedWindowStatesTable.$converterpracticeType.toSql(
          practiceType,
        ),
      );
    }
    map['Entries'] = Variable<String>(entries);
    map['TotalOccupancy'] = Variable<double>(totalOccupancy);
    map['WeightedSum'] = Variable<double>(weightedSum);
    map['WindowAverage'] = Variable<double>(windowAverage);
    return map;
  }

  MaterialisedWindowStatesCompanion toCompanion(bool nullToAbsent) {
    return MaterialisedWindowStatesCompanion(
      userId: Value(userId),
      skillArea: Value(skillArea),
      subskill: Value(subskill),
      practiceType: Value(practiceType),
      entries: Value(entries),
      totalOccupancy: Value(totalOccupancy),
      weightedSum: Value(weightedSum),
      windowAverage: Value(windowAverage),
    );
  }

  factory MaterialisedWindowState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialisedWindowState(
      userId: serializer.fromJson<String>(json['userId']),
      skillArea: serializer.fromJson<SkillArea>(json['skillArea']),
      subskill: serializer.fromJson<String>(json['subskill']),
      practiceType: serializer.fromJson<DrillType>(json['practiceType']),
      entries: serializer.fromJson<String>(json['entries']),
      totalOccupancy: serializer.fromJson<double>(json['totalOccupancy']),
      weightedSum: serializer.fromJson<double>(json['weightedSum']),
      windowAverage: serializer.fromJson<double>(json['windowAverage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'skillArea': serializer.toJson<SkillArea>(skillArea),
      'subskill': serializer.toJson<String>(subskill),
      'practiceType': serializer.toJson<DrillType>(practiceType),
      'entries': serializer.toJson<String>(entries),
      'totalOccupancy': serializer.toJson<double>(totalOccupancy),
      'weightedSum': serializer.toJson<double>(weightedSum),
      'windowAverage': serializer.toJson<double>(windowAverage),
    };
  }

  MaterialisedWindowState copyWith({
    String? userId,
    SkillArea? skillArea,
    String? subskill,
    DrillType? practiceType,
    String? entries,
    double? totalOccupancy,
    double? weightedSum,
    double? windowAverage,
  }) => MaterialisedWindowState(
    userId: userId ?? this.userId,
    skillArea: skillArea ?? this.skillArea,
    subskill: subskill ?? this.subskill,
    practiceType: practiceType ?? this.practiceType,
    entries: entries ?? this.entries,
    totalOccupancy: totalOccupancy ?? this.totalOccupancy,
    weightedSum: weightedSum ?? this.weightedSum,
    windowAverage: windowAverage ?? this.windowAverage,
  );
  MaterialisedWindowState copyWithCompanion(
    MaterialisedWindowStatesCompanion data,
  ) {
    return MaterialisedWindowState(
      userId: data.userId.present ? data.userId.value : this.userId,
      skillArea: data.skillArea.present ? data.skillArea.value : this.skillArea,
      subskill: data.subskill.present ? data.subskill.value : this.subskill,
      practiceType: data.practiceType.present
          ? data.practiceType.value
          : this.practiceType,
      entries: data.entries.present ? data.entries.value : this.entries,
      totalOccupancy: data.totalOccupancy.present
          ? data.totalOccupancy.value
          : this.totalOccupancy,
      weightedSum: data.weightedSum.present
          ? data.weightedSum.value
          : this.weightedSum,
      windowAverage: data.windowAverage.present
          ? data.windowAverage.value
          : this.windowAverage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialisedWindowState(')
          ..write('userId: $userId, ')
          ..write('skillArea: $skillArea, ')
          ..write('subskill: $subskill, ')
          ..write('practiceType: $practiceType, ')
          ..write('entries: $entries, ')
          ..write('totalOccupancy: $totalOccupancy, ')
          ..write('weightedSum: $weightedSum, ')
          ..write('windowAverage: $windowAverage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    skillArea,
    subskill,
    practiceType,
    entries,
    totalOccupancy,
    weightedSum,
    windowAverage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialisedWindowState &&
          other.userId == this.userId &&
          other.skillArea == this.skillArea &&
          other.subskill == this.subskill &&
          other.practiceType == this.practiceType &&
          other.entries == this.entries &&
          other.totalOccupancy == this.totalOccupancy &&
          other.weightedSum == this.weightedSum &&
          other.windowAverage == this.windowAverage);
}

class MaterialisedWindowStatesCompanion
    extends UpdateCompanion<MaterialisedWindowState> {
  final Value<String> userId;
  final Value<SkillArea> skillArea;
  final Value<String> subskill;
  final Value<DrillType> practiceType;
  final Value<String> entries;
  final Value<double> totalOccupancy;
  final Value<double> weightedSum;
  final Value<double> windowAverage;
  final Value<int> rowid;
  const MaterialisedWindowStatesCompanion({
    this.userId = const Value.absent(),
    this.skillArea = const Value.absent(),
    this.subskill = const Value.absent(),
    this.practiceType = const Value.absent(),
    this.entries = const Value.absent(),
    this.totalOccupancy = const Value.absent(),
    this.weightedSum = const Value.absent(),
    this.windowAverage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialisedWindowStatesCompanion.insert({
    required String userId,
    required SkillArea skillArea,
    required String subskill,
    required DrillType practiceType,
    this.entries = const Value.absent(),
    this.totalOccupancy = const Value.absent(),
    this.weightedSum = const Value.absent(),
    this.windowAverage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       skillArea = Value(skillArea),
       subskill = Value(subskill),
       practiceType = Value(practiceType);
  static Insertable<MaterialisedWindowState> custom({
    Expression<String>? userId,
    Expression<String>? skillArea,
    Expression<String>? subskill,
    Expression<String>? practiceType,
    Expression<String>? entries,
    Expression<double>? totalOccupancy,
    Expression<double>? weightedSum,
    Expression<double>? windowAverage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'UserID': userId,
      if (skillArea != null) 'SkillArea': skillArea,
      if (subskill != null) 'Subskill': subskill,
      if (practiceType != null) 'PracticeType': practiceType,
      if (entries != null) 'Entries': entries,
      if (totalOccupancy != null) 'TotalOccupancy': totalOccupancy,
      if (weightedSum != null) 'WeightedSum': weightedSum,
      if (windowAverage != null) 'WindowAverage': windowAverage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialisedWindowStatesCompanion copyWith({
    Value<String>? userId,
    Value<SkillArea>? skillArea,
    Value<String>? subskill,
    Value<DrillType>? practiceType,
    Value<String>? entries,
    Value<double>? totalOccupancy,
    Value<double>? weightedSum,
    Value<double>? windowAverage,
    Value<int>? rowid,
  }) {
    return MaterialisedWindowStatesCompanion(
      userId: userId ?? this.userId,
      skillArea: skillArea ?? this.skillArea,
      subskill: subskill ?? this.subskill,
      practiceType: practiceType ?? this.practiceType,
      entries: entries ?? this.entries,
      totalOccupancy: totalOccupancy ?? this.totalOccupancy,
      weightedSum: weightedSum ?? this.weightedSum,
      windowAverage: windowAverage ?? this.windowAverage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (skillArea.present) {
      map['SkillArea'] = Variable<String>(
        $MaterialisedWindowStatesTable.$converterskillArea.toSql(
          skillArea.value,
        ),
      );
    }
    if (subskill.present) {
      map['Subskill'] = Variable<String>(subskill.value);
    }
    if (practiceType.present) {
      map['PracticeType'] = Variable<String>(
        $MaterialisedWindowStatesTable.$converterpracticeType.toSql(
          practiceType.value,
        ),
      );
    }
    if (entries.present) {
      map['Entries'] = Variable<String>(entries.value);
    }
    if (totalOccupancy.present) {
      map['TotalOccupancy'] = Variable<double>(totalOccupancy.value);
    }
    if (weightedSum.present) {
      map['WeightedSum'] = Variable<double>(weightedSum.value);
    }
    if (windowAverage.present) {
      map['WindowAverage'] = Variable<double>(windowAverage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialisedWindowStatesCompanion(')
          ..write('userId: $userId, ')
          ..write('skillArea: $skillArea, ')
          ..write('subskill: $subskill, ')
          ..write('practiceType: $practiceType, ')
          ..write('entries: $entries, ')
          ..write('totalOccupancy: $totalOccupancy, ')
          ..write('weightedSum: $weightedSum, ')
          ..write('windowAverage: $windowAverage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialisedSubskillScoresTable extends MaterialisedSubskillScores
    with
        TableInfo<$MaterialisedSubskillScoresTable, MaterialisedSubskillScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialisedSubskillScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SkillArea, String> skillArea =
      GeneratedColumn<String>(
        'SkillArea',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillArea>(
        $MaterialisedSubskillScoresTable.$converterskillArea,
      );
  static const VerificationMeta _subskillMeta = const VerificationMeta(
    'subskill',
  );
  @override
  late final GeneratedColumn<String> subskill = GeneratedColumn<String>(
    'Subskill',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transitionAverageMeta = const VerificationMeta(
    'transitionAverage',
  );
  @override
  late final GeneratedColumn<double> transitionAverage =
      GeneratedColumn<double>(
        'TransitionAverage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _pressureAverageMeta = const VerificationMeta(
    'pressureAverage',
  );
  @override
  late final GeneratedColumn<double> pressureAverage = GeneratedColumn<double>(
    'PressureAverage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _weightedAverageMeta = const VerificationMeta(
    'weightedAverage',
  );
  @override
  late final GeneratedColumn<double> weightedAverage = GeneratedColumn<double>(
    'WeightedAverage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subskillPointsMeta = const VerificationMeta(
    'subskillPoints',
  );
  @override
  late final GeneratedColumn<double> subskillPoints = GeneratedColumn<double>(
    'SubskillPoints',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _allocationMeta = const VerificationMeta(
    'allocation',
  );
  @override
  late final GeneratedColumn<int> allocation = GeneratedColumn<int>(
    'Allocation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    skillArea,
    subskill,
    transitionAverage,
    pressureAverage,
    weightedAverage,
    subskillPoints,
    allocation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MaterialisedSubskillScore';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaterialisedSubskillScore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('Subskill')) {
      context.handle(
        _subskillMeta,
        subskill.isAcceptableOrUnknown(data['Subskill']!, _subskillMeta),
      );
    } else if (isInserting) {
      context.missing(_subskillMeta);
    }
    if (data.containsKey('TransitionAverage')) {
      context.handle(
        _transitionAverageMeta,
        transitionAverage.isAcceptableOrUnknown(
          data['TransitionAverage']!,
          _transitionAverageMeta,
        ),
      );
    }
    if (data.containsKey('PressureAverage')) {
      context.handle(
        _pressureAverageMeta,
        pressureAverage.isAcceptableOrUnknown(
          data['PressureAverage']!,
          _pressureAverageMeta,
        ),
      );
    }
    if (data.containsKey('WeightedAverage')) {
      context.handle(
        _weightedAverageMeta,
        weightedAverage.isAcceptableOrUnknown(
          data['WeightedAverage']!,
          _weightedAverageMeta,
        ),
      );
    }
    if (data.containsKey('SubskillPoints')) {
      context.handle(
        _subskillPointsMeta,
        subskillPoints.isAcceptableOrUnknown(
          data['SubskillPoints']!,
          _subskillPointsMeta,
        ),
      );
    }
    if (data.containsKey('Allocation')) {
      context.handle(
        _allocationMeta,
        allocation.isAcceptableOrUnknown(data['Allocation']!, _allocationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, skillArea, subskill};
  @override
  MaterialisedSubskillScore map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialisedSubskillScore(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      skillArea: $MaterialisedSubskillScoresTable.$converterskillArea.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SkillArea'],
        )!,
      ),
      subskill: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Subskill'],
      )!,
      transitionAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}TransitionAverage'],
      )!,
      pressureAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}PressureAverage'],
      )!,
      weightedAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}WeightedAverage'],
      )!,
      subskillPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}SubskillPoints'],
      )!,
      allocation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Allocation'],
      )!,
    );
  }

  @override
  $MaterialisedSubskillScoresTable createAlias(String alias) {
    return $MaterialisedSubskillScoresTable(attachedDatabase, alias);
  }

  static TypeConverter<SkillArea, String> $converterskillArea =
      const SkillAreaConverter();
}

class MaterialisedSubskillScore extends DataClass
    implements Insertable<MaterialisedSubskillScore> {
  final String userId;
  final SkillArea skillArea;
  final String subskill;
  final double transitionAverage;
  final double pressureAverage;
  final double weightedAverage;
  final double subskillPoints;
  final int allocation;
  const MaterialisedSubskillScore({
    required this.userId,
    required this.skillArea,
    required this.subskill,
    required this.transitionAverage,
    required this.pressureAverage,
    required this.weightedAverage,
    required this.subskillPoints,
    required this.allocation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['UserID'] = Variable<String>(userId);
    {
      map['SkillArea'] = Variable<String>(
        $MaterialisedSubskillScoresTable.$converterskillArea.toSql(skillArea),
      );
    }
    map['Subskill'] = Variable<String>(subskill);
    map['TransitionAverage'] = Variable<double>(transitionAverage);
    map['PressureAverage'] = Variable<double>(pressureAverage);
    map['WeightedAverage'] = Variable<double>(weightedAverage);
    map['SubskillPoints'] = Variable<double>(subskillPoints);
    map['Allocation'] = Variable<int>(allocation);
    return map;
  }

  MaterialisedSubskillScoresCompanion toCompanion(bool nullToAbsent) {
    return MaterialisedSubskillScoresCompanion(
      userId: Value(userId),
      skillArea: Value(skillArea),
      subskill: Value(subskill),
      transitionAverage: Value(transitionAverage),
      pressureAverage: Value(pressureAverage),
      weightedAverage: Value(weightedAverage),
      subskillPoints: Value(subskillPoints),
      allocation: Value(allocation),
    );
  }

  factory MaterialisedSubskillScore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialisedSubskillScore(
      userId: serializer.fromJson<String>(json['userId']),
      skillArea: serializer.fromJson<SkillArea>(json['skillArea']),
      subskill: serializer.fromJson<String>(json['subskill']),
      transitionAverage: serializer.fromJson<double>(json['transitionAverage']),
      pressureAverage: serializer.fromJson<double>(json['pressureAverage']),
      weightedAverage: serializer.fromJson<double>(json['weightedAverage']),
      subskillPoints: serializer.fromJson<double>(json['subskillPoints']),
      allocation: serializer.fromJson<int>(json['allocation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'skillArea': serializer.toJson<SkillArea>(skillArea),
      'subskill': serializer.toJson<String>(subskill),
      'transitionAverage': serializer.toJson<double>(transitionAverage),
      'pressureAverage': serializer.toJson<double>(pressureAverage),
      'weightedAverage': serializer.toJson<double>(weightedAverage),
      'subskillPoints': serializer.toJson<double>(subskillPoints),
      'allocation': serializer.toJson<int>(allocation),
    };
  }

  MaterialisedSubskillScore copyWith({
    String? userId,
    SkillArea? skillArea,
    String? subskill,
    double? transitionAverage,
    double? pressureAverage,
    double? weightedAverage,
    double? subskillPoints,
    int? allocation,
  }) => MaterialisedSubskillScore(
    userId: userId ?? this.userId,
    skillArea: skillArea ?? this.skillArea,
    subskill: subskill ?? this.subskill,
    transitionAverage: transitionAverage ?? this.transitionAverage,
    pressureAverage: pressureAverage ?? this.pressureAverage,
    weightedAverage: weightedAverage ?? this.weightedAverage,
    subskillPoints: subskillPoints ?? this.subskillPoints,
    allocation: allocation ?? this.allocation,
  );
  MaterialisedSubskillScore copyWithCompanion(
    MaterialisedSubskillScoresCompanion data,
  ) {
    return MaterialisedSubskillScore(
      userId: data.userId.present ? data.userId.value : this.userId,
      skillArea: data.skillArea.present ? data.skillArea.value : this.skillArea,
      subskill: data.subskill.present ? data.subskill.value : this.subskill,
      transitionAverage: data.transitionAverage.present
          ? data.transitionAverage.value
          : this.transitionAverage,
      pressureAverage: data.pressureAverage.present
          ? data.pressureAverage.value
          : this.pressureAverage,
      weightedAverage: data.weightedAverage.present
          ? data.weightedAverage.value
          : this.weightedAverage,
      subskillPoints: data.subskillPoints.present
          ? data.subskillPoints.value
          : this.subskillPoints,
      allocation: data.allocation.present
          ? data.allocation.value
          : this.allocation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialisedSubskillScore(')
          ..write('userId: $userId, ')
          ..write('skillArea: $skillArea, ')
          ..write('subskill: $subskill, ')
          ..write('transitionAverage: $transitionAverage, ')
          ..write('pressureAverage: $pressureAverage, ')
          ..write('weightedAverage: $weightedAverage, ')
          ..write('subskillPoints: $subskillPoints, ')
          ..write('allocation: $allocation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    skillArea,
    subskill,
    transitionAverage,
    pressureAverage,
    weightedAverage,
    subskillPoints,
    allocation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialisedSubskillScore &&
          other.userId == this.userId &&
          other.skillArea == this.skillArea &&
          other.subskill == this.subskill &&
          other.transitionAverage == this.transitionAverage &&
          other.pressureAverage == this.pressureAverage &&
          other.weightedAverage == this.weightedAverage &&
          other.subskillPoints == this.subskillPoints &&
          other.allocation == this.allocation);
}

class MaterialisedSubskillScoresCompanion
    extends UpdateCompanion<MaterialisedSubskillScore> {
  final Value<String> userId;
  final Value<SkillArea> skillArea;
  final Value<String> subskill;
  final Value<double> transitionAverage;
  final Value<double> pressureAverage;
  final Value<double> weightedAverage;
  final Value<double> subskillPoints;
  final Value<int> allocation;
  final Value<int> rowid;
  const MaterialisedSubskillScoresCompanion({
    this.userId = const Value.absent(),
    this.skillArea = const Value.absent(),
    this.subskill = const Value.absent(),
    this.transitionAverage = const Value.absent(),
    this.pressureAverage = const Value.absent(),
    this.weightedAverage = const Value.absent(),
    this.subskillPoints = const Value.absent(),
    this.allocation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialisedSubskillScoresCompanion.insert({
    required String userId,
    required SkillArea skillArea,
    required String subskill,
    this.transitionAverage = const Value.absent(),
    this.pressureAverage = const Value.absent(),
    this.weightedAverage = const Value.absent(),
    this.subskillPoints = const Value.absent(),
    this.allocation = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       skillArea = Value(skillArea),
       subskill = Value(subskill);
  static Insertable<MaterialisedSubskillScore> custom({
    Expression<String>? userId,
    Expression<String>? skillArea,
    Expression<String>? subskill,
    Expression<double>? transitionAverage,
    Expression<double>? pressureAverage,
    Expression<double>? weightedAverage,
    Expression<double>? subskillPoints,
    Expression<int>? allocation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'UserID': userId,
      if (skillArea != null) 'SkillArea': skillArea,
      if (subskill != null) 'Subskill': subskill,
      if (transitionAverage != null) 'TransitionAverage': transitionAverage,
      if (pressureAverage != null) 'PressureAverage': pressureAverage,
      if (weightedAverage != null) 'WeightedAverage': weightedAverage,
      if (subskillPoints != null) 'SubskillPoints': subskillPoints,
      if (allocation != null) 'Allocation': allocation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialisedSubskillScoresCompanion copyWith({
    Value<String>? userId,
    Value<SkillArea>? skillArea,
    Value<String>? subskill,
    Value<double>? transitionAverage,
    Value<double>? pressureAverage,
    Value<double>? weightedAverage,
    Value<double>? subskillPoints,
    Value<int>? allocation,
    Value<int>? rowid,
  }) {
    return MaterialisedSubskillScoresCompanion(
      userId: userId ?? this.userId,
      skillArea: skillArea ?? this.skillArea,
      subskill: subskill ?? this.subskill,
      transitionAverage: transitionAverage ?? this.transitionAverage,
      pressureAverage: pressureAverage ?? this.pressureAverage,
      weightedAverage: weightedAverage ?? this.weightedAverage,
      subskillPoints: subskillPoints ?? this.subskillPoints,
      allocation: allocation ?? this.allocation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (skillArea.present) {
      map['SkillArea'] = Variable<String>(
        $MaterialisedSubskillScoresTable.$converterskillArea.toSql(
          skillArea.value,
        ),
      );
    }
    if (subskill.present) {
      map['Subskill'] = Variable<String>(subskill.value);
    }
    if (transitionAverage.present) {
      map['TransitionAverage'] = Variable<double>(transitionAverage.value);
    }
    if (pressureAverage.present) {
      map['PressureAverage'] = Variable<double>(pressureAverage.value);
    }
    if (weightedAverage.present) {
      map['WeightedAverage'] = Variable<double>(weightedAverage.value);
    }
    if (subskillPoints.present) {
      map['SubskillPoints'] = Variable<double>(subskillPoints.value);
    }
    if (allocation.present) {
      map['Allocation'] = Variable<int>(allocation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialisedSubskillScoresCompanion(')
          ..write('userId: $userId, ')
          ..write('skillArea: $skillArea, ')
          ..write('subskill: $subskill, ')
          ..write('transitionAverage: $transitionAverage, ')
          ..write('pressureAverage: $pressureAverage, ')
          ..write('weightedAverage: $weightedAverage, ')
          ..write('subskillPoints: $subskillPoints, ')
          ..write('allocation: $allocation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialisedSkillAreaScoresTable extends MaterialisedSkillAreaScores
    with
        TableInfo<
          $MaterialisedSkillAreaScoresTable,
          MaterialisedSkillAreaScore
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialisedSkillAreaScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SkillArea, String> skillArea =
      GeneratedColumn<String>(
        'SkillArea',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SkillArea>(
        $MaterialisedSkillAreaScoresTable.$converterskillArea,
      );
  static const VerificationMeta _skillAreaScoreMeta = const VerificationMeta(
    'skillAreaScore',
  );
  @override
  late final GeneratedColumn<double> skillAreaScore = GeneratedColumn<double>(
    'SkillAreaScore',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _allocationMeta = const VerificationMeta(
    'allocation',
  );
  @override
  late final GeneratedColumn<int> allocation = GeneratedColumn<int>(
    'Allocation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    skillArea,
    skillAreaScore,
    allocation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MaterialisedSkillAreaScore';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaterialisedSkillAreaScore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('SkillAreaScore')) {
      context.handle(
        _skillAreaScoreMeta,
        skillAreaScore.isAcceptableOrUnknown(
          data['SkillAreaScore']!,
          _skillAreaScoreMeta,
        ),
      );
    }
    if (data.containsKey('Allocation')) {
      context.handle(
        _allocationMeta,
        allocation.isAcceptableOrUnknown(data['Allocation']!, _allocationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, skillArea};
  @override
  MaterialisedSkillAreaScore map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialisedSkillAreaScore(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      skillArea: $MaterialisedSkillAreaScoresTable.$converterskillArea.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SkillArea'],
        )!,
      ),
      skillAreaScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}SkillAreaScore'],
      )!,
      allocation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}Allocation'],
      )!,
    );
  }

  @override
  $MaterialisedSkillAreaScoresTable createAlias(String alias) {
    return $MaterialisedSkillAreaScoresTable(attachedDatabase, alias);
  }

  static TypeConverter<SkillArea, String> $converterskillArea =
      const SkillAreaConverter();
}

class MaterialisedSkillAreaScore extends DataClass
    implements Insertable<MaterialisedSkillAreaScore> {
  final String userId;
  final SkillArea skillArea;
  final double skillAreaScore;
  final int allocation;
  const MaterialisedSkillAreaScore({
    required this.userId,
    required this.skillArea,
    required this.skillAreaScore,
    required this.allocation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['UserID'] = Variable<String>(userId);
    {
      map['SkillArea'] = Variable<String>(
        $MaterialisedSkillAreaScoresTable.$converterskillArea.toSql(skillArea),
      );
    }
    map['SkillAreaScore'] = Variable<double>(skillAreaScore);
    map['Allocation'] = Variable<int>(allocation);
    return map;
  }

  MaterialisedSkillAreaScoresCompanion toCompanion(bool nullToAbsent) {
    return MaterialisedSkillAreaScoresCompanion(
      userId: Value(userId),
      skillArea: Value(skillArea),
      skillAreaScore: Value(skillAreaScore),
      allocation: Value(allocation),
    );
  }

  factory MaterialisedSkillAreaScore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialisedSkillAreaScore(
      userId: serializer.fromJson<String>(json['userId']),
      skillArea: serializer.fromJson<SkillArea>(json['skillArea']),
      skillAreaScore: serializer.fromJson<double>(json['skillAreaScore']),
      allocation: serializer.fromJson<int>(json['allocation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'skillArea': serializer.toJson<SkillArea>(skillArea),
      'skillAreaScore': serializer.toJson<double>(skillAreaScore),
      'allocation': serializer.toJson<int>(allocation),
    };
  }

  MaterialisedSkillAreaScore copyWith({
    String? userId,
    SkillArea? skillArea,
    double? skillAreaScore,
    int? allocation,
  }) => MaterialisedSkillAreaScore(
    userId: userId ?? this.userId,
    skillArea: skillArea ?? this.skillArea,
    skillAreaScore: skillAreaScore ?? this.skillAreaScore,
    allocation: allocation ?? this.allocation,
  );
  MaterialisedSkillAreaScore copyWithCompanion(
    MaterialisedSkillAreaScoresCompanion data,
  ) {
    return MaterialisedSkillAreaScore(
      userId: data.userId.present ? data.userId.value : this.userId,
      skillArea: data.skillArea.present ? data.skillArea.value : this.skillArea,
      skillAreaScore: data.skillAreaScore.present
          ? data.skillAreaScore.value
          : this.skillAreaScore,
      allocation: data.allocation.present
          ? data.allocation.value
          : this.allocation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialisedSkillAreaScore(')
          ..write('userId: $userId, ')
          ..write('skillArea: $skillArea, ')
          ..write('skillAreaScore: $skillAreaScore, ')
          ..write('allocation: $allocation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, skillArea, skillAreaScore, allocation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialisedSkillAreaScore &&
          other.userId == this.userId &&
          other.skillArea == this.skillArea &&
          other.skillAreaScore == this.skillAreaScore &&
          other.allocation == this.allocation);
}

class MaterialisedSkillAreaScoresCompanion
    extends UpdateCompanion<MaterialisedSkillAreaScore> {
  final Value<String> userId;
  final Value<SkillArea> skillArea;
  final Value<double> skillAreaScore;
  final Value<int> allocation;
  final Value<int> rowid;
  const MaterialisedSkillAreaScoresCompanion({
    this.userId = const Value.absent(),
    this.skillArea = const Value.absent(),
    this.skillAreaScore = const Value.absent(),
    this.allocation = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialisedSkillAreaScoresCompanion.insert({
    required String userId,
    required SkillArea skillArea,
    this.skillAreaScore = const Value.absent(),
    this.allocation = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       skillArea = Value(skillArea);
  static Insertable<MaterialisedSkillAreaScore> custom({
    Expression<String>? userId,
    Expression<String>? skillArea,
    Expression<double>? skillAreaScore,
    Expression<int>? allocation,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'UserID': userId,
      if (skillArea != null) 'SkillArea': skillArea,
      if (skillAreaScore != null) 'SkillAreaScore': skillAreaScore,
      if (allocation != null) 'Allocation': allocation,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialisedSkillAreaScoresCompanion copyWith({
    Value<String>? userId,
    Value<SkillArea>? skillArea,
    Value<double>? skillAreaScore,
    Value<int>? allocation,
    Value<int>? rowid,
  }) {
    return MaterialisedSkillAreaScoresCompanion(
      userId: userId ?? this.userId,
      skillArea: skillArea ?? this.skillArea,
      skillAreaScore: skillAreaScore ?? this.skillAreaScore,
      allocation: allocation ?? this.allocation,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (skillArea.present) {
      map['SkillArea'] = Variable<String>(
        $MaterialisedSkillAreaScoresTable.$converterskillArea.toSql(
          skillArea.value,
        ),
      );
    }
    if (skillAreaScore.present) {
      map['SkillAreaScore'] = Variable<double>(skillAreaScore.value);
    }
    if (allocation.present) {
      map['Allocation'] = Variable<int>(allocation.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialisedSkillAreaScoresCompanion(')
          ..write('userId: $userId, ')
          ..write('skillArea: $skillArea, ')
          ..write('skillAreaScore: $skillAreaScore, ')
          ..write('allocation: $allocation, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaterialisedOverallScoresTable extends MaterialisedOverallScores
    with TableInfo<$MaterialisedOverallScoresTable, MaterialisedOverallScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaterialisedOverallScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overallScoreMeta = const VerificationMeta(
    'overallScore',
  );
  @override
  late final GeneratedColumn<double> overallScore = GeneratedColumn<double>(
    'OverallScore',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [userId, overallScore];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MaterialisedOverallScore';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaterialisedOverallScore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('OverallScore')) {
      context.handle(
        _overallScoreMeta,
        overallScore.isAcceptableOrUnknown(
          data['OverallScore']!,
          _overallScoreMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  MaterialisedOverallScore map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaterialisedOverallScore(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      overallScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}OverallScore'],
      )!,
    );
  }

  @override
  $MaterialisedOverallScoresTable createAlias(String alias) {
    return $MaterialisedOverallScoresTable(attachedDatabase, alias);
  }
}

class MaterialisedOverallScore extends DataClass
    implements Insertable<MaterialisedOverallScore> {
  final String userId;
  final double overallScore;
  const MaterialisedOverallScore({
    required this.userId,
    required this.overallScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['UserID'] = Variable<String>(userId);
    map['OverallScore'] = Variable<double>(overallScore);
    return map;
  }

  MaterialisedOverallScoresCompanion toCompanion(bool nullToAbsent) {
    return MaterialisedOverallScoresCompanion(
      userId: Value(userId),
      overallScore: Value(overallScore),
    );
  }

  factory MaterialisedOverallScore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaterialisedOverallScore(
      userId: serializer.fromJson<String>(json['userId']),
      overallScore: serializer.fromJson<double>(json['overallScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'overallScore': serializer.toJson<double>(overallScore),
    };
  }

  MaterialisedOverallScore copyWith({String? userId, double? overallScore}) =>
      MaterialisedOverallScore(
        userId: userId ?? this.userId,
        overallScore: overallScore ?? this.overallScore,
      );
  MaterialisedOverallScore copyWithCompanion(
    MaterialisedOverallScoresCompanion data,
  ) {
    return MaterialisedOverallScore(
      userId: data.userId.present ? data.userId.value : this.userId,
      overallScore: data.overallScore.present
          ? data.overallScore.value
          : this.overallScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaterialisedOverallScore(')
          ..write('userId: $userId, ')
          ..write('overallScore: $overallScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, overallScore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaterialisedOverallScore &&
          other.userId == this.userId &&
          other.overallScore == this.overallScore);
}

class MaterialisedOverallScoresCompanion
    extends UpdateCompanion<MaterialisedOverallScore> {
  final Value<String> userId;
  final Value<double> overallScore;
  final Value<int> rowid;
  const MaterialisedOverallScoresCompanion({
    this.userId = const Value.absent(),
    this.overallScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaterialisedOverallScoresCompanion.insert({
    required String userId,
    this.overallScore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<MaterialisedOverallScore> custom({
    Expression<String>? userId,
    Expression<double>? overallScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'UserID': userId,
      if (overallScore != null) 'OverallScore': overallScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaterialisedOverallScoresCompanion copyWith({
    Value<String>? userId,
    Value<double>? overallScore,
    Value<int>? rowid,
  }) {
    return MaterialisedOverallScoresCompanion(
      userId: userId ?? this.userId,
      overallScore: overallScore ?? this.overallScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (overallScore.present) {
      map['OverallScore'] = Variable<double>(overallScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaterialisedOverallScoresCompanion(')
          ..write('userId: $userId, ')
          ..write('overallScore: $overallScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventLogsTable extends EventLogs
    with TableInfo<$EventLogsTable, EventLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventLogIdMeta = const VerificationMeta(
    'eventLogId',
  );
  @override
  late final GeneratedColumn<String> eventLogId = GeneratedColumn<String>(
    'EventLogID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'DeviceID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTypeIdMeta = const VerificationMeta(
    'eventTypeId',
  );
  @override
  late final GeneratedColumn<String> eventTypeId = GeneratedColumn<String>(
    'EventTypeID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'Timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _affectedEntityIdsMeta = const VerificationMeta(
    'affectedEntityIds',
  );
  @override
  late final GeneratedColumn<String> affectedEntityIds =
      GeneratedColumn<String>(
        'AffectedEntityIDs',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _affectedSubskillsMeta = const VerificationMeta(
    'affectedSubskills',
  );
  @override
  late final GeneratedColumn<String> affectedSubskills =
      GeneratedColumn<String>(
        'AffectedSubskills',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'Metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventLogId,
    userId,
    deviceId,
    eventTypeId,
    timestamp,
    affectedEntityIds,
    affectedSubskills,
    metadata,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'EventLog';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('EventLogID')) {
      context.handle(
        _eventLogIdMeta,
        eventLogId.isAcceptableOrUnknown(data['EventLogID']!, _eventLogIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventLogIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('DeviceID')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['DeviceID']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('EventTypeID')) {
      context.handle(
        _eventTypeIdMeta,
        eventTypeId.isAcceptableOrUnknown(
          data['EventTypeID']!,
          _eventTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eventTypeIdMeta);
    }
    if (data.containsKey('Timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['Timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('AffectedEntityIDs')) {
      context.handle(
        _affectedEntityIdsMeta,
        affectedEntityIds.isAcceptableOrUnknown(
          data['AffectedEntityIDs']!,
          _affectedEntityIdsMeta,
        ),
      );
    }
    if (data.containsKey('AffectedSubskills')) {
      context.handle(
        _affectedSubskillsMeta,
        affectedSubskills.isAcceptableOrUnknown(
          data['AffectedSubskills']!,
          _affectedSubskillsMeta,
        ),
      );
    }
    if (data.containsKey('Metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['Metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventLogId};
  @override
  EventLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventLog(
      eventLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}EventLogID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DeviceID'],
      ),
      eventTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}EventTypeID'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}Timestamp'],
      )!,
      affectedEntityIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}AffectedEntityIDs'],
      ),
      affectedSubskills: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}AffectedSubskills'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
    );
  }

  @override
  $EventLogsTable createAlias(String alias) {
    return $EventLogsTable(attachedDatabase, alias);
  }
}

class EventLog extends DataClass implements Insertable<EventLog> {
  final String eventLogId;
  final String userId;
  final String? deviceId;
  final String eventTypeId;
  final DateTime timestamp;
  final String? affectedEntityIds;
  final String? affectedSubskills;
  final String? metadata;
  final DateTime createdAt;
  const EventLog({
    required this.eventLogId,
    required this.userId,
    this.deviceId,
    required this.eventTypeId,
    required this.timestamp,
    this.affectedEntityIds,
    this.affectedSubskills,
    this.metadata,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['EventLogID'] = Variable<String>(eventLogId);
    map['UserID'] = Variable<String>(userId);
    if (!nullToAbsent || deviceId != null) {
      map['DeviceID'] = Variable<String>(deviceId);
    }
    map['EventTypeID'] = Variable<String>(eventTypeId);
    map['Timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || affectedEntityIds != null) {
      map['AffectedEntityIDs'] = Variable<String>(affectedEntityIds);
    }
    if (!nullToAbsent || affectedSubskills != null) {
      map['AffectedSubskills'] = Variable<String>(affectedSubskills);
    }
    if (!nullToAbsent || metadata != null) {
      map['Metadata'] = Variable<String>(metadata);
    }
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventLogsCompanion toCompanion(bool nullToAbsent) {
    return EventLogsCompanion(
      eventLogId: Value(eventLogId),
      userId: Value(userId),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      eventTypeId: Value(eventTypeId),
      timestamp: Value(timestamp),
      affectedEntityIds: affectedEntityIds == null && nullToAbsent
          ? const Value.absent()
          : Value(affectedEntityIds),
      affectedSubskills: affectedSubskills == null && nullToAbsent
          ? const Value.absent()
          : Value(affectedSubskills),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
    );
  }

  factory EventLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventLog(
      eventLogId: serializer.fromJson<String>(json['eventLogId']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      eventTypeId: serializer.fromJson<String>(json['eventTypeId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      affectedEntityIds: serializer.fromJson<String?>(
        json['affectedEntityIds'],
      ),
      affectedSubskills: serializer.fromJson<String?>(
        json['affectedSubskills'],
      ),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventLogId': serializer.toJson<String>(eventLogId),
      'userId': serializer.toJson<String>(userId),
      'deviceId': serializer.toJson<String?>(deviceId),
      'eventTypeId': serializer.toJson<String>(eventTypeId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'affectedEntityIds': serializer.toJson<String?>(affectedEntityIds),
      'affectedSubskills': serializer.toJson<String?>(affectedSubskills),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  EventLog copyWith({
    String? eventLogId,
    String? userId,
    Value<String?> deviceId = const Value.absent(),
    String? eventTypeId,
    DateTime? timestamp,
    Value<String?> affectedEntityIds = const Value.absent(),
    Value<String?> affectedSubskills = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    DateTime? createdAt,
  }) => EventLog(
    eventLogId: eventLogId ?? this.eventLogId,
    userId: userId ?? this.userId,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    eventTypeId: eventTypeId ?? this.eventTypeId,
    timestamp: timestamp ?? this.timestamp,
    affectedEntityIds: affectedEntityIds.present
        ? affectedEntityIds.value
        : this.affectedEntityIds,
    affectedSubskills: affectedSubskills.present
        ? affectedSubskills.value
        : this.affectedSubskills,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
  );
  EventLog copyWithCompanion(EventLogsCompanion data) {
    return EventLog(
      eventLogId: data.eventLogId.present
          ? data.eventLogId.value
          : this.eventLogId,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      eventTypeId: data.eventTypeId.present
          ? data.eventTypeId.value
          : this.eventTypeId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      affectedEntityIds: data.affectedEntityIds.present
          ? data.affectedEntityIds.value
          : this.affectedEntityIds,
      affectedSubskills: data.affectedSubskills.present
          ? data.affectedSubskills.value
          : this.affectedSubskills,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventLog(')
          ..write('eventLogId: $eventLogId, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('eventTypeId: $eventTypeId, ')
          ..write('timestamp: $timestamp, ')
          ..write('affectedEntityIds: $affectedEntityIds, ')
          ..write('affectedSubskills: $affectedSubskills, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventLogId,
    userId,
    deviceId,
    eventTypeId,
    timestamp,
    affectedEntityIds,
    affectedSubskills,
    metadata,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventLog &&
          other.eventLogId == this.eventLogId &&
          other.userId == this.userId &&
          other.deviceId == this.deviceId &&
          other.eventTypeId == this.eventTypeId &&
          other.timestamp == this.timestamp &&
          other.affectedEntityIds == this.affectedEntityIds &&
          other.affectedSubskills == this.affectedSubskills &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt);
}

class EventLogsCompanion extends UpdateCompanion<EventLog> {
  final Value<String> eventLogId;
  final Value<String> userId;
  final Value<String?> deviceId;
  final Value<String> eventTypeId;
  final Value<DateTime> timestamp;
  final Value<String?> affectedEntityIds;
  final Value<String?> affectedSubskills;
  final Value<String?> metadata;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EventLogsCompanion({
    this.eventLogId = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.eventTypeId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.affectedEntityIds = const Value.absent(),
    this.affectedSubskills = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventLogsCompanion.insert({
    required String eventLogId,
    required String userId,
    this.deviceId = const Value.absent(),
    required String eventTypeId,
    this.timestamp = const Value.absent(),
    this.affectedEntityIds = const Value.absent(),
    this.affectedSubskills = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : eventLogId = Value(eventLogId),
       userId = Value(userId),
       eventTypeId = Value(eventTypeId);
  static Insertable<EventLog> custom({
    Expression<String>? eventLogId,
    Expression<String>? userId,
    Expression<String>? deviceId,
    Expression<String>? eventTypeId,
    Expression<DateTime>? timestamp,
    Expression<String>? affectedEntityIds,
    Expression<String>? affectedSubskills,
    Expression<String>? metadata,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventLogId != null) 'EventLogID': eventLogId,
      if (userId != null) 'UserID': userId,
      if (deviceId != null) 'DeviceID': deviceId,
      if (eventTypeId != null) 'EventTypeID': eventTypeId,
      if (timestamp != null) 'Timestamp': timestamp,
      if (affectedEntityIds != null) 'AffectedEntityIDs': affectedEntityIds,
      if (affectedSubskills != null) 'AffectedSubskills': affectedSubskills,
      if (metadata != null) 'Metadata': metadata,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventLogsCompanion copyWith({
    Value<String>? eventLogId,
    Value<String>? userId,
    Value<String?>? deviceId,
    Value<String>? eventTypeId,
    Value<DateTime>? timestamp,
    Value<String?>? affectedEntityIds,
    Value<String?>? affectedSubskills,
    Value<String?>? metadata,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EventLogsCompanion(
      eventLogId: eventLogId ?? this.eventLogId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      eventTypeId: eventTypeId ?? this.eventTypeId,
      timestamp: timestamp ?? this.timestamp,
      affectedEntityIds: affectedEntityIds ?? this.affectedEntityIds,
      affectedSubskills: affectedSubskills ?? this.affectedSubskills,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventLogId.present) {
      map['EventLogID'] = Variable<String>(eventLogId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (deviceId.present) {
      map['DeviceID'] = Variable<String>(deviceId.value);
    }
    if (eventTypeId.present) {
      map['EventTypeID'] = Variable<String>(eventTypeId.value);
    }
    if (timestamp.present) {
      map['Timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (affectedEntityIds.present) {
      map['AffectedEntityIDs'] = Variable<String>(affectedEntityIds.value);
    }
    if (affectedSubskills.present) {
      map['AffectedSubskills'] = Variable<String>(affectedSubskills.value);
    }
    if (metadata.present) {
      map['Metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventLogsCompanion(')
          ..write('eventLogId: $eventLogId, ')
          ..write('userId: $userId, ')
          ..write('deviceId: $deviceId, ')
          ..write('eventTypeId: $eventTypeId, ')
          ..write('timestamp: $timestamp, ')
          ..write('affectedEntityIds: $affectedEntityIds, ')
          ..write('affectedSubskills: $affectedSubskills, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserDevicesTable extends UserDevices
    with TableInfo<$UserDevicesTable, UserDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'DeviceID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceLabelMeta = const VerificationMeta(
    'deviceLabel',
  );
  @override
  late final GeneratedColumn<String> deviceLabel = GeneratedColumn<String>(
    'DeviceLabel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _registeredAtMeta = const VerificationMeta(
    'registeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> registeredAt = GeneratedColumn<DateTime>(
    'RegisteredAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'LastSyncAt',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    userId,
    deviceLabel,
    registeredAt,
    lastSyncAt,
    isDeleted,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'UserDevice';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('DeviceID')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['DeviceID']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('DeviceLabel')) {
      context.handle(
        _deviceLabelMeta,
        deviceLabel.isAcceptableOrUnknown(
          data['DeviceLabel']!,
          _deviceLabelMeta,
        ),
      );
    }
    if (data.containsKey('RegisteredAt')) {
      context.handle(
        _registeredAtMeta,
        registeredAt.isAcceptableOrUnknown(
          data['RegisteredAt']!,
          _registeredAtMeta,
        ),
      );
    }
    if (data.containsKey('LastSyncAt')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(data['LastSyncAt']!, _lastSyncAtMeta),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  UserDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserDevice(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DeviceID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      deviceLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}DeviceLabel'],
      ),
      registeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}RegisteredAt'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}LastSyncAt'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $UserDevicesTable createAlias(String alias) {
    return $UserDevicesTable(attachedDatabase, alias);
  }
}

class UserDevice extends DataClass implements Insertable<UserDevice> {
  final String deviceId;
  final String userId;
  final String? deviceLabel;
  final DateTime registeredAt;
  final DateTime? lastSyncAt;
  final bool isDeleted;
  final DateTime updatedAt;
  const UserDevice({
    required this.deviceId,
    required this.userId,
    this.deviceLabel,
    required this.registeredAt,
    this.lastSyncAt,
    required this.isDeleted,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['DeviceID'] = Variable<String>(deviceId);
    map['UserID'] = Variable<String>(userId);
    if (!nullToAbsent || deviceLabel != null) {
      map['DeviceLabel'] = Variable<String>(deviceLabel);
    }
    map['RegisteredAt'] = Variable<DateTime>(registeredAt);
    if (!nullToAbsent || lastSyncAt != null) {
      map['LastSyncAt'] = Variable<DateTime>(lastSyncAt);
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserDevicesCompanion toCompanion(bool nullToAbsent) {
    return UserDevicesCompanion(
      deviceId: Value(deviceId),
      userId: Value(userId),
      deviceLabel: deviceLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceLabel),
      registeredAt: Value(registeredAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserDevice(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      userId: serializer.fromJson<String>(json['userId']),
      deviceLabel: serializer.fromJson<String?>(json['deviceLabel']),
      registeredAt: serializer.fromJson<DateTime>(json['registeredAt']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'userId': serializer.toJson<String>(userId),
      'deviceLabel': serializer.toJson<String?>(deviceLabel),
      'registeredAt': serializer.toJson<DateTime>(registeredAt),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserDevice copyWith({
    String? deviceId,
    String? userId,
    Value<String?> deviceLabel = const Value.absent(),
    DateTime? registeredAt,
    Value<DateTime?> lastSyncAt = const Value.absent(),
    bool? isDeleted,
    DateTime? updatedAt,
  }) => UserDevice(
    deviceId: deviceId ?? this.deviceId,
    userId: userId ?? this.userId,
    deviceLabel: deviceLabel.present ? deviceLabel.value : this.deviceLabel,
    registeredAt: registeredAt ?? this.registeredAt,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserDevice copyWithCompanion(UserDevicesCompanion data) {
    return UserDevice(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      userId: data.userId.present ? data.userId.value : this.userId,
      deviceLabel: data.deviceLabel.present
          ? data.deviceLabel.value
          : this.deviceLabel,
      registeredAt: data.registeredAt.present
          ? data.registeredAt.value
          : this.registeredAt,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserDevice(')
          ..write('deviceId: $deviceId, ')
          ..write('userId: $userId, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    userId,
    deviceLabel,
    registeredAt,
    lastSyncAt,
    isDeleted,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserDevice &&
          other.deviceId == this.deviceId &&
          other.userId == this.userId &&
          other.deviceLabel == this.deviceLabel &&
          other.registeredAt == this.registeredAt &&
          other.lastSyncAt == this.lastSyncAt &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt);
}

class UserDevicesCompanion extends UpdateCompanion<UserDevice> {
  final Value<String> deviceId;
  final Value<String> userId;
  final Value<String?> deviceLabel;
  final Value<DateTime> registeredAt;
  final Value<DateTime?> lastSyncAt;
  final Value<bool> isDeleted;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserDevicesCompanion({
    this.deviceId = const Value.absent(),
    this.userId = const Value.absent(),
    this.deviceLabel = const Value.absent(),
    this.registeredAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserDevicesCompanion.insert({
    required String deviceId,
    required String userId,
    this.deviceLabel = const Value.absent(),
    this.registeredAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       userId = Value(userId);
  static Insertable<UserDevice> custom({
    Expression<String>? deviceId,
    Expression<String>? userId,
    Expression<String>? deviceLabel,
    Expression<DateTime>? registeredAt,
    Expression<DateTime>? lastSyncAt,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'DeviceID': deviceId,
      if (userId != null) 'UserID': userId,
      if (deviceLabel != null) 'DeviceLabel': deviceLabel,
      if (registeredAt != null) 'RegisteredAt': registeredAt,
      if (lastSyncAt != null) 'LastSyncAt': lastSyncAt,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserDevicesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? userId,
    Value<String?>? deviceLabel,
    Value<DateTime>? registeredAt,
    Value<DateTime?>? lastSyncAt,
    Value<bool>? isDeleted,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserDevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      registeredAt: registeredAt ?? this.registeredAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['DeviceID'] = Variable<String>(deviceId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (deviceLabel.present) {
      map['DeviceLabel'] = Variable<String>(deviceLabel.value);
    }
    if (registeredAt.present) {
      map['RegisteredAt'] = Variable<DateTime>(registeredAt.value);
    }
    if (lastSyncAt.present) {
      map['LastSyncAt'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserDevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('userId: $userId, ')
          ..write('deviceLabel: $deviceLabel, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserScoringLocksTable extends UserScoringLocks
    with TableInfo<$UserScoringLocksTable, UserScoringLock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserScoringLocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'IsLocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsLocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lockedAtMeta = const VerificationMeta(
    'lockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockedAt = GeneratedColumn<DateTime>(
    'LockedAt',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockExpiresAtMeta = const VerificationMeta(
    'lockExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockExpiresAt =
      GeneratedColumn<DateTime>(
        'LockExpiresAt',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    isLocked,
    lockedAt,
    lockExpiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'UserScoringLock';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserScoringLock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('IsLocked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['IsLocked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('LockedAt')) {
      context.handle(
        _lockedAtMeta,
        lockedAt.isAcceptableOrUnknown(data['LockedAt']!, _lockedAtMeta),
      );
    }
    if (data.containsKey('LockExpiresAt')) {
      context.handle(
        _lockExpiresAtMeta,
        lockExpiresAt.isAcceptableOrUnknown(
          data['LockExpiresAt']!,
          _lockExpiresAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  UserScoringLock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserScoringLock(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsLocked'],
      )!,
      lockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}LockedAt'],
      ),
      lockExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}LockExpiresAt'],
      ),
    );
  }

  @override
  $UserScoringLocksTable createAlias(String alias) {
    return $UserScoringLocksTable(attachedDatabase, alias);
  }
}

class UserScoringLock extends DataClass implements Insertable<UserScoringLock> {
  final String userId;
  final bool isLocked;
  final DateTime? lockedAt;
  final DateTime? lockExpiresAt;
  const UserScoringLock({
    required this.userId,
    required this.isLocked,
    this.lockedAt,
    this.lockExpiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['UserID'] = Variable<String>(userId);
    map['IsLocked'] = Variable<bool>(isLocked);
    if (!nullToAbsent || lockedAt != null) {
      map['LockedAt'] = Variable<DateTime>(lockedAt);
    }
    if (!nullToAbsent || lockExpiresAt != null) {
      map['LockExpiresAt'] = Variable<DateTime>(lockExpiresAt);
    }
    return map;
  }

  UserScoringLocksCompanion toCompanion(bool nullToAbsent) {
    return UserScoringLocksCompanion(
      userId: Value(userId),
      isLocked: Value(isLocked),
      lockedAt: lockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedAt),
      lockExpiresAt: lockExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lockExpiresAt),
    );
  }

  factory UserScoringLock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserScoringLock(
      userId: serializer.fromJson<String>(json['userId']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      lockedAt: serializer.fromJson<DateTime?>(json['lockedAt']),
      lockExpiresAt: serializer.fromJson<DateTime?>(json['lockExpiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'isLocked': serializer.toJson<bool>(isLocked),
      'lockedAt': serializer.toJson<DateTime?>(lockedAt),
      'lockExpiresAt': serializer.toJson<DateTime?>(lockExpiresAt),
    };
  }

  UserScoringLock copyWith({
    String? userId,
    bool? isLocked,
    Value<DateTime?> lockedAt = const Value.absent(),
    Value<DateTime?> lockExpiresAt = const Value.absent(),
  }) => UserScoringLock(
    userId: userId ?? this.userId,
    isLocked: isLocked ?? this.isLocked,
    lockedAt: lockedAt.present ? lockedAt.value : this.lockedAt,
    lockExpiresAt: lockExpiresAt.present
        ? lockExpiresAt.value
        : this.lockExpiresAt,
  );
  UserScoringLock copyWithCompanion(UserScoringLocksCompanion data) {
    return UserScoringLock(
      userId: data.userId.present ? data.userId.value : this.userId,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      lockedAt: data.lockedAt.present ? data.lockedAt.value : this.lockedAt,
      lockExpiresAt: data.lockExpiresAt.present
          ? data.lockExpiresAt.value
          : this.lockExpiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserScoringLock(')
          ..write('userId: $userId, ')
          ..write('isLocked: $isLocked, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('lockExpiresAt: $lockExpiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, isLocked, lockedAt, lockExpiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserScoringLock &&
          other.userId == this.userId &&
          other.isLocked == this.isLocked &&
          other.lockedAt == this.lockedAt &&
          other.lockExpiresAt == this.lockExpiresAt);
}

class UserScoringLocksCompanion extends UpdateCompanion<UserScoringLock> {
  final Value<String> userId;
  final Value<bool> isLocked;
  final Value<DateTime?> lockedAt;
  final Value<DateTime?> lockExpiresAt;
  final Value<int> rowid;
  const UserScoringLocksCompanion({
    this.userId = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.lockExpiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserScoringLocksCompanion.insert({
    required String userId,
    this.isLocked = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.lockExpiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<UserScoringLock> custom({
    Expression<String>? userId,
    Expression<bool>? isLocked,
    Expression<DateTime>? lockedAt,
    Expression<DateTime>? lockExpiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'UserID': userId,
      if (isLocked != null) 'IsLocked': isLocked,
      if (lockedAt != null) 'LockedAt': lockedAt,
      if (lockExpiresAt != null) 'LockExpiresAt': lockExpiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserScoringLocksCompanion copyWith({
    Value<String>? userId,
    Value<bool>? isLocked,
    Value<DateTime?>? lockedAt,
    Value<DateTime?>? lockExpiresAt,
    Value<int>? rowid,
  }) {
    return UserScoringLocksCompanion(
      userId: userId ?? this.userId,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      lockExpiresAt: lockExpiresAt ?? this.lockExpiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (isLocked.present) {
      map['IsLocked'] = Variable<bool>(isLocked.value);
    }
    if (lockedAt.present) {
      map['LockedAt'] = Variable<DateTime>(lockedAt.value);
    }
    if (lockExpiresAt.present) {
      map['LockExpiresAt'] = Variable<DateTime>(lockExpiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserScoringLocksCompanion(')
          ..write('userId: $userId, ')
          ..write('isLocked: $isLocked, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('lockExpiresAt: $lockExpiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatrixRunsTable extends MatrixRuns
    with TableInfo<$MatrixRunsTable, MatrixRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatrixRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matrixRunIdMeta = const VerificationMeta(
    'matrixRunId',
  );
  @override
  late final GeneratedColumn<String> matrixRunId = GeneratedColumn<String>(
    'MatrixRunID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MatrixType, String> matrixType =
      GeneratedColumn<String>(
        'MatrixType',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MatrixType>($MatrixRunsTable.$convertermatrixType);
  static const VerificationMeta _runNumberMeta = const VerificationMeta(
    'runNumber',
  );
  @override
  late final GeneratedColumn<int> runNumber = GeneratedColumn<int>(
    'RunNumber',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RunState, String> runState =
      GeneratedColumn<String>(
        'RunState',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RunState>($MatrixRunsTable.$converterrunState);
  static const VerificationMeta _startTimestampMeta = const VerificationMeta(
    'startTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> startTimestamp =
      GeneratedColumn<DateTime>(
        'StartTimestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: () => DateTime.now(),
      );
  static const VerificationMeta _endTimestampMeta = const VerificationMeta(
    'endTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> endTimestamp = GeneratedColumn<DateTime>(
    'EndTimestamp',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionShotTargetMeta = const VerificationMeta(
    'sessionShotTarget',
  );
  @override
  late final GeneratedColumn<int> sessionShotTarget = GeneratedColumn<int>(
    'SessionShotTarget',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShotOrderMode, String>
  shotOrderMode = GeneratedColumn<String>(
    'ShotOrderMode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ShotOrderMode>($MatrixRunsTable.$convertershotOrderMode);
  static const VerificationMeta _dispersionCaptureEnabledMeta =
      const VerificationMeta('dispersionCaptureEnabled');
  @override
  late final GeneratedColumn<bool> dispersionCaptureEnabled =
      GeneratedColumn<bool>(
        'DispersionCaptureEnabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("DispersionCaptureEnabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _measurementDeviceMeta = const VerificationMeta(
    'measurementDevice',
  );
  @override
  late final GeneratedColumn<String> measurementDevice =
      GeneratedColumn<String>(
        'MeasurementDevice',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<EnvironmentType?, String>
  environmentType =
      GeneratedColumn<String>(
        'EnvironmentType',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<EnvironmentType?>(
        $MatrixRunsTable.$converterenvironmentTypen,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SurfaceType?, String>
  surfaceType = GeneratedColumn<String>(
    'SurfaceType',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<SurfaceType?>($MatrixRunsTable.$convertersurfaceTypen);
  static const VerificationMeta _greenSpeedMeta = const VerificationMeta(
    'greenSpeed',
  );
  @override
  late final GeneratedColumn<double> greenSpeed = GeneratedColumn<double>(
    'GreenSpeed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GreenFirmness?, String>
  greenFirmness = GeneratedColumn<String>(
    'GreenFirmness',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<GreenFirmness?>($MatrixRunsTable.$convertergreenFirmnessn);
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    matrixRunId,
    userId,
    matrixType,
    runNumber,
    runState,
    startTimestamp,
    endTimestamp,
    sessionShotTarget,
    shotOrderMode,
    dispersionCaptureEnabled,
    measurementDevice,
    environmentType,
    surfaceType,
    greenSpeed,
    greenFirmness,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MatrixRun';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatrixRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('MatrixRunID')) {
      context.handle(
        _matrixRunIdMeta,
        matrixRunId.isAcceptableOrUnknown(
          data['MatrixRunID']!,
          _matrixRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matrixRunIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('RunNumber')) {
      context.handle(
        _runNumberMeta,
        runNumber.isAcceptableOrUnknown(data['RunNumber']!, _runNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_runNumberMeta);
    }
    if (data.containsKey('StartTimestamp')) {
      context.handle(
        _startTimestampMeta,
        startTimestamp.isAcceptableOrUnknown(
          data['StartTimestamp']!,
          _startTimestampMeta,
        ),
      );
    }
    if (data.containsKey('EndTimestamp')) {
      context.handle(
        _endTimestampMeta,
        endTimestamp.isAcceptableOrUnknown(
          data['EndTimestamp']!,
          _endTimestampMeta,
        ),
      );
    }
    if (data.containsKey('SessionShotTarget')) {
      context.handle(
        _sessionShotTargetMeta,
        sessionShotTarget.isAcceptableOrUnknown(
          data['SessionShotTarget']!,
          _sessionShotTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionShotTargetMeta);
    }
    if (data.containsKey('DispersionCaptureEnabled')) {
      context.handle(
        _dispersionCaptureEnabledMeta,
        dispersionCaptureEnabled.isAcceptableOrUnknown(
          data['DispersionCaptureEnabled']!,
          _dispersionCaptureEnabledMeta,
        ),
      );
    }
    if (data.containsKey('MeasurementDevice')) {
      context.handle(
        _measurementDeviceMeta,
        measurementDevice.isAcceptableOrUnknown(
          data['MeasurementDevice']!,
          _measurementDeviceMeta,
        ),
      );
    }
    if (data.containsKey('GreenSpeed')) {
      context.handle(
        _greenSpeedMeta,
        greenSpeed.isAcceptableOrUnknown(data['GreenSpeed']!, _greenSpeedMeta),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matrixRunId};
  @override
  MatrixRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatrixRun(
      matrixRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixRunID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      matrixType: $MatrixRunsTable.$convertermatrixType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}MatrixType'],
        )!,
      ),
      runNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}RunNumber'],
      )!,
      runState: $MatrixRunsTable.$converterrunState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}RunState'],
        )!,
      ),
      startTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}StartTimestamp'],
      )!,
      endTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}EndTimestamp'],
      ),
      sessionShotTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}SessionShotTarget'],
      )!,
      shotOrderMode: $MatrixRunsTable.$convertershotOrderMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ShotOrderMode'],
        )!,
      ),
      dispersionCaptureEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}DispersionCaptureEnabled'],
      )!,
      measurementDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MeasurementDevice'],
      ),
      environmentType: $MatrixRunsTable.$converterenvironmentTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}EnvironmentType'],
        ),
      ),
      surfaceType: $MatrixRunsTable.$convertersurfaceTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}SurfaceType'],
        ),
      ),
      greenSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}GreenSpeed'],
      ),
      greenFirmness: $MatrixRunsTable.$convertergreenFirmnessn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}GreenFirmness'],
        ),
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $MatrixRunsTable createAlias(String alias) {
    return $MatrixRunsTable(attachedDatabase, alias);
  }

  static TypeConverter<MatrixType, String> $convertermatrixType =
      const MatrixTypeConverter();
  static TypeConverter<RunState, String> $converterrunState =
      const RunStateConverter();
  static TypeConverter<ShotOrderMode, String> $convertershotOrderMode =
      const ShotOrderModeConverter();
  static TypeConverter<EnvironmentType, String> $converterenvironmentType =
      const EnvironmentTypeConverter();
  static TypeConverter<EnvironmentType?, String?> $converterenvironmentTypen =
      NullAwareTypeConverter.wrap($converterenvironmentType);
  static TypeConverter<SurfaceType, String> $convertersurfaceType =
      const SurfaceTypeConverter();
  static TypeConverter<SurfaceType?, String?> $convertersurfaceTypen =
      NullAwareTypeConverter.wrap($convertersurfaceType);
  static TypeConverter<GreenFirmness, String> $convertergreenFirmness =
      const GreenFirmnessConverter();
  static TypeConverter<GreenFirmness?, String?> $convertergreenFirmnessn =
      NullAwareTypeConverter.wrap($convertergreenFirmness);
}

class MatrixRun extends DataClass implements Insertable<MatrixRun> {
  final String matrixRunId;
  final String userId;
  final MatrixType matrixType;
  final int runNumber;
  final RunState runState;
  final DateTime startTimestamp;
  final DateTime? endTimestamp;
  final int sessionShotTarget;
  final ShotOrderMode shotOrderMode;
  final bool dispersionCaptureEnabled;
  final String? measurementDevice;
  final EnvironmentType? environmentType;
  final SurfaceType? surfaceType;
  final double? greenSpeed;
  final GreenFirmness? greenFirmness;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MatrixRun({
    required this.matrixRunId,
    required this.userId,
    required this.matrixType,
    required this.runNumber,
    required this.runState,
    required this.startTimestamp,
    this.endTimestamp,
    required this.sessionShotTarget,
    required this.shotOrderMode,
    required this.dispersionCaptureEnabled,
    this.measurementDevice,
    this.environmentType,
    this.surfaceType,
    this.greenSpeed,
    this.greenFirmness,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['MatrixRunID'] = Variable<String>(matrixRunId);
    map['UserID'] = Variable<String>(userId);
    {
      map['MatrixType'] = Variable<String>(
        $MatrixRunsTable.$convertermatrixType.toSql(matrixType),
      );
    }
    map['RunNumber'] = Variable<int>(runNumber);
    {
      map['RunState'] = Variable<String>(
        $MatrixRunsTable.$converterrunState.toSql(runState),
      );
    }
    map['StartTimestamp'] = Variable<DateTime>(startTimestamp);
    if (!nullToAbsent || endTimestamp != null) {
      map['EndTimestamp'] = Variable<DateTime>(endTimestamp);
    }
    map['SessionShotTarget'] = Variable<int>(sessionShotTarget);
    {
      map['ShotOrderMode'] = Variable<String>(
        $MatrixRunsTable.$convertershotOrderMode.toSql(shotOrderMode),
      );
    }
    map['DispersionCaptureEnabled'] = Variable<bool>(dispersionCaptureEnabled);
    if (!nullToAbsent || measurementDevice != null) {
      map['MeasurementDevice'] = Variable<String>(measurementDevice);
    }
    if (!nullToAbsent || environmentType != null) {
      map['EnvironmentType'] = Variable<String>(
        $MatrixRunsTable.$converterenvironmentTypen.toSql(environmentType),
      );
    }
    if (!nullToAbsent || surfaceType != null) {
      map['SurfaceType'] = Variable<String>(
        $MatrixRunsTable.$convertersurfaceTypen.toSql(surfaceType),
      );
    }
    if (!nullToAbsent || greenSpeed != null) {
      map['GreenSpeed'] = Variable<double>(greenSpeed);
    }
    if (!nullToAbsent || greenFirmness != null) {
      map['GreenFirmness'] = Variable<String>(
        $MatrixRunsTable.$convertergreenFirmnessn.toSql(greenFirmness),
      );
    }
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MatrixRunsCompanion toCompanion(bool nullToAbsent) {
    return MatrixRunsCompanion(
      matrixRunId: Value(matrixRunId),
      userId: Value(userId),
      matrixType: Value(matrixType),
      runNumber: Value(runNumber),
      runState: Value(runState),
      startTimestamp: Value(startTimestamp),
      endTimestamp: endTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(endTimestamp),
      sessionShotTarget: Value(sessionShotTarget),
      shotOrderMode: Value(shotOrderMode),
      dispersionCaptureEnabled: Value(dispersionCaptureEnabled),
      measurementDevice: measurementDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(measurementDevice),
      environmentType: environmentType == null && nullToAbsent
          ? const Value.absent()
          : Value(environmentType),
      surfaceType: surfaceType == null && nullToAbsent
          ? const Value.absent()
          : Value(surfaceType),
      greenSpeed: greenSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(greenSpeed),
      greenFirmness: greenFirmness == null && nullToAbsent
          ? const Value.absent()
          : Value(greenFirmness),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MatrixRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatrixRun(
      matrixRunId: serializer.fromJson<String>(json['matrixRunId']),
      userId: serializer.fromJson<String>(json['userId']),
      matrixType: serializer.fromJson<MatrixType>(json['matrixType']),
      runNumber: serializer.fromJson<int>(json['runNumber']),
      runState: serializer.fromJson<RunState>(json['runState']),
      startTimestamp: serializer.fromJson<DateTime>(json['startTimestamp']),
      endTimestamp: serializer.fromJson<DateTime?>(json['endTimestamp']),
      sessionShotTarget: serializer.fromJson<int>(json['sessionShotTarget']),
      shotOrderMode: serializer.fromJson<ShotOrderMode>(json['shotOrderMode']),
      dispersionCaptureEnabled: serializer.fromJson<bool>(
        json['dispersionCaptureEnabled'],
      ),
      measurementDevice: serializer.fromJson<String?>(
        json['measurementDevice'],
      ),
      environmentType: serializer.fromJson<EnvironmentType?>(
        json['environmentType'],
      ),
      surfaceType: serializer.fromJson<SurfaceType?>(json['surfaceType']),
      greenSpeed: serializer.fromJson<double?>(json['greenSpeed']),
      greenFirmness: serializer.fromJson<GreenFirmness?>(json['greenFirmness']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matrixRunId': serializer.toJson<String>(matrixRunId),
      'userId': serializer.toJson<String>(userId),
      'matrixType': serializer.toJson<MatrixType>(matrixType),
      'runNumber': serializer.toJson<int>(runNumber),
      'runState': serializer.toJson<RunState>(runState),
      'startTimestamp': serializer.toJson<DateTime>(startTimestamp),
      'endTimestamp': serializer.toJson<DateTime?>(endTimestamp),
      'sessionShotTarget': serializer.toJson<int>(sessionShotTarget),
      'shotOrderMode': serializer.toJson<ShotOrderMode>(shotOrderMode),
      'dispersionCaptureEnabled': serializer.toJson<bool>(
        dispersionCaptureEnabled,
      ),
      'measurementDevice': serializer.toJson<String?>(measurementDevice),
      'environmentType': serializer.toJson<EnvironmentType?>(environmentType),
      'surfaceType': serializer.toJson<SurfaceType?>(surfaceType),
      'greenSpeed': serializer.toJson<double?>(greenSpeed),
      'greenFirmness': serializer.toJson<GreenFirmness?>(greenFirmness),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MatrixRun copyWith({
    String? matrixRunId,
    String? userId,
    MatrixType? matrixType,
    int? runNumber,
    RunState? runState,
    DateTime? startTimestamp,
    Value<DateTime?> endTimestamp = const Value.absent(),
    int? sessionShotTarget,
    ShotOrderMode? shotOrderMode,
    bool? dispersionCaptureEnabled,
    Value<String?> measurementDevice = const Value.absent(),
    Value<EnvironmentType?> environmentType = const Value.absent(),
    Value<SurfaceType?> surfaceType = const Value.absent(),
    Value<double?> greenSpeed = const Value.absent(),
    Value<GreenFirmness?> greenFirmness = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MatrixRun(
    matrixRunId: matrixRunId ?? this.matrixRunId,
    userId: userId ?? this.userId,
    matrixType: matrixType ?? this.matrixType,
    runNumber: runNumber ?? this.runNumber,
    runState: runState ?? this.runState,
    startTimestamp: startTimestamp ?? this.startTimestamp,
    endTimestamp: endTimestamp.present ? endTimestamp.value : this.endTimestamp,
    sessionShotTarget: sessionShotTarget ?? this.sessionShotTarget,
    shotOrderMode: shotOrderMode ?? this.shotOrderMode,
    dispersionCaptureEnabled:
        dispersionCaptureEnabled ?? this.dispersionCaptureEnabled,
    measurementDevice: measurementDevice.present
        ? measurementDevice.value
        : this.measurementDevice,
    environmentType: environmentType.present
        ? environmentType.value
        : this.environmentType,
    surfaceType: surfaceType.present ? surfaceType.value : this.surfaceType,
    greenSpeed: greenSpeed.present ? greenSpeed.value : this.greenSpeed,
    greenFirmness: greenFirmness.present
        ? greenFirmness.value
        : this.greenFirmness,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MatrixRun copyWithCompanion(MatrixRunsCompanion data) {
    return MatrixRun(
      matrixRunId: data.matrixRunId.present
          ? data.matrixRunId.value
          : this.matrixRunId,
      userId: data.userId.present ? data.userId.value : this.userId,
      matrixType: data.matrixType.present
          ? data.matrixType.value
          : this.matrixType,
      runNumber: data.runNumber.present ? data.runNumber.value : this.runNumber,
      runState: data.runState.present ? data.runState.value : this.runState,
      startTimestamp: data.startTimestamp.present
          ? data.startTimestamp.value
          : this.startTimestamp,
      endTimestamp: data.endTimestamp.present
          ? data.endTimestamp.value
          : this.endTimestamp,
      sessionShotTarget: data.sessionShotTarget.present
          ? data.sessionShotTarget.value
          : this.sessionShotTarget,
      shotOrderMode: data.shotOrderMode.present
          ? data.shotOrderMode.value
          : this.shotOrderMode,
      dispersionCaptureEnabled: data.dispersionCaptureEnabled.present
          ? data.dispersionCaptureEnabled.value
          : this.dispersionCaptureEnabled,
      measurementDevice: data.measurementDevice.present
          ? data.measurementDevice.value
          : this.measurementDevice,
      environmentType: data.environmentType.present
          ? data.environmentType.value
          : this.environmentType,
      surfaceType: data.surfaceType.present
          ? data.surfaceType.value
          : this.surfaceType,
      greenSpeed: data.greenSpeed.present
          ? data.greenSpeed.value
          : this.greenSpeed,
      greenFirmness: data.greenFirmness.present
          ? data.greenFirmness.value
          : this.greenFirmness,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatrixRun(')
          ..write('matrixRunId: $matrixRunId, ')
          ..write('userId: $userId, ')
          ..write('matrixType: $matrixType, ')
          ..write('runNumber: $runNumber, ')
          ..write('runState: $runState, ')
          ..write('startTimestamp: $startTimestamp, ')
          ..write('endTimestamp: $endTimestamp, ')
          ..write('sessionShotTarget: $sessionShotTarget, ')
          ..write('shotOrderMode: $shotOrderMode, ')
          ..write('dispersionCaptureEnabled: $dispersionCaptureEnabled, ')
          ..write('measurementDevice: $measurementDevice, ')
          ..write('environmentType: $environmentType, ')
          ..write('surfaceType: $surfaceType, ')
          ..write('greenSpeed: $greenSpeed, ')
          ..write('greenFirmness: $greenFirmness, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    matrixRunId,
    userId,
    matrixType,
    runNumber,
    runState,
    startTimestamp,
    endTimestamp,
    sessionShotTarget,
    shotOrderMode,
    dispersionCaptureEnabled,
    measurementDevice,
    environmentType,
    surfaceType,
    greenSpeed,
    greenFirmness,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatrixRun &&
          other.matrixRunId == this.matrixRunId &&
          other.userId == this.userId &&
          other.matrixType == this.matrixType &&
          other.runNumber == this.runNumber &&
          other.runState == this.runState &&
          other.startTimestamp == this.startTimestamp &&
          other.endTimestamp == this.endTimestamp &&
          other.sessionShotTarget == this.sessionShotTarget &&
          other.shotOrderMode == this.shotOrderMode &&
          other.dispersionCaptureEnabled == this.dispersionCaptureEnabled &&
          other.measurementDevice == this.measurementDevice &&
          other.environmentType == this.environmentType &&
          other.surfaceType == this.surfaceType &&
          other.greenSpeed == this.greenSpeed &&
          other.greenFirmness == this.greenFirmness &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MatrixRunsCompanion extends UpdateCompanion<MatrixRun> {
  final Value<String> matrixRunId;
  final Value<String> userId;
  final Value<MatrixType> matrixType;
  final Value<int> runNumber;
  final Value<RunState> runState;
  final Value<DateTime> startTimestamp;
  final Value<DateTime?> endTimestamp;
  final Value<int> sessionShotTarget;
  final Value<ShotOrderMode> shotOrderMode;
  final Value<bool> dispersionCaptureEnabled;
  final Value<String?> measurementDevice;
  final Value<EnvironmentType?> environmentType;
  final Value<SurfaceType?> surfaceType;
  final Value<double?> greenSpeed;
  final Value<GreenFirmness?> greenFirmness;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MatrixRunsCompanion({
    this.matrixRunId = const Value.absent(),
    this.userId = const Value.absent(),
    this.matrixType = const Value.absent(),
    this.runNumber = const Value.absent(),
    this.runState = const Value.absent(),
    this.startTimestamp = const Value.absent(),
    this.endTimestamp = const Value.absent(),
    this.sessionShotTarget = const Value.absent(),
    this.shotOrderMode = const Value.absent(),
    this.dispersionCaptureEnabled = const Value.absent(),
    this.measurementDevice = const Value.absent(),
    this.environmentType = const Value.absent(),
    this.surfaceType = const Value.absent(),
    this.greenSpeed = const Value.absent(),
    this.greenFirmness = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatrixRunsCompanion.insert({
    required String matrixRunId,
    required String userId,
    required MatrixType matrixType,
    required int runNumber,
    required RunState runState,
    this.startTimestamp = const Value.absent(),
    this.endTimestamp = const Value.absent(),
    required int sessionShotTarget,
    required ShotOrderMode shotOrderMode,
    this.dispersionCaptureEnabled = const Value.absent(),
    this.measurementDevice = const Value.absent(),
    this.environmentType = const Value.absent(),
    this.surfaceType = const Value.absent(),
    this.greenSpeed = const Value.absent(),
    this.greenFirmness = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : matrixRunId = Value(matrixRunId),
       userId = Value(userId),
       matrixType = Value(matrixType),
       runNumber = Value(runNumber),
       runState = Value(runState),
       sessionShotTarget = Value(sessionShotTarget),
       shotOrderMode = Value(shotOrderMode);
  static Insertable<MatrixRun> custom({
    Expression<String>? matrixRunId,
    Expression<String>? userId,
    Expression<String>? matrixType,
    Expression<int>? runNumber,
    Expression<String>? runState,
    Expression<DateTime>? startTimestamp,
    Expression<DateTime>? endTimestamp,
    Expression<int>? sessionShotTarget,
    Expression<String>? shotOrderMode,
    Expression<bool>? dispersionCaptureEnabled,
    Expression<String>? measurementDevice,
    Expression<String>? environmentType,
    Expression<String>? surfaceType,
    Expression<double>? greenSpeed,
    Expression<String>? greenFirmness,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matrixRunId != null) 'MatrixRunID': matrixRunId,
      if (userId != null) 'UserID': userId,
      if (matrixType != null) 'MatrixType': matrixType,
      if (runNumber != null) 'RunNumber': runNumber,
      if (runState != null) 'RunState': runState,
      if (startTimestamp != null) 'StartTimestamp': startTimestamp,
      if (endTimestamp != null) 'EndTimestamp': endTimestamp,
      if (sessionShotTarget != null) 'SessionShotTarget': sessionShotTarget,
      if (shotOrderMode != null) 'ShotOrderMode': shotOrderMode,
      if (dispersionCaptureEnabled != null)
        'DispersionCaptureEnabled': dispersionCaptureEnabled,
      if (measurementDevice != null) 'MeasurementDevice': measurementDevice,
      if (environmentType != null) 'EnvironmentType': environmentType,
      if (surfaceType != null) 'SurfaceType': surfaceType,
      if (greenSpeed != null) 'GreenSpeed': greenSpeed,
      if (greenFirmness != null) 'GreenFirmness': greenFirmness,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatrixRunsCompanion copyWith({
    Value<String>? matrixRunId,
    Value<String>? userId,
    Value<MatrixType>? matrixType,
    Value<int>? runNumber,
    Value<RunState>? runState,
    Value<DateTime>? startTimestamp,
    Value<DateTime?>? endTimestamp,
    Value<int>? sessionShotTarget,
    Value<ShotOrderMode>? shotOrderMode,
    Value<bool>? dispersionCaptureEnabled,
    Value<String?>? measurementDevice,
    Value<EnvironmentType?>? environmentType,
    Value<SurfaceType?>? surfaceType,
    Value<double?>? greenSpeed,
    Value<GreenFirmness?>? greenFirmness,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MatrixRunsCompanion(
      matrixRunId: matrixRunId ?? this.matrixRunId,
      userId: userId ?? this.userId,
      matrixType: matrixType ?? this.matrixType,
      runNumber: runNumber ?? this.runNumber,
      runState: runState ?? this.runState,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      sessionShotTarget: sessionShotTarget ?? this.sessionShotTarget,
      shotOrderMode: shotOrderMode ?? this.shotOrderMode,
      dispersionCaptureEnabled:
          dispersionCaptureEnabled ?? this.dispersionCaptureEnabled,
      measurementDevice: measurementDevice ?? this.measurementDevice,
      environmentType: environmentType ?? this.environmentType,
      surfaceType: surfaceType ?? this.surfaceType,
      greenSpeed: greenSpeed ?? this.greenSpeed,
      greenFirmness: greenFirmness ?? this.greenFirmness,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matrixRunId.present) {
      map['MatrixRunID'] = Variable<String>(matrixRunId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (matrixType.present) {
      map['MatrixType'] = Variable<String>(
        $MatrixRunsTable.$convertermatrixType.toSql(matrixType.value),
      );
    }
    if (runNumber.present) {
      map['RunNumber'] = Variable<int>(runNumber.value);
    }
    if (runState.present) {
      map['RunState'] = Variable<String>(
        $MatrixRunsTable.$converterrunState.toSql(runState.value),
      );
    }
    if (startTimestamp.present) {
      map['StartTimestamp'] = Variable<DateTime>(startTimestamp.value);
    }
    if (endTimestamp.present) {
      map['EndTimestamp'] = Variable<DateTime>(endTimestamp.value);
    }
    if (sessionShotTarget.present) {
      map['SessionShotTarget'] = Variable<int>(sessionShotTarget.value);
    }
    if (shotOrderMode.present) {
      map['ShotOrderMode'] = Variable<String>(
        $MatrixRunsTable.$convertershotOrderMode.toSql(shotOrderMode.value),
      );
    }
    if (dispersionCaptureEnabled.present) {
      map['DispersionCaptureEnabled'] = Variable<bool>(
        dispersionCaptureEnabled.value,
      );
    }
    if (measurementDevice.present) {
      map['MeasurementDevice'] = Variable<String>(measurementDevice.value);
    }
    if (environmentType.present) {
      map['EnvironmentType'] = Variable<String>(
        $MatrixRunsTable.$converterenvironmentTypen.toSql(
          environmentType.value,
        ),
      );
    }
    if (surfaceType.present) {
      map['SurfaceType'] = Variable<String>(
        $MatrixRunsTable.$convertersurfaceTypen.toSql(surfaceType.value),
      );
    }
    if (greenSpeed.present) {
      map['GreenSpeed'] = Variable<double>(greenSpeed.value);
    }
    if (greenFirmness.present) {
      map['GreenFirmness'] = Variable<String>(
        $MatrixRunsTable.$convertergreenFirmnessn.toSql(greenFirmness.value),
      );
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatrixRunsCompanion(')
          ..write('matrixRunId: $matrixRunId, ')
          ..write('userId: $userId, ')
          ..write('matrixType: $matrixType, ')
          ..write('runNumber: $runNumber, ')
          ..write('runState: $runState, ')
          ..write('startTimestamp: $startTimestamp, ')
          ..write('endTimestamp: $endTimestamp, ')
          ..write('sessionShotTarget: $sessionShotTarget, ')
          ..write('shotOrderMode: $shotOrderMode, ')
          ..write('dispersionCaptureEnabled: $dispersionCaptureEnabled, ')
          ..write('measurementDevice: $measurementDevice, ')
          ..write('environmentType: $environmentType, ')
          ..write('surfaceType: $surfaceType, ')
          ..write('greenSpeed: $greenSpeed, ')
          ..write('greenFirmness: $greenFirmness, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatrixAxesTable extends MatrixAxes
    with TableInfo<$MatrixAxesTable, MatrixAxis> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatrixAxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matrixAxisIdMeta = const VerificationMeta(
    'matrixAxisId',
  );
  @override
  late final GeneratedColumn<String> matrixAxisId = GeneratedColumn<String>(
    'MatrixAxisID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matrixRunIdMeta = const VerificationMeta(
    'matrixRunId',
  );
  @override
  late final GeneratedColumn<String> matrixRunId = GeneratedColumn<String>(
    'MatrixRunID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AxisType, String> axisType =
      GeneratedColumn<String>(
        'AxisType',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AxisType>($MatrixAxesTable.$converteraxisType);
  static const VerificationMeta _axisNameMeta = const VerificationMeta(
    'axisName',
  );
  @override
  late final GeneratedColumn<String> axisName = GeneratedColumn<String>(
    'AxisName',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _axisOrderMeta = const VerificationMeta(
    'axisOrder',
  );
  @override
  late final GeneratedColumn<int> axisOrder = GeneratedColumn<int>(
    'AxisOrder',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    matrixAxisId,
    matrixRunId,
    axisType,
    axisName,
    axisOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MatrixAxis';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatrixAxis> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('MatrixAxisID')) {
      context.handle(
        _matrixAxisIdMeta,
        matrixAxisId.isAcceptableOrUnknown(
          data['MatrixAxisID']!,
          _matrixAxisIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matrixAxisIdMeta);
    }
    if (data.containsKey('MatrixRunID')) {
      context.handle(
        _matrixRunIdMeta,
        matrixRunId.isAcceptableOrUnknown(
          data['MatrixRunID']!,
          _matrixRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matrixRunIdMeta);
    }
    if (data.containsKey('AxisName')) {
      context.handle(
        _axisNameMeta,
        axisName.isAcceptableOrUnknown(data['AxisName']!, _axisNameMeta),
      );
    } else if (isInserting) {
      context.missing(_axisNameMeta);
    }
    if (data.containsKey('AxisOrder')) {
      context.handle(
        _axisOrderMeta,
        axisOrder.isAcceptableOrUnknown(data['AxisOrder']!, _axisOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_axisOrderMeta);
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matrixAxisId};
  @override
  MatrixAxis map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatrixAxis(
      matrixAxisId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixAxisID'],
      )!,
      matrixRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixRunID'],
      )!,
      axisType: $MatrixAxesTable.$converteraxisType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}AxisType'],
        )!,
      ),
      axisName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}AxisName'],
      )!,
      axisOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}AxisOrder'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $MatrixAxesTable createAlias(String alias) {
    return $MatrixAxesTable(attachedDatabase, alias);
  }

  static TypeConverter<AxisType, String> $converteraxisType =
      const AxisTypeConverter();
}

class MatrixAxis extends DataClass implements Insertable<MatrixAxis> {
  final String matrixAxisId;
  final String matrixRunId;
  final AxisType axisType;
  final String axisName;
  final int axisOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MatrixAxis({
    required this.matrixAxisId,
    required this.matrixRunId,
    required this.axisType,
    required this.axisName,
    required this.axisOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['MatrixAxisID'] = Variable<String>(matrixAxisId);
    map['MatrixRunID'] = Variable<String>(matrixRunId);
    {
      map['AxisType'] = Variable<String>(
        $MatrixAxesTable.$converteraxisType.toSql(axisType),
      );
    }
    map['AxisName'] = Variable<String>(axisName);
    map['AxisOrder'] = Variable<int>(axisOrder);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MatrixAxesCompanion toCompanion(bool nullToAbsent) {
    return MatrixAxesCompanion(
      matrixAxisId: Value(matrixAxisId),
      matrixRunId: Value(matrixRunId),
      axisType: Value(axisType),
      axisName: Value(axisName),
      axisOrder: Value(axisOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MatrixAxis.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatrixAxis(
      matrixAxisId: serializer.fromJson<String>(json['matrixAxisId']),
      matrixRunId: serializer.fromJson<String>(json['matrixRunId']),
      axisType: serializer.fromJson<AxisType>(json['axisType']),
      axisName: serializer.fromJson<String>(json['axisName']),
      axisOrder: serializer.fromJson<int>(json['axisOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matrixAxisId': serializer.toJson<String>(matrixAxisId),
      'matrixRunId': serializer.toJson<String>(matrixRunId),
      'axisType': serializer.toJson<AxisType>(axisType),
      'axisName': serializer.toJson<String>(axisName),
      'axisOrder': serializer.toJson<int>(axisOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MatrixAxis copyWith({
    String? matrixAxisId,
    String? matrixRunId,
    AxisType? axisType,
    String? axisName,
    int? axisOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MatrixAxis(
    matrixAxisId: matrixAxisId ?? this.matrixAxisId,
    matrixRunId: matrixRunId ?? this.matrixRunId,
    axisType: axisType ?? this.axisType,
    axisName: axisName ?? this.axisName,
    axisOrder: axisOrder ?? this.axisOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MatrixAxis copyWithCompanion(MatrixAxesCompanion data) {
    return MatrixAxis(
      matrixAxisId: data.matrixAxisId.present
          ? data.matrixAxisId.value
          : this.matrixAxisId,
      matrixRunId: data.matrixRunId.present
          ? data.matrixRunId.value
          : this.matrixRunId,
      axisType: data.axisType.present ? data.axisType.value : this.axisType,
      axisName: data.axisName.present ? data.axisName.value : this.axisName,
      axisOrder: data.axisOrder.present ? data.axisOrder.value : this.axisOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatrixAxis(')
          ..write('matrixAxisId: $matrixAxisId, ')
          ..write('matrixRunId: $matrixRunId, ')
          ..write('axisType: $axisType, ')
          ..write('axisName: $axisName, ')
          ..write('axisOrder: $axisOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    matrixAxisId,
    matrixRunId,
    axisType,
    axisName,
    axisOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatrixAxis &&
          other.matrixAxisId == this.matrixAxisId &&
          other.matrixRunId == this.matrixRunId &&
          other.axisType == this.axisType &&
          other.axisName == this.axisName &&
          other.axisOrder == this.axisOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MatrixAxesCompanion extends UpdateCompanion<MatrixAxis> {
  final Value<String> matrixAxisId;
  final Value<String> matrixRunId;
  final Value<AxisType> axisType;
  final Value<String> axisName;
  final Value<int> axisOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MatrixAxesCompanion({
    this.matrixAxisId = const Value.absent(),
    this.matrixRunId = const Value.absent(),
    this.axisType = const Value.absent(),
    this.axisName = const Value.absent(),
    this.axisOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatrixAxesCompanion.insert({
    required String matrixAxisId,
    required String matrixRunId,
    required AxisType axisType,
    required String axisName,
    required int axisOrder,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : matrixAxisId = Value(matrixAxisId),
       matrixRunId = Value(matrixRunId),
       axisType = Value(axisType),
       axisName = Value(axisName),
       axisOrder = Value(axisOrder);
  static Insertable<MatrixAxis> custom({
    Expression<String>? matrixAxisId,
    Expression<String>? matrixRunId,
    Expression<String>? axisType,
    Expression<String>? axisName,
    Expression<int>? axisOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matrixAxisId != null) 'MatrixAxisID': matrixAxisId,
      if (matrixRunId != null) 'MatrixRunID': matrixRunId,
      if (axisType != null) 'AxisType': axisType,
      if (axisName != null) 'AxisName': axisName,
      if (axisOrder != null) 'AxisOrder': axisOrder,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatrixAxesCompanion copyWith({
    Value<String>? matrixAxisId,
    Value<String>? matrixRunId,
    Value<AxisType>? axisType,
    Value<String>? axisName,
    Value<int>? axisOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MatrixAxesCompanion(
      matrixAxisId: matrixAxisId ?? this.matrixAxisId,
      matrixRunId: matrixRunId ?? this.matrixRunId,
      axisType: axisType ?? this.axisType,
      axisName: axisName ?? this.axisName,
      axisOrder: axisOrder ?? this.axisOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matrixAxisId.present) {
      map['MatrixAxisID'] = Variable<String>(matrixAxisId.value);
    }
    if (matrixRunId.present) {
      map['MatrixRunID'] = Variable<String>(matrixRunId.value);
    }
    if (axisType.present) {
      map['AxisType'] = Variable<String>(
        $MatrixAxesTable.$converteraxisType.toSql(axisType.value),
      );
    }
    if (axisName.present) {
      map['AxisName'] = Variable<String>(axisName.value);
    }
    if (axisOrder.present) {
      map['AxisOrder'] = Variable<int>(axisOrder.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatrixAxesCompanion(')
          ..write('matrixAxisId: $matrixAxisId, ')
          ..write('matrixRunId: $matrixRunId, ')
          ..write('axisType: $axisType, ')
          ..write('axisName: $axisName, ')
          ..write('axisOrder: $axisOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatrixAxisValuesTable extends MatrixAxisValues
    with TableInfo<$MatrixAxisValuesTable, MatrixAxisValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatrixAxisValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _axisValueIdMeta = const VerificationMeta(
    'axisValueId',
  );
  @override
  late final GeneratedColumn<String> axisValueId = GeneratedColumn<String>(
    'AxisValueID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matrixAxisIdMeta = const VerificationMeta(
    'matrixAxisId',
  );
  @override
  late final GeneratedColumn<String> matrixAxisId = GeneratedColumn<String>(
    'MatrixAxisID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'Label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'SortOrder',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    axisValueId,
    matrixAxisId,
    label,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MatrixAxisValue';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatrixAxisValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('AxisValueID')) {
      context.handle(
        _axisValueIdMeta,
        axisValueId.isAcceptableOrUnknown(
          data['AxisValueID']!,
          _axisValueIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_axisValueIdMeta);
    }
    if (data.containsKey('MatrixAxisID')) {
      context.handle(
        _matrixAxisIdMeta,
        matrixAxisId.isAcceptableOrUnknown(
          data['MatrixAxisID']!,
          _matrixAxisIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matrixAxisIdMeta);
    }
    if (data.containsKey('Label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['Label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('SortOrder')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['SortOrder']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {axisValueId};
  @override
  MatrixAxisValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatrixAxisValue(
      axisValueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}AxisValueID'],
      )!,
      matrixAxisId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixAxisID'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Label'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}SortOrder'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $MatrixAxisValuesTable createAlias(String alias) {
    return $MatrixAxisValuesTable(attachedDatabase, alias);
  }
}

class MatrixAxisValue extends DataClass implements Insertable<MatrixAxisValue> {
  final String axisValueId;
  final String matrixAxisId;
  final String label;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MatrixAxisValue({
    required this.axisValueId,
    required this.matrixAxisId,
    required this.label,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['AxisValueID'] = Variable<String>(axisValueId);
    map['MatrixAxisID'] = Variable<String>(matrixAxisId);
    map['Label'] = Variable<String>(label);
    map['SortOrder'] = Variable<int>(sortOrder);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MatrixAxisValuesCompanion toCompanion(bool nullToAbsent) {
    return MatrixAxisValuesCompanion(
      axisValueId: Value(axisValueId),
      matrixAxisId: Value(matrixAxisId),
      label: Value(label),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MatrixAxisValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatrixAxisValue(
      axisValueId: serializer.fromJson<String>(json['axisValueId']),
      matrixAxisId: serializer.fromJson<String>(json['matrixAxisId']),
      label: serializer.fromJson<String>(json['label']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'axisValueId': serializer.toJson<String>(axisValueId),
      'matrixAxisId': serializer.toJson<String>(matrixAxisId),
      'label': serializer.toJson<String>(label),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MatrixAxisValue copyWith({
    String? axisValueId,
    String? matrixAxisId,
    String? label,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MatrixAxisValue(
    axisValueId: axisValueId ?? this.axisValueId,
    matrixAxisId: matrixAxisId ?? this.matrixAxisId,
    label: label ?? this.label,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MatrixAxisValue copyWithCompanion(MatrixAxisValuesCompanion data) {
    return MatrixAxisValue(
      axisValueId: data.axisValueId.present
          ? data.axisValueId.value
          : this.axisValueId,
      matrixAxisId: data.matrixAxisId.present
          ? data.matrixAxisId.value
          : this.matrixAxisId,
      label: data.label.present ? data.label.value : this.label,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatrixAxisValue(')
          ..write('axisValueId: $axisValueId, ')
          ..write('matrixAxisId: $matrixAxisId, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    axisValueId,
    matrixAxisId,
    label,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatrixAxisValue &&
          other.axisValueId == this.axisValueId &&
          other.matrixAxisId == this.matrixAxisId &&
          other.label == this.label &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MatrixAxisValuesCompanion extends UpdateCompanion<MatrixAxisValue> {
  final Value<String> axisValueId;
  final Value<String> matrixAxisId;
  final Value<String> label;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MatrixAxisValuesCompanion({
    this.axisValueId = const Value.absent(),
    this.matrixAxisId = const Value.absent(),
    this.label = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatrixAxisValuesCompanion.insert({
    required String axisValueId,
    required String matrixAxisId,
    required String label,
    required int sortOrder,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : axisValueId = Value(axisValueId),
       matrixAxisId = Value(matrixAxisId),
       label = Value(label),
       sortOrder = Value(sortOrder);
  static Insertable<MatrixAxisValue> custom({
    Expression<String>? axisValueId,
    Expression<String>? matrixAxisId,
    Expression<String>? label,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (axisValueId != null) 'AxisValueID': axisValueId,
      if (matrixAxisId != null) 'MatrixAxisID': matrixAxisId,
      if (label != null) 'Label': label,
      if (sortOrder != null) 'SortOrder': sortOrder,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatrixAxisValuesCompanion copyWith({
    Value<String>? axisValueId,
    Value<String>? matrixAxisId,
    Value<String>? label,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MatrixAxisValuesCompanion(
      axisValueId: axisValueId ?? this.axisValueId,
      matrixAxisId: matrixAxisId ?? this.matrixAxisId,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (axisValueId.present) {
      map['AxisValueID'] = Variable<String>(axisValueId.value);
    }
    if (matrixAxisId.present) {
      map['MatrixAxisID'] = Variable<String>(matrixAxisId.value);
    }
    if (label.present) {
      map['Label'] = Variable<String>(label.value);
    }
    if (sortOrder.present) {
      map['SortOrder'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatrixAxisValuesCompanion(')
          ..write('axisValueId: $axisValueId, ')
          ..write('matrixAxisId: $matrixAxisId, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatrixCellsTable extends MatrixCells
    with TableInfo<$MatrixCellsTable, MatrixCell> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatrixCellsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matrixCellIdMeta = const VerificationMeta(
    'matrixCellId',
  );
  @override
  late final GeneratedColumn<String> matrixCellId = GeneratedColumn<String>(
    'MatrixCellID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matrixRunIdMeta = const VerificationMeta(
    'matrixRunId',
  );
  @override
  late final GeneratedColumn<String> matrixRunId = GeneratedColumn<String>(
    'MatrixRunID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _axisValueIdsMeta = const VerificationMeta(
    'axisValueIds',
  );
  @override
  late final GeneratedColumn<String> axisValueIds = GeneratedColumn<String>(
    'AxisValueIDs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _excludedFromRunMeta = const VerificationMeta(
    'excludedFromRun',
  );
  @override
  late final GeneratedColumn<bool> excludedFromRun = GeneratedColumn<bool>(
    'ExcludedFromRun',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ExcludedFromRun" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    matrixCellId,
    matrixRunId,
    axisValueIds,
    excludedFromRun,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MatrixCell';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatrixCell> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('MatrixCellID')) {
      context.handle(
        _matrixCellIdMeta,
        matrixCellId.isAcceptableOrUnknown(
          data['MatrixCellID']!,
          _matrixCellIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matrixCellIdMeta);
    }
    if (data.containsKey('MatrixRunID')) {
      context.handle(
        _matrixRunIdMeta,
        matrixRunId.isAcceptableOrUnknown(
          data['MatrixRunID']!,
          _matrixRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matrixRunIdMeta);
    }
    if (data.containsKey('AxisValueIDs')) {
      context.handle(
        _axisValueIdsMeta,
        axisValueIds.isAcceptableOrUnknown(
          data['AxisValueIDs']!,
          _axisValueIdsMeta,
        ),
      );
    }
    if (data.containsKey('ExcludedFromRun')) {
      context.handle(
        _excludedFromRunMeta,
        excludedFromRun.isAcceptableOrUnknown(
          data['ExcludedFromRun']!,
          _excludedFromRunMeta,
        ),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matrixCellId};
  @override
  MatrixCell map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatrixCell(
      matrixCellId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixCellID'],
      )!,
      matrixRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixRunID'],
      )!,
      axisValueIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}AxisValueIDs'],
      )!,
      excludedFromRun: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ExcludedFromRun'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $MatrixCellsTable createAlias(String alias) {
    return $MatrixCellsTable(attachedDatabase, alias);
  }
}

class MatrixCell extends DataClass implements Insertable<MatrixCell> {
  final String matrixCellId;
  final String matrixRunId;
  final String axisValueIds;
  final bool excludedFromRun;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MatrixCell({
    required this.matrixCellId,
    required this.matrixRunId,
    required this.axisValueIds,
    required this.excludedFromRun,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['MatrixCellID'] = Variable<String>(matrixCellId);
    map['MatrixRunID'] = Variable<String>(matrixRunId);
    map['AxisValueIDs'] = Variable<String>(axisValueIds);
    map['ExcludedFromRun'] = Variable<bool>(excludedFromRun);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MatrixCellsCompanion toCompanion(bool nullToAbsent) {
    return MatrixCellsCompanion(
      matrixCellId: Value(matrixCellId),
      matrixRunId: Value(matrixRunId),
      axisValueIds: Value(axisValueIds),
      excludedFromRun: Value(excludedFromRun),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MatrixCell.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatrixCell(
      matrixCellId: serializer.fromJson<String>(json['matrixCellId']),
      matrixRunId: serializer.fromJson<String>(json['matrixRunId']),
      axisValueIds: serializer.fromJson<String>(json['axisValueIds']),
      excludedFromRun: serializer.fromJson<bool>(json['excludedFromRun']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matrixCellId': serializer.toJson<String>(matrixCellId),
      'matrixRunId': serializer.toJson<String>(matrixRunId),
      'axisValueIds': serializer.toJson<String>(axisValueIds),
      'excludedFromRun': serializer.toJson<bool>(excludedFromRun),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MatrixCell copyWith({
    String? matrixCellId,
    String? matrixRunId,
    String? axisValueIds,
    bool? excludedFromRun,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MatrixCell(
    matrixCellId: matrixCellId ?? this.matrixCellId,
    matrixRunId: matrixRunId ?? this.matrixRunId,
    axisValueIds: axisValueIds ?? this.axisValueIds,
    excludedFromRun: excludedFromRun ?? this.excludedFromRun,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MatrixCell copyWithCompanion(MatrixCellsCompanion data) {
    return MatrixCell(
      matrixCellId: data.matrixCellId.present
          ? data.matrixCellId.value
          : this.matrixCellId,
      matrixRunId: data.matrixRunId.present
          ? data.matrixRunId.value
          : this.matrixRunId,
      axisValueIds: data.axisValueIds.present
          ? data.axisValueIds.value
          : this.axisValueIds,
      excludedFromRun: data.excludedFromRun.present
          ? data.excludedFromRun.value
          : this.excludedFromRun,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatrixCell(')
          ..write('matrixCellId: $matrixCellId, ')
          ..write('matrixRunId: $matrixRunId, ')
          ..write('axisValueIds: $axisValueIds, ')
          ..write('excludedFromRun: $excludedFromRun, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    matrixCellId,
    matrixRunId,
    axisValueIds,
    excludedFromRun,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatrixCell &&
          other.matrixCellId == this.matrixCellId &&
          other.matrixRunId == this.matrixRunId &&
          other.axisValueIds == this.axisValueIds &&
          other.excludedFromRun == this.excludedFromRun &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MatrixCellsCompanion extends UpdateCompanion<MatrixCell> {
  final Value<String> matrixCellId;
  final Value<String> matrixRunId;
  final Value<String> axisValueIds;
  final Value<bool> excludedFromRun;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MatrixCellsCompanion({
    this.matrixCellId = const Value.absent(),
    this.matrixRunId = const Value.absent(),
    this.axisValueIds = const Value.absent(),
    this.excludedFromRun = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatrixCellsCompanion.insert({
    required String matrixCellId,
    required String matrixRunId,
    this.axisValueIds = const Value.absent(),
    this.excludedFromRun = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : matrixCellId = Value(matrixCellId),
       matrixRunId = Value(matrixRunId);
  static Insertable<MatrixCell> custom({
    Expression<String>? matrixCellId,
    Expression<String>? matrixRunId,
    Expression<String>? axisValueIds,
    Expression<bool>? excludedFromRun,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matrixCellId != null) 'MatrixCellID': matrixCellId,
      if (matrixRunId != null) 'MatrixRunID': matrixRunId,
      if (axisValueIds != null) 'AxisValueIDs': axisValueIds,
      if (excludedFromRun != null) 'ExcludedFromRun': excludedFromRun,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatrixCellsCompanion copyWith({
    Value<String>? matrixCellId,
    Value<String>? matrixRunId,
    Value<String>? axisValueIds,
    Value<bool>? excludedFromRun,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MatrixCellsCompanion(
      matrixCellId: matrixCellId ?? this.matrixCellId,
      matrixRunId: matrixRunId ?? this.matrixRunId,
      axisValueIds: axisValueIds ?? this.axisValueIds,
      excludedFromRun: excludedFromRun ?? this.excludedFromRun,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matrixCellId.present) {
      map['MatrixCellID'] = Variable<String>(matrixCellId.value);
    }
    if (matrixRunId.present) {
      map['MatrixRunID'] = Variable<String>(matrixRunId.value);
    }
    if (axisValueIds.present) {
      map['AxisValueIDs'] = Variable<String>(axisValueIds.value);
    }
    if (excludedFromRun.present) {
      map['ExcludedFromRun'] = Variable<bool>(excludedFromRun.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatrixCellsCompanion(')
          ..write('matrixCellId: $matrixCellId, ')
          ..write('matrixRunId: $matrixRunId, ')
          ..write('axisValueIds: $axisValueIds, ')
          ..write('excludedFromRun: $excludedFromRun, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatrixAttemptsTable extends MatrixAttempts
    with TableInfo<$MatrixAttemptsTable, MatrixAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatrixAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matrixAttemptIdMeta = const VerificationMeta(
    'matrixAttemptId',
  );
  @override
  late final GeneratedColumn<String> matrixAttemptId = GeneratedColumn<String>(
    'MatrixAttemptID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matrixCellIdMeta = const VerificationMeta(
    'matrixCellId',
  );
  @override
  late final GeneratedColumn<String> matrixCellId = GeneratedColumn<String>(
    'MatrixCellID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptTimestampMeta = const VerificationMeta(
    'attemptTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> attemptTimestamp =
      GeneratedColumn<DateTime>(
        'AttemptTimestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: () => DateTime.now(),
      );
  static const VerificationMeta _carryDistanceMetersMeta =
      const VerificationMeta('carryDistanceMeters');
  @override
  late final GeneratedColumn<double> carryDistanceMeters =
      GeneratedColumn<double>(
        'CarryDistanceMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalDistanceMetersMeta =
      const VerificationMeta('totalDistanceMeters');
  @override
  late final GeneratedColumn<double> totalDistanceMeters =
      GeneratedColumn<double>(
        'TotalDistanceMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _leftDeviationMetersMeta =
      const VerificationMeta('leftDeviationMeters');
  @override
  late final GeneratedColumn<double> leftDeviationMeters =
      GeneratedColumn<double>(
        'LeftDeviationMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rightDeviationMetersMeta =
      const VerificationMeta('rightDeviationMeters');
  @override
  late final GeneratedColumn<double> rightDeviationMeters =
      GeneratedColumn<double>(
        'RightDeviationMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rolloutDistanceMetersMeta =
      const VerificationMeta('rolloutDistanceMeters');
  @override
  late final GeneratedColumn<double> rolloutDistanceMeters =
      GeneratedColumn<double>(
        'RolloutDistanceMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    matrixAttemptId,
    matrixCellId,
    attemptTimestamp,
    carryDistanceMeters,
    totalDistanceMeters,
    leftDeviationMeters,
    rightDeviationMeters,
    rolloutDistanceMeters,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'MatrixAttempt';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatrixAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('MatrixAttemptID')) {
      context.handle(
        _matrixAttemptIdMeta,
        matrixAttemptId.isAcceptableOrUnknown(
          data['MatrixAttemptID']!,
          _matrixAttemptIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matrixAttemptIdMeta);
    }
    if (data.containsKey('MatrixCellID')) {
      context.handle(
        _matrixCellIdMeta,
        matrixCellId.isAcceptableOrUnknown(
          data['MatrixCellID']!,
          _matrixCellIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matrixCellIdMeta);
    }
    if (data.containsKey('AttemptTimestamp')) {
      context.handle(
        _attemptTimestampMeta,
        attemptTimestamp.isAcceptableOrUnknown(
          data['AttemptTimestamp']!,
          _attemptTimestampMeta,
        ),
      );
    }
    if (data.containsKey('CarryDistanceMeters')) {
      context.handle(
        _carryDistanceMetersMeta,
        carryDistanceMeters.isAcceptableOrUnknown(
          data['CarryDistanceMeters']!,
          _carryDistanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('TotalDistanceMeters')) {
      context.handle(
        _totalDistanceMetersMeta,
        totalDistanceMeters.isAcceptableOrUnknown(
          data['TotalDistanceMeters']!,
          _totalDistanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('LeftDeviationMeters')) {
      context.handle(
        _leftDeviationMetersMeta,
        leftDeviationMeters.isAcceptableOrUnknown(
          data['LeftDeviationMeters']!,
          _leftDeviationMetersMeta,
        ),
      );
    }
    if (data.containsKey('RightDeviationMeters')) {
      context.handle(
        _rightDeviationMetersMeta,
        rightDeviationMeters.isAcceptableOrUnknown(
          data['RightDeviationMeters']!,
          _rightDeviationMetersMeta,
        ),
      );
    }
    if (data.containsKey('RolloutDistanceMeters')) {
      context.handle(
        _rolloutDistanceMetersMeta,
        rolloutDistanceMeters.isAcceptableOrUnknown(
          data['RolloutDistanceMeters']!,
          _rolloutDistanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matrixAttemptId};
  @override
  MatrixAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatrixAttempt(
      matrixAttemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixAttemptID'],
      )!,
      matrixCellId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixCellID'],
      )!,
      attemptTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}AttemptTimestamp'],
      )!,
      carryDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}CarryDistanceMeters'],
      ),
      totalDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}TotalDistanceMeters'],
      ),
      leftDeviationMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}LeftDeviationMeters'],
      ),
      rightDeviationMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}RightDeviationMeters'],
      ),
      rolloutDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}RolloutDistanceMeters'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $MatrixAttemptsTable createAlias(String alias) {
    return $MatrixAttemptsTable(attachedDatabase, alias);
  }
}

class MatrixAttempt extends DataClass implements Insertable<MatrixAttempt> {
  final String matrixAttemptId;
  final String matrixCellId;
  final DateTime attemptTimestamp;
  final double? carryDistanceMeters;
  final double? totalDistanceMeters;
  final double? leftDeviationMeters;
  final double? rightDeviationMeters;
  final double? rolloutDistanceMeters;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MatrixAttempt({
    required this.matrixAttemptId,
    required this.matrixCellId,
    required this.attemptTimestamp,
    this.carryDistanceMeters,
    this.totalDistanceMeters,
    this.leftDeviationMeters,
    this.rightDeviationMeters,
    this.rolloutDistanceMeters,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['MatrixAttemptID'] = Variable<String>(matrixAttemptId);
    map['MatrixCellID'] = Variable<String>(matrixCellId);
    map['AttemptTimestamp'] = Variable<DateTime>(attemptTimestamp);
    if (!nullToAbsent || carryDistanceMeters != null) {
      map['CarryDistanceMeters'] = Variable<double>(carryDistanceMeters);
    }
    if (!nullToAbsent || totalDistanceMeters != null) {
      map['TotalDistanceMeters'] = Variable<double>(totalDistanceMeters);
    }
    if (!nullToAbsent || leftDeviationMeters != null) {
      map['LeftDeviationMeters'] = Variable<double>(leftDeviationMeters);
    }
    if (!nullToAbsent || rightDeviationMeters != null) {
      map['RightDeviationMeters'] = Variable<double>(rightDeviationMeters);
    }
    if (!nullToAbsent || rolloutDistanceMeters != null) {
      map['RolloutDistanceMeters'] = Variable<double>(rolloutDistanceMeters);
    }
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MatrixAttemptsCompanion toCompanion(bool nullToAbsent) {
    return MatrixAttemptsCompanion(
      matrixAttemptId: Value(matrixAttemptId),
      matrixCellId: Value(matrixCellId),
      attemptTimestamp: Value(attemptTimestamp),
      carryDistanceMeters: carryDistanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(carryDistanceMeters),
      totalDistanceMeters: totalDistanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDistanceMeters),
      leftDeviationMeters: leftDeviationMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(leftDeviationMeters),
      rightDeviationMeters: rightDeviationMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(rightDeviationMeters),
      rolloutDistanceMeters: rolloutDistanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(rolloutDistanceMeters),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MatrixAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatrixAttempt(
      matrixAttemptId: serializer.fromJson<String>(json['matrixAttemptId']),
      matrixCellId: serializer.fromJson<String>(json['matrixCellId']),
      attemptTimestamp: serializer.fromJson<DateTime>(json['attemptTimestamp']),
      carryDistanceMeters: serializer.fromJson<double?>(
        json['carryDistanceMeters'],
      ),
      totalDistanceMeters: serializer.fromJson<double?>(
        json['totalDistanceMeters'],
      ),
      leftDeviationMeters: serializer.fromJson<double?>(
        json['leftDeviationMeters'],
      ),
      rightDeviationMeters: serializer.fromJson<double?>(
        json['rightDeviationMeters'],
      ),
      rolloutDistanceMeters: serializer.fromJson<double?>(
        json['rolloutDistanceMeters'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matrixAttemptId': serializer.toJson<String>(matrixAttemptId),
      'matrixCellId': serializer.toJson<String>(matrixCellId),
      'attemptTimestamp': serializer.toJson<DateTime>(attemptTimestamp),
      'carryDistanceMeters': serializer.toJson<double?>(carryDistanceMeters),
      'totalDistanceMeters': serializer.toJson<double?>(totalDistanceMeters),
      'leftDeviationMeters': serializer.toJson<double?>(leftDeviationMeters),
      'rightDeviationMeters': serializer.toJson<double?>(rightDeviationMeters),
      'rolloutDistanceMeters': serializer.toJson<double?>(
        rolloutDistanceMeters,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MatrixAttempt copyWith({
    String? matrixAttemptId,
    String? matrixCellId,
    DateTime? attemptTimestamp,
    Value<double?> carryDistanceMeters = const Value.absent(),
    Value<double?> totalDistanceMeters = const Value.absent(),
    Value<double?> leftDeviationMeters = const Value.absent(),
    Value<double?> rightDeviationMeters = const Value.absent(),
    Value<double?> rolloutDistanceMeters = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MatrixAttempt(
    matrixAttemptId: matrixAttemptId ?? this.matrixAttemptId,
    matrixCellId: matrixCellId ?? this.matrixCellId,
    attemptTimestamp: attemptTimestamp ?? this.attemptTimestamp,
    carryDistanceMeters: carryDistanceMeters.present
        ? carryDistanceMeters.value
        : this.carryDistanceMeters,
    totalDistanceMeters: totalDistanceMeters.present
        ? totalDistanceMeters.value
        : this.totalDistanceMeters,
    leftDeviationMeters: leftDeviationMeters.present
        ? leftDeviationMeters.value
        : this.leftDeviationMeters,
    rightDeviationMeters: rightDeviationMeters.present
        ? rightDeviationMeters.value
        : this.rightDeviationMeters,
    rolloutDistanceMeters: rolloutDistanceMeters.present
        ? rolloutDistanceMeters.value
        : this.rolloutDistanceMeters,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MatrixAttempt copyWithCompanion(MatrixAttemptsCompanion data) {
    return MatrixAttempt(
      matrixAttemptId: data.matrixAttemptId.present
          ? data.matrixAttemptId.value
          : this.matrixAttemptId,
      matrixCellId: data.matrixCellId.present
          ? data.matrixCellId.value
          : this.matrixCellId,
      attemptTimestamp: data.attemptTimestamp.present
          ? data.attemptTimestamp.value
          : this.attemptTimestamp,
      carryDistanceMeters: data.carryDistanceMeters.present
          ? data.carryDistanceMeters.value
          : this.carryDistanceMeters,
      totalDistanceMeters: data.totalDistanceMeters.present
          ? data.totalDistanceMeters.value
          : this.totalDistanceMeters,
      leftDeviationMeters: data.leftDeviationMeters.present
          ? data.leftDeviationMeters.value
          : this.leftDeviationMeters,
      rightDeviationMeters: data.rightDeviationMeters.present
          ? data.rightDeviationMeters.value
          : this.rightDeviationMeters,
      rolloutDistanceMeters: data.rolloutDistanceMeters.present
          ? data.rolloutDistanceMeters.value
          : this.rolloutDistanceMeters,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatrixAttempt(')
          ..write('matrixAttemptId: $matrixAttemptId, ')
          ..write('matrixCellId: $matrixCellId, ')
          ..write('attemptTimestamp: $attemptTimestamp, ')
          ..write('carryDistanceMeters: $carryDistanceMeters, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('leftDeviationMeters: $leftDeviationMeters, ')
          ..write('rightDeviationMeters: $rightDeviationMeters, ')
          ..write('rolloutDistanceMeters: $rolloutDistanceMeters, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    matrixAttemptId,
    matrixCellId,
    attemptTimestamp,
    carryDistanceMeters,
    totalDistanceMeters,
    leftDeviationMeters,
    rightDeviationMeters,
    rolloutDistanceMeters,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatrixAttempt &&
          other.matrixAttemptId == this.matrixAttemptId &&
          other.matrixCellId == this.matrixCellId &&
          other.attemptTimestamp == this.attemptTimestamp &&
          other.carryDistanceMeters == this.carryDistanceMeters &&
          other.totalDistanceMeters == this.totalDistanceMeters &&
          other.leftDeviationMeters == this.leftDeviationMeters &&
          other.rightDeviationMeters == this.rightDeviationMeters &&
          other.rolloutDistanceMeters == this.rolloutDistanceMeters &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MatrixAttemptsCompanion extends UpdateCompanion<MatrixAttempt> {
  final Value<String> matrixAttemptId;
  final Value<String> matrixCellId;
  final Value<DateTime> attemptTimestamp;
  final Value<double?> carryDistanceMeters;
  final Value<double?> totalDistanceMeters;
  final Value<double?> leftDeviationMeters;
  final Value<double?> rightDeviationMeters;
  final Value<double?> rolloutDistanceMeters;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MatrixAttemptsCompanion({
    this.matrixAttemptId = const Value.absent(),
    this.matrixCellId = const Value.absent(),
    this.attemptTimestamp = const Value.absent(),
    this.carryDistanceMeters = const Value.absent(),
    this.totalDistanceMeters = const Value.absent(),
    this.leftDeviationMeters = const Value.absent(),
    this.rightDeviationMeters = const Value.absent(),
    this.rolloutDistanceMeters = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatrixAttemptsCompanion.insert({
    required String matrixAttemptId,
    required String matrixCellId,
    this.attemptTimestamp = const Value.absent(),
    this.carryDistanceMeters = const Value.absent(),
    this.totalDistanceMeters = const Value.absent(),
    this.leftDeviationMeters = const Value.absent(),
    this.rightDeviationMeters = const Value.absent(),
    this.rolloutDistanceMeters = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : matrixAttemptId = Value(matrixAttemptId),
       matrixCellId = Value(matrixCellId);
  static Insertable<MatrixAttempt> custom({
    Expression<String>? matrixAttemptId,
    Expression<String>? matrixCellId,
    Expression<DateTime>? attemptTimestamp,
    Expression<double>? carryDistanceMeters,
    Expression<double>? totalDistanceMeters,
    Expression<double>? leftDeviationMeters,
    Expression<double>? rightDeviationMeters,
    Expression<double>? rolloutDistanceMeters,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matrixAttemptId != null) 'MatrixAttemptID': matrixAttemptId,
      if (matrixCellId != null) 'MatrixCellID': matrixCellId,
      if (attemptTimestamp != null) 'AttemptTimestamp': attemptTimestamp,
      if (carryDistanceMeters != null)
        'CarryDistanceMeters': carryDistanceMeters,
      if (totalDistanceMeters != null)
        'TotalDistanceMeters': totalDistanceMeters,
      if (leftDeviationMeters != null)
        'LeftDeviationMeters': leftDeviationMeters,
      if (rightDeviationMeters != null)
        'RightDeviationMeters': rightDeviationMeters,
      if (rolloutDistanceMeters != null)
        'RolloutDistanceMeters': rolloutDistanceMeters,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatrixAttemptsCompanion copyWith({
    Value<String>? matrixAttemptId,
    Value<String>? matrixCellId,
    Value<DateTime>? attemptTimestamp,
    Value<double?>? carryDistanceMeters,
    Value<double?>? totalDistanceMeters,
    Value<double?>? leftDeviationMeters,
    Value<double?>? rightDeviationMeters,
    Value<double?>? rolloutDistanceMeters,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MatrixAttemptsCompanion(
      matrixAttemptId: matrixAttemptId ?? this.matrixAttemptId,
      matrixCellId: matrixCellId ?? this.matrixCellId,
      attemptTimestamp: attemptTimestamp ?? this.attemptTimestamp,
      carryDistanceMeters: carryDistanceMeters ?? this.carryDistanceMeters,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      leftDeviationMeters: leftDeviationMeters ?? this.leftDeviationMeters,
      rightDeviationMeters: rightDeviationMeters ?? this.rightDeviationMeters,
      rolloutDistanceMeters:
          rolloutDistanceMeters ?? this.rolloutDistanceMeters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matrixAttemptId.present) {
      map['MatrixAttemptID'] = Variable<String>(matrixAttemptId.value);
    }
    if (matrixCellId.present) {
      map['MatrixCellID'] = Variable<String>(matrixCellId.value);
    }
    if (attemptTimestamp.present) {
      map['AttemptTimestamp'] = Variable<DateTime>(attemptTimestamp.value);
    }
    if (carryDistanceMeters.present) {
      map['CarryDistanceMeters'] = Variable<double>(carryDistanceMeters.value);
    }
    if (totalDistanceMeters.present) {
      map['TotalDistanceMeters'] = Variable<double>(totalDistanceMeters.value);
    }
    if (leftDeviationMeters.present) {
      map['LeftDeviationMeters'] = Variable<double>(leftDeviationMeters.value);
    }
    if (rightDeviationMeters.present) {
      map['RightDeviationMeters'] = Variable<double>(
        rightDeviationMeters.value,
      );
    }
    if (rolloutDistanceMeters.present) {
      map['RolloutDistanceMeters'] = Variable<double>(
        rolloutDistanceMeters.value,
      );
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatrixAttemptsCompanion(')
          ..write('matrixAttemptId: $matrixAttemptId, ')
          ..write('matrixCellId: $matrixCellId, ')
          ..write('attemptTimestamp: $attemptTimestamp, ')
          ..write('carryDistanceMeters: $carryDistanceMeters, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('leftDeviationMeters: $leftDeviationMeters, ')
          ..write('rightDeviationMeters: $rightDeviationMeters, ')
          ..write('rolloutDistanceMeters: $rolloutDistanceMeters, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PerformanceSnapshotsTable extends PerformanceSnapshots
    with TableInfo<$PerformanceSnapshotsTable, PerformanceSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PerformanceSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
    'SnapshotID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'UserID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matrixRunIdMeta = const VerificationMeta(
    'matrixRunId',
  );
  @override
  late final GeneratedColumn<String> matrixRunId = GeneratedColumn<String>(
    'MatrixRunID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MatrixType?, String> matrixType =
      GeneratedColumn<String>(
        'MatrixType',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MatrixType?>(
        $PerformanceSnapshotsTable.$convertermatrixTypen,
      );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'IsPrimary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsPrimary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'Label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snapshotTimestampMeta = const VerificationMeta(
    'snapshotTimestamp',
  );
  @override
  late final GeneratedColumn<DateTime> snapshotTimestamp =
      GeneratedColumn<DateTime>(
        'SnapshotTimestamp',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        clientDefault: () => DateTime.now(),
      );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'IsDeleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("IsDeleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    snapshotId,
    userId,
    matrixRunId,
    matrixType,
    isPrimary,
    label,
    snapshotTimestamp,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'PerformanceSnapshot';
  @override
  VerificationContext validateIntegrity(
    Insertable<PerformanceSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('SnapshotID')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['SnapshotID']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('UserID')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['UserID']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('MatrixRunID')) {
      context.handle(
        _matrixRunIdMeta,
        matrixRunId.isAcceptableOrUnknown(
          data['MatrixRunID']!,
          _matrixRunIdMeta,
        ),
      );
    }
    if (data.containsKey('IsPrimary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['IsPrimary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('Label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['Label']!, _labelMeta),
      );
    }
    if (data.containsKey('SnapshotTimestamp')) {
      context.handle(
        _snapshotTimestampMeta,
        snapshotTimestamp.isAcceptableOrUnknown(
          data['SnapshotTimestamp']!,
          _snapshotTimestampMeta,
        ),
      );
    }
    if (data.containsKey('IsDeleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['IsDeleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {snapshotId};
  @override
  PerformanceSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PerformanceSnapshot(
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SnapshotID'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}UserID'],
      )!,
      matrixRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MatrixRunID'],
      ),
      matrixType: $PerformanceSnapshotsTable.$convertermatrixTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}MatrixType'],
        ),
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsPrimary'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Label'],
      ),
      snapshotTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}SnapshotTimestamp'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}IsDeleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $PerformanceSnapshotsTable createAlias(String alias) {
    return $PerformanceSnapshotsTable(attachedDatabase, alias);
  }

  static TypeConverter<MatrixType, String> $convertermatrixType =
      const MatrixTypeConverter();
  static TypeConverter<MatrixType?, String?> $convertermatrixTypen =
      NullAwareTypeConverter.wrap($convertermatrixType);
}

class PerformanceSnapshot extends DataClass
    implements Insertable<PerformanceSnapshot> {
  final String snapshotId;
  final String userId;
  final String? matrixRunId;
  final MatrixType? matrixType;
  final bool isPrimary;
  final String? label;
  final DateTime snapshotTimestamp;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PerformanceSnapshot({
    required this.snapshotId,
    required this.userId,
    this.matrixRunId,
    this.matrixType,
    required this.isPrimary,
    this.label,
    required this.snapshotTimestamp,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['SnapshotID'] = Variable<String>(snapshotId);
    map['UserID'] = Variable<String>(userId);
    if (!nullToAbsent || matrixRunId != null) {
      map['MatrixRunID'] = Variable<String>(matrixRunId);
    }
    if (!nullToAbsent || matrixType != null) {
      map['MatrixType'] = Variable<String>(
        $PerformanceSnapshotsTable.$convertermatrixTypen.toSql(matrixType),
      );
    }
    map['IsPrimary'] = Variable<bool>(isPrimary);
    if (!nullToAbsent || label != null) {
      map['Label'] = Variable<String>(label);
    }
    map['SnapshotTimestamp'] = Variable<DateTime>(snapshotTimestamp);
    map['IsDeleted'] = Variable<bool>(isDeleted);
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PerformanceSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return PerformanceSnapshotsCompanion(
      snapshotId: Value(snapshotId),
      userId: Value(userId),
      matrixRunId: matrixRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(matrixRunId),
      matrixType: matrixType == null && nullToAbsent
          ? const Value.absent()
          : Value(matrixType),
      isPrimary: Value(isPrimary),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      snapshotTimestamp: Value(snapshotTimestamp),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PerformanceSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PerformanceSnapshot(
      snapshotId: serializer.fromJson<String>(json['snapshotId']),
      userId: serializer.fromJson<String>(json['userId']),
      matrixRunId: serializer.fromJson<String?>(json['matrixRunId']),
      matrixType: serializer.fromJson<MatrixType?>(json['matrixType']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      label: serializer.fromJson<String?>(json['label']),
      snapshotTimestamp: serializer.fromJson<DateTime>(
        json['snapshotTimestamp'],
      ),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'snapshotId': serializer.toJson<String>(snapshotId),
      'userId': serializer.toJson<String>(userId),
      'matrixRunId': serializer.toJson<String?>(matrixRunId),
      'matrixType': serializer.toJson<MatrixType?>(matrixType),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'label': serializer.toJson<String?>(label),
      'snapshotTimestamp': serializer.toJson<DateTime>(snapshotTimestamp),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PerformanceSnapshot copyWith({
    String? snapshotId,
    String? userId,
    Value<String?> matrixRunId = const Value.absent(),
    Value<MatrixType?> matrixType = const Value.absent(),
    bool? isPrimary,
    Value<String?> label = const Value.absent(),
    DateTime? snapshotTimestamp,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PerformanceSnapshot(
    snapshotId: snapshotId ?? this.snapshotId,
    userId: userId ?? this.userId,
    matrixRunId: matrixRunId.present ? matrixRunId.value : this.matrixRunId,
    matrixType: matrixType.present ? matrixType.value : this.matrixType,
    isPrimary: isPrimary ?? this.isPrimary,
    label: label.present ? label.value : this.label,
    snapshotTimestamp: snapshotTimestamp ?? this.snapshotTimestamp,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PerformanceSnapshot copyWithCompanion(PerformanceSnapshotsCompanion data) {
    return PerformanceSnapshot(
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      userId: data.userId.present ? data.userId.value : this.userId,
      matrixRunId: data.matrixRunId.present
          ? data.matrixRunId.value
          : this.matrixRunId,
      matrixType: data.matrixType.present
          ? data.matrixType.value
          : this.matrixType,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      label: data.label.present ? data.label.value : this.label,
      snapshotTimestamp: data.snapshotTimestamp.present
          ? data.snapshotTimestamp.value
          : this.snapshotTimestamp,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PerformanceSnapshot(')
          ..write('snapshotId: $snapshotId, ')
          ..write('userId: $userId, ')
          ..write('matrixRunId: $matrixRunId, ')
          ..write('matrixType: $matrixType, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('label: $label, ')
          ..write('snapshotTimestamp: $snapshotTimestamp, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    snapshotId,
    userId,
    matrixRunId,
    matrixType,
    isPrimary,
    label,
    snapshotTimestamp,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PerformanceSnapshot &&
          other.snapshotId == this.snapshotId &&
          other.userId == this.userId &&
          other.matrixRunId == this.matrixRunId &&
          other.matrixType == this.matrixType &&
          other.isPrimary == this.isPrimary &&
          other.label == this.label &&
          other.snapshotTimestamp == this.snapshotTimestamp &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PerformanceSnapshotsCompanion
    extends UpdateCompanion<PerformanceSnapshot> {
  final Value<String> snapshotId;
  final Value<String> userId;
  final Value<String?> matrixRunId;
  final Value<MatrixType?> matrixType;
  final Value<bool> isPrimary;
  final Value<String?> label;
  final Value<DateTime> snapshotTimestamp;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PerformanceSnapshotsCompanion({
    this.snapshotId = const Value.absent(),
    this.userId = const Value.absent(),
    this.matrixRunId = const Value.absent(),
    this.matrixType = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.label = const Value.absent(),
    this.snapshotTimestamp = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PerformanceSnapshotsCompanion.insert({
    required String snapshotId,
    required String userId,
    this.matrixRunId = const Value.absent(),
    this.matrixType = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.label = const Value.absent(),
    this.snapshotTimestamp = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : snapshotId = Value(snapshotId),
       userId = Value(userId);
  static Insertable<PerformanceSnapshot> custom({
    Expression<String>? snapshotId,
    Expression<String>? userId,
    Expression<String>? matrixRunId,
    Expression<String>? matrixType,
    Expression<bool>? isPrimary,
    Expression<String>? label,
    Expression<DateTime>? snapshotTimestamp,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (snapshotId != null) 'SnapshotID': snapshotId,
      if (userId != null) 'UserID': userId,
      if (matrixRunId != null) 'MatrixRunID': matrixRunId,
      if (matrixType != null) 'MatrixType': matrixType,
      if (isPrimary != null) 'IsPrimary': isPrimary,
      if (label != null) 'Label': label,
      if (snapshotTimestamp != null) 'SnapshotTimestamp': snapshotTimestamp,
      if (isDeleted != null) 'IsDeleted': isDeleted,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PerformanceSnapshotsCompanion copyWith({
    Value<String>? snapshotId,
    Value<String>? userId,
    Value<String?>? matrixRunId,
    Value<MatrixType?>? matrixType,
    Value<bool>? isPrimary,
    Value<String?>? label,
    Value<DateTime>? snapshotTimestamp,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PerformanceSnapshotsCompanion(
      snapshotId: snapshotId ?? this.snapshotId,
      userId: userId ?? this.userId,
      matrixRunId: matrixRunId ?? this.matrixRunId,
      matrixType: matrixType ?? this.matrixType,
      isPrimary: isPrimary ?? this.isPrimary,
      label: label ?? this.label,
      snapshotTimestamp: snapshotTimestamp ?? this.snapshotTimestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (snapshotId.present) {
      map['SnapshotID'] = Variable<String>(snapshotId.value);
    }
    if (userId.present) {
      map['UserID'] = Variable<String>(userId.value);
    }
    if (matrixRunId.present) {
      map['MatrixRunID'] = Variable<String>(matrixRunId.value);
    }
    if (matrixType.present) {
      map['MatrixType'] = Variable<String>(
        $PerformanceSnapshotsTable.$convertermatrixTypen.toSql(
          matrixType.value,
        ),
      );
    }
    if (isPrimary.present) {
      map['IsPrimary'] = Variable<bool>(isPrimary.value);
    }
    if (label.present) {
      map['Label'] = Variable<String>(label.value);
    }
    if (snapshotTimestamp.present) {
      map['SnapshotTimestamp'] = Variable<DateTime>(snapshotTimestamp.value);
    }
    if (isDeleted.present) {
      map['IsDeleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PerformanceSnapshotsCompanion(')
          ..write('snapshotId: $snapshotId, ')
          ..write('userId: $userId, ')
          ..write('matrixRunId: $matrixRunId, ')
          ..write('matrixType: $matrixType, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('label: $label, ')
          ..write('snapshotTimestamp: $snapshotTimestamp, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotClubsTable extends SnapshotClubs
    with TableInfo<$SnapshotClubsTable, SnapshotClub> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotClubsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _snapshotClubIdMeta = const VerificationMeta(
    'snapshotClubId',
  );
  @override
  late final GeneratedColumn<String> snapshotClubId = GeneratedColumn<String>(
    'SnapshotClubID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
    'SnapshotID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<String> clubId = GeneratedColumn<String>(
    'ClubID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _carryDistanceMetersMeta =
      const VerificationMeta('carryDistanceMeters');
  @override
  late final GeneratedColumn<double> carryDistanceMeters =
      GeneratedColumn<double>(
        'CarryDistanceMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalDistanceMetersMeta =
      const VerificationMeta('totalDistanceMeters');
  @override
  late final GeneratedColumn<double> totalDistanceMeters =
      GeneratedColumn<double>(
        'TotalDistanceMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dispersionLeftMetersMeta =
      const VerificationMeta('dispersionLeftMeters');
  @override
  late final GeneratedColumn<double> dispersionLeftMeters =
      GeneratedColumn<double>(
        'DispersionLeftMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dispersionRightMetersMeta =
      const VerificationMeta('dispersionRightMeters');
  @override
  late final GeneratedColumn<double> dispersionRightMeters =
      GeneratedColumn<double>(
        'DispersionRightMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rolloutDistanceMetersMeta =
      const VerificationMeta('rolloutDistanceMeters');
  @override
  late final GeneratedColumn<double> rolloutDistanceMeters =
      GeneratedColumn<double>(
        'RolloutDistanceMeters',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'CreatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    snapshotClubId,
    snapshotId,
    clubId,
    carryDistanceMeters,
    totalDistanceMeters,
    dispersionLeftMeters,
    dispersionRightMeters,
    rolloutDistanceMeters,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SnapshotClub';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotClub> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('SnapshotClubID')) {
      context.handle(
        _snapshotClubIdMeta,
        snapshotClubId.isAcceptableOrUnknown(
          data['SnapshotClubID']!,
          _snapshotClubIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotClubIdMeta);
    }
    if (data.containsKey('SnapshotID')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['SnapshotID']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('ClubID')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['ClubID']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('CarryDistanceMeters')) {
      context.handle(
        _carryDistanceMetersMeta,
        carryDistanceMeters.isAcceptableOrUnknown(
          data['CarryDistanceMeters']!,
          _carryDistanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('TotalDistanceMeters')) {
      context.handle(
        _totalDistanceMetersMeta,
        totalDistanceMeters.isAcceptableOrUnknown(
          data['TotalDistanceMeters']!,
          _totalDistanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('DispersionLeftMeters')) {
      context.handle(
        _dispersionLeftMetersMeta,
        dispersionLeftMeters.isAcceptableOrUnknown(
          data['DispersionLeftMeters']!,
          _dispersionLeftMetersMeta,
        ),
      );
    }
    if (data.containsKey('DispersionRightMeters')) {
      context.handle(
        _dispersionRightMetersMeta,
        dispersionRightMeters.isAcceptableOrUnknown(
          data['DispersionRightMeters']!,
          _dispersionRightMetersMeta,
        ),
      );
    }
    if (data.containsKey('RolloutDistanceMeters')) {
      context.handle(
        _rolloutDistanceMetersMeta,
        rolloutDistanceMeters.isAcceptableOrUnknown(
          data['RolloutDistanceMeters']!,
          _rolloutDistanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('CreatedAt')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['CreatedAt']!, _createdAtMeta),
      );
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {snapshotClubId};
  @override
  SnapshotClub map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotClub(
      snapshotClubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SnapshotClubID'],
      )!,
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}SnapshotID'],
      )!,
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ClubID'],
      )!,
      carryDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}CarryDistanceMeters'],
      ),
      totalDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}TotalDistanceMeters'],
      ),
      dispersionLeftMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}DispersionLeftMeters'],
      ),
      dispersionRightMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}DispersionRightMeters'],
      ),
      rolloutDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}RolloutDistanceMeters'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}CreatedAt'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $SnapshotClubsTable createAlias(String alias) {
    return $SnapshotClubsTable(attachedDatabase, alias);
  }
}

class SnapshotClub extends DataClass implements Insertable<SnapshotClub> {
  final String snapshotClubId;
  final String snapshotId;
  final String clubId;
  final double? carryDistanceMeters;
  final double? totalDistanceMeters;
  final double? dispersionLeftMeters;
  final double? dispersionRightMeters;
  final double? rolloutDistanceMeters;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SnapshotClub({
    required this.snapshotClubId,
    required this.snapshotId,
    required this.clubId,
    this.carryDistanceMeters,
    this.totalDistanceMeters,
    this.dispersionLeftMeters,
    this.dispersionRightMeters,
    this.rolloutDistanceMeters,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['SnapshotClubID'] = Variable<String>(snapshotClubId);
    map['SnapshotID'] = Variable<String>(snapshotId);
    map['ClubID'] = Variable<String>(clubId);
    if (!nullToAbsent || carryDistanceMeters != null) {
      map['CarryDistanceMeters'] = Variable<double>(carryDistanceMeters);
    }
    if (!nullToAbsent || totalDistanceMeters != null) {
      map['TotalDistanceMeters'] = Variable<double>(totalDistanceMeters);
    }
    if (!nullToAbsent || dispersionLeftMeters != null) {
      map['DispersionLeftMeters'] = Variable<double>(dispersionLeftMeters);
    }
    if (!nullToAbsent || dispersionRightMeters != null) {
      map['DispersionRightMeters'] = Variable<double>(dispersionRightMeters);
    }
    if (!nullToAbsent || rolloutDistanceMeters != null) {
      map['RolloutDistanceMeters'] = Variable<double>(rolloutDistanceMeters);
    }
    map['CreatedAt'] = Variable<DateTime>(createdAt);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SnapshotClubsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotClubsCompanion(
      snapshotClubId: Value(snapshotClubId),
      snapshotId: Value(snapshotId),
      clubId: Value(clubId),
      carryDistanceMeters: carryDistanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(carryDistanceMeters),
      totalDistanceMeters: totalDistanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDistanceMeters),
      dispersionLeftMeters: dispersionLeftMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(dispersionLeftMeters),
      dispersionRightMeters: dispersionRightMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(dispersionRightMeters),
      rolloutDistanceMeters: rolloutDistanceMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(rolloutDistanceMeters),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SnapshotClub.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotClub(
      snapshotClubId: serializer.fromJson<String>(json['snapshotClubId']),
      snapshotId: serializer.fromJson<String>(json['snapshotId']),
      clubId: serializer.fromJson<String>(json['clubId']),
      carryDistanceMeters: serializer.fromJson<double?>(
        json['carryDistanceMeters'],
      ),
      totalDistanceMeters: serializer.fromJson<double?>(
        json['totalDistanceMeters'],
      ),
      dispersionLeftMeters: serializer.fromJson<double?>(
        json['dispersionLeftMeters'],
      ),
      dispersionRightMeters: serializer.fromJson<double?>(
        json['dispersionRightMeters'],
      ),
      rolloutDistanceMeters: serializer.fromJson<double?>(
        json['rolloutDistanceMeters'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'snapshotClubId': serializer.toJson<String>(snapshotClubId),
      'snapshotId': serializer.toJson<String>(snapshotId),
      'clubId': serializer.toJson<String>(clubId),
      'carryDistanceMeters': serializer.toJson<double?>(carryDistanceMeters),
      'totalDistanceMeters': serializer.toJson<double?>(totalDistanceMeters),
      'dispersionLeftMeters': serializer.toJson<double?>(dispersionLeftMeters),
      'dispersionRightMeters': serializer.toJson<double?>(
        dispersionRightMeters,
      ),
      'rolloutDistanceMeters': serializer.toJson<double?>(
        rolloutDistanceMeters,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SnapshotClub copyWith({
    String? snapshotClubId,
    String? snapshotId,
    String? clubId,
    Value<double?> carryDistanceMeters = const Value.absent(),
    Value<double?> totalDistanceMeters = const Value.absent(),
    Value<double?> dispersionLeftMeters = const Value.absent(),
    Value<double?> dispersionRightMeters = const Value.absent(),
    Value<double?> rolloutDistanceMeters = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SnapshotClub(
    snapshotClubId: snapshotClubId ?? this.snapshotClubId,
    snapshotId: snapshotId ?? this.snapshotId,
    clubId: clubId ?? this.clubId,
    carryDistanceMeters: carryDistanceMeters.present
        ? carryDistanceMeters.value
        : this.carryDistanceMeters,
    totalDistanceMeters: totalDistanceMeters.present
        ? totalDistanceMeters.value
        : this.totalDistanceMeters,
    dispersionLeftMeters: dispersionLeftMeters.present
        ? dispersionLeftMeters.value
        : this.dispersionLeftMeters,
    dispersionRightMeters: dispersionRightMeters.present
        ? dispersionRightMeters.value
        : this.dispersionRightMeters,
    rolloutDistanceMeters: rolloutDistanceMeters.present
        ? rolloutDistanceMeters.value
        : this.rolloutDistanceMeters,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SnapshotClub copyWithCompanion(SnapshotClubsCompanion data) {
    return SnapshotClub(
      snapshotClubId: data.snapshotClubId.present
          ? data.snapshotClubId.value
          : this.snapshotClubId,
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      carryDistanceMeters: data.carryDistanceMeters.present
          ? data.carryDistanceMeters.value
          : this.carryDistanceMeters,
      totalDistanceMeters: data.totalDistanceMeters.present
          ? data.totalDistanceMeters.value
          : this.totalDistanceMeters,
      dispersionLeftMeters: data.dispersionLeftMeters.present
          ? data.dispersionLeftMeters.value
          : this.dispersionLeftMeters,
      dispersionRightMeters: data.dispersionRightMeters.present
          ? data.dispersionRightMeters.value
          : this.dispersionRightMeters,
      rolloutDistanceMeters: data.rolloutDistanceMeters.present
          ? data.rolloutDistanceMeters.value
          : this.rolloutDistanceMeters,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotClub(')
          ..write('snapshotClubId: $snapshotClubId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('clubId: $clubId, ')
          ..write('carryDistanceMeters: $carryDistanceMeters, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('dispersionLeftMeters: $dispersionLeftMeters, ')
          ..write('dispersionRightMeters: $dispersionRightMeters, ')
          ..write('rolloutDistanceMeters: $rolloutDistanceMeters, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    snapshotClubId,
    snapshotId,
    clubId,
    carryDistanceMeters,
    totalDistanceMeters,
    dispersionLeftMeters,
    dispersionRightMeters,
    rolloutDistanceMeters,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotClub &&
          other.snapshotClubId == this.snapshotClubId &&
          other.snapshotId == this.snapshotId &&
          other.clubId == this.clubId &&
          other.carryDistanceMeters == this.carryDistanceMeters &&
          other.totalDistanceMeters == this.totalDistanceMeters &&
          other.dispersionLeftMeters == this.dispersionLeftMeters &&
          other.dispersionRightMeters == this.dispersionRightMeters &&
          other.rolloutDistanceMeters == this.rolloutDistanceMeters &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SnapshotClubsCompanion extends UpdateCompanion<SnapshotClub> {
  final Value<String> snapshotClubId;
  final Value<String> snapshotId;
  final Value<String> clubId;
  final Value<double?> carryDistanceMeters;
  final Value<double?> totalDistanceMeters;
  final Value<double?> dispersionLeftMeters;
  final Value<double?> dispersionRightMeters;
  final Value<double?> rolloutDistanceMeters;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SnapshotClubsCompanion({
    this.snapshotClubId = const Value.absent(),
    this.snapshotId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.carryDistanceMeters = const Value.absent(),
    this.totalDistanceMeters = const Value.absent(),
    this.dispersionLeftMeters = const Value.absent(),
    this.dispersionRightMeters = const Value.absent(),
    this.rolloutDistanceMeters = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotClubsCompanion.insert({
    required String snapshotClubId,
    required String snapshotId,
    required String clubId,
    this.carryDistanceMeters = const Value.absent(),
    this.totalDistanceMeters = const Value.absent(),
    this.dispersionLeftMeters = const Value.absent(),
    this.dispersionRightMeters = const Value.absent(),
    this.rolloutDistanceMeters = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : snapshotClubId = Value(snapshotClubId),
       snapshotId = Value(snapshotId),
       clubId = Value(clubId);
  static Insertable<SnapshotClub> custom({
    Expression<String>? snapshotClubId,
    Expression<String>? snapshotId,
    Expression<String>? clubId,
    Expression<double>? carryDistanceMeters,
    Expression<double>? totalDistanceMeters,
    Expression<double>? dispersionLeftMeters,
    Expression<double>? dispersionRightMeters,
    Expression<double>? rolloutDistanceMeters,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (snapshotClubId != null) 'SnapshotClubID': snapshotClubId,
      if (snapshotId != null) 'SnapshotID': snapshotId,
      if (clubId != null) 'ClubID': clubId,
      if (carryDistanceMeters != null)
        'CarryDistanceMeters': carryDistanceMeters,
      if (totalDistanceMeters != null)
        'TotalDistanceMeters': totalDistanceMeters,
      if (dispersionLeftMeters != null)
        'DispersionLeftMeters': dispersionLeftMeters,
      if (dispersionRightMeters != null)
        'DispersionRightMeters': dispersionRightMeters,
      if (rolloutDistanceMeters != null)
        'RolloutDistanceMeters': rolloutDistanceMeters,
      if (createdAt != null) 'CreatedAt': createdAt,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotClubsCompanion copyWith({
    Value<String>? snapshotClubId,
    Value<String>? snapshotId,
    Value<String>? clubId,
    Value<double?>? carryDistanceMeters,
    Value<double?>? totalDistanceMeters,
    Value<double?>? dispersionLeftMeters,
    Value<double?>? dispersionRightMeters,
    Value<double?>? rolloutDistanceMeters,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SnapshotClubsCompanion(
      snapshotClubId: snapshotClubId ?? this.snapshotClubId,
      snapshotId: snapshotId ?? this.snapshotId,
      clubId: clubId ?? this.clubId,
      carryDistanceMeters: carryDistanceMeters ?? this.carryDistanceMeters,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      dispersionLeftMeters: dispersionLeftMeters ?? this.dispersionLeftMeters,
      dispersionRightMeters:
          dispersionRightMeters ?? this.dispersionRightMeters,
      rolloutDistanceMeters:
          rolloutDistanceMeters ?? this.rolloutDistanceMeters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (snapshotClubId.present) {
      map['SnapshotClubID'] = Variable<String>(snapshotClubId.value);
    }
    if (snapshotId.present) {
      map['SnapshotID'] = Variable<String>(snapshotId.value);
    }
    if (clubId.present) {
      map['ClubID'] = Variable<String>(clubId.value);
    }
    if (carryDistanceMeters.present) {
      map['CarryDistanceMeters'] = Variable<double>(carryDistanceMeters.value);
    }
    if (totalDistanceMeters.present) {
      map['TotalDistanceMeters'] = Variable<double>(totalDistanceMeters.value);
    }
    if (dispersionLeftMeters.present) {
      map['DispersionLeftMeters'] = Variable<double>(
        dispersionLeftMeters.value,
      );
    }
    if (dispersionRightMeters.present) {
      map['DispersionRightMeters'] = Variable<double>(
        dispersionRightMeters.value,
      );
    }
    if (rolloutDistanceMeters.present) {
      map['RolloutDistanceMeters'] = Variable<double>(
        rolloutDistanceMeters.value,
      );
    }
    if (createdAt.present) {
      map['CreatedAt'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotClubsCompanion(')
          ..write('snapshotClubId: $snapshotClubId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('clubId: $clubId, ')
          ..write('carryDistanceMeters: $carryDistanceMeters, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('dispersionLeftMeters: $dispersionLeftMeters, ')
          ..write('dispersionRightMeters: $dispersionRightMeters, ')
          ..write('rolloutDistanceMeters: $rolloutDistanceMeters, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetadataEntriesTable extends SyncMetadataEntries
    with TableInfo<$SyncMetadataEntriesTable, SyncMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetadataEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'Key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'Value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'UpdatedAt',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'SyncMetadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetadataEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('Key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['Key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('Value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['Value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('UpdatedAt')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['UpdatedAt']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetadataEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}Value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}UpdatedAt'],
      )!,
    );
  }

  @override
  $SyncMetadataEntriesTable createAlias(String alias) {
    return $SyncMetadataEntriesTable(attachedDatabase, alias);
  }
}

class SyncMetadataEntry extends DataClass
    implements Insertable<SyncMetadataEntry> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const SyncMetadataEntry({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['Key'] = Variable<String>(key);
    map['Value'] = Variable<String>(value);
    map['UpdatedAt'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncMetadataEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncMetadataEntriesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncMetadataEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetadataEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncMetadataEntry copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => SyncMetadataEntry(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncMetadataEntry copyWithCompanion(SyncMetadataEntriesCompanion data) {
    return SyncMetadataEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntry(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetadataEntry &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SyncMetadataEntriesCompanion extends UpdateCompanion<SyncMetadataEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncMetadataEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetadataEntriesCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncMetadataEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'Key': key,
      if (value != null) 'Value': value,
      if (updatedAt != null) 'UpdatedAt': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetadataEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncMetadataEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['Key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['Value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['UpdatedAt'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetadataEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventTypeRefsTable eventTypeRefs = $EventTypeRefsTable(this);
  late final $MetricSchemasTable metricSchemas = $MetricSchemasTable(this);
  late final $SubskillRefsTable subskillRefs = $SubskillRefsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $DrillsTable drills = $DrillsTable(this);
  late final $PracticeBlocksTable practiceBlocks = $PracticeBlocksTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SetsTable sets = $SetsTable(this);
  late final $InstancesTable instances = $InstancesTable(this);
  late final $PracticeEntriesTable practiceEntries = $PracticeEntriesTable(
    this,
  );
  late final $UserDrillAdoptionsTable userDrillAdoptions =
      $UserDrillAdoptionsTable(this);
  late final $UserClubsTable userClubs = $UserClubsTable(this);
  late final $ClubPerformanceProfilesTable clubPerformanceProfiles =
      $ClubPerformanceProfilesTable(this);
  late final $UserSkillAreaClubMappingsTable userSkillAreaClubMappings =
      $UserSkillAreaClubMappingsTable(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $SchedulesTable schedules = $SchedulesTable(this);
  late final $CalendarDaysTable calendarDays = $CalendarDaysTable(this);
  late final $RoutineInstancesTable routineInstances = $RoutineInstancesTable(
    this,
  );
  late final $ScheduleInstancesTable scheduleInstances =
      $ScheduleInstancesTable(this);
  late final $MaterialisedWindowStatesTable materialisedWindowStates =
      $MaterialisedWindowStatesTable(this);
  late final $MaterialisedSubskillScoresTable materialisedSubskillScores =
      $MaterialisedSubskillScoresTable(this);
  late final $MaterialisedSkillAreaScoresTable materialisedSkillAreaScores =
      $MaterialisedSkillAreaScoresTable(this);
  late final $MaterialisedOverallScoresTable materialisedOverallScores =
      $MaterialisedOverallScoresTable(this);
  late final $EventLogsTable eventLogs = $EventLogsTable(this);
  late final $UserDevicesTable userDevices = $UserDevicesTable(this);
  late final $UserScoringLocksTable userScoringLocks = $UserScoringLocksTable(
    this,
  );
  late final $MatrixRunsTable matrixRuns = $MatrixRunsTable(this);
  late final $MatrixAxesTable matrixAxes = $MatrixAxesTable(this);
  late final $MatrixAxisValuesTable matrixAxisValues = $MatrixAxisValuesTable(
    this,
  );
  late final $MatrixCellsTable matrixCells = $MatrixCellsTable(this);
  late final $MatrixAttemptsTable matrixAttempts = $MatrixAttemptsTable(this);
  late final $PerformanceSnapshotsTable performanceSnapshots =
      $PerformanceSnapshotsTable(this);
  late final $SnapshotClubsTable snapshotClubs = $SnapshotClubsTable(this);
  late final $SyncMetadataEntriesTable syncMetadataEntries =
      $SyncMetadataEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    eventTypeRefs,
    metricSchemas,
    subskillRefs,
    users,
    drills,
    practiceBlocks,
    sessions,
    sets,
    instances,
    practiceEntries,
    userDrillAdoptions,
    userClubs,
    clubPerformanceProfiles,
    userSkillAreaClubMappings,
    routines,
    schedules,
    calendarDays,
    routineInstances,
    scheduleInstances,
    materialisedWindowStates,
    materialisedSubskillScores,
    materialisedSkillAreaScores,
    materialisedOverallScores,
    eventLogs,
    userDevices,
    userScoringLocks,
    matrixRuns,
    matrixAxes,
    matrixAxisValues,
    matrixCells,
    matrixAttempts,
    performanceSnapshots,
    snapshotClubs,
    syncMetadataEntries,
  ];
}

typedef $$EventTypeRefsTableCreateCompanionBuilder =
    EventTypeRefsCompanion Function({
      required String eventTypeId,
      required String name,
      Value<String?> description,
      Value<int> rowid,
    });
typedef $$EventTypeRefsTableUpdateCompanionBuilder =
    EventTypeRefsCompanion Function({
      Value<String> eventTypeId,
      Value<String> name,
      Value<String?> description,
      Value<int> rowid,
    });

class $$EventTypeRefsTableFilterComposer
    extends Composer<_$AppDatabase, $EventTypeRefsTable> {
  $$EventTypeRefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventTypeId => $composableBuilder(
    column: $table.eventTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventTypeRefsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventTypeRefsTable> {
  $$EventTypeRefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventTypeId => $composableBuilder(
    column: $table.eventTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventTypeRefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventTypeRefsTable> {
  $$EventTypeRefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventTypeId => $composableBuilder(
    column: $table.eventTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$EventTypeRefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventTypeRefsTable,
          EventTypeRef,
          $$EventTypeRefsTableFilterComposer,
          $$EventTypeRefsTableOrderingComposer,
          $$EventTypeRefsTableAnnotationComposer,
          $$EventTypeRefsTableCreateCompanionBuilder,
          $$EventTypeRefsTableUpdateCompanionBuilder,
          (
            EventTypeRef,
            BaseReferences<_$AppDatabase, $EventTypeRefsTable, EventTypeRef>,
          ),
          EventTypeRef,
          PrefetchHooks Function()
        > {
  $$EventTypeRefsTableTableManager(_$AppDatabase db, $EventTypeRefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventTypeRefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventTypeRefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventTypeRefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventTypeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventTypeRefsCompanion(
                eventTypeId: eventTypeId,
                name: name,
                description: description,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventTypeId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventTypeRefsCompanion.insert(
                eventTypeId: eventTypeId,
                name: name,
                description: description,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventTypeRefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventTypeRefsTable,
      EventTypeRef,
      $$EventTypeRefsTableFilterComposer,
      $$EventTypeRefsTableOrderingComposer,
      $$EventTypeRefsTableAnnotationComposer,
      $$EventTypeRefsTableCreateCompanionBuilder,
      $$EventTypeRefsTableUpdateCompanionBuilder,
      (
        EventTypeRef,
        BaseReferences<_$AppDatabase, $EventTypeRefsTable, EventTypeRef>,
      ),
      EventTypeRef,
      PrefetchHooks Function()
    >;
typedef $$MetricSchemasTableCreateCompanionBuilder =
    MetricSchemasCompanion Function({
      required String metricSchemaId,
      required String name,
      required InputMode inputMode,
      Value<double?> hardMinInput,
      Value<double?> hardMaxInput,
      Value<String?> validationRules,
      required String scoringAdapterBinding,
      Value<int> rowid,
    });
typedef $$MetricSchemasTableUpdateCompanionBuilder =
    MetricSchemasCompanion Function({
      Value<String> metricSchemaId,
      Value<String> name,
      Value<InputMode> inputMode,
      Value<double?> hardMinInput,
      Value<double?> hardMaxInput,
      Value<String?> validationRules,
      Value<String> scoringAdapterBinding,
      Value<int> rowid,
    });

class $$MetricSchemasTableFilterComposer
    extends Composer<_$AppDatabase, $MetricSchemasTable> {
  $$MetricSchemasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get metricSchemaId => $composableBuilder(
    column: $table.metricSchemaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InputMode, InputMode, String> get inputMode =>
      $composableBuilder(
        column: $table.inputMode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get hardMinInput => $composableBuilder(
    column: $table.hardMinInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hardMaxInput => $composableBuilder(
    column: $table.hardMaxInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get validationRules => $composableBuilder(
    column: $table.validationRules,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoringAdapterBinding => $composableBuilder(
    column: $table.scoringAdapterBinding,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetricSchemasTableOrderingComposer
    extends Composer<_$AppDatabase, $MetricSchemasTable> {
  $$MetricSchemasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get metricSchemaId => $composableBuilder(
    column: $table.metricSchemaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hardMinInput => $composableBuilder(
    column: $table.hardMinInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hardMaxInput => $composableBuilder(
    column: $table.hardMaxInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get validationRules => $composableBuilder(
    column: $table.validationRules,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringAdapterBinding => $composableBuilder(
    column: $table.scoringAdapterBinding,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetricSchemasTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetricSchemasTable> {
  $$MetricSchemasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get metricSchemaId => $composableBuilder(
    column: $table.metricSchemaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<InputMode, String> get inputMode =>
      $composableBuilder(column: $table.inputMode, builder: (column) => column);

  GeneratedColumn<double> get hardMinInput => $composableBuilder(
    column: $table.hardMinInput,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hardMaxInput => $composableBuilder(
    column: $table.hardMaxInput,
    builder: (column) => column,
  );

  GeneratedColumn<String> get validationRules => $composableBuilder(
    column: $table.validationRules,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scoringAdapterBinding => $composableBuilder(
    column: $table.scoringAdapterBinding,
    builder: (column) => column,
  );
}

class $$MetricSchemasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetricSchemasTable,
          MetricSchema,
          $$MetricSchemasTableFilterComposer,
          $$MetricSchemasTableOrderingComposer,
          $$MetricSchemasTableAnnotationComposer,
          $$MetricSchemasTableCreateCompanionBuilder,
          $$MetricSchemasTableUpdateCompanionBuilder,
          (
            MetricSchema,
            BaseReferences<_$AppDatabase, $MetricSchemasTable, MetricSchema>,
          ),
          MetricSchema,
          PrefetchHooks Function()
        > {
  $$MetricSchemasTableTableManager(_$AppDatabase db, $MetricSchemasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetricSchemasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetricSchemasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetricSchemasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> metricSchemaId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<InputMode> inputMode = const Value.absent(),
                Value<double?> hardMinInput = const Value.absent(),
                Value<double?> hardMaxInput = const Value.absent(),
                Value<String?> validationRules = const Value.absent(),
                Value<String> scoringAdapterBinding = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetricSchemasCompanion(
                metricSchemaId: metricSchemaId,
                name: name,
                inputMode: inputMode,
                hardMinInput: hardMinInput,
                hardMaxInput: hardMaxInput,
                validationRules: validationRules,
                scoringAdapterBinding: scoringAdapterBinding,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String metricSchemaId,
                required String name,
                required InputMode inputMode,
                Value<double?> hardMinInput = const Value.absent(),
                Value<double?> hardMaxInput = const Value.absent(),
                Value<String?> validationRules = const Value.absent(),
                required String scoringAdapterBinding,
                Value<int> rowid = const Value.absent(),
              }) => MetricSchemasCompanion.insert(
                metricSchemaId: metricSchemaId,
                name: name,
                inputMode: inputMode,
                hardMinInput: hardMinInput,
                hardMaxInput: hardMaxInput,
                validationRules: validationRules,
                scoringAdapterBinding: scoringAdapterBinding,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricSchemasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetricSchemasTable,
      MetricSchema,
      $$MetricSchemasTableFilterComposer,
      $$MetricSchemasTableOrderingComposer,
      $$MetricSchemasTableAnnotationComposer,
      $$MetricSchemasTableCreateCompanionBuilder,
      $$MetricSchemasTableUpdateCompanionBuilder,
      (
        MetricSchema,
        BaseReferences<_$AppDatabase, $MetricSchemasTable, MetricSchema>,
      ),
      MetricSchema,
      PrefetchHooks Function()
    >;
typedef $$SubskillRefsTableCreateCompanionBuilder =
    SubskillRefsCompanion Function({
      required String subskillId,
      required SkillArea skillArea,
      required String name,
      required int allocation,
      Value<int> windowSize,
      Value<int> rowid,
    });
typedef $$SubskillRefsTableUpdateCompanionBuilder =
    SubskillRefsCompanion Function({
      Value<String> subskillId,
      Value<SkillArea> skillArea,
      Value<String> name,
      Value<int> allocation,
      Value<int> windowSize,
      Value<int> rowid,
    });

class $$SubskillRefsTableFilterComposer
    extends Composer<_$AppDatabase, $SubskillRefsTable> {
  $$SubskillRefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subskillId => $composableBuilder(
    column: $table.subskillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SkillArea, SkillArea, String> get skillArea =>
      $composableBuilder(
        column: $table.skillArea,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowSize => $composableBuilder(
    column: $table.windowSize,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubskillRefsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubskillRefsTable> {
  $$SubskillRefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subskillId => $composableBuilder(
    column: $table.subskillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillArea => $composableBuilder(
    column: $table.skillArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowSize => $composableBuilder(
    column: $table.windowSize,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubskillRefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubskillRefsTable> {
  $$SubskillRefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subskillId => $composableBuilder(
    column: $table.subskillId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SkillArea, String> get skillArea =>
      $composableBuilder(column: $table.skillArea, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowSize => $composableBuilder(
    column: $table.windowSize,
    builder: (column) => column,
  );
}

class $$SubskillRefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubskillRefsTable,
          SubskillRef,
          $$SubskillRefsTableFilterComposer,
          $$SubskillRefsTableOrderingComposer,
          $$SubskillRefsTableAnnotationComposer,
          $$SubskillRefsTableCreateCompanionBuilder,
          $$SubskillRefsTableUpdateCompanionBuilder,
          (
            SubskillRef,
            BaseReferences<_$AppDatabase, $SubskillRefsTable, SubskillRef>,
          ),
          SubskillRef,
          PrefetchHooks Function()
        > {
  $$SubskillRefsTableTableManager(_$AppDatabase db, $SubskillRefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubskillRefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubskillRefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubskillRefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> subskillId = const Value.absent(),
                Value<SkillArea> skillArea = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> allocation = const Value.absent(),
                Value<int> windowSize = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubskillRefsCompanion(
                subskillId: subskillId,
                skillArea: skillArea,
                name: name,
                allocation: allocation,
                windowSize: windowSize,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String subskillId,
                required SkillArea skillArea,
                required String name,
                required int allocation,
                Value<int> windowSize = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubskillRefsCompanion.insert(
                subskillId: subskillId,
                skillArea: skillArea,
                name: name,
                allocation: allocation,
                windowSize: windowSize,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubskillRefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubskillRefsTable,
      SubskillRef,
      $$SubskillRefsTableFilterComposer,
      $$SubskillRefsTableOrderingComposer,
      $$SubskillRefsTableAnnotationComposer,
      $$SubskillRefsTableCreateCompanionBuilder,
      $$SubskillRefsTableUpdateCompanionBuilder,
      (
        SubskillRef,
        BaseReferences<_$AppDatabase, $SubskillRefsTable, SubskillRef>,
      ),
      SubskillRef,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String userId,
      Value<String?> displayName,
      Value<String?> email,
      Value<String> timezone,
      Value<int> weekStartDay,
      Value<String> unitPreferences,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> userId,
      Value<String?> displayName,
      Value<String?> email,
      Value<String> timezone,
      Value<int> weekStartDay,
      Value<String> unitPreferences,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekStartDay => $composableBuilder(
    column: $table.weekStartDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitPreferences => $composableBuilder(
    column: $table.unitPreferences,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekStartDay => $composableBuilder(
    column: $table.weekStartDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPreferences => $composableBuilder(
    column: $table.unitPreferences,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get weekStartDay => $composableBuilder(
    column: $table.weekStartDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitPreferences => $composableBuilder(
    column: $table.unitPreferences,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int> weekStartDay = const Value.absent(),
                Value<String> unitPreferences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                userId: userId,
                displayName: displayName,
                email: email,
                timezone: timezone,
                weekStartDay: weekStartDay,
                unitPreferences: unitPreferences,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> displayName = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int> weekStartDay = const Value.absent(),
                Value<String> unitPreferences = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                userId: userId,
                displayName: displayName,
                email: email,
                timezone: timezone,
                weekStartDay: weekStartDay,
                unitPreferences: unitPreferences,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$DrillsTableCreateCompanionBuilder =
    DrillsCompanion Function({
      required String drillId,
      Value<String?> userId,
      required String name,
      required SkillArea skillArea,
      required DrillType drillType,
      Value<ScoringMode?> scoringMode,
      required InputMode inputMode,
      required String metricSchemaId,
      Value<GridType?> gridType,
      Value<String> subskillMapping,
      Value<ClubSelectionMode?> clubSelectionMode,
      Value<TargetDistanceMode?> targetDistanceMode,
      Value<double?> targetDistanceValue,
      Value<TargetSizeMode?> targetSizeMode,
      Value<double?> targetSizeWidth,
      Value<double?> targetSizeDepth,
      Value<int> requiredSetCount,
      Value<int?> requiredAttemptsPerSet,
      Value<String> anchors,
      Value<double?> target,
      Value<String?> description,
      Value<DrillLengthUnit?> targetDistanceUnit,
      Value<DrillLengthUnit?> targetSizeUnit,
      required DrillOrigin origin,
      Value<DrillStatus> status,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DrillsTableUpdateCompanionBuilder =
    DrillsCompanion Function({
      Value<String> drillId,
      Value<String?> userId,
      Value<String> name,
      Value<SkillArea> skillArea,
      Value<DrillType> drillType,
      Value<ScoringMode?> scoringMode,
      Value<InputMode> inputMode,
      Value<String> metricSchemaId,
      Value<GridType?> gridType,
      Value<String> subskillMapping,
      Value<ClubSelectionMode?> clubSelectionMode,
      Value<TargetDistanceMode?> targetDistanceMode,
      Value<double?> targetDistanceValue,
      Value<TargetSizeMode?> targetSizeMode,
      Value<double?> targetSizeWidth,
      Value<double?> targetSizeDepth,
      Value<int> requiredSetCount,
      Value<int?> requiredAttemptsPerSet,
      Value<String> anchors,
      Value<double?> target,
      Value<String?> description,
      Value<DrillLengthUnit?> targetDistanceUnit,
      Value<DrillLengthUnit?> targetSizeUnit,
      Value<DrillOrigin> origin,
      Value<DrillStatus> status,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DrillsTableFilterComposer
    extends Composer<_$AppDatabase, $DrillsTable> {
  $$DrillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get drillId => $composableBuilder(
    column: $table.drillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SkillArea, SkillArea, String> get skillArea =>
      $composableBuilder(
        column: $table.skillArea,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DrillType, DrillType, String> get drillType =>
      $composableBuilder(
        column: $table.drillType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ScoringMode?, ScoringMode, String>
  get scoringMode => $composableBuilder(
    column: $table.scoringMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<InputMode, InputMode, String> get inputMode =>
      $composableBuilder(
        column: $table.inputMode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get metricSchemaId => $composableBuilder(
    column: $table.metricSchemaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GridType?, GridType, String> get gridType =>
      $composableBuilder(
        column: $table.gridType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get subskillMapping => $composableBuilder(
    column: $table.subskillMapping,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ClubSelectionMode?, ClubSelectionMode, String>
  get clubSelectionMode => $composableBuilder(
    column: $table.clubSelectionMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    TargetDistanceMode?,
    TargetDistanceMode,
    String
  >
  get targetDistanceMode => $composableBuilder(
    column: $table.targetDistanceMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get targetDistanceValue => $composableBuilder(
    column: $table.targetDistanceValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TargetSizeMode?, TargetSizeMode, String>
  get targetSizeMode => $composableBuilder(
    column: $table.targetSizeMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get targetSizeWidth => $composableBuilder(
    column: $table.targetSizeWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetSizeDepth => $composableBuilder(
    column: $table.targetSizeDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requiredSetCount => $composableBuilder(
    column: $table.requiredSetCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requiredAttemptsPerSet => $composableBuilder(
    column: $table.requiredAttemptsPerSet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchors => $composableBuilder(
    column: $table.anchors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DrillLengthUnit?, DrillLengthUnit, String>
  get targetDistanceUnit => $composableBuilder(
    column: $table.targetDistanceUnit,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DrillLengthUnit?, DrillLengthUnit, String>
  get targetSizeUnit => $composableBuilder(
    column: $table.targetSizeUnit,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DrillOrigin, DrillOrigin, String> get origin =>
      $composableBuilder(
        column: $table.origin,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DrillStatus, DrillStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DrillsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrillsTable> {
  $$DrillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get drillId => $composableBuilder(
    column: $table.drillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillArea => $composableBuilder(
    column: $table.skillArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drillType => $composableBuilder(
    column: $table.drillType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringMode => $composableBuilder(
    column: $table.scoringMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricSchemaId => $composableBuilder(
    column: $table.metricSchemaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gridType => $composableBuilder(
    column: $table.gridType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subskillMapping => $composableBuilder(
    column: $table.subskillMapping,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubSelectionMode => $composableBuilder(
    column: $table.clubSelectionMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDistanceMode => $composableBuilder(
    column: $table.targetDistanceMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetDistanceValue => $composableBuilder(
    column: $table.targetDistanceValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetSizeMode => $composableBuilder(
    column: $table.targetSizeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetSizeWidth => $composableBuilder(
    column: $table.targetSizeWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetSizeDepth => $composableBuilder(
    column: $table.targetSizeDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requiredSetCount => $composableBuilder(
    column: $table.requiredSetCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requiredAttemptsPerSet => $composableBuilder(
    column: $table.requiredAttemptsPerSet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchors => $composableBuilder(
    column: $table.anchors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get target => $composableBuilder(
    column: $table.target,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDistanceUnit => $composableBuilder(
    column: $table.targetDistanceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetSizeUnit => $composableBuilder(
    column: $table.targetSizeUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DrillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrillsTable> {
  $$DrillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get drillId =>
      $composableBuilder(column: $table.drillId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkillArea, String> get skillArea =>
      $composableBuilder(column: $table.skillArea, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DrillType, String> get drillType =>
      $composableBuilder(column: $table.drillType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScoringMode?, String> get scoringMode =>
      $composableBuilder(
        column: $table.scoringMode,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<InputMode, String> get inputMode =>
      $composableBuilder(column: $table.inputMode, builder: (column) => column);

  GeneratedColumn<String> get metricSchemaId => $composableBuilder(
    column: $table.metricSchemaId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GridType?, String> get gridType =>
      $composableBuilder(column: $table.gridType, builder: (column) => column);

  GeneratedColumn<String> get subskillMapping => $composableBuilder(
    column: $table.subskillMapping,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ClubSelectionMode?, String>
  get clubSelectionMode => $composableBuilder(
    column: $table.clubSelectionMode,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TargetDistanceMode?, String>
  get targetDistanceMode => $composableBuilder(
    column: $table.targetDistanceMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetDistanceValue => $composableBuilder(
    column: $table.targetDistanceValue,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TargetSizeMode?, String>
  get targetSizeMode => $composableBuilder(
    column: $table.targetSizeMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetSizeWidth => $composableBuilder(
    column: $table.targetSizeWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetSizeDepth => $composableBuilder(
    column: $table.targetSizeDepth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requiredSetCount => $composableBuilder(
    column: $table.requiredSetCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get requiredAttemptsPerSet => $composableBuilder(
    column: $table.requiredAttemptsPerSet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anchors =>
      $composableBuilder(column: $table.anchors, builder: (column) => column);

  GeneratedColumn<double> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DrillLengthUnit?, String>
  get targetDistanceUnit => $composableBuilder(
    column: $table.targetDistanceUnit,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DrillLengthUnit?, String>
  get targetSizeUnit => $composableBuilder(
    column: $table.targetSizeUnit,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DrillOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DrillStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DrillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DrillsTable,
          Drill,
          $$DrillsTableFilterComposer,
          $$DrillsTableOrderingComposer,
          $$DrillsTableAnnotationComposer,
          $$DrillsTableCreateCompanionBuilder,
          $$DrillsTableUpdateCompanionBuilder,
          (Drill, BaseReferences<_$AppDatabase, $DrillsTable, Drill>),
          Drill,
          PrefetchHooks Function()
        > {
  $$DrillsTableTableManager(_$AppDatabase db, $DrillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> drillId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<SkillArea> skillArea = const Value.absent(),
                Value<DrillType> drillType = const Value.absent(),
                Value<ScoringMode?> scoringMode = const Value.absent(),
                Value<InputMode> inputMode = const Value.absent(),
                Value<String> metricSchemaId = const Value.absent(),
                Value<GridType?> gridType = const Value.absent(),
                Value<String> subskillMapping = const Value.absent(),
                Value<ClubSelectionMode?> clubSelectionMode =
                    const Value.absent(),
                Value<TargetDistanceMode?> targetDistanceMode =
                    const Value.absent(),
                Value<double?> targetDistanceValue = const Value.absent(),
                Value<TargetSizeMode?> targetSizeMode = const Value.absent(),
                Value<double?> targetSizeWidth = const Value.absent(),
                Value<double?> targetSizeDepth = const Value.absent(),
                Value<int> requiredSetCount = const Value.absent(),
                Value<int?> requiredAttemptsPerSet = const Value.absent(),
                Value<String> anchors = const Value.absent(),
                Value<double?> target = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DrillLengthUnit?> targetDistanceUnit =
                    const Value.absent(),
                Value<DrillLengthUnit?> targetSizeUnit = const Value.absent(),
                Value<DrillOrigin> origin = const Value.absent(),
                Value<DrillStatus> status = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DrillsCompanion(
                drillId: drillId,
                userId: userId,
                name: name,
                skillArea: skillArea,
                drillType: drillType,
                scoringMode: scoringMode,
                inputMode: inputMode,
                metricSchemaId: metricSchemaId,
                gridType: gridType,
                subskillMapping: subskillMapping,
                clubSelectionMode: clubSelectionMode,
                targetDistanceMode: targetDistanceMode,
                targetDistanceValue: targetDistanceValue,
                targetSizeMode: targetSizeMode,
                targetSizeWidth: targetSizeWidth,
                targetSizeDepth: targetSizeDepth,
                requiredSetCount: requiredSetCount,
                requiredAttemptsPerSet: requiredAttemptsPerSet,
                anchors: anchors,
                target: target,
                description: description,
                targetDistanceUnit: targetDistanceUnit,
                targetSizeUnit: targetSizeUnit,
                origin: origin,
                status: status,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String drillId,
                Value<String?> userId = const Value.absent(),
                required String name,
                required SkillArea skillArea,
                required DrillType drillType,
                Value<ScoringMode?> scoringMode = const Value.absent(),
                required InputMode inputMode,
                required String metricSchemaId,
                Value<GridType?> gridType = const Value.absent(),
                Value<String> subskillMapping = const Value.absent(),
                Value<ClubSelectionMode?> clubSelectionMode =
                    const Value.absent(),
                Value<TargetDistanceMode?> targetDistanceMode =
                    const Value.absent(),
                Value<double?> targetDistanceValue = const Value.absent(),
                Value<TargetSizeMode?> targetSizeMode = const Value.absent(),
                Value<double?> targetSizeWidth = const Value.absent(),
                Value<double?> targetSizeDepth = const Value.absent(),
                Value<int> requiredSetCount = const Value.absent(),
                Value<int?> requiredAttemptsPerSet = const Value.absent(),
                Value<String> anchors = const Value.absent(),
                Value<double?> target = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DrillLengthUnit?> targetDistanceUnit =
                    const Value.absent(),
                Value<DrillLengthUnit?> targetSizeUnit = const Value.absent(),
                required DrillOrigin origin,
                Value<DrillStatus> status = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DrillsCompanion.insert(
                drillId: drillId,
                userId: userId,
                name: name,
                skillArea: skillArea,
                drillType: drillType,
                scoringMode: scoringMode,
                inputMode: inputMode,
                metricSchemaId: metricSchemaId,
                gridType: gridType,
                subskillMapping: subskillMapping,
                clubSelectionMode: clubSelectionMode,
                targetDistanceMode: targetDistanceMode,
                targetDistanceValue: targetDistanceValue,
                targetSizeMode: targetSizeMode,
                targetSizeWidth: targetSizeWidth,
                targetSizeDepth: targetSizeDepth,
                requiredSetCount: requiredSetCount,
                requiredAttemptsPerSet: requiredAttemptsPerSet,
                anchors: anchors,
                target: target,
                description: description,
                targetDistanceUnit: targetDistanceUnit,
                targetSizeUnit: targetSizeUnit,
                origin: origin,
                status: status,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DrillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DrillsTable,
      Drill,
      $$DrillsTableFilterComposer,
      $$DrillsTableOrderingComposer,
      $$DrillsTableAnnotationComposer,
      $$DrillsTableCreateCompanionBuilder,
      $$DrillsTableUpdateCompanionBuilder,
      (Drill, BaseReferences<_$AppDatabase, $DrillsTable, Drill>),
      Drill,
      PrefetchHooks Function()
    >;
typedef $$PracticeBlocksTableCreateCompanionBuilder =
    PracticeBlocksCompanion Function({
      required String practiceBlockId,
      required String userId,
      Value<String?> sourceRoutineId,
      Value<String> drillOrder,
      Value<DateTime> startTimestamp,
      Value<DateTime?> endTimestamp,
      Value<EnvironmentType?> environmentType,
      Value<SurfaceType?> surfaceType,
      Value<ClosureType?> closureType,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PracticeBlocksTableUpdateCompanionBuilder =
    PracticeBlocksCompanion Function({
      Value<String> practiceBlockId,
      Value<String> userId,
      Value<String?> sourceRoutineId,
      Value<String> drillOrder,
      Value<DateTime> startTimestamp,
      Value<DateTime?> endTimestamp,
      Value<EnvironmentType?> environmentType,
      Value<SurfaceType?> surfaceType,
      Value<ClosureType?> closureType,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PracticeBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $PracticeBlocksTable> {
  $$PracticeBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceRoutineId => $composableBuilder(
    column: $table.sourceRoutineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get drillOrder => $composableBuilder(
    column: $table.drillOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTimestamp => $composableBuilder(
    column: $table.endTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EnvironmentType?, EnvironmentType, String>
  get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SurfaceType?, SurfaceType, String>
  get surfaceType => $composableBuilder(
    column: $table.surfaceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ClosureType?, ClosureType, String>
  get closureType => $composableBuilder(
    column: $table.closureType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PracticeBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $PracticeBlocksTable> {
  $$PracticeBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceRoutineId => $composableBuilder(
    column: $table.sourceRoutineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drillOrder => $composableBuilder(
    column: $table.drillOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTimestamp => $composableBuilder(
    column: $table.endTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surfaceType => $composableBuilder(
    column: $table.surfaceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closureType => $composableBuilder(
    column: $table.closureType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PracticeBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $PracticeBlocksTable> {
  $$PracticeBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get sourceRoutineId => $composableBuilder(
    column: $table.sourceRoutineId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get drillOrder => $composableBuilder(
    column: $table.drillOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endTimestamp => $composableBuilder(
    column: $table.endTimestamp,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EnvironmentType?, String>
  get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SurfaceType?, String> get surfaceType =>
      $composableBuilder(
        column: $table.surfaceType,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<ClosureType?, String> get closureType =>
      $composableBuilder(
        column: $table.closureType,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PracticeBlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PracticeBlocksTable,
          PracticeBlock,
          $$PracticeBlocksTableFilterComposer,
          $$PracticeBlocksTableOrderingComposer,
          $$PracticeBlocksTableAnnotationComposer,
          $$PracticeBlocksTableCreateCompanionBuilder,
          $$PracticeBlocksTableUpdateCompanionBuilder,
          (
            PracticeBlock,
            BaseReferences<_$AppDatabase, $PracticeBlocksTable, PracticeBlock>,
          ),
          PracticeBlock,
          PrefetchHooks Function()
        > {
  $$PracticeBlocksTableTableManager(
    _$AppDatabase db,
    $PracticeBlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> practiceBlockId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> sourceRoutineId = const Value.absent(),
                Value<String> drillOrder = const Value.absent(),
                Value<DateTime> startTimestamp = const Value.absent(),
                Value<DateTime?> endTimestamp = const Value.absent(),
                Value<EnvironmentType?> environmentType = const Value.absent(),
                Value<SurfaceType?> surfaceType = const Value.absent(),
                Value<ClosureType?> closureType = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeBlocksCompanion(
                practiceBlockId: practiceBlockId,
                userId: userId,
                sourceRoutineId: sourceRoutineId,
                drillOrder: drillOrder,
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                environmentType: environmentType,
                surfaceType: surfaceType,
                closureType: closureType,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String practiceBlockId,
                required String userId,
                Value<String?> sourceRoutineId = const Value.absent(),
                Value<String> drillOrder = const Value.absent(),
                Value<DateTime> startTimestamp = const Value.absent(),
                Value<DateTime?> endTimestamp = const Value.absent(),
                Value<EnvironmentType?> environmentType = const Value.absent(),
                Value<SurfaceType?> surfaceType = const Value.absent(),
                Value<ClosureType?> closureType = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeBlocksCompanion.insert(
                practiceBlockId: practiceBlockId,
                userId: userId,
                sourceRoutineId: sourceRoutineId,
                drillOrder: drillOrder,
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                environmentType: environmentType,
                surfaceType: surfaceType,
                closureType: closureType,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PracticeBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PracticeBlocksTable,
      PracticeBlock,
      $$PracticeBlocksTableFilterComposer,
      $$PracticeBlocksTableOrderingComposer,
      $$PracticeBlocksTableAnnotationComposer,
      $$PracticeBlocksTableCreateCompanionBuilder,
      $$PracticeBlocksTableUpdateCompanionBuilder,
      (
        PracticeBlock,
        BaseReferences<_$AppDatabase, $PracticeBlocksTable, PracticeBlock>,
      ),
      PracticeBlock,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String sessionId,
      required String drillId,
      required String practiceBlockId,
      Value<DateTime?> completionTimestamp,
      Value<SessionStatus> status,
      Value<bool> integrityFlag,
      Value<bool> integritySuppressed,
      Value<SurfaceType?> surfaceType,
      Value<String?> userDeclaration,
      Value<int?> sessionDuration,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> sessionId,
      Value<String> drillId,
      Value<String> practiceBlockId,
      Value<DateTime?> completionTimestamp,
      Value<SessionStatus> status,
      Value<bool> integrityFlag,
      Value<bool> integritySuppressed,
      Value<SurfaceType?> surfaceType,
      Value<String?> userDeclaration,
      Value<int?> sessionDuration,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get drillId => $composableBuilder(
    column: $table.drillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completionTimestamp => $composableBuilder(
    column: $table.completionTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionStatus, SessionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get integrityFlag => $composableBuilder(
    column: $table.integrityFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get integritySuppressed => $composableBuilder(
    column: $table.integritySuppressed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SurfaceType?, SurfaceType, String>
  get surfaceType => $composableBuilder(
    column: $table.surfaceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get userDeclaration => $composableBuilder(
    column: $table.userDeclaration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionDuration => $composableBuilder(
    column: $table.sessionDuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drillId => $composableBuilder(
    column: $table.drillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completionTimestamp => $composableBuilder(
    column: $table.completionTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get integrityFlag => $composableBuilder(
    column: $table.integrityFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get integritySuppressed => $composableBuilder(
    column: $table.integritySuppressed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surfaceType => $composableBuilder(
    column: $table.surfaceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userDeclaration => $composableBuilder(
    column: $table.userDeclaration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionDuration => $composableBuilder(
    column: $table.sessionDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get drillId =>
      $composableBuilder(column: $table.drillId, builder: (column) => column);

  GeneratedColumn<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completionTimestamp => $composableBuilder(
    column: $table.completionTimestamp,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SessionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get integrityFlag => $composableBuilder(
    column: $table.integrityFlag,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get integritySuppressed => $composableBuilder(
    column: $table.integritySuppressed,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SurfaceType?, String> get surfaceType =>
      $composableBuilder(
        column: $table.surfaceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get userDeclaration => $composableBuilder(
    column: $table.userDeclaration,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sessionDuration => $composableBuilder(
    column: $table.sessionDuration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> drillId = const Value.absent(),
                Value<String> practiceBlockId = const Value.absent(),
                Value<DateTime?> completionTimestamp = const Value.absent(),
                Value<SessionStatus> status = const Value.absent(),
                Value<bool> integrityFlag = const Value.absent(),
                Value<bool> integritySuppressed = const Value.absent(),
                Value<SurfaceType?> surfaceType = const Value.absent(),
                Value<String?> userDeclaration = const Value.absent(),
                Value<int?> sessionDuration = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                sessionId: sessionId,
                drillId: drillId,
                practiceBlockId: practiceBlockId,
                completionTimestamp: completionTimestamp,
                status: status,
                integrityFlag: integrityFlag,
                integritySuppressed: integritySuppressed,
                surfaceType: surfaceType,
                userDeclaration: userDeclaration,
                sessionDuration: sessionDuration,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String drillId,
                required String practiceBlockId,
                Value<DateTime?> completionTimestamp = const Value.absent(),
                Value<SessionStatus> status = const Value.absent(),
                Value<bool> integrityFlag = const Value.absent(),
                Value<bool> integritySuppressed = const Value.absent(),
                Value<SurfaceType?> surfaceType = const Value.absent(),
                Value<String?> userDeclaration = const Value.absent(),
                Value<int?> sessionDuration = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                sessionId: sessionId,
                drillId: drillId,
                practiceBlockId: practiceBlockId,
                completionTimestamp: completionTimestamp,
                status: status,
                integrityFlag: integrityFlag,
                integritySuppressed: integritySuppressed,
                surfaceType: surfaceType,
                userDeclaration: userDeclaration,
                sessionDuration: sessionDuration,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$SetsTableCreateCompanionBuilder =
    SetsCompanion Function({
      required String setId,
      required String sessionId,
      required int setIndex,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SetsTableUpdateCompanionBuilder =
    SetsCompanion Function({
      Value<String> setId,
      Value<String> sessionId,
      Value<int> setIndex,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SetsTableFilterComposer extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get setId => $composableBuilder(
    column: $table.setId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SetsTableOrderingComposer extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get setId => $composableBuilder(
    column: $table.setId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetsTable,
          PracticeSet,
          $$SetsTableFilterComposer,
          $$SetsTableOrderingComposer,
          $$SetsTableAnnotationComposer,
          $$SetsTableCreateCompanionBuilder,
          $$SetsTableUpdateCompanionBuilder,
          (PracticeSet, BaseReferences<_$AppDatabase, $SetsTable, PracticeSet>),
          PracticeSet,
          PrefetchHooks Function()
        > {
  $$SetsTableTableManager(_$AppDatabase db, $SetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> setId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetsCompanion(
                setId: setId,
                sessionId: sessionId,
                setIndex: setIndex,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String setId,
                required String sessionId,
                required int setIndex,
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetsCompanion.insert(
                setId: setId,
                sessionId: sessionId,
                setIndex: setIndex,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetsTable,
      PracticeSet,
      $$SetsTableFilterComposer,
      $$SetsTableOrderingComposer,
      $$SetsTableAnnotationComposer,
      $$SetsTableCreateCompanionBuilder,
      $$SetsTableUpdateCompanionBuilder,
      (PracticeSet, BaseReferences<_$AppDatabase, $SetsTable, PracticeSet>),
      PracticeSet,
      PrefetchHooks Function()
    >;
typedef $$InstancesTableCreateCompanionBuilder =
    InstancesCompanion Function({
      required String instanceId,
      required String setId,
      required String selectedClub,
      required String rawMetrics,
      Value<DateTime> timestamp,
      Value<double?> resolvedTargetDistance,
      Value<double?> resolvedTargetWidth,
      Value<double?> resolvedTargetDepth,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$InstancesTableUpdateCompanionBuilder =
    InstancesCompanion Function({
      Value<String> instanceId,
      Value<String> setId,
      Value<String> selectedClub,
      Value<String> rawMetrics,
      Value<DateTime> timestamp,
      Value<double?> resolvedTargetDistance,
      Value<double?> resolvedTargetWidth,
      Value<double?> resolvedTargetDepth,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$InstancesTableFilterComposer
    extends Composer<_$AppDatabase, $InstancesTable> {
  $$InstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setId => $composableBuilder(
    column: $table.setId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedClub => $composableBuilder(
    column: $table.selectedClub,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawMetrics => $composableBuilder(
    column: $table.rawMetrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get resolvedTargetDistance => $composableBuilder(
    column: $table.resolvedTargetDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get resolvedTargetWidth => $composableBuilder(
    column: $table.resolvedTargetWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get resolvedTargetDepth => $composableBuilder(
    column: $table.resolvedTargetDepth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $InstancesTable> {
  $$InstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setId => $composableBuilder(
    column: $table.setId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedClub => $composableBuilder(
    column: $table.selectedClub,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawMetrics => $composableBuilder(
    column: $table.rawMetrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get resolvedTargetDistance => $composableBuilder(
    column: $table.resolvedTargetDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get resolvedTargetWidth => $composableBuilder(
    column: $table.resolvedTargetWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get resolvedTargetDepth => $composableBuilder(
    column: $table.resolvedTargetDepth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstancesTable> {
  $$InstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => column);

  GeneratedColumn<String> get selectedClub => $composableBuilder(
    column: $table.selectedClub,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawMetrics => $composableBuilder(
    column: $table.rawMetrics,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get resolvedTargetDistance => $composableBuilder(
    column: $table.resolvedTargetDistance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get resolvedTargetWidth => $composableBuilder(
    column: $table.resolvedTargetWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get resolvedTargetDepth => $composableBuilder(
    column: $table.resolvedTargetDepth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InstancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstancesTable,
          Instance,
          $$InstancesTableFilterComposer,
          $$InstancesTableOrderingComposer,
          $$InstancesTableAnnotationComposer,
          $$InstancesTableCreateCompanionBuilder,
          $$InstancesTableUpdateCompanionBuilder,
          (Instance, BaseReferences<_$AppDatabase, $InstancesTable, Instance>),
          Instance,
          PrefetchHooks Function()
        > {
  $$InstancesTableTableManager(_$AppDatabase db, $InstancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> instanceId = const Value.absent(),
                Value<String> setId = const Value.absent(),
                Value<String> selectedClub = const Value.absent(),
                Value<String> rawMetrics = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double?> resolvedTargetDistance = const Value.absent(),
                Value<double?> resolvedTargetWidth = const Value.absent(),
                Value<double?> resolvedTargetDepth = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstancesCompanion(
                instanceId: instanceId,
                setId: setId,
                selectedClub: selectedClub,
                rawMetrics: rawMetrics,
                timestamp: timestamp,
                resolvedTargetDistance: resolvedTargetDistance,
                resolvedTargetWidth: resolvedTargetWidth,
                resolvedTargetDepth: resolvedTargetDepth,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String instanceId,
                required String setId,
                required String selectedClub,
                required String rawMetrics,
                Value<DateTime> timestamp = const Value.absent(),
                Value<double?> resolvedTargetDistance = const Value.absent(),
                Value<double?> resolvedTargetWidth = const Value.absent(),
                Value<double?> resolvedTargetDepth = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstancesCompanion.insert(
                instanceId: instanceId,
                setId: setId,
                selectedClub: selectedClub,
                rawMetrics: rawMetrics,
                timestamp: timestamp,
                resolvedTargetDistance: resolvedTargetDistance,
                resolvedTargetWidth: resolvedTargetWidth,
                resolvedTargetDepth: resolvedTargetDepth,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstancesTable,
      Instance,
      $$InstancesTableFilterComposer,
      $$InstancesTableOrderingComposer,
      $$InstancesTableAnnotationComposer,
      $$InstancesTableCreateCompanionBuilder,
      $$InstancesTableUpdateCompanionBuilder,
      (Instance, BaseReferences<_$AppDatabase, $InstancesTable, Instance>),
      Instance,
      PrefetchHooks Function()
    >;
typedef $$PracticeEntriesTableCreateCompanionBuilder =
    PracticeEntriesCompanion Function({
      required String practiceEntryId,
      required String practiceBlockId,
      required String drillId,
      Value<String?> sessionId,
      Value<PracticeEntryType> entryType,
      required int positionIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PracticeEntriesTableUpdateCompanionBuilder =
    PracticeEntriesCompanion Function({
      Value<String> practiceEntryId,
      Value<String> practiceBlockId,
      Value<String> drillId,
      Value<String?> sessionId,
      Value<PracticeEntryType> entryType,
      Value<int> positionIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PracticeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PracticeEntriesTable> {
  $$PracticeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get practiceEntryId => $composableBuilder(
    column: $table.practiceEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get drillId => $composableBuilder(
    column: $table.drillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PracticeEntryType, PracticeEntryType, String>
  get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get positionIndex => $composableBuilder(
    column: $table.positionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PracticeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PracticeEntriesTable> {
  $$PracticeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get practiceEntryId => $composableBuilder(
    column: $table.practiceEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drillId => $composableBuilder(
    column: $table.drillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionIndex => $composableBuilder(
    column: $table.positionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PracticeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PracticeEntriesTable> {
  $$PracticeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get practiceEntryId => $composableBuilder(
    column: $table.practiceEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get practiceBlockId => $composableBuilder(
    column: $table.practiceBlockId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get drillId =>
      $composableBuilder(column: $table.drillId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PracticeEntryType, String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<int> get positionIndex => $composableBuilder(
    column: $table.positionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PracticeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PracticeEntriesTable,
          PracticeEntry,
          $$PracticeEntriesTableFilterComposer,
          $$PracticeEntriesTableOrderingComposer,
          $$PracticeEntriesTableAnnotationComposer,
          $$PracticeEntriesTableCreateCompanionBuilder,
          $$PracticeEntriesTableUpdateCompanionBuilder,
          (
            PracticeEntry,
            BaseReferences<_$AppDatabase, $PracticeEntriesTable, PracticeEntry>,
          ),
          PracticeEntry,
          PrefetchHooks Function()
        > {
  $$PracticeEntriesTableTableManager(
    _$AppDatabase db,
    $PracticeEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> practiceEntryId = const Value.absent(),
                Value<String> practiceBlockId = const Value.absent(),
                Value<String> drillId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<PracticeEntryType> entryType = const Value.absent(),
                Value<int> positionIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeEntriesCompanion(
                practiceEntryId: practiceEntryId,
                practiceBlockId: practiceBlockId,
                drillId: drillId,
                sessionId: sessionId,
                entryType: entryType,
                positionIndex: positionIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String practiceEntryId,
                required String practiceBlockId,
                required String drillId,
                Value<String?> sessionId = const Value.absent(),
                Value<PracticeEntryType> entryType = const Value.absent(),
                required int positionIndex,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeEntriesCompanion.insert(
                practiceEntryId: practiceEntryId,
                practiceBlockId: practiceBlockId,
                drillId: drillId,
                sessionId: sessionId,
                entryType: entryType,
                positionIndex: positionIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PracticeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PracticeEntriesTable,
      PracticeEntry,
      $$PracticeEntriesTableFilterComposer,
      $$PracticeEntriesTableOrderingComposer,
      $$PracticeEntriesTableAnnotationComposer,
      $$PracticeEntriesTableCreateCompanionBuilder,
      $$PracticeEntriesTableUpdateCompanionBuilder,
      (
        PracticeEntry,
        BaseReferences<_$AppDatabase, $PracticeEntriesTable, PracticeEntry>,
      ),
      PracticeEntry,
      PrefetchHooks Function()
    >;
typedef $$UserDrillAdoptionsTableCreateCompanionBuilder =
    UserDrillAdoptionsCompanion Function({
      required String userDrillAdoptionId,
      required String userId,
      required String drillId,
      Value<AdoptionStatus> status,
      Value<bool> isDeleted,
      Value<bool> hasUnseenUpdate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserDrillAdoptionsTableUpdateCompanionBuilder =
    UserDrillAdoptionsCompanion Function({
      Value<String> userDrillAdoptionId,
      Value<String> userId,
      Value<String> drillId,
      Value<AdoptionStatus> status,
      Value<bool> isDeleted,
      Value<bool> hasUnseenUpdate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserDrillAdoptionsTableFilterComposer
    extends Composer<_$AppDatabase, $UserDrillAdoptionsTable> {
  $$UserDrillAdoptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userDrillAdoptionId => $composableBuilder(
    column: $table.userDrillAdoptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get drillId => $composableBuilder(
    column: $table.drillId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AdoptionStatus, AdoptionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasUnseenUpdate => $composableBuilder(
    column: $table.hasUnseenUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserDrillAdoptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserDrillAdoptionsTable> {
  $$UserDrillAdoptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userDrillAdoptionId => $composableBuilder(
    column: $table.userDrillAdoptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drillId => $composableBuilder(
    column: $table.drillId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasUnseenUpdate => $composableBuilder(
    column: $table.hasUnseenUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserDrillAdoptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserDrillAdoptionsTable> {
  $$UserDrillAdoptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userDrillAdoptionId => $composableBuilder(
    column: $table.userDrillAdoptionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get drillId =>
      $composableBuilder(column: $table.drillId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AdoptionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get hasUnseenUpdate => $composableBuilder(
    column: $table.hasUnseenUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserDrillAdoptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserDrillAdoptionsTable,
          UserDrillAdoption,
          $$UserDrillAdoptionsTableFilterComposer,
          $$UserDrillAdoptionsTableOrderingComposer,
          $$UserDrillAdoptionsTableAnnotationComposer,
          $$UserDrillAdoptionsTableCreateCompanionBuilder,
          $$UserDrillAdoptionsTableUpdateCompanionBuilder,
          (
            UserDrillAdoption,
            BaseReferences<
              _$AppDatabase,
              $UserDrillAdoptionsTable,
              UserDrillAdoption
            >,
          ),
          UserDrillAdoption,
          PrefetchHooks Function()
        > {
  $$UserDrillAdoptionsTableTableManager(
    _$AppDatabase db,
    $UserDrillAdoptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserDrillAdoptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserDrillAdoptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserDrillAdoptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userDrillAdoptionId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> drillId = const Value.absent(),
                Value<AdoptionStatus> status = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> hasUnseenUpdate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserDrillAdoptionsCompanion(
                userDrillAdoptionId: userDrillAdoptionId,
                userId: userId,
                drillId: drillId,
                status: status,
                isDeleted: isDeleted,
                hasUnseenUpdate: hasUnseenUpdate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userDrillAdoptionId,
                required String userId,
                required String drillId,
                Value<AdoptionStatus> status = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> hasUnseenUpdate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserDrillAdoptionsCompanion.insert(
                userDrillAdoptionId: userDrillAdoptionId,
                userId: userId,
                drillId: drillId,
                status: status,
                isDeleted: isDeleted,
                hasUnseenUpdate: hasUnseenUpdate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserDrillAdoptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserDrillAdoptionsTable,
      UserDrillAdoption,
      $$UserDrillAdoptionsTableFilterComposer,
      $$UserDrillAdoptionsTableOrderingComposer,
      $$UserDrillAdoptionsTableAnnotationComposer,
      $$UserDrillAdoptionsTableCreateCompanionBuilder,
      $$UserDrillAdoptionsTableUpdateCompanionBuilder,
      (
        UserDrillAdoption,
        BaseReferences<
          _$AppDatabase,
          $UserDrillAdoptionsTable,
          UserDrillAdoption
        >,
      ),
      UserDrillAdoption,
      PrefetchHooks Function()
    >;
typedef $$UserClubsTableCreateCompanionBuilder =
    UserClubsCompanion Function({
      required String clubId,
      required String userId,
      required ClubType clubType,
      Value<String?> make,
      Value<String?> model,
      Value<double?> loft,
      Value<UserClubStatus> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserClubsTableUpdateCompanionBuilder =
    UserClubsCompanion Function({
      Value<String> clubId,
      Value<String> userId,
      Value<ClubType> clubType,
      Value<String?> make,
      Value<String?> model,
      Value<double?> loft,
      Value<UserClubStatus> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserClubsTableFilterComposer
    extends Composer<_$AppDatabase, $UserClubsTable> {
  $$UserClubsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ClubType, ClubType, String> get clubType =>
      $composableBuilder(
        column: $table.clubType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get loft => $composableBuilder(
    column: $table.loft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<UserClubStatus, UserClubStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserClubsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserClubsTable> {
  $$UserClubsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubType => $composableBuilder(
    column: $table.clubType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get make => $composableBuilder(
    column: $table.make,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get loft => $composableBuilder(
    column: $table.loft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserClubsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserClubsTable> {
  $$UserClubsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ClubType, String> get clubType =>
      $composableBuilder(column: $table.clubType, builder: (column) => column);

  GeneratedColumn<String> get make =>
      $composableBuilder(column: $table.make, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<double> get loft =>
      $composableBuilder(column: $table.loft, builder: (column) => column);

  GeneratedColumnWithTypeConverter<UserClubStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserClubsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserClubsTable,
          UserClub,
          $$UserClubsTableFilterComposer,
          $$UserClubsTableOrderingComposer,
          $$UserClubsTableAnnotationComposer,
          $$UserClubsTableCreateCompanionBuilder,
          $$UserClubsTableUpdateCompanionBuilder,
          (UserClub, BaseReferences<_$AppDatabase, $UserClubsTable, UserClub>),
          UserClub,
          PrefetchHooks Function()
        > {
  $$UserClubsTableTableManager(_$AppDatabase db, $UserClubsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserClubsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserClubsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserClubsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clubId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<ClubType> clubType = const Value.absent(),
                Value<String?> make = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<double?> loft = const Value.absent(),
                Value<UserClubStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserClubsCompanion(
                clubId: clubId,
                userId: userId,
                clubType: clubType,
                make: make,
                model: model,
                loft: loft,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clubId,
                required String userId,
                required ClubType clubType,
                Value<String?> make = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<double?> loft = const Value.absent(),
                Value<UserClubStatus> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserClubsCompanion.insert(
                clubId: clubId,
                userId: userId,
                clubType: clubType,
                make: make,
                model: model,
                loft: loft,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserClubsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserClubsTable,
      UserClub,
      $$UserClubsTableFilterComposer,
      $$UserClubsTableOrderingComposer,
      $$UserClubsTableAnnotationComposer,
      $$UserClubsTableCreateCompanionBuilder,
      $$UserClubsTableUpdateCompanionBuilder,
      (UserClub, BaseReferences<_$AppDatabase, $UserClubsTable, UserClub>),
      UserClub,
      PrefetchHooks Function()
    >;
typedef $$ClubPerformanceProfilesTableCreateCompanionBuilder =
    ClubPerformanceProfilesCompanion Function({
      required String profileId,
      required String clubId,
      required DateTime effectiveFromDate,
      Value<double?> carryDistance,
      Value<double?> totalDistance,
      Value<double?> dispersionLeft,
      Value<double?> dispersionRight,
      Value<double?> dispersionShort,
      Value<double?> dispersionLong,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ClubPerformanceProfilesTableUpdateCompanionBuilder =
    ClubPerformanceProfilesCompanion Function({
      Value<String> profileId,
      Value<String> clubId,
      Value<DateTime> effectiveFromDate,
      Value<double?> carryDistance,
      Value<double?> totalDistance,
      Value<double?> dispersionLeft,
      Value<double?> dispersionRight,
      Value<double?> dispersionShort,
      Value<double?> dispersionLong,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ClubPerformanceProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ClubPerformanceProfilesTable> {
  $$ClubPerformanceProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveFromDate => $composableBuilder(
    column: $table.effectiveFromDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carryDistance => $composableBuilder(
    column: $table.carryDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dispersionLeft => $composableBuilder(
    column: $table.dispersionLeft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dispersionRight => $composableBuilder(
    column: $table.dispersionRight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dispersionShort => $composableBuilder(
    column: $table.dispersionShort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dispersionLong => $composableBuilder(
    column: $table.dispersionLong,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClubPerformanceProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ClubPerformanceProfilesTable> {
  $$ClubPerformanceProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveFromDate => $composableBuilder(
    column: $table.effectiveFromDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carryDistance => $composableBuilder(
    column: $table.carryDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dispersionLeft => $composableBuilder(
    column: $table.dispersionLeft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dispersionRight => $composableBuilder(
    column: $table.dispersionRight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dispersionShort => $composableBuilder(
    column: $table.dispersionShort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dispersionLong => $composableBuilder(
    column: $table.dispersionLong,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClubPerformanceProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClubPerformanceProfilesTable> {
  $$ClubPerformanceProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveFromDate => $composableBuilder(
    column: $table.effectiveFromDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carryDistance => $composableBuilder(
    column: $table.carryDistance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDistance => $composableBuilder(
    column: $table.totalDistance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dispersionLeft => $composableBuilder(
    column: $table.dispersionLeft,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dispersionRight => $composableBuilder(
    column: $table.dispersionRight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dispersionShort => $composableBuilder(
    column: $table.dispersionShort,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dispersionLong => $composableBuilder(
    column: $table.dispersionLong,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ClubPerformanceProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClubPerformanceProfilesTable,
          ClubPerformanceProfile,
          $$ClubPerformanceProfilesTableFilterComposer,
          $$ClubPerformanceProfilesTableOrderingComposer,
          $$ClubPerformanceProfilesTableAnnotationComposer,
          $$ClubPerformanceProfilesTableCreateCompanionBuilder,
          $$ClubPerformanceProfilesTableUpdateCompanionBuilder,
          (
            ClubPerformanceProfile,
            BaseReferences<
              _$AppDatabase,
              $ClubPerformanceProfilesTable,
              ClubPerformanceProfile
            >,
          ),
          ClubPerformanceProfile,
          PrefetchHooks Function()
        > {
  $$ClubPerformanceProfilesTableTableManager(
    _$AppDatabase db,
    $ClubPerformanceProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClubPerformanceProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ClubPerformanceProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClubPerformanceProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> profileId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<DateTime> effectiveFromDate = const Value.absent(),
                Value<double?> carryDistance = const Value.absent(),
                Value<double?> totalDistance = const Value.absent(),
                Value<double?> dispersionLeft = const Value.absent(),
                Value<double?> dispersionRight = const Value.absent(),
                Value<double?> dispersionShort = const Value.absent(),
                Value<double?> dispersionLong = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClubPerformanceProfilesCompanion(
                profileId: profileId,
                clubId: clubId,
                effectiveFromDate: effectiveFromDate,
                carryDistance: carryDistance,
                totalDistance: totalDistance,
                dispersionLeft: dispersionLeft,
                dispersionRight: dispersionRight,
                dispersionShort: dispersionShort,
                dispersionLong: dispersionLong,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String profileId,
                required String clubId,
                required DateTime effectiveFromDate,
                Value<double?> carryDistance = const Value.absent(),
                Value<double?> totalDistance = const Value.absent(),
                Value<double?> dispersionLeft = const Value.absent(),
                Value<double?> dispersionRight = const Value.absent(),
                Value<double?> dispersionShort = const Value.absent(),
                Value<double?> dispersionLong = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClubPerformanceProfilesCompanion.insert(
                profileId: profileId,
                clubId: clubId,
                effectiveFromDate: effectiveFromDate,
                carryDistance: carryDistance,
                totalDistance: totalDistance,
                dispersionLeft: dispersionLeft,
                dispersionRight: dispersionRight,
                dispersionShort: dispersionShort,
                dispersionLong: dispersionLong,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClubPerformanceProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClubPerformanceProfilesTable,
      ClubPerformanceProfile,
      $$ClubPerformanceProfilesTableFilterComposer,
      $$ClubPerformanceProfilesTableOrderingComposer,
      $$ClubPerformanceProfilesTableAnnotationComposer,
      $$ClubPerformanceProfilesTableCreateCompanionBuilder,
      $$ClubPerformanceProfilesTableUpdateCompanionBuilder,
      (
        ClubPerformanceProfile,
        BaseReferences<
          _$AppDatabase,
          $ClubPerformanceProfilesTable,
          ClubPerformanceProfile
        >,
      ),
      ClubPerformanceProfile,
      PrefetchHooks Function()
    >;
typedef $$UserSkillAreaClubMappingsTableCreateCompanionBuilder =
    UserSkillAreaClubMappingsCompanion Function({
      required String mappingId,
      required String userId,
      required ClubType clubType,
      required SkillArea skillArea,
      Value<bool> isMandatory,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserSkillAreaClubMappingsTableUpdateCompanionBuilder =
    UserSkillAreaClubMappingsCompanion Function({
      Value<String> mappingId,
      Value<String> userId,
      Value<ClubType> clubType,
      Value<SkillArea> skillArea,
      Value<bool> isMandatory,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserSkillAreaClubMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSkillAreaClubMappingsTable> {
  $$UserSkillAreaClubMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mappingId => $composableBuilder(
    column: $table.mappingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ClubType, ClubType, String> get clubType =>
      $composableBuilder(
        column: $table.clubType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SkillArea, SkillArea, String> get skillArea =>
      $composableBuilder(
        column: $table.skillArea,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isMandatory => $composableBuilder(
    column: $table.isMandatory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSkillAreaClubMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSkillAreaClubMappingsTable> {
  $$UserSkillAreaClubMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mappingId => $composableBuilder(
    column: $table.mappingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubType => $composableBuilder(
    column: $table.clubType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillArea => $composableBuilder(
    column: $table.skillArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMandatory => $composableBuilder(
    column: $table.isMandatory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSkillAreaClubMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSkillAreaClubMappingsTable> {
  $$UserSkillAreaClubMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mappingId =>
      $composableBuilder(column: $table.mappingId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ClubType, String> get clubType =>
      $composableBuilder(column: $table.clubType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkillArea, String> get skillArea =>
      $composableBuilder(column: $table.skillArea, builder: (column) => column);

  GeneratedColumn<bool> get isMandatory => $composableBuilder(
    column: $table.isMandatory,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserSkillAreaClubMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSkillAreaClubMappingsTable,
          UserSkillAreaClubMapping,
          $$UserSkillAreaClubMappingsTableFilterComposer,
          $$UserSkillAreaClubMappingsTableOrderingComposer,
          $$UserSkillAreaClubMappingsTableAnnotationComposer,
          $$UserSkillAreaClubMappingsTableCreateCompanionBuilder,
          $$UserSkillAreaClubMappingsTableUpdateCompanionBuilder,
          (
            UserSkillAreaClubMapping,
            BaseReferences<
              _$AppDatabase,
              $UserSkillAreaClubMappingsTable,
              UserSkillAreaClubMapping
            >,
          ),
          UserSkillAreaClubMapping,
          PrefetchHooks Function()
        > {
  $$UserSkillAreaClubMappingsTableTableManager(
    _$AppDatabase db,
    $UserSkillAreaClubMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSkillAreaClubMappingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserSkillAreaClubMappingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserSkillAreaClubMappingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> mappingId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<ClubType> clubType = const Value.absent(),
                Value<SkillArea> skillArea = const Value.absent(),
                Value<bool> isMandatory = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSkillAreaClubMappingsCompanion(
                mappingId: mappingId,
                userId: userId,
                clubType: clubType,
                skillArea: skillArea,
                isMandatory: isMandatory,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mappingId,
                required String userId,
                required ClubType clubType,
                required SkillArea skillArea,
                Value<bool> isMandatory = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSkillAreaClubMappingsCompanion.insert(
                mappingId: mappingId,
                userId: userId,
                clubType: clubType,
                skillArea: skillArea,
                isMandatory: isMandatory,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSkillAreaClubMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSkillAreaClubMappingsTable,
      UserSkillAreaClubMapping,
      $$UserSkillAreaClubMappingsTableFilterComposer,
      $$UserSkillAreaClubMappingsTableOrderingComposer,
      $$UserSkillAreaClubMappingsTableAnnotationComposer,
      $$UserSkillAreaClubMappingsTableCreateCompanionBuilder,
      $$UserSkillAreaClubMappingsTableUpdateCompanionBuilder,
      (
        UserSkillAreaClubMapping,
        BaseReferences<
          _$AppDatabase,
          $UserSkillAreaClubMappingsTable,
          UserSkillAreaClubMapping
        >,
      ),
      UserSkillAreaClubMapping,
      PrefetchHooks Function()
    >;
typedef $$RoutinesTableCreateCompanionBuilder =
    RoutinesCompanion Function({
      required String routineId,
      required String userId,
      required String name,
      Value<String> entries,
      Value<RoutineStatus> status,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastAppliedAt,
      Value<int> rowid,
    });
typedef $$RoutinesTableUpdateCompanionBuilder =
    RoutinesCompanion Function({
      Value<String> routineId,
      Value<String> userId,
      Value<String> name,
      Value<String> entries,
      Value<RoutineStatus> status,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastAppliedAt,
      Value<int> rowid,
    });

class $$RoutinesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entries => $composableBuilder(
    column: $table.entries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RoutineStatus, RoutineStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAppliedAt => $composableBuilder(
    column: $table.lastAppliedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entries => $composableBuilder(
    column: $table.entries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAppliedAt => $composableBuilder(
    column: $table.lastAppliedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get entries =>
      $composableBuilder(column: $table.entries, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RoutineStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAppliedAt => $composableBuilder(
    column: $table.lastAppliedAt,
    builder: (column) => column,
  );
}

class $$RoutinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutinesTable,
          Routine,
          $$RoutinesTableFilterComposer,
          $$RoutinesTableOrderingComposer,
          $$RoutinesTableAnnotationComposer,
          $$RoutinesTableCreateCompanionBuilder,
          $$RoutinesTableUpdateCompanionBuilder,
          (Routine, BaseReferences<_$AppDatabase, $RoutinesTable, Routine>),
          Routine,
          PrefetchHooks Function()
        > {
  $$RoutinesTableTableManager(_$AppDatabase db, $RoutinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> routineId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> entries = const Value.absent(),
                Value<RoutineStatus> status = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastAppliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutinesCompanion(
                routineId: routineId,
                userId: userId,
                name: name,
                entries: entries,
                status: status,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastAppliedAt: lastAppliedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String routineId,
                required String userId,
                required String name,
                Value<String> entries = const Value.absent(),
                Value<RoutineStatus> status = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastAppliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutinesCompanion.insert(
                routineId: routineId,
                userId: userId,
                name: name,
                entries: entries,
                status: status,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastAppliedAt: lastAppliedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoutinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutinesTable,
      Routine,
      $$RoutinesTableFilterComposer,
      $$RoutinesTableOrderingComposer,
      $$RoutinesTableAnnotationComposer,
      $$RoutinesTableCreateCompanionBuilder,
      $$RoutinesTableUpdateCompanionBuilder,
      (Routine, BaseReferences<_$AppDatabase, $RoutinesTable, Routine>),
      Routine,
      PrefetchHooks Function()
    >;
typedef $$SchedulesTableCreateCompanionBuilder =
    SchedulesCompanion Function({
      required String scheduleId,
      required String userId,
      required String name,
      required ScheduleAppMode applicationMode,
      Value<String> entries,
      Value<ScheduleStatus> status,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SchedulesTableUpdateCompanionBuilder =
    SchedulesCompanion Function({
      Value<String> scheduleId,
      Value<String> userId,
      Value<String> name,
      Value<ScheduleAppMode> applicationMode,
      Value<String> entries,
      Value<ScheduleStatus> status,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ScheduleAppMode, ScheduleAppMode, String>
  get applicationMode => $composableBuilder(
    column: $table.applicationMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get entries => $composableBuilder(
    column: $table.entries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ScheduleStatus, ScheduleStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applicationMode => $composableBuilder(
    column: $table.applicationMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entries => $composableBuilder(
    column: $table.entries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScheduleAppMode, String>
  get applicationMode => $composableBuilder(
    column: $table.applicationMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entries =>
      $composableBuilder(column: $table.entries, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScheduleStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchedulesTable,
          Schedule,
          $$SchedulesTableFilterComposer,
          $$SchedulesTableOrderingComposer,
          $$SchedulesTableAnnotationComposer,
          $$SchedulesTableCreateCompanionBuilder,
          $$SchedulesTableUpdateCompanionBuilder,
          (Schedule, BaseReferences<_$AppDatabase, $SchedulesTable, Schedule>),
          Schedule,
          PrefetchHooks Function()
        > {
  $$SchedulesTableTableManager(_$AppDatabase db, $SchedulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scheduleId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ScheduleAppMode> applicationMode = const Value.absent(),
                Value<String> entries = const Value.absent(),
                Value<ScheduleStatus> status = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulesCompanion(
                scheduleId: scheduleId,
                userId: userId,
                name: name,
                applicationMode: applicationMode,
                entries: entries,
                status: status,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scheduleId,
                required String userId,
                required String name,
                required ScheduleAppMode applicationMode,
                Value<String> entries = const Value.absent(),
                Value<ScheduleStatus> status = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulesCompanion.insert(
                scheduleId: scheduleId,
                userId: userId,
                name: name,
                applicationMode: applicationMode,
                entries: entries,
                status: status,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchedulesTable,
      Schedule,
      $$SchedulesTableFilterComposer,
      $$SchedulesTableOrderingComposer,
      $$SchedulesTableAnnotationComposer,
      $$SchedulesTableCreateCompanionBuilder,
      $$SchedulesTableUpdateCompanionBuilder,
      (Schedule, BaseReferences<_$AppDatabase, $SchedulesTable, Schedule>),
      Schedule,
      PrefetchHooks Function()
    >;
typedef $$CalendarDaysTableCreateCompanionBuilder =
    CalendarDaysCompanion Function({
      required String calendarDayId,
      required String userId,
      required DateTime date,
      Value<int> slotCapacity,
      Value<String> slots,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CalendarDaysTableUpdateCompanionBuilder =
    CalendarDaysCompanion Function({
      Value<String> calendarDayId,
      Value<String> userId,
      Value<DateTime> date,
      Value<int> slotCapacity,
      Value<String> slots,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CalendarDaysTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarDaysTable> {
  $$CalendarDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get calendarDayId => $composableBuilder(
    column: $table.calendarDayId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slotCapacity => $composableBuilder(
    column: $table.slotCapacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slots => $composableBuilder(
    column: $table.slots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CalendarDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarDaysTable> {
  $$CalendarDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get calendarDayId => $composableBuilder(
    column: $table.calendarDayId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slotCapacity => $composableBuilder(
    column: $table.slotCapacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slots => $composableBuilder(
    column: $table.slots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarDaysTable> {
  $$CalendarDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get calendarDayId => $composableBuilder(
    column: $table.calendarDayId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get slotCapacity => $composableBuilder(
    column: $table.slotCapacity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get slots =>
      $composableBuilder(column: $table.slots, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CalendarDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarDaysTable,
          CalendarDay,
          $$CalendarDaysTableFilterComposer,
          $$CalendarDaysTableOrderingComposer,
          $$CalendarDaysTableAnnotationComposer,
          $$CalendarDaysTableCreateCompanionBuilder,
          $$CalendarDaysTableUpdateCompanionBuilder,
          (
            CalendarDay,
            BaseReferences<_$AppDatabase, $CalendarDaysTable, CalendarDay>,
          ),
          CalendarDay,
          PrefetchHooks Function()
        > {
  $$CalendarDaysTableTableManager(_$AppDatabase db, $CalendarDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> calendarDayId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> slotCapacity = const Value.absent(),
                Value<String> slots = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarDaysCompanion(
                calendarDayId: calendarDayId,
                userId: userId,
                date: date,
                slotCapacity: slotCapacity,
                slots: slots,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String calendarDayId,
                required String userId,
                required DateTime date,
                Value<int> slotCapacity = const Value.absent(),
                Value<String> slots = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarDaysCompanion.insert(
                calendarDayId: calendarDayId,
                userId: userId,
                date: date,
                slotCapacity: slotCapacity,
                slots: slots,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarDaysTable,
      CalendarDay,
      $$CalendarDaysTableFilterComposer,
      $$CalendarDaysTableOrderingComposer,
      $$CalendarDaysTableAnnotationComposer,
      $$CalendarDaysTableCreateCompanionBuilder,
      $$CalendarDaysTableUpdateCompanionBuilder,
      (
        CalendarDay,
        BaseReferences<_$AppDatabase, $CalendarDaysTable, CalendarDay>,
      ),
      CalendarDay,
      PrefetchHooks Function()
    >;
typedef $$RoutineInstancesTableCreateCompanionBuilder =
    RoutineInstancesCompanion Function({
      required String routineInstanceId,
      Value<String?> routineId,
      required String userId,
      required DateTime calendarDayDate,
      Value<String> ownedSlots,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RoutineInstancesTableUpdateCompanionBuilder =
    RoutineInstancesCompanion Function({
      Value<String> routineInstanceId,
      Value<String?> routineId,
      Value<String> userId,
      Value<DateTime> calendarDayDate,
      Value<String> ownedSlots,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RoutineInstancesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineInstancesTable> {
  $$RoutineInstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get routineInstanceId => $composableBuilder(
    column: $table.routineInstanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get calendarDayDate => $composableBuilder(
    column: $table.calendarDayDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownedSlots => $composableBuilder(
    column: $table.ownedSlots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RoutineInstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineInstancesTable> {
  $$RoutineInstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get routineInstanceId => $composableBuilder(
    column: $table.routineInstanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get calendarDayDate => $composableBuilder(
    column: $table.calendarDayDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownedSlots => $composableBuilder(
    column: $table.ownedSlots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoutineInstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineInstancesTable> {
  $$RoutineInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get routineInstanceId => $composableBuilder(
    column: $table.routineInstanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get calendarDayDate => $composableBuilder(
    column: $table.calendarDayDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownedSlots => $composableBuilder(
    column: $table.ownedSlots,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RoutineInstancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoutineInstancesTable,
          RoutineInstance,
          $$RoutineInstancesTableFilterComposer,
          $$RoutineInstancesTableOrderingComposer,
          $$RoutineInstancesTableAnnotationComposer,
          $$RoutineInstancesTableCreateCompanionBuilder,
          $$RoutineInstancesTableUpdateCompanionBuilder,
          (
            RoutineInstance,
            BaseReferences<
              _$AppDatabase,
              $RoutineInstancesTable,
              RoutineInstance
            >,
          ),
          RoutineInstance,
          PrefetchHooks Function()
        > {
  $$RoutineInstancesTableTableManager(
    _$AppDatabase db,
    $RoutineInstancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineInstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineInstancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> routineInstanceId = const Value.absent(),
                Value<String?> routineId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> calendarDayDate = const Value.absent(),
                Value<String> ownedSlots = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineInstancesCompanion(
                routineInstanceId: routineInstanceId,
                routineId: routineId,
                userId: userId,
                calendarDayDate: calendarDayDate,
                ownedSlots: ownedSlots,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String routineInstanceId,
                Value<String?> routineId = const Value.absent(),
                required String userId,
                required DateTime calendarDayDate,
                Value<String> ownedSlots = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineInstancesCompanion.insert(
                routineInstanceId: routineInstanceId,
                routineId: routineId,
                userId: userId,
                calendarDayDate: calendarDayDate,
                ownedSlots: ownedSlots,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoutineInstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoutineInstancesTable,
      RoutineInstance,
      $$RoutineInstancesTableFilterComposer,
      $$RoutineInstancesTableOrderingComposer,
      $$RoutineInstancesTableAnnotationComposer,
      $$RoutineInstancesTableCreateCompanionBuilder,
      $$RoutineInstancesTableUpdateCompanionBuilder,
      (
        RoutineInstance,
        BaseReferences<_$AppDatabase, $RoutineInstancesTable, RoutineInstance>,
      ),
      RoutineInstance,
      PrefetchHooks Function()
    >;
typedef $$ScheduleInstancesTableCreateCompanionBuilder =
    ScheduleInstancesCompanion Function({
      required String scheduleInstanceId,
      Value<String?> scheduleId,
      required String userId,
      required DateTime startDate,
      required DateTime endDate,
      Value<String> ownedSlots,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$ScheduleInstancesTableUpdateCompanionBuilder =
    ScheduleInstancesCompanion Function({
      Value<String> scheduleInstanceId,
      Value<String?> scheduleId,
      Value<String> userId,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<String> ownedSlots,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ScheduleInstancesTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduleInstancesTable> {
  $$ScheduleInstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scheduleInstanceId => $composableBuilder(
    column: $table.scheduleInstanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownedSlots => $composableBuilder(
    column: $table.ownedSlots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScheduleInstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduleInstancesTable> {
  $$ScheduleInstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scheduleInstanceId => $composableBuilder(
    column: $table.scheduleInstanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownedSlots => $composableBuilder(
    column: $table.ownedSlots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScheduleInstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduleInstancesTable> {
  $$ScheduleInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scheduleInstanceId => $composableBuilder(
    column: $table.scheduleInstanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get ownedSlots => $composableBuilder(
    column: $table.ownedSlots,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ScheduleInstancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduleInstancesTable,
          ScheduleInstance,
          $$ScheduleInstancesTableFilterComposer,
          $$ScheduleInstancesTableOrderingComposer,
          $$ScheduleInstancesTableAnnotationComposer,
          $$ScheduleInstancesTableCreateCompanionBuilder,
          $$ScheduleInstancesTableUpdateCompanionBuilder,
          (
            ScheduleInstance,
            BaseReferences<
              _$AppDatabase,
              $ScheduleInstancesTable,
              ScheduleInstance
            >,
          ),
          ScheduleInstance,
          PrefetchHooks Function()
        > {
  $$ScheduleInstancesTableTableManager(
    _$AppDatabase db,
    $ScheduleInstancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleInstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleInstancesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scheduleInstanceId = const Value.absent(),
                Value<String?> scheduleId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<String> ownedSlots = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleInstancesCompanion(
                scheduleInstanceId: scheduleInstanceId,
                scheduleId: scheduleId,
                userId: userId,
                startDate: startDate,
                endDate: endDate,
                ownedSlots: ownedSlots,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scheduleInstanceId,
                Value<String?> scheduleId = const Value.absent(),
                required String userId,
                required DateTime startDate,
                required DateTime endDate,
                Value<String> ownedSlots = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScheduleInstancesCompanion.insert(
                scheduleInstanceId: scheduleInstanceId,
                scheduleId: scheduleId,
                userId: userId,
                startDate: startDate,
                endDate: endDate,
                ownedSlots: ownedSlots,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduleInstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduleInstancesTable,
      ScheduleInstance,
      $$ScheduleInstancesTableFilterComposer,
      $$ScheduleInstancesTableOrderingComposer,
      $$ScheduleInstancesTableAnnotationComposer,
      $$ScheduleInstancesTableCreateCompanionBuilder,
      $$ScheduleInstancesTableUpdateCompanionBuilder,
      (
        ScheduleInstance,
        BaseReferences<
          _$AppDatabase,
          $ScheduleInstancesTable,
          ScheduleInstance
        >,
      ),
      ScheduleInstance,
      PrefetchHooks Function()
    >;
typedef $$MaterialisedWindowStatesTableCreateCompanionBuilder =
    MaterialisedWindowStatesCompanion Function({
      required String userId,
      required SkillArea skillArea,
      required String subskill,
      required DrillType practiceType,
      Value<String> entries,
      Value<double> totalOccupancy,
      Value<double> weightedSum,
      Value<double> windowAverage,
      Value<int> rowid,
    });
typedef $$MaterialisedWindowStatesTableUpdateCompanionBuilder =
    MaterialisedWindowStatesCompanion Function({
      Value<String> userId,
      Value<SkillArea> skillArea,
      Value<String> subskill,
      Value<DrillType> practiceType,
      Value<String> entries,
      Value<double> totalOccupancy,
      Value<double> weightedSum,
      Value<double> windowAverage,
      Value<int> rowid,
    });

class $$MaterialisedWindowStatesTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialisedWindowStatesTable> {
  $$MaterialisedWindowStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SkillArea, SkillArea, String> get skillArea =>
      $composableBuilder(
        column: $table.skillArea,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get subskill => $composableBuilder(
    column: $table.subskill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DrillType, DrillType, String>
  get practiceType => $composableBuilder(
    column: $table.practiceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get entries => $composableBuilder(
    column: $table.entries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalOccupancy => $composableBuilder(
    column: $table.totalOccupancy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightedSum => $composableBuilder(
    column: $table.weightedSum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get windowAverage => $composableBuilder(
    column: $table.windowAverage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaterialisedWindowStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialisedWindowStatesTable> {
  $$MaterialisedWindowStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillArea => $composableBuilder(
    column: $table.skillArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subskill => $composableBuilder(
    column: $table.subskill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get practiceType => $composableBuilder(
    column: $table.practiceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entries => $composableBuilder(
    column: $table.entries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalOccupancy => $composableBuilder(
    column: $table.totalOccupancy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightedSum => $composableBuilder(
    column: $table.weightedSum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get windowAverage => $composableBuilder(
    column: $table.windowAverage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaterialisedWindowStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialisedWindowStatesTable> {
  $$MaterialisedWindowStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkillArea, String> get skillArea =>
      $composableBuilder(column: $table.skillArea, builder: (column) => column);

  GeneratedColumn<String> get subskill =>
      $composableBuilder(column: $table.subskill, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DrillType, String> get practiceType =>
      $composableBuilder(
        column: $table.practiceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get entries =>
      $composableBuilder(column: $table.entries, builder: (column) => column);

  GeneratedColumn<double> get totalOccupancy => $composableBuilder(
    column: $table.totalOccupancy,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightedSum => $composableBuilder(
    column: $table.weightedSum,
    builder: (column) => column,
  );

  GeneratedColumn<double> get windowAverage => $composableBuilder(
    column: $table.windowAverage,
    builder: (column) => column,
  );
}

class $$MaterialisedWindowStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaterialisedWindowStatesTable,
          MaterialisedWindowState,
          $$MaterialisedWindowStatesTableFilterComposer,
          $$MaterialisedWindowStatesTableOrderingComposer,
          $$MaterialisedWindowStatesTableAnnotationComposer,
          $$MaterialisedWindowStatesTableCreateCompanionBuilder,
          $$MaterialisedWindowStatesTableUpdateCompanionBuilder,
          (
            MaterialisedWindowState,
            BaseReferences<
              _$AppDatabase,
              $MaterialisedWindowStatesTable,
              MaterialisedWindowState
            >,
          ),
          MaterialisedWindowState,
          PrefetchHooks Function()
        > {
  $$MaterialisedWindowStatesTableTableManager(
    _$AppDatabase db,
    $MaterialisedWindowStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialisedWindowStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MaterialisedWindowStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MaterialisedWindowStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<SkillArea> skillArea = const Value.absent(),
                Value<String> subskill = const Value.absent(),
                Value<DrillType> practiceType = const Value.absent(),
                Value<String> entries = const Value.absent(),
                Value<double> totalOccupancy = const Value.absent(),
                Value<double> weightedSum = const Value.absent(),
                Value<double> windowAverage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialisedWindowStatesCompanion(
                userId: userId,
                skillArea: skillArea,
                subskill: subskill,
                practiceType: practiceType,
                entries: entries,
                totalOccupancy: totalOccupancy,
                weightedSum: weightedSum,
                windowAverage: windowAverage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required SkillArea skillArea,
                required String subskill,
                required DrillType practiceType,
                Value<String> entries = const Value.absent(),
                Value<double> totalOccupancy = const Value.absent(),
                Value<double> weightedSum = const Value.absent(),
                Value<double> windowAverage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialisedWindowStatesCompanion.insert(
                userId: userId,
                skillArea: skillArea,
                subskill: subskill,
                practiceType: practiceType,
                entries: entries,
                totalOccupancy: totalOccupancy,
                weightedSum: weightedSum,
                windowAverage: windowAverage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaterialisedWindowStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaterialisedWindowStatesTable,
      MaterialisedWindowState,
      $$MaterialisedWindowStatesTableFilterComposer,
      $$MaterialisedWindowStatesTableOrderingComposer,
      $$MaterialisedWindowStatesTableAnnotationComposer,
      $$MaterialisedWindowStatesTableCreateCompanionBuilder,
      $$MaterialisedWindowStatesTableUpdateCompanionBuilder,
      (
        MaterialisedWindowState,
        BaseReferences<
          _$AppDatabase,
          $MaterialisedWindowStatesTable,
          MaterialisedWindowState
        >,
      ),
      MaterialisedWindowState,
      PrefetchHooks Function()
    >;
typedef $$MaterialisedSubskillScoresTableCreateCompanionBuilder =
    MaterialisedSubskillScoresCompanion Function({
      required String userId,
      required SkillArea skillArea,
      required String subskill,
      Value<double> transitionAverage,
      Value<double> pressureAverage,
      Value<double> weightedAverage,
      Value<double> subskillPoints,
      Value<int> allocation,
      Value<int> rowid,
    });
typedef $$MaterialisedSubskillScoresTableUpdateCompanionBuilder =
    MaterialisedSubskillScoresCompanion Function({
      Value<String> userId,
      Value<SkillArea> skillArea,
      Value<String> subskill,
      Value<double> transitionAverage,
      Value<double> pressureAverage,
      Value<double> weightedAverage,
      Value<double> subskillPoints,
      Value<int> allocation,
      Value<int> rowid,
    });

class $$MaterialisedSubskillScoresTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialisedSubskillScoresTable> {
  $$MaterialisedSubskillScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SkillArea, SkillArea, String> get skillArea =>
      $composableBuilder(
        column: $table.skillArea,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get subskill => $composableBuilder(
    column: $table.subskill,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get transitionAverage => $composableBuilder(
    column: $table.transitionAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pressureAverage => $composableBuilder(
    column: $table.pressureAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightedAverage => $composableBuilder(
    column: $table.weightedAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subskillPoints => $composableBuilder(
    column: $table.subskillPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaterialisedSubskillScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialisedSubskillScoresTable> {
  $$MaterialisedSubskillScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillArea => $composableBuilder(
    column: $table.skillArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subskill => $composableBuilder(
    column: $table.subskill,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get transitionAverage => $composableBuilder(
    column: $table.transitionAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pressureAverage => $composableBuilder(
    column: $table.pressureAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightedAverage => $composableBuilder(
    column: $table.weightedAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subskillPoints => $composableBuilder(
    column: $table.subskillPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaterialisedSubskillScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialisedSubskillScoresTable> {
  $$MaterialisedSubskillScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkillArea, String> get skillArea =>
      $composableBuilder(column: $table.skillArea, builder: (column) => column);

  GeneratedColumn<String> get subskill =>
      $composableBuilder(column: $table.subskill, builder: (column) => column);

  GeneratedColumn<double> get transitionAverage => $composableBuilder(
    column: $table.transitionAverage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pressureAverage => $composableBuilder(
    column: $table.pressureAverage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightedAverage => $composableBuilder(
    column: $table.weightedAverage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subskillPoints => $composableBuilder(
    column: $table.subskillPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => column,
  );
}

class $$MaterialisedSubskillScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaterialisedSubskillScoresTable,
          MaterialisedSubskillScore,
          $$MaterialisedSubskillScoresTableFilterComposer,
          $$MaterialisedSubskillScoresTableOrderingComposer,
          $$MaterialisedSubskillScoresTableAnnotationComposer,
          $$MaterialisedSubskillScoresTableCreateCompanionBuilder,
          $$MaterialisedSubskillScoresTableUpdateCompanionBuilder,
          (
            MaterialisedSubskillScore,
            BaseReferences<
              _$AppDatabase,
              $MaterialisedSubskillScoresTable,
              MaterialisedSubskillScore
            >,
          ),
          MaterialisedSubskillScore,
          PrefetchHooks Function()
        > {
  $$MaterialisedSubskillScoresTableTableManager(
    _$AppDatabase db,
    $MaterialisedSubskillScoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialisedSubskillScoresTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MaterialisedSubskillScoresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MaterialisedSubskillScoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<SkillArea> skillArea = const Value.absent(),
                Value<String> subskill = const Value.absent(),
                Value<double> transitionAverage = const Value.absent(),
                Value<double> pressureAverage = const Value.absent(),
                Value<double> weightedAverage = const Value.absent(),
                Value<double> subskillPoints = const Value.absent(),
                Value<int> allocation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialisedSubskillScoresCompanion(
                userId: userId,
                skillArea: skillArea,
                subskill: subskill,
                transitionAverage: transitionAverage,
                pressureAverage: pressureAverage,
                weightedAverage: weightedAverage,
                subskillPoints: subskillPoints,
                allocation: allocation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required SkillArea skillArea,
                required String subskill,
                Value<double> transitionAverage = const Value.absent(),
                Value<double> pressureAverage = const Value.absent(),
                Value<double> weightedAverage = const Value.absent(),
                Value<double> subskillPoints = const Value.absent(),
                Value<int> allocation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialisedSubskillScoresCompanion.insert(
                userId: userId,
                skillArea: skillArea,
                subskill: subskill,
                transitionAverage: transitionAverage,
                pressureAverage: pressureAverage,
                weightedAverage: weightedAverage,
                subskillPoints: subskillPoints,
                allocation: allocation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaterialisedSubskillScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaterialisedSubskillScoresTable,
      MaterialisedSubskillScore,
      $$MaterialisedSubskillScoresTableFilterComposer,
      $$MaterialisedSubskillScoresTableOrderingComposer,
      $$MaterialisedSubskillScoresTableAnnotationComposer,
      $$MaterialisedSubskillScoresTableCreateCompanionBuilder,
      $$MaterialisedSubskillScoresTableUpdateCompanionBuilder,
      (
        MaterialisedSubskillScore,
        BaseReferences<
          _$AppDatabase,
          $MaterialisedSubskillScoresTable,
          MaterialisedSubskillScore
        >,
      ),
      MaterialisedSubskillScore,
      PrefetchHooks Function()
    >;
typedef $$MaterialisedSkillAreaScoresTableCreateCompanionBuilder =
    MaterialisedSkillAreaScoresCompanion Function({
      required String userId,
      required SkillArea skillArea,
      Value<double> skillAreaScore,
      Value<int> allocation,
      Value<int> rowid,
    });
typedef $$MaterialisedSkillAreaScoresTableUpdateCompanionBuilder =
    MaterialisedSkillAreaScoresCompanion Function({
      Value<String> userId,
      Value<SkillArea> skillArea,
      Value<double> skillAreaScore,
      Value<int> allocation,
      Value<int> rowid,
    });

class $$MaterialisedSkillAreaScoresTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialisedSkillAreaScoresTable> {
  $$MaterialisedSkillAreaScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SkillArea, SkillArea, String> get skillArea =>
      $composableBuilder(
        column: $table.skillArea,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get skillAreaScore => $composableBuilder(
    column: $table.skillAreaScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaterialisedSkillAreaScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialisedSkillAreaScoresTable> {
  $$MaterialisedSkillAreaScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillArea => $composableBuilder(
    column: $table.skillArea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get skillAreaScore => $composableBuilder(
    column: $table.skillAreaScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaterialisedSkillAreaScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialisedSkillAreaScoresTable> {
  $$MaterialisedSkillAreaScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SkillArea, String> get skillArea =>
      $composableBuilder(column: $table.skillArea, builder: (column) => column);

  GeneratedColumn<double> get skillAreaScore => $composableBuilder(
    column: $table.skillAreaScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get allocation => $composableBuilder(
    column: $table.allocation,
    builder: (column) => column,
  );
}

class $$MaterialisedSkillAreaScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaterialisedSkillAreaScoresTable,
          MaterialisedSkillAreaScore,
          $$MaterialisedSkillAreaScoresTableFilterComposer,
          $$MaterialisedSkillAreaScoresTableOrderingComposer,
          $$MaterialisedSkillAreaScoresTableAnnotationComposer,
          $$MaterialisedSkillAreaScoresTableCreateCompanionBuilder,
          $$MaterialisedSkillAreaScoresTableUpdateCompanionBuilder,
          (
            MaterialisedSkillAreaScore,
            BaseReferences<
              _$AppDatabase,
              $MaterialisedSkillAreaScoresTable,
              MaterialisedSkillAreaScore
            >,
          ),
          MaterialisedSkillAreaScore,
          PrefetchHooks Function()
        > {
  $$MaterialisedSkillAreaScoresTableTableManager(
    _$AppDatabase db,
    $MaterialisedSkillAreaScoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialisedSkillAreaScoresTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MaterialisedSkillAreaScoresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MaterialisedSkillAreaScoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<SkillArea> skillArea = const Value.absent(),
                Value<double> skillAreaScore = const Value.absent(),
                Value<int> allocation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialisedSkillAreaScoresCompanion(
                userId: userId,
                skillArea: skillArea,
                skillAreaScore: skillAreaScore,
                allocation: allocation,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required SkillArea skillArea,
                Value<double> skillAreaScore = const Value.absent(),
                Value<int> allocation = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialisedSkillAreaScoresCompanion.insert(
                userId: userId,
                skillArea: skillArea,
                skillAreaScore: skillAreaScore,
                allocation: allocation,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaterialisedSkillAreaScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaterialisedSkillAreaScoresTable,
      MaterialisedSkillAreaScore,
      $$MaterialisedSkillAreaScoresTableFilterComposer,
      $$MaterialisedSkillAreaScoresTableOrderingComposer,
      $$MaterialisedSkillAreaScoresTableAnnotationComposer,
      $$MaterialisedSkillAreaScoresTableCreateCompanionBuilder,
      $$MaterialisedSkillAreaScoresTableUpdateCompanionBuilder,
      (
        MaterialisedSkillAreaScore,
        BaseReferences<
          _$AppDatabase,
          $MaterialisedSkillAreaScoresTable,
          MaterialisedSkillAreaScore
        >,
      ),
      MaterialisedSkillAreaScore,
      PrefetchHooks Function()
    >;
typedef $$MaterialisedOverallScoresTableCreateCompanionBuilder =
    MaterialisedOverallScoresCompanion Function({
      required String userId,
      Value<double> overallScore,
      Value<int> rowid,
    });
typedef $$MaterialisedOverallScoresTableUpdateCompanionBuilder =
    MaterialisedOverallScoresCompanion Function({
      Value<String> userId,
      Value<double> overallScore,
      Value<int> rowid,
    });

class $$MaterialisedOverallScoresTableFilterComposer
    extends Composer<_$AppDatabase, $MaterialisedOverallScoresTable> {
  $$MaterialisedOverallScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaterialisedOverallScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $MaterialisedOverallScoresTable> {
  $$MaterialisedOverallScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaterialisedOverallScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaterialisedOverallScoresTable> {
  $$MaterialisedOverallScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get overallScore => $composableBuilder(
    column: $table.overallScore,
    builder: (column) => column,
  );
}

class $$MaterialisedOverallScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaterialisedOverallScoresTable,
          MaterialisedOverallScore,
          $$MaterialisedOverallScoresTableFilterComposer,
          $$MaterialisedOverallScoresTableOrderingComposer,
          $$MaterialisedOverallScoresTableAnnotationComposer,
          $$MaterialisedOverallScoresTableCreateCompanionBuilder,
          $$MaterialisedOverallScoresTableUpdateCompanionBuilder,
          (
            MaterialisedOverallScore,
            BaseReferences<
              _$AppDatabase,
              $MaterialisedOverallScoresTable,
              MaterialisedOverallScore
            >,
          ),
          MaterialisedOverallScore,
          PrefetchHooks Function()
        > {
  $$MaterialisedOverallScoresTableTableManager(
    _$AppDatabase db,
    $MaterialisedOverallScoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaterialisedOverallScoresTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MaterialisedOverallScoresTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MaterialisedOverallScoresTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<double> overallScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialisedOverallScoresCompanion(
                userId: userId,
                overallScore: overallScore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<double> overallScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaterialisedOverallScoresCompanion.insert(
                userId: userId,
                overallScore: overallScore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaterialisedOverallScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaterialisedOverallScoresTable,
      MaterialisedOverallScore,
      $$MaterialisedOverallScoresTableFilterComposer,
      $$MaterialisedOverallScoresTableOrderingComposer,
      $$MaterialisedOverallScoresTableAnnotationComposer,
      $$MaterialisedOverallScoresTableCreateCompanionBuilder,
      $$MaterialisedOverallScoresTableUpdateCompanionBuilder,
      (
        MaterialisedOverallScore,
        BaseReferences<
          _$AppDatabase,
          $MaterialisedOverallScoresTable,
          MaterialisedOverallScore
        >,
      ),
      MaterialisedOverallScore,
      PrefetchHooks Function()
    >;
typedef $$EventLogsTableCreateCompanionBuilder =
    EventLogsCompanion Function({
      required String eventLogId,
      required String userId,
      Value<String?> deviceId,
      required String eventTypeId,
      Value<DateTime> timestamp,
      Value<String?> affectedEntityIds,
      Value<String?> affectedSubskills,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$EventLogsTableUpdateCompanionBuilder =
    EventLogsCompanion Function({
      Value<String> eventLogId,
      Value<String> userId,
      Value<String?> deviceId,
      Value<String> eventTypeId,
      Value<DateTime> timestamp,
      Value<String?> affectedEntityIds,
      Value<String?> affectedSubskills,
      Value<String?> metadata,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$EventLogsTableFilterComposer
    extends Composer<_$AppDatabase, $EventLogsTable> {
  $$EventLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventLogId => $composableBuilder(
    column: $table.eventLogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventTypeId => $composableBuilder(
    column: $table.eventTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get affectedEntityIds => $composableBuilder(
    column: $table.affectedEntityIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get affectedSubskills => $composableBuilder(
    column: $table.affectedSubskills,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventLogsTable> {
  $$EventLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventLogId => $composableBuilder(
    column: $table.eventLogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventTypeId => $composableBuilder(
    column: $table.eventTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get affectedEntityIds => $composableBuilder(
    column: $table.affectedEntityIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get affectedSubskills => $composableBuilder(
    column: $table.affectedSubskills,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventLogsTable> {
  $$EventLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventLogId => $composableBuilder(
    column: $table.eventLogId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get eventTypeId => $composableBuilder(
    column: $table.eventTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get affectedEntityIds => $composableBuilder(
    column: $table.affectedEntityIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get affectedSubskills => $composableBuilder(
    column: $table.affectedSubskills,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EventLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventLogsTable,
          EventLog,
          $$EventLogsTableFilterComposer,
          $$EventLogsTableOrderingComposer,
          $$EventLogsTableAnnotationComposer,
          $$EventLogsTableCreateCompanionBuilder,
          $$EventLogsTableUpdateCompanionBuilder,
          (EventLog, BaseReferences<_$AppDatabase, $EventLogsTable, EventLog>),
          EventLog,
          PrefetchHooks Function()
        > {
  $$EventLogsTableTableManager(_$AppDatabase db, $EventLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventLogId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> eventTypeId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> affectedEntityIds = const Value.absent(),
                Value<String?> affectedSubskills = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventLogsCompanion(
                eventLogId: eventLogId,
                userId: userId,
                deviceId: deviceId,
                eventTypeId: eventTypeId,
                timestamp: timestamp,
                affectedEntityIds: affectedEntityIds,
                affectedSubskills: affectedSubskills,
                metadata: metadata,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventLogId,
                required String userId,
                Value<String?> deviceId = const Value.absent(),
                required String eventTypeId,
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> affectedEntityIds = const Value.absent(),
                Value<String?> affectedSubskills = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventLogsCompanion.insert(
                eventLogId: eventLogId,
                userId: userId,
                deviceId: deviceId,
                eventTypeId: eventTypeId,
                timestamp: timestamp,
                affectedEntityIds: affectedEntityIds,
                affectedSubskills: affectedSubskills,
                metadata: metadata,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventLogsTable,
      EventLog,
      $$EventLogsTableFilterComposer,
      $$EventLogsTableOrderingComposer,
      $$EventLogsTableAnnotationComposer,
      $$EventLogsTableCreateCompanionBuilder,
      $$EventLogsTableUpdateCompanionBuilder,
      (EventLog, BaseReferences<_$AppDatabase, $EventLogsTable, EventLog>),
      EventLog,
      PrefetchHooks Function()
    >;
typedef $$UserDevicesTableCreateCompanionBuilder =
    UserDevicesCompanion Function({
      required String deviceId,
      required String userId,
      Value<String?> deviceLabel,
      Value<DateTime> registeredAt,
      Value<DateTime?> lastSyncAt,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UserDevicesTableUpdateCompanionBuilder =
    UserDevicesCompanion Function({
      Value<String> deviceId,
      Value<String> userId,
      Value<String?> deviceLabel,
      Value<DateTime> registeredAt,
      Value<DateTime?> lastSyncAt,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UserDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $UserDevicesTable> {
  $$UserDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserDevicesTable> {
  $$UserDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserDevicesTable> {
  $$UserDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get deviceLabel => $composableBuilder(
    column: $table.deviceLabel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserDevicesTable,
          UserDevice,
          $$UserDevicesTableFilterComposer,
          $$UserDevicesTableOrderingComposer,
          $$UserDevicesTableAnnotationComposer,
          $$UserDevicesTableCreateCompanionBuilder,
          $$UserDevicesTableUpdateCompanionBuilder,
          (
            UserDevice,
            BaseReferences<_$AppDatabase, $UserDevicesTable, UserDevice>,
          ),
          UserDevice,
          PrefetchHooks Function()
        > {
  $$UserDevicesTableTableManager(_$AppDatabase db, $UserDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> deviceLabel = const Value.absent(),
                Value<DateTime> registeredAt = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserDevicesCompanion(
                deviceId: deviceId,
                userId: userId,
                deviceLabel: deviceLabel,
                registeredAt: registeredAt,
                lastSyncAt: lastSyncAt,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String userId,
                Value<String?> deviceLabel = const Value.absent(),
                Value<DateTime> registeredAt = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserDevicesCompanion.insert(
                deviceId: deviceId,
                userId: userId,
                deviceLabel: deviceLabel,
                registeredAt: registeredAt,
                lastSyncAt: lastSyncAt,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserDevicesTable,
      UserDevice,
      $$UserDevicesTableFilterComposer,
      $$UserDevicesTableOrderingComposer,
      $$UserDevicesTableAnnotationComposer,
      $$UserDevicesTableCreateCompanionBuilder,
      $$UserDevicesTableUpdateCompanionBuilder,
      (
        UserDevice,
        BaseReferences<_$AppDatabase, $UserDevicesTable, UserDevice>,
      ),
      UserDevice,
      PrefetchHooks Function()
    >;
typedef $$UserScoringLocksTableCreateCompanionBuilder =
    UserScoringLocksCompanion Function({
      required String userId,
      Value<bool> isLocked,
      Value<DateTime?> lockedAt,
      Value<DateTime?> lockExpiresAt,
      Value<int> rowid,
    });
typedef $$UserScoringLocksTableUpdateCompanionBuilder =
    UserScoringLocksCompanion Function({
      Value<String> userId,
      Value<bool> isLocked,
      Value<DateTime?> lockedAt,
      Value<DateTime?> lockExpiresAt,
      Value<int> rowid,
    });

class $$UserScoringLocksTableFilterComposer
    extends Composer<_$AppDatabase, $UserScoringLocksTable> {
  $$UserScoringLocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockExpiresAt => $composableBuilder(
    column: $table.lockExpiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserScoringLocksTableOrderingComposer
    extends Composer<_$AppDatabase, $UserScoringLocksTable> {
  $$UserScoringLocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockExpiresAt => $composableBuilder(
    column: $table.lockExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserScoringLocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserScoringLocksTable> {
  $$UserScoringLocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<DateTime> get lockedAt =>
      $composableBuilder(column: $table.lockedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lockExpiresAt => $composableBuilder(
    column: $table.lockExpiresAt,
    builder: (column) => column,
  );
}

class $$UserScoringLocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserScoringLocksTable,
          UserScoringLock,
          $$UserScoringLocksTableFilterComposer,
          $$UserScoringLocksTableOrderingComposer,
          $$UserScoringLocksTableAnnotationComposer,
          $$UserScoringLocksTableCreateCompanionBuilder,
          $$UserScoringLocksTableUpdateCompanionBuilder,
          (
            UserScoringLock,
            BaseReferences<
              _$AppDatabase,
              $UserScoringLocksTable,
              UserScoringLock
            >,
          ),
          UserScoringLock,
          PrefetchHooks Function()
        > {
  $$UserScoringLocksTableTableManager(
    _$AppDatabase db,
    $UserScoringLocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserScoringLocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserScoringLocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserScoringLocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<DateTime?> lockExpiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserScoringLocksCompanion(
                userId: userId,
                isLocked: isLocked,
                lockedAt: lockedAt,
                lockExpiresAt: lockExpiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<bool> isLocked = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<DateTime?> lockExpiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserScoringLocksCompanion.insert(
                userId: userId,
                isLocked: isLocked,
                lockedAt: lockedAt,
                lockExpiresAt: lockExpiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserScoringLocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserScoringLocksTable,
      UserScoringLock,
      $$UserScoringLocksTableFilterComposer,
      $$UserScoringLocksTableOrderingComposer,
      $$UserScoringLocksTableAnnotationComposer,
      $$UserScoringLocksTableCreateCompanionBuilder,
      $$UserScoringLocksTableUpdateCompanionBuilder,
      (
        UserScoringLock,
        BaseReferences<_$AppDatabase, $UserScoringLocksTable, UserScoringLock>,
      ),
      UserScoringLock,
      PrefetchHooks Function()
    >;
typedef $$MatrixRunsTableCreateCompanionBuilder =
    MatrixRunsCompanion Function({
      required String matrixRunId,
      required String userId,
      required MatrixType matrixType,
      required int runNumber,
      required RunState runState,
      Value<DateTime> startTimestamp,
      Value<DateTime?> endTimestamp,
      required int sessionShotTarget,
      required ShotOrderMode shotOrderMode,
      Value<bool> dispersionCaptureEnabled,
      Value<String?> measurementDevice,
      Value<EnvironmentType?> environmentType,
      Value<SurfaceType?> surfaceType,
      Value<double?> greenSpeed,
      Value<GreenFirmness?> greenFirmness,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MatrixRunsTableUpdateCompanionBuilder =
    MatrixRunsCompanion Function({
      Value<String> matrixRunId,
      Value<String> userId,
      Value<MatrixType> matrixType,
      Value<int> runNumber,
      Value<RunState> runState,
      Value<DateTime> startTimestamp,
      Value<DateTime?> endTimestamp,
      Value<int> sessionShotTarget,
      Value<ShotOrderMode> shotOrderMode,
      Value<bool> dispersionCaptureEnabled,
      Value<String?> measurementDevice,
      Value<EnvironmentType?> environmentType,
      Value<SurfaceType?> surfaceType,
      Value<double?> greenSpeed,
      Value<GreenFirmness?> greenFirmness,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MatrixRunsTableFilterComposer
    extends Composer<_$AppDatabase, $MatrixRunsTable> {
  $$MatrixRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MatrixType, MatrixType, String>
  get matrixType => $composableBuilder(
    column: $table.matrixType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get runNumber => $composableBuilder(
    column: $table.runNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RunState, RunState, String> get runState =>
      $composableBuilder(
        column: $table.runState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTimestamp => $composableBuilder(
    column: $table.endTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionShotTarget => $composableBuilder(
    column: $table.sessionShotTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ShotOrderMode, ShotOrderMode, String>
  get shotOrderMode => $composableBuilder(
    column: $table.shotOrderMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get dispersionCaptureEnabled => $composableBuilder(
    column: $table.dispersionCaptureEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementDevice => $composableBuilder(
    column: $table.measurementDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EnvironmentType?, EnvironmentType, String>
  get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SurfaceType?, SurfaceType, String>
  get surfaceType => $composableBuilder(
    column: $table.surfaceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get greenSpeed => $composableBuilder(
    column: $table.greenSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<GreenFirmness?, GreenFirmness, String>
  get greenFirmness => $composableBuilder(
    column: $table.greenFirmness,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatrixRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $MatrixRunsTable> {
  $$MatrixRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixType => $composableBuilder(
    column: $table.matrixType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runNumber => $composableBuilder(
    column: $table.runNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runState => $composableBuilder(
    column: $table.runState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTimestamp => $composableBuilder(
    column: $table.endTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionShotTarget => $composableBuilder(
    column: $table.sessionShotTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shotOrderMode => $composableBuilder(
    column: $table.shotOrderMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dispersionCaptureEnabled => $composableBuilder(
    column: $table.dispersionCaptureEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementDevice => $composableBuilder(
    column: $table.measurementDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surfaceType => $composableBuilder(
    column: $table.surfaceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get greenSpeed => $composableBuilder(
    column: $table.greenSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get greenFirmness => $composableBuilder(
    column: $table.greenFirmness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatrixRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatrixRunsTable> {
  $$MatrixRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MatrixType, String> get matrixType =>
      $composableBuilder(
        column: $table.matrixType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get runNumber =>
      $composableBuilder(column: $table.runNumber, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RunState, String> get runState =>
      $composableBuilder(column: $table.runState, builder: (column) => column);

  GeneratedColumn<DateTime> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endTimestamp => $composableBuilder(
    column: $table.endTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sessionShotTarget => $composableBuilder(
    column: $table.sessionShotTarget,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ShotOrderMode, String> get shotOrderMode =>
      $composableBuilder(
        column: $table.shotOrderMode,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get dispersionCaptureEnabled => $composableBuilder(
    column: $table.dispersionCaptureEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measurementDevice => $composableBuilder(
    column: $table.measurementDevice,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EnvironmentType?, String>
  get environmentType => $composableBuilder(
    column: $table.environmentType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SurfaceType?, String> get surfaceType =>
      $composableBuilder(
        column: $table.surfaceType,
        builder: (column) => column,
      );

  GeneratedColumn<double> get greenSpeed => $composableBuilder(
    column: $table.greenSpeed,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GreenFirmness?, String> get greenFirmness =>
      $composableBuilder(
        column: $table.greenFirmness,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MatrixRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatrixRunsTable,
          MatrixRun,
          $$MatrixRunsTableFilterComposer,
          $$MatrixRunsTableOrderingComposer,
          $$MatrixRunsTableAnnotationComposer,
          $$MatrixRunsTableCreateCompanionBuilder,
          $$MatrixRunsTableUpdateCompanionBuilder,
          (
            MatrixRun,
            BaseReferences<_$AppDatabase, $MatrixRunsTable, MatrixRun>,
          ),
          MatrixRun,
          PrefetchHooks Function()
        > {
  $$MatrixRunsTableTableManager(_$AppDatabase db, $MatrixRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatrixRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatrixRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatrixRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> matrixRunId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<MatrixType> matrixType = const Value.absent(),
                Value<int> runNumber = const Value.absent(),
                Value<RunState> runState = const Value.absent(),
                Value<DateTime> startTimestamp = const Value.absent(),
                Value<DateTime?> endTimestamp = const Value.absent(),
                Value<int> sessionShotTarget = const Value.absent(),
                Value<ShotOrderMode> shotOrderMode = const Value.absent(),
                Value<bool> dispersionCaptureEnabled = const Value.absent(),
                Value<String?> measurementDevice = const Value.absent(),
                Value<EnvironmentType?> environmentType = const Value.absent(),
                Value<SurfaceType?> surfaceType = const Value.absent(),
                Value<double?> greenSpeed = const Value.absent(),
                Value<GreenFirmness?> greenFirmness = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixRunsCompanion(
                matrixRunId: matrixRunId,
                userId: userId,
                matrixType: matrixType,
                runNumber: runNumber,
                runState: runState,
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                sessionShotTarget: sessionShotTarget,
                shotOrderMode: shotOrderMode,
                dispersionCaptureEnabled: dispersionCaptureEnabled,
                measurementDevice: measurementDevice,
                environmentType: environmentType,
                surfaceType: surfaceType,
                greenSpeed: greenSpeed,
                greenFirmness: greenFirmness,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matrixRunId,
                required String userId,
                required MatrixType matrixType,
                required int runNumber,
                required RunState runState,
                Value<DateTime> startTimestamp = const Value.absent(),
                Value<DateTime?> endTimestamp = const Value.absent(),
                required int sessionShotTarget,
                required ShotOrderMode shotOrderMode,
                Value<bool> dispersionCaptureEnabled = const Value.absent(),
                Value<String?> measurementDevice = const Value.absent(),
                Value<EnvironmentType?> environmentType = const Value.absent(),
                Value<SurfaceType?> surfaceType = const Value.absent(),
                Value<double?> greenSpeed = const Value.absent(),
                Value<GreenFirmness?> greenFirmness = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixRunsCompanion.insert(
                matrixRunId: matrixRunId,
                userId: userId,
                matrixType: matrixType,
                runNumber: runNumber,
                runState: runState,
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                sessionShotTarget: sessionShotTarget,
                shotOrderMode: shotOrderMode,
                dispersionCaptureEnabled: dispersionCaptureEnabled,
                measurementDevice: measurementDevice,
                environmentType: environmentType,
                surfaceType: surfaceType,
                greenSpeed: greenSpeed,
                greenFirmness: greenFirmness,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatrixRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatrixRunsTable,
      MatrixRun,
      $$MatrixRunsTableFilterComposer,
      $$MatrixRunsTableOrderingComposer,
      $$MatrixRunsTableAnnotationComposer,
      $$MatrixRunsTableCreateCompanionBuilder,
      $$MatrixRunsTableUpdateCompanionBuilder,
      (MatrixRun, BaseReferences<_$AppDatabase, $MatrixRunsTable, MatrixRun>),
      MatrixRun,
      PrefetchHooks Function()
    >;
typedef $$MatrixAxesTableCreateCompanionBuilder =
    MatrixAxesCompanion Function({
      required String matrixAxisId,
      required String matrixRunId,
      required AxisType axisType,
      required String axisName,
      required int axisOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MatrixAxesTableUpdateCompanionBuilder =
    MatrixAxesCompanion Function({
      Value<String> matrixAxisId,
      Value<String> matrixRunId,
      Value<AxisType> axisType,
      Value<String> axisName,
      Value<int> axisOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MatrixAxesTableFilterComposer
    extends Composer<_$AppDatabase, $MatrixAxesTable> {
  $$MatrixAxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matrixAxisId => $composableBuilder(
    column: $table.matrixAxisId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AxisType, AxisType, String> get axisType =>
      $composableBuilder(
        column: $table.axisType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get axisName => $composableBuilder(
    column: $table.axisName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get axisOrder => $composableBuilder(
    column: $table.axisOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatrixAxesTableOrderingComposer
    extends Composer<_$AppDatabase, $MatrixAxesTable> {
  $$MatrixAxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matrixAxisId => $composableBuilder(
    column: $table.matrixAxisId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get axisType => $composableBuilder(
    column: $table.axisType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get axisName => $composableBuilder(
    column: $table.axisName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get axisOrder => $composableBuilder(
    column: $table.axisOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatrixAxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatrixAxesTable> {
  $$MatrixAxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matrixAxisId => $composableBuilder(
    column: $table.matrixAxisId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AxisType, String> get axisType =>
      $composableBuilder(column: $table.axisType, builder: (column) => column);

  GeneratedColumn<String> get axisName =>
      $composableBuilder(column: $table.axisName, builder: (column) => column);

  GeneratedColumn<int> get axisOrder =>
      $composableBuilder(column: $table.axisOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MatrixAxesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatrixAxesTable,
          MatrixAxis,
          $$MatrixAxesTableFilterComposer,
          $$MatrixAxesTableOrderingComposer,
          $$MatrixAxesTableAnnotationComposer,
          $$MatrixAxesTableCreateCompanionBuilder,
          $$MatrixAxesTableUpdateCompanionBuilder,
          (
            MatrixAxis,
            BaseReferences<_$AppDatabase, $MatrixAxesTable, MatrixAxis>,
          ),
          MatrixAxis,
          PrefetchHooks Function()
        > {
  $$MatrixAxesTableTableManager(_$AppDatabase db, $MatrixAxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatrixAxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatrixAxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatrixAxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> matrixAxisId = const Value.absent(),
                Value<String> matrixRunId = const Value.absent(),
                Value<AxisType> axisType = const Value.absent(),
                Value<String> axisName = const Value.absent(),
                Value<int> axisOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixAxesCompanion(
                matrixAxisId: matrixAxisId,
                matrixRunId: matrixRunId,
                axisType: axisType,
                axisName: axisName,
                axisOrder: axisOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matrixAxisId,
                required String matrixRunId,
                required AxisType axisType,
                required String axisName,
                required int axisOrder,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixAxesCompanion.insert(
                matrixAxisId: matrixAxisId,
                matrixRunId: matrixRunId,
                axisType: axisType,
                axisName: axisName,
                axisOrder: axisOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatrixAxesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatrixAxesTable,
      MatrixAxis,
      $$MatrixAxesTableFilterComposer,
      $$MatrixAxesTableOrderingComposer,
      $$MatrixAxesTableAnnotationComposer,
      $$MatrixAxesTableCreateCompanionBuilder,
      $$MatrixAxesTableUpdateCompanionBuilder,
      (MatrixAxis, BaseReferences<_$AppDatabase, $MatrixAxesTable, MatrixAxis>),
      MatrixAxis,
      PrefetchHooks Function()
    >;
typedef $$MatrixAxisValuesTableCreateCompanionBuilder =
    MatrixAxisValuesCompanion Function({
      required String axisValueId,
      required String matrixAxisId,
      required String label,
      required int sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MatrixAxisValuesTableUpdateCompanionBuilder =
    MatrixAxisValuesCompanion Function({
      Value<String> axisValueId,
      Value<String> matrixAxisId,
      Value<String> label,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MatrixAxisValuesTableFilterComposer
    extends Composer<_$AppDatabase, $MatrixAxisValuesTable> {
  $$MatrixAxisValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get axisValueId => $composableBuilder(
    column: $table.axisValueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matrixAxisId => $composableBuilder(
    column: $table.matrixAxisId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatrixAxisValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $MatrixAxisValuesTable> {
  $$MatrixAxisValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get axisValueId => $composableBuilder(
    column: $table.axisValueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixAxisId => $composableBuilder(
    column: $table.matrixAxisId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatrixAxisValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatrixAxisValuesTable> {
  $$MatrixAxisValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get axisValueId => $composableBuilder(
    column: $table.axisValueId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matrixAxisId => $composableBuilder(
    column: $table.matrixAxisId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MatrixAxisValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatrixAxisValuesTable,
          MatrixAxisValue,
          $$MatrixAxisValuesTableFilterComposer,
          $$MatrixAxisValuesTableOrderingComposer,
          $$MatrixAxisValuesTableAnnotationComposer,
          $$MatrixAxisValuesTableCreateCompanionBuilder,
          $$MatrixAxisValuesTableUpdateCompanionBuilder,
          (
            MatrixAxisValue,
            BaseReferences<
              _$AppDatabase,
              $MatrixAxisValuesTable,
              MatrixAxisValue
            >,
          ),
          MatrixAxisValue,
          PrefetchHooks Function()
        > {
  $$MatrixAxisValuesTableTableManager(
    _$AppDatabase db,
    $MatrixAxisValuesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatrixAxisValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatrixAxisValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatrixAxisValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> axisValueId = const Value.absent(),
                Value<String> matrixAxisId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixAxisValuesCompanion(
                axisValueId: axisValueId,
                matrixAxisId: matrixAxisId,
                label: label,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String axisValueId,
                required String matrixAxisId,
                required String label,
                required int sortOrder,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixAxisValuesCompanion.insert(
                axisValueId: axisValueId,
                matrixAxisId: matrixAxisId,
                label: label,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatrixAxisValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatrixAxisValuesTable,
      MatrixAxisValue,
      $$MatrixAxisValuesTableFilterComposer,
      $$MatrixAxisValuesTableOrderingComposer,
      $$MatrixAxisValuesTableAnnotationComposer,
      $$MatrixAxisValuesTableCreateCompanionBuilder,
      $$MatrixAxisValuesTableUpdateCompanionBuilder,
      (
        MatrixAxisValue,
        BaseReferences<_$AppDatabase, $MatrixAxisValuesTable, MatrixAxisValue>,
      ),
      MatrixAxisValue,
      PrefetchHooks Function()
    >;
typedef $$MatrixCellsTableCreateCompanionBuilder =
    MatrixCellsCompanion Function({
      required String matrixCellId,
      required String matrixRunId,
      Value<String> axisValueIds,
      Value<bool> excludedFromRun,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MatrixCellsTableUpdateCompanionBuilder =
    MatrixCellsCompanion Function({
      Value<String> matrixCellId,
      Value<String> matrixRunId,
      Value<String> axisValueIds,
      Value<bool> excludedFromRun,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MatrixCellsTableFilterComposer
    extends Composer<_$AppDatabase, $MatrixCellsTable> {
  $$MatrixCellsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matrixCellId => $composableBuilder(
    column: $table.matrixCellId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get axisValueIds => $composableBuilder(
    column: $table.axisValueIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludedFromRun => $composableBuilder(
    column: $table.excludedFromRun,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatrixCellsTableOrderingComposer
    extends Composer<_$AppDatabase, $MatrixCellsTable> {
  $$MatrixCellsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matrixCellId => $composableBuilder(
    column: $table.matrixCellId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get axisValueIds => $composableBuilder(
    column: $table.axisValueIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludedFromRun => $composableBuilder(
    column: $table.excludedFromRun,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatrixCellsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatrixCellsTable> {
  $$MatrixCellsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matrixCellId => $composableBuilder(
    column: $table.matrixCellId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get axisValueIds => $composableBuilder(
    column: $table.axisValueIds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get excludedFromRun => $composableBuilder(
    column: $table.excludedFromRun,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MatrixCellsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatrixCellsTable,
          MatrixCell,
          $$MatrixCellsTableFilterComposer,
          $$MatrixCellsTableOrderingComposer,
          $$MatrixCellsTableAnnotationComposer,
          $$MatrixCellsTableCreateCompanionBuilder,
          $$MatrixCellsTableUpdateCompanionBuilder,
          (
            MatrixCell,
            BaseReferences<_$AppDatabase, $MatrixCellsTable, MatrixCell>,
          ),
          MatrixCell,
          PrefetchHooks Function()
        > {
  $$MatrixCellsTableTableManager(_$AppDatabase db, $MatrixCellsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatrixCellsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatrixCellsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatrixCellsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> matrixCellId = const Value.absent(),
                Value<String> matrixRunId = const Value.absent(),
                Value<String> axisValueIds = const Value.absent(),
                Value<bool> excludedFromRun = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixCellsCompanion(
                matrixCellId: matrixCellId,
                matrixRunId: matrixRunId,
                axisValueIds: axisValueIds,
                excludedFromRun: excludedFromRun,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matrixCellId,
                required String matrixRunId,
                Value<String> axisValueIds = const Value.absent(),
                Value<bool> excludedFromRun = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixCellsCompanion.insert(
                matrixCellId: matrixCellId,
                matrixRunId: matrixRunId,
                axisValueIds: axisValueIds,
                excludedFromRun: excludedFromRun,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatrixCellsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatrixCellsTable,
      MatrixCell,
      $$MatrixCellsTableFilterComposer,
      $$MatrixCellsTableOrderingComposer,
      $$MatrixCellsTableAnnotationComposer,
      $$MatrixCellsTableCreateCompanionBuilder,
      $$MatrixCellsTableUpdateCompanionBuilder,
      (
        MatrixCell,
        BaseReferences<_$AppDatabase, $MatrixCellsTable, MatrixCell>,
      ),
      MatrixCell,
      PrefetchHooks Function()
    >;
typedef $$MatrixAttemptsTableCreateCompanionBuilder =
    MatrixAttemptsCompanion Function({
      required String matrixAttemptId,
      required String matrixCellId,
      Value<DateTime> attemptTimestamp,
      Value<double?> carryDistanceMeters,
      Value<double?> totalDistanceMeters,
      Value<double?> leftDeviationMeters,
      Value<double?> rightDeviationMeters,
      Value<double?> rolloutDistanceMeters,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MatrixAttemptsTableUpdateCompanionBuilder =
    MatrixAttemptsCompanion Function({
      Value<String> matrixAttemptId,
      Value<String> matrixCellId,
      Value<DateTime> attemptTimestamp,
      Value<double?> carryDistanceMeters,
      Value<double?> totalDistanceMeters,
      Value<double?> leftDeviationMeters,
      Value<double?> rightDeviationMeters,
      Value<double?> rolloutDistanceMeters,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MatrixAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $MatrixAttemptsTable> {
  $$MatrixAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matrixAttemptId => $composableBuilder(
    column: $table.matrixAttemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matrixCellId => $composableBuilder(
    column: $table.matrixCellId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get attemptTimestamp => $composableBuilder(
    column: $table.attemptTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carryDistanceMeters => $composableBuilder(
    column: $table.carryDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get leftDeviationMeters => $composableBuilder(
    column: $table.leftDeviationMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rightDeviationMeters => $composableBuilder(
    column: $table.rightDeviationMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rolloutDistanceMeters => $composableBuilder(
    column: $table.rolloutDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatrixAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $MatrixAttemptsTable> {
  $$MatrixAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matrixAttemptId => $composableBuilder(
    column: $table.matrixAttemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixCellId => $composableBuilder(
    column: $table.matrixCellId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get attemptTimestamp => $composableBuilder(
    column: $table.attemptTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carryDistanceMeters => $composableBuilder(
    column: $table.carryDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get leftDeviationMeters => $composableBuilder(
    column: $table.leftDeviationMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rightDeviationMeters => $composableBuilder(
    column: $table.rightDeviationMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rolloutDistanceMeters => $composableBuilder(
    column: $table.rolloutDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatrixAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatrixAttemptsTable> {
  $$MatrixAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matrixAttemptId => $composableBuilder(
    column: $table.matrixAttemptId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matrixCellId => $composableBuilder(
    column: $table.matrixCellId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get attemptTimestamp => $composableBuilder(
    column: $table.attemptTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<double> get carryDistanceMeters => $composableBuilder(
    column: $table.carryDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get leftDeviationMeters => $composableBuilder(
    column: $table.leftDeviationMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rightDeviationMeters => $composableBuilder(
    column: $table.rightDeviationMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rolloutDistanceMeters => $composableBuilder(
    column: $table.rolloutDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MatrixAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatrixAttemptsTable,
          MatrixAttempt,
          $$MatrixAttemptsTableFilterComposer,
          $$MatrixAttemptsTableOrderingComposer,
          $$MatrixAttemptsTableAnnotationComposer,
          $$MatrixAttemptsTableCreateCompanionBuilder,
          $$MatrixAttemptsTableUpdateCompanionBuilder,
          (
            MatrixAttempt,
            BaseReferences<_$AppDatabase, $MatrixAttemptsTable, MatrixAttempt>,
          ),
          MatrixAttempt,
          PrefetchHooks Function()
        > {
  $$MatrixAttemptsTableTableManager(
    _$AppDatabase db,
    $MatrixAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatrixAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatrixAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatrixAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> matrixAttemptId = const Value.absent(),
                Value<String> matrixCellId = const Value.absent(),
                Value<DateTime> attemptTimestamp = const Value.absent(),
                Value<double?> carryDistanceMeters = const Value.absent(),
                Value<double?> totalDistanceMeters = const Value.absent(),
                Value<double?> leftDeviationMeters = const Value.absent(),
                Value<double?> rightDeviationMeters = const Value.absent(),
                Value<double?> rolloutDistanceMeters = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixAttemptsCompanion(
                matrixAttemptId: matrixAttemptId,
                matrixCellId: matrixCellId,
                attemptTimestamp: attemptTimestamp,
                carryDistanceMeters: carryDistanceMeters,
                totalDistanceMeters: totalDistanceMeters,
                leftDeviationMeters: leftDeviationMeters,
                rightDeviationMeters: rightDeviationMeters,
                rolloutDistanceMeters: rolloutDistanceMeters,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String matrixAttemptId,
                required String matrixCellId,
                Value<DateTime> attemptTimestamp = const Value.absent(),
                Value<double?> carryDistanceMeters = const Value.absent(),
                Value<double?> totalDistanceMeters = const Value.absent(),
                Value<double?> leftDeviationMeters = const Value.absent(),
                Value<double?> rightDeviationMeters = const Value.absent(),
                Value<double?> rolloutDistanceMeters = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatrixAttemptsCompanion.insert(
                matrixAttemptId: matrixAttemptId,
                matrixCellId: matrixCellId,
                attemptTimestamp: attemptTimestamp,
                carryDistanceMeters: carryDistanceMeters,
                totalDistanceMeters: totalDistanceMeters,
                leftDeviationMeters: leftDeviationMeters,
                rightDeviationMeters: rightDeviationMeters,
                rolloutDistanceMeters: rolloutDistanceMeters,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatrixAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatrixAttemptsTable,
      MatrixAttempt,
      $$MatrixAttemptsTableFilterComposer,
      $$MatrixAttemptsTableOrderingComposer,
      $$MatrixAttemptsTableAnnotationComposer,
      $$MatrixAttemptsTableCreateCompanionBuilder,
      $$MatrixAttemptsTableUpdateCompanionBuilder,
      (
        MatrixAttempt,
        BaseReferences<_$AppDatabase, $MatrixAttemptsTable, MatrixAttempt>,
      ),
      MatrixAttempt,
      PrefetchHooks Function()
    >;
typedef $$PerformanceSnapshotsTableCreateCompanionBuilder =
    PerformanceSnapshotsCompanion Function({
      required String snapshotId,
      required String userId,
      Value<String?> matrixRunId,
      Value<MatrixType?> matrixType,
      Value<bool> isPrimary,
      Value<String?> label,
      Value<DateTime> snapshotTimestamp,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$PerformanceSnapshotsTableUpdateCompanionBuilder =
    PerformanceSnapshotsCompanion Function({
      Value<String> snapshotId,
      Value<String> userId,
      Value<String?> matrixRunId,
      Value<MatrixType?> matrixType,
      Value<bool> isPrimary,
      Value<String?> label,
      Value<DateTime> snapshotTimestamp,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PerformanceSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $PerformanceSnapshotsTable> {
  $$PerformanceSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MatrixType?, MatrixType, String>
  get matrixType => $composableBuilder(
    column: $table.matrixType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get snapshotTimestamp => $composableBuilder(
    column: $table.snapshotTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PerformanceSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PerformanceSnapshotsTable> {
  $$PerformanceSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixType => $composableBuilder(
    column: $table.matrixType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get snapshotTimestamp => $composableBuilder(
    column: $table.snapshotTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PerformanceSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PerformanceSnapshotsTable> {
  $$PerformanceSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get matrixRunId => $composableBuilder(
    column: $table.matrixRunId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MatrixType?, String> get matrixType =>
      $composableBuilder(
        column: $table.matrixType,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get snapshotTimestamp => $composableBuilder(
    column: $table.snapshotTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PerformanceSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PerformanceSnapshotsTable,
          PerformanceSnapshot,
          $$PerformanceSnapshotsTableFilterComposer,
          $$PerformanceSnapshotsTableOrderingComposer,
          $$PerformanceSnapshotsTableAnnotationComposer,
          $$PerformanceSnapshotsTableCreateCompanionBuilder,
          $$PerformanceSnapshotsTableUpdateCompanionBuilder,
          (
            PerformanceSnapshot,
            BaseReferences<
              _$AppDatabase,
              $PerformanceSnapshotsTable,
              PerformanceSnapshot
            >,
          ),
          PerformanceSnapshot,
          PrefetchHooks Function()
        > {
  $$PerformanceSnapshotsTableTableManager(
    _$AppDatabase db,
    $PerformanceSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PerformanceSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PerformanceSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PerformanceSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> snapshotId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> matrixRunId = const Value.absent(),
                Value<MatrixType?> matrixType = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<DateTime> snapshotTimestamp = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PerformanceSnapshotsCompanion(
                snapshotId: snapshotId,
                userId: userId,
                matrixRunId: matrixRunId,
                matrixType: matrixType,
                isPrimary: isPrimary,
                label: label,
                snapshotTimestamp: snapshotTimestamp,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String snapshotId,
                required String userId,
                Value<String?> matrixRunId = const Value.absent(),
                Value<MatrixType?> matrixType = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<DateTime> snapshotTimestamp = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PerformanceSnapshotsCompanion.insert(
                snapshotId: snapshotId,
                userId: userId,
                matrixRunId: matrixRunId,
                matrixType: matrixType,
                isPrimary: isPrimary,
                label: label,
                snapshotTimestamp: snapshotTimestamp,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PerformanceSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PerformanceSnapshotsTable,
      PerformanceSnapshot,
      $$PerformanceSnapshotsTableFilterComposer,
      $$PerformanceSnapshotsTableOrderingComposer,
      $$PerformanceSnapshotsTableAnnotationComposer,
      $$PerformanceSnapshotsTableCreateCompanionBuilder,
      $$PerformanceSnapshotsTableUpdateCompanionBuilder,
      (
        PerformanceSnapshot,
        BaseReferences<
          _$AppDatabase,
          $PerformanceSnapshotsTable,
          PerformanceSnapshot
        >,
      ),
      PerformanceSnapshot,
      PrefetchHooks Function()
    >;
typedef $$SnapshotClubsTableCreateCompanionBuilder =
    SnapshotClubsCompanion Function({
      required String snapshotClubId,
      required String snapshotId,
      required String clubId,
      Value<double?> carryDistanceMeters,
      Value<double?> totalDistanceMeters,
      Value<double?> dispersionLeftMeters,
      Value<double?> dispersionRightMeters,
      Value<double?> rolloutDistanceMeters,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SnapshotClubsTableUpdateCompanionBuilder =
    SnapshotClubsCompanion Function({
      Value<String> snapshotClubId,
      Value<String> snapshotId,
      Value<String> clubId,
      Value<double?> carryDistanceMeters,
      Value<double?> totalDistanceMeters,
      Value<double?> dispersionLeftMeters,
      Value<double?> dispersionRightMeters,
      Value<double?> rolloutDistanceMeters,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SnapshotClubsTableFilterComposer
    extends Composer<_$AppDatabase, $SnapshotClubsTable> {
  $$SnapshotClubsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get snapshotClubId => $composableBuilder(
    column: $table.snapshotClubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carryDistanceMeters => $composableBuilder(
    column: $table.carryDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dispersionLeftMeters => $composableBuilder(
    column: $table.dispersionLeftMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dispersionRightMeters => $composableBuilder(
    column: $table.dispersionRightMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rolloutDistanceMeters => $composableBuilder(
    column: $table.rolloutDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SnapshotClubsTableOrderingComposer
    extends Composer<_$AppDatabase, $SnapshotClubsTable> {
  $$SnapshotClubsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get snapshotClubId => $composableBuilder(
    column: $table.snapshotClubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubId => $composableBuilder(
    column: $table.clubId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carryDistanceMeters => $composableBuilder(
    column: $table.carryDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dispersionLeftMeters => $composableBuilder(
    column: $table.dispersionLeftMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dispersionRightMeters => $composableBuilder(
    column: $table.dispersionRightMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rolloutDistanceMeters => $composableBuilder(
    column: $table.rolloutDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SnapshotClubsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnapshotClubsTable> {
  $$SnapshotClubsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get snapshotClubId => $composableBuilder(
    column: $table.snapshotClubId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clubId =>
      $composableBuilder(column: $table.clubId, builder: (column) => column);

  GeneratedColumn<double> get carryDistanceMeters => $composableBuilder(
    column: $table.carryDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dispersionLeftMeters => $composableBuilder(
    column: $table.dispersionLeftMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dispersionRightMeters => $composableBuilder(
    column: $table.dispersionRightMeters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rolloutDistanceMeters => $composableBuilder(
    column: $table.rolloutDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SnapshotClubsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SnapshotClubsTable,
          SnapshotClub,
          $$SnapshotClubsTableFilterComposer,
          $$SnapshotClubsTableOrderingComposer,
          $$SnapshotClubsTableAnnotationComposer,
          $$SnapshotClubsTableCreateCompanionBuilder,
          $$SnapshotClubsTableUpdateCompanionBuilder,
          (
            SnapshotClub,
            BaseReferences<_$AppDatabase, $SnapshotClubsTable, SnapshotClub>,
          ),
          SnapshotClub,
          PrefetchHooks Function()
        > {
  $$SnapshotClubsTableTableManager(_$AppDatabase db, $SnapshotClubsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotClubsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotClubsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotClubsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> snapshotClubId = const Value.absent(),
                Value<String> snapshotId = const Value.absent(),
                Value<String> clubId = const Value.absent(),
                Value<double?> carryDistanceMeters = const Value.absent(),
                Value<double?> totalDistanceMeters = const Value.absent(),
                Value<double?> dispersionLeftMeters = const Value.absent(),
                Value<double?> dispersionRightMeters = const Value.absent(),
                Value<double?> rolloutDistanceMeters = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotClubsCompanion(
                snapshotClubId: snapshotClubId,
                snapshotId: snapshotId,
                clubId: clubId,
                carryDistanceMeters: carryDistanceMeters,
                totalDistanceMeters: totalDistanceMeters,
                dispersionLeftMeters: dispersionLeftMeters,
                dispersionRightMeters: dispersionRightMeters,
                rolloutDistanceMeters: rolloutDistanceMeters,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String snapshotClubId,
                required String snapshotId,
                required String clubId,
                Value<double?> carryDistanceMeters = const Value.absent(),
                Value<double?> totalDistanceMeters = const Value.absent(),
                Value<double?> dispersionLeftMeters = const Value.absent(),
                Value<double?> dispersionRightMeters = const Value.absent(),
                Value<double?> rolloutDistanceMeters = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotClubsCompanion.insert(
                snapshotClubId: snapshotClubId,
                snapshotId: snapshotId,
                clubId: clubId,
                carryDistanceMeters: carryDistanceMeters,
                totalDistanceMeters: totalDistanceMeters,
                dispersionLeftMeters: dispersionLeftMeters,
                dispersionRightMeters: dispersionRightMeters,
                rolloutDistanceMeters: rolloutDistanceMeters,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SnapshotClubsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SnapshotClubsTable,
      SnapshotClub,
      $$SnapshotClubsTableFilterComposer,
      $$SnapshotClubsTableOrderingComposer,
      $$SnapshotClubsTableAnnotationComposer,
      $$SnapshotClubsTableCreateCompanionBuilder,
      $$SnapshotClubsTableUpdateCompanionBuilder,
      (
        SnapshotClub,
        BaseReferences<_$AppDatabase, $SnapshotClubsTable, SnapshotClub>,
      ),
      SnapshotClub,
      PrefetchHooks Function()
    >;
typedef $$SyncMetadataEntriesTableCreateCompanionBuilder =
    SyncMetadataEntriesCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SyncMetadataEntriesTableUpdateCompanionBuilder =
    SyncMetadataEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SyncMetadataEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetadataEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetadataEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetadataEntriesTable> {
  $$SyncMetadataEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncMetadataEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetadataEntriesTable,
          SyncMetadataEntry,
          $$SyncMetadataEntriesTableFilterComposer,
          $$SyncMetadataEntriesTableOrderingComposer,
          $$SyncMetadataEntriesTableAnnotationComposer,
          $$SyncMetadataEntriesTableCreateCompanionBuilder,
          $$SyncMetadataEntriesTableUpdateCompanionBuilder,
          (
            SyncMetadataEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncMetadataEntriesTable,
              SyncMetadataEntry
            >,
          ),
          SyncMetadataEntry,
          PrefetchHooks Function()
        > {
  $$SyncMetadataEntriesTableTableManager(
    _$AppDatabase db,
    $SyncMetadataEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetadataEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetadataEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncMetadataEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataEntriesCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetadataEntriesCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetadataEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetadataEntriesTable,
      SyncMetadataEntry,
      $$SyncMetadataEntriesTableFilterComposer,
      $$SyncMetadataEntriesTableOrderingComposer,
      $$SyncMetadataEntriesTableAnnotationComposer,
      $$SyncMetadataEntriesTableCreateCompanionBuilder,
      $$SyncMetadataEntriesTableUpdateCompanionBuilder,
      (
        SyncMetadataEntry,
        BaseReferences<
          _$AppDatabase,
          $SyncMetadataEntriesTable,
          SyncMetadataEntry
        >,
      ),
      SyncMetadataEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventTypeRefsTableTableManager get eventTypeRefs =>
      $$EventTypeRefsTableTableManager(_db, _db.eventTypeRefs);
  $$MetricSchemasTableTableManager get metricSchemas =>
      $$MetricSchemasTableTableManager(_db, _db.metricSchemas);
  $$SubskillRefsTableTableManager get subskillRefs =>
      $$SubskillRefsTableTableManager(_db, _db.subskillRefs);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$DrillsTableTableManager get drills =>
      $$DrillsTableTableManager(_db, _db.drills);
  $$PracticeBlocksTableTableManager get practiceBlocks =>
      $$PracticeBlocksTableTableManager(_db, _db.practiceBlocks);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SetsTableTableManager get sets => $$SetsTableTableManager(_db, _db.sets);
  $$InstancesTableTableManager get instances =>
      $$InstancesTableTableManager(_db, _db.instances);
  $$PracticeEntriesTableTableManager get practiceEntries =>
      $$PracticeEntriesTableTableManager(_db, _db.practiceEntries);
  $$UserDrillAdoptionsTableTableManager get userDrillAdoptions =>
      $$UserDrillAdoptionsTableTableManager(_db, _db.userDrillAdoptions);
  $$UserClubsTableTableManager get userClubs =>
      $$UserClubsTableTableManager(_db, _db.userClubs);
  $$ClubPerformanceProfilesTableTableManager get clubPerformanceProfiles =>
      $$ClubPerformanceProfilesTableTableManager(
        _db,
        _db.clubPerformanceProfiles,
      );
  $$UserSkillAreaClubMappingsTableTableManager get userSkillAreaClubMappings =>
      $$UserSkillAreaClubMappingsTableTableManager(
        _db,
        _db.userSkillAreaClubMappings,
      );
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$SchedulesTableTableManager get schedules =>
      $$SchedulesTableTableManager(_db, _db.schedules);
  $$CalendarDaysTableTableManager get calendarDays =>
      $$CalendarDaysTableTableManager(_db, _db.calendarDays);
  $$RoutineInstancesTableTableManager get routineInstances =>
      $$RoutineInstancesTableTableManager(_db, _db.routineInstances);
  $$ScheduleInstancesTableTableManager get scheduleInstances =>
      $$ScheduleInstancesTableTableManager(_db, _db.scheduleInstances);
  $$MaterialisedWindowStatesTableTableManager get materialisedWindowStates =>
      $$MaterialisedWindowStatesTableTableManager(
        _db,
        _db.materialisedWindowStates,
      );
  $$MaterialisedSubskillScoresTableTableManager
  get materialisedSubskillScores =>
      $$MaterialisedSubskillScoresTableTableManager(
        _db,
        _db.materialisedSubskillScores,
      );
  $$MaterialisedSkillAreaScoresTableTableManager
  get materialisedSkillAreaScores =>
      $$MaterialisedSkillAreaScoresTableTableManager(
        _db,
        _db.materialisedSkillAreaScores,
      );
  $$MaterialisedOverallScoresTableTableManager get materialisedOverallScores =>
      $$MaterialisedOverallScoresTableTableManager(
        _db,
        _db.materialisedOverallScores,
      );
  $$EventLogsTableTableManager get eventLogs =>
      $$EventLogsTableTableManager(_db, _db.eventLogs);
  $$UserDevicesTableTableManager get userDevices =>
      $$UserDevicesTableTableManager(_db, _db.userDevices);
  $$UserScoringLocksTableTableManager get userScoringLocks =>
      $$UserScoringLocksTableTableManager(_db, _db.userScoringLocks);
  $$MatrixRunsTableTableManager get matrixRuns =>
      $$MatrixRunsTableTableManager(_db, _db.matrixRuns);
  $$MatrixAxesTableTableManager get matrixAxes =>
      $$MatrixAxesTableTableManager(_db, _db.matrixAxes);
  $$MatrixAxisValuesTableTableManager get matrixAxisValues =>
      $$MatrixAxisValuesTableTableManager(_db, _db.matrixAxisValues);
  $$MatrixCellsTableTableManager get matrixCells =>
      $$MatrixCellsTableTableManager(_db, _db.matrixCells);
  $$MatrixAttemptsTableTableManager get matrixAttempts =>
      $$MatrixAttemptsTableTableManager(_db, _db.matrixAttempts);
  $$PerformanceSnapshotsTableTableManager get performanceSnapshots =>
      $$PerformanceSnapshotsTableTableManager(_db, _db.performanceSnapshots);
  $$SnapshotClubsTableTableManager get snapshotClubs =>
      $$SnapshotClubsTableTableManager(_db, _db.snapshotClubs);
  $$SyncMetadataEntriesTableTableManager get syncMetadataEntries =>
      $$SyncMetadataEntriesTableTableManager(_db, _db.syncMetadataEntries);
}
