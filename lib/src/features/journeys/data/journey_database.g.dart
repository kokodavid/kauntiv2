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
  static const VerificationMeta _startedAtMillisMeta = const VerificationMeta(
    'startedAtMillis',
  );
  @override
  late final GeneratedColumn<int> startedAtMillis = GeneratedColumn<int>(
    'started_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastChangedAtMillisMeta =
      const VerificationMeta('lastChangedAtMillis');
  @override
  late final GeneratedColumn<int> lastChangedAtMillis = GeneratedColumn<int>(
    'last_changed_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pausedAtMillisMeta = const VerificationMeta(
    'pausedAtMillis',
  );
  @override
  late final GeneratedColumn<int> pausedAtMillis = GeneratedColumn<int>(
    'paused_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMillisMeta = const VerificationMeta(
    'endedAtMillis',
  );
  @override
  late final GeneratedColumn<int> endedAtMillis = GeneratedColumn<int>(
    'ended_at_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    startedAtMillis,
    lastChangedAtMillis,
    pausedAtMillis,
    endedAtMillis,
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
    if (data.containsKey('started_at_millis')) {
      context.handle(
        _startedAtMillisMeta,
        startedAtMillis.isAcceptableOrUnknown(
          data['started_at_millis']!,
          _startedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMillisMeta);
    }
    if (data.containsKey('last_changed_at_millis')) {
      context.handle(
        _lastChangedAtMillisMeta,
        lastChangedAtMillis.isAcceptableOrUnknown(
          data['last_changed_at_millis']!,
          _lastChangedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastChangedAtMillisMeta);
    }
    if (data.containsKey('paused_at_millis')) {
      context.handle(
        _pausedAtMillisMeta,
        pausedAtMillis.isAcceptableOrUnknown(
          data['paused_at_millis']!,
          _pausedAtMillisMeta,
        ),
      );
    }
    if (data.containsKey('ended_at_millis')) {
      context.handle(
        _endedAtMillisMeta,
        endedAtMillis.isAcceptableOrUnknown(
          data['ended_at_millis']!,
          _endedAtMillisMeta,
        ),
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
      startedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_millis'],
      )!,
      lastChangedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_changed_at_millis'],
      )!,
      pausedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_at_millis'],
      ),
      endedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_millis'],
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
  final int startedAtMillis;
  final int lastChangedAtMillis;
  final int? pausedAtMillis;
  final int? endedAtMillis;
  final int segmentNumber;
  const JourneySession({
    required this.id,
    required this.userId,
    required this.phase,
    required this.startedAtMillis,
    required this.lastChangedAtMillis,
    this.pausedAtMillis,
    this.endedAtMillis,
    required this.segmentNumber,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['phase'] = Variable<String>(phase);
    map['started_at_millis'] = Variable<int>(startedAtMillis);
    map['last_changed_at_millis'] = Variable<int>(lastChangedAtMillis);
    if (!nullToAbsent || pausedAtMillis != null) {
      map['paused_at_millis'] = Variable<int>(pausedAtMillis);
    }
    if (!nullToAbsent || endedAtMillis != null) {
      map['ended_at_millis'] = Variable<int>(endedAtMillis);
    }
    map['segment_number'] = Variable<int>(segmentNumber);
    return map;
  }

  JourneySessionsCompanion toCompanion(bool nullToAbsent) {
    return JourneySessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      phase: Value(phase),
      startedAtMillis: Value(startedAtMillis),
      lastChangedAtMillis: Value(lastChangedAtMillis),
      pausedAtMillis: pausedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAtMillis),
      endedAtMillis: endedAtMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMillis),
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
      startedAtMillis: serializer.fromJson<int>(json['startedAtMillis']),
      lastChangedAtMillis: serializer.fromJson<int>(
        json['lastChangedAtMillis'],
      ),
      pausedAtMillis: serializer.fromJson<int?>(json['pausedAtMillis']),
      endedAtMillis: serializer.fromJson<int?>(json['endedAtMillis']),
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
      'startedAtMillis': serializer.toJson<int>(startedAtMillis),
      'lastChangedAtMillis': serializer.toJson<int>(lastChangedAtMillis),
      'pausedAtMillis': serializer.toJson<int?>(pausedAtMillis),
      'endedAtMillis': serializer.toJson<int?>(endedAtMillis),
      'segmentNumber': serializer.toJson<int>(segmentNumber),
    };
  }

  JourneySession copyWith({
    String? id,
    String? userId,
    String? phase,
    int? startedAtMillis,
    int? lastChangedAtMillis,
    Value<int?> pausedAtMillis = const Value.absent(),
    Value<int?> endedAtMillis = const Value.absent(),
    int? segmentNumber,
  }) => JourneySession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    phase: phase ?? this.phase,
    startedAtMillis: startedAtMillis ?? this.startedAtMillis,
    lastChangedAtMillis: lastChangedAtMillis ?? this.lastChangedAtMillis,
    pausedAtMillis: pausedAtMillis.present
        ? pausedAtMillis.value
        : this.pausedAtMillis,
    endedAtMillis: endedAtMillis.present
        ? endedAtMillis.value
        : this.endedAtMillis,
    segmentNumber: segmentNumber ?? this.segmentNumber,
  );
  JourneySession copyWithCompanion(JourneySessionsCompanion data) {
    return JourneySession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      phase: data.phase.present ? data.phase.value : this.phase,
      startedAtMillis: data.startedAtMillis.present
          ? data.startedAtMillis.value
          : this.startedAtMillis,
      lastChangedAtMillis: data.lastChangedAtMillis.present
          ? data.lastChangedAtMillis.value
          : this.lastChangedAtMillis,
      pausedAtMillis: data.pausedAtMillis.present
          ? data.pausedAtMillis.value
          : this.pausedAtMillis,
      endedAtMillis: data.endedAtMillis.present
          ? data.endedAtMillis.value
          : this.endedAtMillis,
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
          ..write('startedAtMillis: $startedAtMillis, ')
          ..write('lastChangedAtMillis: $lastChangedAtMillis, ')
          ..write('pausedAtMillis: $pausedAtMillis, ')
          ..write('endedAtMillis: $endedAtMillis, ')
          ..write('segmentNumber: $segmentNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    phase,
    startedAtMillis,
    lastChangedAtMillis,
    pausedAtMillis,
    endedAtMillis,
    segmentNumber,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JourneySession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.phase == this.phase &&
          other.startedAtMillis == this.startedAtMillis &&
          other.lastChangedAtMillis == this.lastChangedAtMillis &&
          other.pausedAtMillis == this.pausedAtMillis &&
          other.endedAtMillis == this.endedAtMillis &&
          other.segmentNumber == this.segmentNumber);
}

