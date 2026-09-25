// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journey_database.dart';

// ignore_for_file: type=lint
class $JourneySessionsTable extends JourneySessions
    with TableInfo<$JourneySessionsTable, JourneySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastChangedAtMeta = const VerificationMeta(
    'lastChangedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastChangedAt =
      GeneratedColumn<DateTime>(
        'last_changed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pausedAtMeta = const VerificationMeta(
    'pausedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
    'paused_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segmentNumberMeta = const VerificationMeta(
    'segmentNumber',
  );
  @override
  late final GeneratedColumn<int> segmentNumber = GeneratedColumn<int>(
    'segment_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    phase,
    startedAt,
    lastChangedAt,
    pausedAt,
    endedAt,
    segmentNumber,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneySession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    } else if (isInserting) {
      context.missing(_phaseMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('last_changed_at')) {
      context.handle(
        _lastChangedAtMeta,
        lastChangedAt.isAcceptableOrUnknown(
          data['last_changed_at']!,
          _lastChangedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastChangedAtMeta);
    }
    if (data.containsKey('paused_at')) {
      context.handle(
        _pausedAtMeta,
        pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('segment_number')) {
      context.handle(
        _segmentNumberMeta,
        segmentNumber.isAcceptableOrUnknown(
          data['segment_number']!,
          _segmentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_segmentNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JourneySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneySession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      lastChangedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_changed_at'],
      )!,
      pausedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paused_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      segmentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_number'],
      )!,
    );
  }

  @override
  $JourneySessionsTable createAlias(String alias) {
    return $JourneySessionsTable(attachedDatabase, alias);
  }
}

class JourneySession extends DataClass implements Insertable<JourneySession> {
  final String id;
  final String userId;
  final String phase;
  final DateTime startedAt;
  final DateTime lastChangedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final int segmentNumber;
  const JourneySession({
    required this.id,
    required this.userId,
    required this.phase,
    required this.startedAt,
    required this.lastChangedAt,
    this.pausedAt,
    this.endedAt,
    required this.segmentNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['phase'] = Variable<String>(phase);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['last_changed_at'] = Variable<DateTime>(lastChangedAt);
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['segment_number'] = Variable<int>(segmentNumber);
    return map;
  }

  JourneySessionsCompanion toCompanion(bool nullToAbsent) {
    return JourneySessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      phase: Value(phase),
      startedAt: Value(startedAt),
      lastChangedAt: Value(lastChangedAt),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      segmentNumber: Value(segmentNumber),
    );
  }

  factory JourneySession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneySession(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      phase: serializer.fromJson<String>(json['phase']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      lastChangedAt: serializer.fromJson<DateTime>(json['lastChangedAt']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      segmentNumber: serializer.fromJson<int>(json['segmentNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'phase': serializer.toJson<String>(phase),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'lastChangedAt': serializer.toJson<DateTime>(lastChangedAt),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'segmentNumber': serializer.toJson<int>(segmentNumber),
    };
  }

  JourneySession copyWith({
    String? id,
    String? userId,
    String? phase,
    DateTime? startedAt,
    DateTime? lastChangedAt,
    Value<DateTime?> pausedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    int? segmentNumber,
  }) => JourneySession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    phase: phase ?? this.phase,
    startedAt: startedAt ?? this.startedAt,
    lastChangedAt: lastChangedAt ?? this.lastChangedAt,
    pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    segmentNumber: segmentNumber ?? this.segmentNumber,
  );
  JourneySession copyWithCompanion(JourneySessionsCompanion data) {
    return JourneySession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      phase: data.phase.present ? data.phase.value : this.phase,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastChangedAt: data.lastChangedAt.present
          ? data.lastChangedAt.value
          : this.lastChangedAt,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      segmentNumber: data.segmentNumber.present
          ? data.segmentNumber.value
          : this.segmentNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneySession(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('phase: $phase, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastChangedAt: $lastChangedAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('segmentNumber: $segmentNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    phase,
    startedAt,
    lastChangedAt,
    pausedAt,
    endedAt,
    segmentNumber,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneySession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.phase == this.phase &&
          other.startedAt == this.startedAt &&
          other.lastChangedAt == this.lastChangedAt &&
          other.pausedAt == this.pausedAt &&
          other.endedAt == this.endedAt &&
          other.segmentNumber == this.segmentNumber);
}

class JourneySessionsCompanion extends UpdateCompanion<JourneySession> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> phase;
  final Value<DateTime> startedAt;
  final Value<DateTime> lastChangedAt;
  final Value<DateTime?> pausedAt;
  final Value<DateTime?> endedAt;
  final Value<int> segmentNumber;
  final Value<int> rowid;
  const JourneySessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.phase = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastChangedAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.segmentNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneySessionsCompanion.insert({
    required String id,
    required String userId,
    required String phase,
    required DateTime startedAt,
    required DateTime lastChangedAt,
    this.pausedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    required int segmentNumber,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       phase = Value(phase),
       startedAt = Value(startedAt),
       lastChangedAt = Value(lastChangedAt),
       segmentNumber = Value(segmentNumber);
  static Insertable<JourneySession> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? phase,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? lastChangedAt,
    Expression<DateTime>? pausedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? segmentNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (phase != null) 'phase': phase,
      if (startedAt != null) 'started_at': startedAt,
      if (lastChangedAt != null) 'last_changed_at': lastChangedAt,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (segmentNumber != null) 'segment_number': segmentNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneySessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? phase,
    Value<DateTime>? startedAt,
    Value<DateTime>? lastChangedAt,
    Value<DateTime?>? pausedAt,
    Value<DateTime?>? endedAt,
    Value<int>? segmentNumber,
    Value<int>? rowid,
  }) {
    return JourneySessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phase: phase ?? this.phase,
      startedAt: startedAt ?? this.startedAt,
      lastChangedAt: lastChangedAt ?? this.lastChangedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      endedAt: endedAt ?? this.endedAt,
      segmentNumber: segmentNumber ?? this.segmentNumber,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (lastChangedAt.present) {
      map['last_changed_at'] = Variable<DateTime>(lastChangedAt.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (segmentNumber.present) {
      map['segment_number'] = Variable<int>(segmentNumber.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneySessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('phase: $phase, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastChangedAt: $lastChangedAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('segmentNumber: $segmentNumber, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JourneySamplesTable extends JourneySamples
    with TableInfo<$JourneySamplesTable, JourneySample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JourneySamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _journeyIdMeta = const VerificationMeta(
    'journeyId',
  );
  @override
  late final GeneratedColumn<String> journeyId = GeneratedColumn<String>(
    'journey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceNumberMeta = const VerificationMeta(
    'sequenceNumber',
  );
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
    'sequence_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentNumberMeta = const VerificationMeta(
    'segmentNumber',
  );
  @override
  late final GeneratedColumn<int> segmentNumber = GeneratedColumn<int>(
    'segment_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMetersMeta = const VerificationMeta(
    'accuracyMeters',
  );
  @override
  late final GeneratedColumn<double> accuracyMeters = GeneratedColumn<double>(
    'accuracy_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    journeyId,
    sequenceNumber,
    segmentNumber,
    recordedAt,
    latitude,
    longitude,
    accuracyMeters,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journey_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<JourneySample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('journey_id')) {
      context.handle(
        _journeyIdMeta,
        journeyId.isAcceptableOrUnknown(data['journey_id']!, _journeyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_journeyIdMeta);
    }
    if (data.containsKey('sequence_number')) {
      context.handle(
        _sequenceNumberMeta,
        sequenceNumber.isAcceptableOrUnknown(
          data['sequence_number']!,
          _sequenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumberMeta);
    }
    if (data.containsKey('segment_number')) {
      context.handle(
        _segmentNumberMeta,
        segmentNumber.isAcceptableOrUnknown(
          data['segment_number']!,
          _segmentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_segmentNumberMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy_meters')) {
      context.handle(
        _accuracyMetersMeta,
        accuracyMeters.isAcceptableOrUnknown(
          data['accuracy_meters']!,
          _accuracyMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accuracyMetersMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {journeyId, sequenceNumber};
  @override
  JourneySample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JourneySample(
      journeyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journey_id'],
      )!,
      sequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_number'],
      )!,
      segmentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_number'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracyMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_meters'],
      )!,
    );
  }

  @override
  $JourneySamplesTable createAlias(String alias) {
    return $JourneySamplesTable(attachedDatabase, alias);
  }
}

class JourneySample extends DataClass implements Insertable<JourneySample> {
  final String journeyId;
  final int sequenceNumber;
  final int segmentNumber;
  final DateTime recordedAt;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  const JourneySample({
    required this.journeyId,
    required this.sequenceNumber,
    required this.segmentNumber,
    required this.recordedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['journey_id'] = Variable<String>(journeyId);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    map['segment_number'] = Variable<int>(segmentNumber);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['accuracy_meters'] = Variable<double>(accuracyMeters);
    return map;
  }

  JourneySamplesCompanion toCompanion(bool nullToAbsent) {
    return JourneySamplesCompanion(
      journeyId: Value(journeyId),
      sequenceNumber: Value(sequenceNumber),
      segmentNumber: Value(segmentNumber),
      recordedAt: Value(recordedAt),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracyMeters: Value(accuracyMeters),
    );
  }

  factory JourneySample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JourneySample(
      journeyId: serializer.fromJson<String>(json['journeyId']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      segmentNumber: serializer.fromJson<int>(json['segmentNumber']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracyMeters: serializer.fromJson<double>(json['accuracyMeters']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'journeyId': serializer.toJson<String>(journeyId),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'segmentNumber': serializer.toJson<int>(segmentNumber),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracyMeters': serializer.toJson<double>(accuracyMeters),
    };
  }

  JourneySample copyWith({
    String? journeyId,
    int? sequenceNumber,
    int? segmentNumber,
    DateTime? recordedAt,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
  }) => JourneySample(
    journeyId: journeyId ?? this.journeyId,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    segmentNumber: segmentNumber ?? this.segmentNumber,
    recordedAt: recordedAt ?? this.recordedAt,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracyMeters: accuracyMeters ?? this.accuracyMeters,
  );
  JourneySample copyWithCompanion(JourneySamplesCompanion data) {
    return JourneySample(
      journeyId: data.journeyId.present ? data.journeyId.value : this.journeyId,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      segmentNumber: data.segmentNumber.present
          ? data.segmentNumber.value
          : this.segmentNumber,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracyMeters: data.accuracyMeters.present
          ? data.accuracyMeters.value
          : this.accuracyMeters,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JourneySample(')
          ..write('journeyId: $journeyId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('segmentNumber: $segmentNumber, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyMeters: $accuracyMeters')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    journeyId,
    sequenceNumber,
    segmentNumber,
    recordedAt,
    latitude,
    longitude,
    accuracyMeters,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneySample &&
          other.journeyId == this.journeyId &&
          other.sequenceNumber == this.sequenceNumber &&
          other.segmentNumber == this.segmentNumber &&
          other.recordedAt == this.recordedAt &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracyMeters == this.accuracyMeters);
}

class JourneySamplesCompanion extends UpdateCompanion<JourneySample> {
  final Value<String> journeyId;
  final Value<int> sequenceNumber;
  final Value<int> segmentNumber;
  final Value<DateTime> recordedAt;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> accuracyMeters;
  final Value<int> rowid;
  const JourneySamplesCompanion({
    this.journeyId = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.segmentNumber = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneySamplesCompanion.insert({
    required String journeyId,
    required int sequenceNumber,
    required int segmentNumber,
    required DateTime recordedAt,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    this.rowid = const Value.absent(),
  }) : journeyId = Value(journeyId),
       sequenceNumber = Value(sequenceNumber),
       segmentNumber = Value(segmentNumber),
       recordedAt = Value(recordedAt),
       latitude = Value(latitude),
       longitude = Value(longitude),
       accuracyMeters = Value(accuracyMeters);
  static Insertable<JourneySample> custom({
    Expression<String>? journeyId,
    Expression<int>? sequenceNumber,
    Expression<int>? segmentNumber,
    Expression<DateTime>? recordedAt,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracyMeters,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (journeyId != null) 'journey_id': journeyId,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (segmentNumber != null) 'segment_number': segmentNumber,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneySamplesCompanion copyWith({
    Value<String>? journeyId,
    Value<int>? sequenceNumber,
    Value<int>? segmentNumber,
    Value<DateTime>? recordedAt,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? accuracyMeters,
    Value<int>? rowid,
  }) {
    return JourneySamplesCompanion(
      journeyId: journeyId ?? this.journeyId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      segmentNumber: segmentNumber ?? this.segmentNumber,
      recordedAt: recordedAt ?? this.recordedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (journeyId.present) {
      map['journey_id'] = Variable<String>(journeyId.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (segmentNumber.present) {
      map['segment_number'] = Variable<int>(segmentNumber.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracyMeters.present) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JourneySamplesCompanion(')
          ..write('journeyId: $journeyId, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('segmentNumber: $segmentNumber, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$JourneyDatabase extends GeneratedDatabase {
  _$JourneyDatabase(QueryExecutor e) : super(e);
  $JourneyDatabaseManager get managers => $JourneyDatabaseManager(this);
  late final $JourneySessionsTable journeySessions = $JourneySessionsTable(
    this,
  );
  late final $JourneySamplesTable journeySamples = $JourneySamplesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    journeySessions,
    journeySamples,
  ];
}

typedef $$JourneySessionsTableCreateCompanionBuilder =
    JourneySessionsCompanion Function({
      required String id,
      required String userId,
      required String phase,
      required DateTime startedAt,
      required DateTime lastChangedAt,
      Value<DateTime?> pausedAt,
      Value<DateTime?> endedAt,
      required int segmentNumber,
      Value<int> rowid,
    });
typedef $$JourneySessionsTableUpdateCompanionBuilder =
    JourneySessionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> phase,
      Value<DateTime> startedAt,
      Value<DateTime> lastChangedAt,
      Value<DateTime?> pausedAt,
      Value<DateTime?> endedAt,
      Value<int> segmentNumber,
      Value<int> rowid,
    });

class $$JourneySessionsTableFilterComposer
    extends Composer<_$JourneyDatabase, $JourneySessionsTable> {
  $$JourneySessionsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastChangedAt => $composableBuilder(
    column: $table.lastChangedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segmentNumber => $composableBuilder(
    column: $table.segmentNumber,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneySessionsTableOrderingComposer
    extends Composer<_$JourneyDatabase, $JourneySessionsTable> {
  $$JourneySessionsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastChangedAt => $composableBuilder(
    column: $table.lastChangedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segmentNumber => $composableBuilder(
    column: $table.segmentNumber,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneySessionsTableAnnotationComposer
    extends Composer<_$JourneyDatabase, $JourneySessionsTable> {
  $$JourneySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastChangedAt => $composableBuilder(
    column: $table.lastChangedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get segmentNumber => $composableBuilder(
    column: $table.segmentNumber,
    builder: (column) => column,
  );
}

class $$JourneySessionsTableTableManager
    extends
        RootTableManager<
          _$JourneyDatabase,
          $JourneySessionsTable,
          JourneySession,
          $$JourneySessionsTableFilterComposer,
          $$JourneySessionsTableOrderingComposer,
          $$JourneySessionsTableAnnotationComposer,
          $$JourneySessionsTableCreateCompanionBuilder,
          $$JourneySessionsTableUpdateCompanionBuilder,
          (
            JourneySession,
            BaseReferences<
              _$JourneyDatabase,
              $JourneySessionsTable,
              JourneySession
            >,
          ),
          JourneySession,
          PrefetchHooks Function()
        > {
  $$JourneySessionsTableTableManager(
    _$JourneyDatabase db,
    $JourneySessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> phase = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> lastChangedAt = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> segmentNumber = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneySessionsCompanion(
                id: id,
                userId: userId,
                phase: phase,
                startedAt: startedAt,
                lastChangedAt: lastChangedAt,
                pausedAt: pausedAt,
                endedAt: endedAt,
                segmentNumber: segmentNumber,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String phase,
                required DateTime startedAt,
                required DateTime lastChangedAt,
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                required int segmentNumber,
                Value<int> rowid = const Value.absent(),
              }) => JourneySessionsCompanion.insert(
                id: id,
                userId: userId,
                phase: phase,
                startedAt: startedAt,
                lastChangedAt: lastChangedAt,
                pausedAt: pausedAt,
                endedAt: endedAt,
                segmentNumber: segmentNumber,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$JourneyDatabase,
      $JourneySessionsTable,
      JourneySession,
      $$JourneySessionsTableFilterComposer,
      $$JourneySessionsTableOrderingComposer,
      $$JourneySessionsTableAnnotationComposer,
      $$JourneySessionsTableCreateCompanionBuilder,
      $$JourneySessionsTableUpdateCompanionBuilder,
      (
        JourneySession,
        BaseReferences<
          _$JourneyDatabase,
          $JourneySessionsTable,
          JourneySession
        >,
      ),
      JourneySession,
      PrefetchHooks Function()
    >;
typedef $$JourneySamplesTableCreateCompanionBuilder =
    JourneySamplesCompanion Function({
      required String journeyId,
      required int sequenceNumber,
      required int segmentNumber,
      required DateTime recordedAt,
      required double latitude,
      required double longitude,
      required double accuracyMeters,
      Value<int> rowid,
    });
typedef $$JourneySamplesTableUpdateCompanionBuilder =
    JourneySamplesCompanion Function({
      Value<String> journeyId,
      Value<int> sequenceNumber,
      Value<int> segmentNumber,
      Value<DateTime> recordedAt,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> accuracyMeters,
      Value<int> rowid,
    });

class $$JourneySamplesTableFilterComposer
    extends Composer<_$JourneyDatabase, $JourneySamplesTable> {
  $$JourneySamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segmentNumber => $composableBuilder(
    column: $table.segmentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JourneySamplesTableOrderingComposer
    extends Composer<_$JourneyDatabase, $JourneySamplesTable> {
  $$JourneySamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get journeyId => $composableBuilder(
    column: $table.journeyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segmentNumber => $composableBuilder(
    column: $table.segmentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JourneySamplesTableAnnotationComposer
    extends Composer<_$JourneyDatabase, $JourneySamplesTable> {
  $$JourneySamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get journeyId =>
      $composableBuilder(column: $table.journeyId, builder: (column) => column);

  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segmentNumber => $composableBuilder(
    column: $table.segmentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracyMeters => $composableBuilder(
    column: $table.accuracyMeters,
    builder: (column) => column,
  );
}

class $$JourneySamplesTableTableManager
    extends
        RootTableManager<
          _$JourneyDatabase,
          $JourneySamplesTable,
          JourneySample,
          $$JourneySamplesTableFilterComposer,
          $$JourneySamplesTableOrderingComposer,
          $$JourneySamplesTableAnnotationComposer,
          $$JourneySamplesTableCreateCompanionBuilder,
          $$JourneySamplesTableUpdateCompanionBuilder,
          (
            JourneySample,
            BaseReferences<
              _$JourneyDatabase,
              $JourneySamplesTable,
              JourneySample
            >,
          ),
          JourneySample,
          PrefetchHooks Function()
        > {
  $$JourneySamplesTableTableManager(
    _$JourneyDatabase db,
    $JourneySamplesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JourneySamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JourneySamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JourneySamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> journeyId = const Value.absent(),
                Value<int> sequenceNumber = const Value.absent(),
                Value<int> segmentNumber = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> accuracyMeters = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneySamplesCompanion(
                journeyId: journeyId,
                sequenceNumber: sequenceNumber,
                segmentNumber: segmentNumber,
                recordedAt: recordedAt,
                latitude: latitude,
                longitude: longitude,
                accuracyMeters: accuracyMeters,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String journeyId,
                required int sequenceNumber,
                required int segmentNumber,
                required DateTime recordedAt,
                required double latitude,
                required double longitude,
                required double accuracyMeters,
                Value<int> rowid = const Value.absent(),
              }) => JourneySamplesCompanion.insert(
                journeyId: journeyId,
                sequenceNumber: sequenceNumber,
                segmentNumber: segmentNumber,
                recordedAt: recordedAt,
                latitude: latitude,
                longitude: longitude,
                accuracyMeters: accuracyMeters,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JourneySamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$JourneyDatabase,
      $JourneySamplesTable,
      JourneySample,
      $$JourneySamplesTableFilterComposer,
      $$JourneySamplesTableOrderingComposer,
      $$JourneySamplesTableAnnotationComposer,
      $$JourneySamplesTableCreateCompanionBuilder,
      $$JourneySamplesTableUpdateCompanionBuilder,
      (
        JourneySample,
        BaseReferences<_$JourneyDatabase, $JourneySamplesTable, JourneySample>,
      ),
      JourneySample,
      PrefetchHooks Function()
    >;

class $JourneyDatabaseManager {
  final _$JourneyDatabase _db;
  $JourneyDatabaseManager(this._db);
  $$JourneySessionsTableTableManager get journeySessions =>
      $$JourneySessionsTableTableManager(_db, _db.journeySessions);
  $$JourneySamplesTableTableManager get journeySamples =>
      $$JourneySamplesTableTableManager(_db, _db.journeySamples);
}