class JourneySessionsCompanion extends UpdateCompanion<JourneySession> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> phase;
  final Value<int> startedAtMillis;
  final Value<int> lastChangedAtMillis;
  final Value<int?> pausedAtMillis;
  final Value<int?> endedAtMillis;
  final Value<int> segmentNumber;
  final Value<int> rowid;
  const JourneySessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.phase = const Value.absent(),
    this.startedAtMillis = const Value.absent(),
    this.lastChangedAtMillis = const Value.absent(),
    this.pausedAtMillis = const Value.absent(),
    this.endedAtMillis = const Value.absent(),
    this.segmentNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneySessionsCompanion.insert({
    required String id,
    required String userId,
    required String phase,
    required int startedAtMillis,
    required int lastChangedAtMillis,
    this.pausedAtMillis = const Value.absent(),
    this.endedAtMillis = const Value.absent(),
    required int segmentNumber,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       phase = Value(phase),
       startedAtMillis = Value(startedAtMillis),
       lastChangedAtMillis = Value(lastChangedAtMillis),
       segmentNumber = Value(segmentNumber);
  static Insertable<JourneySession> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? phase,
    Expression<int>? startedAtMillis,
    Expression<int>? lastChangedAtMillis,
    Expression<int>? pausedAtMillis,
    Expression<int>? endedAtMillis,
    Expression<int>? segmentNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (phase != null) 'phase': phase,
      if (startedAtMillis != null) 'started_at_millis': startedAtMillis,
      if (lastChangedAtMillis != null)
        'last_changed_at_millis': lastChangedAtMillis,
      if (pausedAtMillis != null) 'paused_at_millis': pausedAtMillis,
      if (endedAtMillis != null) 'ended_at_millis': endedAtMillis,
      if (segmentNumber != null) 'segment_number': segmentNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JourneySessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? phase,
    Value<int>? startedAtMillis,
    Value<int>? lastChangedAtMillis,
    Value<int?>? pausedAtMillis,
    Value<int?>? endedAtMillis,
    Value<int>? segmentNumber,
    Value<int>? rowid,
  }) {
    return JourneySessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phase: phase ?? this.phase,
      startedAtMillis: startedAtMillis ?? this.startedAtMillis,
      lastChangedAtMillis: lastChangedAtMillis ?? this.lastChangedAtMillis,
      pausedAtMillis: pausedAtMillis ?? this.pausedAtMillis,
      endedAtMillis: endedAtMillis ?? this.endedAtMillis,
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
    if (startedAtMillis.present) {
      map['started_at_millis'] = Variable<int>(startedAtMillis.value);
    }
    if (lastChangedAtMillis.present) {
      map['last_changed_at_millis'] = Variable<int>(lastChangedAtMillis.value);
    }
    if (pausedAtMillis.present) {
      map['paused_at_millis'] = Variable<int>(pausedAtMillis.value);
    }
    if (endedAtMillis.present) {
      map['ended_at_millis'] = Variable<int>(endedAtMillis.value);
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
          ..write('startedAtMillis: $startedAtMillis, ')
          ..write('lastChangedAtMillis: $lastChangedAtMillis, ')
          ..write('pausedAtMillis: $pausedAtMillis, ')
          ..write('endedAtMillis: $endedAtMillis, ')
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
  static const VerificationMeta _recordedAtMillisMeta = const VerificationMeta(
    'recordedAtMillis',
  );
  @override
  late final GeneratedColumn<int> recordedAtMillis = GeneratedColumn<int>(
    'recorded_at_millis',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    recordedAtMillis,
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
    if (data.containsKey('recorded_at_millis')) {
      context.handle(
        _recordedAtMillisMeta,
        recordedAtMillis.isAcceptableOrUnknown(
          data['recorded_at_millis']!,
          _recordedAtMillisMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMillisMeta);
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
      recordedAtMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at_millis'],
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
  final int recordedAtMillis;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  const JourneySample({
    required this.journeyId,
    required this.sequenceNumber,
    required this.segmentNumber,
    required this.recordedAtMillis,
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
    map['recorded_at_millis'] = Variable<int>(recordedAtMillis);
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
      recordedAtMillis: Value(recordedAtMillis),
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
      recordedAtMillis: serializer.fromJson<int>(json['recordedAtMillis']),
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
      'recordedAtMillis': serializer.toJson<int>(recordedAtMillis),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracyMeters': serializer.toJson<double>(accuracyMeters),
    };
  }

  JourneySample copyWith({
    String? journeyId,
    int? sequenceNumber,
    int? segmentNumber,
    int? recordedAtMillis,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
  }) => JourneySample(
    journeyId: journeyId ?? this.journeyId,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    segmentNumber: segmentNumber ?? this.segmentNumber,
    recordedAtMillis: recordedAtMillis ?? this.recordedAtMillis,
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
      recordedAtMillis: data.recordedAtMillis.present
          ? data.recordedAtMillis.value
          : this.recordedAtMillis,
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
          ..write('recordedAtMillis: $recordedAtMillis, ')
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
    recordedAtMillis,
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
          other.recordedAtMillis == this.recordedAtMillis &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracyMeters == this.accuracyMeters);
}

class JourneySamplesCompanion extends UpdateCompanion<JourneySample> {
  final Value<String> journeyId;
  final Value<int> sequenceNumber;
  final Value<int> segmentNumber;
  final Value<int> recordedAtMillis;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> accuracyMeters;
  final Value<int> rowid;
  const JourneySamplesCompanion({
    this.journeyId = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.segmentNumber = const Value.absent(),
    this.recordedAtMillis = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JourneySamplesCompanion.insert({
    required String journeyId,
    required int sequenceNumber,
    required int segmentNumber,
    required int recordedAtMillis,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    this.rowid = const Value.absent(),
  }) : journeyId = Value(journeyId),
       sequenceNumber = Value(sequenceNumber),
       segmentNumber = Value(segmentNumber),
       recordedAtMillis = Value(recordedAtMillis),
       latitude = Value(latitude),
       longitude = Value(longitude),
       accuracyMeters = Value(accuracyMeters);
  static Insertable<JourneySample> custom({
    Expression<String>? journeyId,
    Expression<int>? sequenceNumber,
    Expression<int>? segmentNumber,
    Expression<int>? recordedAtMillis,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracyMeters,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (journeyId != null) 'journey_id': journeyId,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (segmentNumber != null) 'segment_number': segmentNumber,
      if (recordedAtMillis != null) 'recorded_at_millis': recordedAtMillis,
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
    Value<int>? recordedAtMillis,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? accuracyMeters,
    Value<int>? rowid,
  }) {
    return JourneySamplesCompanion(
      journeyId: journeyId ?? this.journeyId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      segmentNumber: segmentNumber ?? this.segmentNumber,
      recordedAtMillis: recordedAtMillis ?? this.recordedAtMillis,
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
    if (recordedAtMillis.present) {
      map['recorded_at_millis'] = Variable<int>(recordedAtMillis.value);
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
          ..write('recordedAtMillis: $recordedAtMillis, ')
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
      required int startedAtMillis,
      required int lastChangedAtMillis,
      Value<int?> pausedAtMillis,
      Value<int?> endedAtMillis,
      required int segmentNumber,
      Value<int> rowid,
    });
typedef $$JourneySessionsTableUpdateCompanionBuilder =
    JourneySessionsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> phase,
      Value<int> startedAtMillis,
      Value<int> lastChangedAtMillis,
      Value<int?> pausedAtMillis,
      Value<int?> endedAtMillis,
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

  ColumnFilters<int> get startedAtMillis => $composableBuilder(
    column: $table.startedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastChangedAtMillis => $composableBuilder(
    column: $table.lastChangedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedAtMillis => $composableBuilder(
    column: $table.pausedAtMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMillis => $composableBuilder(
    column: $table.endedAtMillis,
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

  ColumnOrderings<int> get startedAtMillis => $composableBuilder(
    column: $table.startedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastChangedAtMillis => $composableBuilder(
    column: $table.lastChangedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedAtMillis => $composableBuilder(
    column: $table.pausedAtMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMillis => $composableBuilder(
    column: $table.endedAtMillis,
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

  GeneratedColumn<int> get startedAtMillis => $composableBuilder(
    column: $table.startedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastChangedAtMillis => $composableBuilder(
    column: $table.lastChangedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedAtMillis => $composableBuilder(
    column: $table.pausedAtMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMillis => $composableBuilder(
    column: $table.endedAtMillis,
    builder: (column) => column,
  );

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
                Value<int> startedAtMillis = const Value.absent(),
                Value<int> lastChangedAtMillis = const Value.absent(),
                Value<int?> pausedAtMillis = const Value.absent(),
                Value<int?> endedAtMillis = const Value.absent(),
                Value<int> segmentNumber = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneySessionsCompanion(
                id: id,
                userId: userId,
                phase: phase,
                startedAtMillis: startedAtMillis,
                lastChangedAtMillis: lastChangedAtMillis,
                pausedAtMillis: pausedAtMillis,
                endedAtMillis: endedAtMillis,
                segmentNumber: segmentNumber,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String phase,
                required int startedAtMillis,
                required int lastChangedAtMillis,
                Value<int?> pausedAtMillis = const Value.absent(),
                Value<int?> endedAtMillis = const Value.absent(),
                required int segmentNumber,
                Value<int> rowid = const Value.absent(),
              }) => JourneySessionsCompanion.insert(
                id: id,
                userId: userId,
                phase: phase,
                startedAtMillis: startedAtMillis,
                lastChangedAtMillis: lastChangedAtMillis,
                pausedAtMillis: pausedAtMillis,
                endedAtMillis: endedAtMillis,
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
      required int recordedAtMillis,
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
      Value<int> recordedAtMillis,
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

  ColumnFilters<int> get recordedAtMillis => $composableBuilder(
    column: $table.recordedAtMillis,
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

  ColumnOrderings<int> get recordedAtMillis => $composableBuilder(
    column: $table.recordedAtMillis,
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

  GeneratedColumn<int> get recordedAtMillis => $composableBuilder(
    column: $table.recordedAtMillis,
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
                Value<int> recordedAtMillis = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> accuracyMeters = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JourneySamplesCompanion(
                journeyId: journeyId,
                sequenceNumber: sequenceNumber,
                segmentNumber: segmentNumber,
                recordedAtMillis: recordedAtMillis,
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
                required int recordedAtMillis,
                required double latitude,
                required double longitude,
                required double accuracyMeters,
                Value<int> rowid = const Value.absent(),
              }) => JourneySamplesCompanion.insert(
                journeyId: journeyId,
                sequenceNumber: sequenceNumber,
                segmentNumber: segmentNumber,
                recordedAtMillis: recordedAtMillis,
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
