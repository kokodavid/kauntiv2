// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_database.dart';

// ignore_for_file: type=lint
class $CandidatesTable extends Candidates
    with TableInfo<$CandidatesTable, Candidate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CandidatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _countyCodeMeta = const VerificationMeta(
    'countyCode',
  );
  @override
  late final GeneratedColumn<int> countyCode = GeneratedColumn<int>(
    'county_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enteredAtMeta = const VerificationMeta(
    'enteredAt',
  );
  @override
  late final GeneratedColumn<DateTime> enteredAt = GeneratedColumn<DateTime>(
    'entered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [countyCode, enteredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'candidates';
  @override
  VerificationContext validateIntegrity(
    Insertable<Candidate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('county_code')) {
      context.handle(
        _countyCodeMeta,
        countyCode.isAcceptableOrUnknown(data['county_code']!, _countyCodeMeta),
      );
    }
    if (data.containsKey('entered_at')) {
      context.handle(
        _enteredAtMeta,
        enteredAt.isAcceptableOrUnknown(data['entered_at']!, _enteredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {countyCode};
  @override
  Candidate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Candidate(
      countyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}county_code'],
      )!,
      enteredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entered_at'],
      )!,
    );
  }

  @override
  $CandidatesTable createAlias(String alias) {
    return $CandidatesTable(attachedDatabase, alias);
  }
}

class Candidate extends DataClass implements Insertable<Candidate> {
  /// One active candidate per county at a time.
  final int countyCode;
  final DateTime enteredAt;
  const Candidate({required this.countyCode, required this.enteredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['county_code'] = Variable<int>(countyCode);
    map['entered_at'] = Variable<DateTime>(enteredAt);
    return map;
  }

  CandidatesCompanion toCompanion(bool nullToAbsent) {
    return CandidatesCompanion(
      countyCode: Value(countyCode),
      enteredAt: Value(enteredAt),
    );
  }

  factory Candidate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Candidate(
      countyCode: serializer.fromJson<int>(json['countyCode']),
      enteredAt: serializer.fromJson<DateTime>(json['enteredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'countyCode': serializer.toJson<int>(countyCode),
      'enteredAt': serializer.toJson<DateTime>(enteredAt),
    };
  }

  Candidate copyWith({int? countyCode, DateTime? enteredAt}) => Candidate(
    countyCode: countyCode ?? this.countyCode,
    enteredAt: enteredAt ?? this.enteredAt,
  );
  Candidate copyWithCompanion(CandidatesCompanion data) {
    return Candidate(
      countyCode: data.countyCode.present
          ? data.countyCode.value
          : this.countyCode,
      enteredAt: data.enteredAt.present ? data.enteredAt.value : this.enteredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Candidate(')
          ..write('countyCode: $countyCode, ')
          ..write('enteredAt: $enteredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(countyCode, enteredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Candidate &&
          other.countyCode == this.countyCode &&
          other.enteredAt == this.enteredAt);
}

class CandidatesCompanion extends UpdateCompanion<Candidate> {
  final Value<int> countyCode;
  final Value<DateTime> enteredAt;
  const CandidatesCompanion({
    this.countyCode = const Value.absent(),
    this.enteredAt = const Value.absent(),
  });
  CandidatesCompanion.insert({
    this.countyCode = const Value.absent(),
    required DateTime enteredAt,
  }) : enteredAt = Value(enteredAt);
  static Insertable<Candidate> custom({
    Expression<int>? countyCode,
    Expression<DateTime>? enteredAt,
  }) {
    return RawValuesInsertable({
      if (countyCode != null) 'county_code': countyCode,
      if (enteredAt != null) 'entered_at': enteredAt,
    });
  }

  CandidatesCompanion copyWith({
    Value<int>? countyCode,
    Value<DateTime>? enteredAt,
  }) {
    return CandidatesCompanion(
      countyCode: countyCode ?? this.countyCode,
      enteredAt: enteredAt ?? this.enteredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (countyCode.present) {
      map['county_code'] = Variable<int>(countyCode.value);
    }
    if (enteredAt.present) {
      map['entered_at'] = Variable<DateTime>(enteredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CandidatesCompanion(')
          ..write('countyCode: $countyCode, ')
          ..write('enteredAt: $enteredAt')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncOpsTable extends PendingSyncOps
    with TableInfo<$PendingSyncOpsTable, PendingSyncOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _countyCodeMeta = const VerificationMeta(
    'countyCode',
  );
  @override
  late final GeneratedColumn<int> countyCode = GeneratedColumn<int>(
    'county_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredAtMeta = const VerificationMeta(
    'enteredAt',
  );
  @override
  late final GeneratedColumn<DateTime> enteredAt = GeneratedColumn<DateTime>(
    'entered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    nextAttemptAt,
    countyCode,
    outcome,
    enteredAt,
    resolvedAt,
    queuedAt,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncOp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('county_code')) {
      context.handle(
        _countyCodeMeta,
        countyCode.isAcceptableOrUnknown(data['county_code']!, _countyCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_countyCodeMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('entered_at')) {
      context.handle(
        _enteredAtMeta,
        enteredAt.isAcceptableOrUnknown(data['entered_at']!, _enteredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_resolvedAtMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncOp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      countyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}county_code'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      enteredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entered_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $PendingSyncOpsTable createAlias(String alias) {
    return $PendingSyncOpsTable(attachedDatabase, alias);
  }
}

class PendingSyncOp extends DataClass implements Insertable<PendingSyncOp> {
  /// `autoIncrement()` already makes this column drift's primary key --
  /// don't also override `primaryKey` below (drift_dev warns: "Tables
  /// can't override primaryKey and use autoIncrement()").
  final int id;
  final String? userId;
  final DateTime? nextAttemptAt;
  final int countyCode;

  /// 'explored' or 'passed_through' -- stored as text (not an enum column)
  /// so it lines up directly with Supabase's own `county_visits.state`
  /// check constraint values.
  final String outcome;
  final DateTime enteredAt;
  final DateTime resolvedAt;
  final DateTime queuedAt;

  /// How many sync attempts have failed so far -- lets the sync loop back
  /// off or surface a persistently-failing op rather than retrying a
  /// broken write forever with no visibility.
  final int attempts;
  const PendingSyncOp({
    required this.id,
    this.userId,
    this.nextAttemptAt,
    required this.countyCode,
    required this.outcome,
    required this.enteredAt,
    required this.resolvedAt,
    required this.queuedAt,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    map['county_code'] = Variable<int>(countyCode);
    map['outcome'] = Variable<String>(outcome);
    map['entered_at'] = Variable<DateTime>(enteredAt);
    map['resolved_at'] = Variable<DateTime>(resolvedAt);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  PendingSyncOpsCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncOpsCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      countyCode: Value(countyCode),
      outcome: Value(outcome),
      enteredAt: Value(enteredAt),
      resolvedAt: Value(resolvedAt),
      queuedAt: Value(queuedAt),
      attempts: Value(attempts),
    );
  }

  factory PendingSyncOp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncOp(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      countyCode: serializer.fromJson<int>(json['countyCode']),
      outcome: serializer.fromJson<String>(json['outcome']),
      enteredAt: serializer.fromJson<DateTime>(json['enteredAt']),
      resolvedAt: serializer.fromJson<DateTime>(json['resolvedAt']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String?>(userId),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'countyCode': serializer.toJson<int>(countyCode),
      'outcome': serializer.toJson<String>(outcome),
      'enteredAt': serializer.toJson<DateTime>(enteredAt),
      'resolvedAt': serializer.toJson<DateTime>(resolvedAt),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  PendingSyncOp copyWith({
    int? id,
    Value<String?> userId = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    int? countyCode,
    String? outcome,
    DateTime? enteredAt,
    DateTime? resolvedAt,
    DateTime? queuedAt,
    int? attempts,
  }) => PendingSyncOp(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    countyCode: countyCode ?? this.countyCode,
    outcome: outcome ?? this.outcome,
    enteredAt: enteredAt ?? this.enteredAt,
    resolvedAt: resolvedAt ?? this.resolvedAt,
    queuedAt: queuedAt ?? this.queuedAt,
    attempts: attempts ?? this.attempts,
  );
  PendingSyncOp copyWithCompanion(PendingSyncOpsCompanion data) {
    return PendingSyncOp(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      countyCode: data.countyCode.present
          ? data.countyCode.value
          : this.countyCode,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      enteredAt: data.enteredAt.present ? data.enteredAt.value : this.enteredAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOp(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('countyCode: $countyCode, ')
          ..write('outcome: $outcome, ')
          ..write('enteredAt: $enteredAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    nextAttemptAt,
    countyCode,
    outcome,
    enteredAt,
    resolvedAt,
    queuedAt,
    attempts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncOp &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.countyCode == this.countyCode &&
          other.outcome == this.outcome &&
          other.enteredAt == this.enteredAt &&
          other.resolvedAt == this.resolvedAt &&
          other.queuedAt == this.queuedAt &&
          other.attempts == this.attempts);
}

class PendingSyncOpsCompanion extends UpdateCompanion<PendingSyncOp> {
  final Value<int> id;
  final Value<String?> userId;
  final Value<DateTime?> nextAttemptAt;
  final Value<int> countyCode;
  final Value<String> outcome;
  final Value<DateTime> enteredAt;
  final Value<DateTime> resolvedAt;
  final Value<DateTime> queuedAt;
  final Value<int> attempts;
  const PendingSyncOpsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.countyCode = const Value.absent(),
    this.outcome = const Value.absent(),
    this.enteredAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  PendingSyncOpsCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    required int countyCode,
    required String outcome,
    required DateTime enteredAt,
    required DateTime resolvedAt,
    this.queuedAt = const Value.absent(),
    this.attempts = const Value.absent(),
  }) : countyCode = Value(countyCode),
       outcome = Value(outcome),
       enteredAt = Value(enteredAt),
       resolvedAt = Value(resolvedAt);
  static Insertable<PendingSyncOp> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<DateTime>? nextAttemptAt,
    Expression<int>? countyCode,
    Expression<String>? outcome,
    Expression<DateTime>? enteredAt,
    Expression<DateTime>? resolvedAt,
    Expression<DateTime>? queuedAt,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (countyCode != null) 'county_code': countyCode,
      if (outcome != null) 'outcome': outcome,
      if (enteredAt != null) 'entered_at': enteredAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (attempts != null) 'attempts': attempts,
    });
  }

  PendingSyncOpsCompanion copyWith({
    Value<int>? id,
    Value<String?>? userId,
    Value<DateTime?>? nextAttemptAt,
    Value<int>? countyCode,
    Value<String>? outcome,
    Value<DateTime>? enteredAt,
    Value<DateTime>? resolvedAt,
    Value<DateTime>? queuedAt,
    Value<int>? attempts,
  }) {
    return PendingSyncOpsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      countyCode: countyCode ?? this.countyCode,
      outcome: outcome ?? this.outcome,
      enteredAt: enteredAt ?? this.enteredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      queuedAt: queuedAt ?? this.queuedAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (countyCode.present) {
      map['county_code'] = Variable<int>(countyCode.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (enteredAt.present) {
      map['entered_at'] = Variable<DateTime>(enteredAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOpsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('countyCode: $countyCode, ')
          ..write('outcome: $outcome, ')
          ..write('enteredAt: $enteredAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

class $CurrentCountyTable extends CurrentCounty
    with TableInfo<$CurrentCountyTable, CurrentCountyData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrentCountyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countyCodeMeta = const VerificationMeta(
    'countyCode',
  );
  @override
  late final GeneratedColumn<int> countyCode = GeneratedColumn<int>(
    'county_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, countyCode, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'current_county';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurrentCountyData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('county_code')) {
      context.handle(
        _countyCodeMeta,
        countyCode.isAcceptableOrUnknown(data['county_code']!, _countyCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_countyCodeMeta);
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
  CurrentCountyData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrentCountyData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      countyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}county_code'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CurrentCountyTable createAlias(String alias) {
    return $CurrentCountyTable(attachedDatabase, alias);
  }
}

class CurrentCountyData extends DataClass
    implements Insertable<CurrentCountyData> {
  /// Always 0 -- this table only ever holds one row.
  final int id;
  final int countyCode;
  final DateTime updatedAt;
  const CurrentCountyData({
    required this.id,
    required this.countyCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['county_code'] = Variable<int>(countyCode);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CurrentCountyCompanion toCompanion(bool nullToAbsent) {
    return CurrentCountyCompanion(
      id: Value(id),
      countyCode: Value(countyCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory CurrentCountyData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrentCountyData(
      id: serializer.fromJson<int>(json['id']),
      countyCode: serializer.fromJson<int>(json['countyCode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'countyCode': serializer.toJson<int>(countyCode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CurrentCountyData copyWith({int? id, int? countyCode, DateTime? updatedAt}) =>
      CurrentCountyData(
        id: id ?? this.id,
        countyCode: countyCode ?? this.countyCode,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CurrentCountyData copyWithCompanion(CurrentCountyCompanion data) {
    return CurrentCountyData(
      id: data.id.present ? data.id.value : this.id,
      countyCode: data.countyCode.present
          ? data.countyCode.value
          : this.countyCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrentCountyData(')
          ..write('id: $id, ')
          ..write('countyCode: $countyCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, countyCode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrentCountyData &&
          other.id == this.id &&
          other.countyCode == this.countyCode &&
          other.updatedAt == this.updatedAt);
}

class CurrentCountyCompanion extends UpdateCompanion<CurrentCountyData> {
  final Value<int> id;
  final Value<int> countyCode;
  final Value<DateTime> updatedAt;
  const CurrentCountyCompanion({
    this.id = const Value.absent(),
    this.countyCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CurrentCountyCompanion.insert({
    this.id = const Value.absent(),
    required int countyCode,
    required DateTime updatedAt,
  }) : countyCode = Value(countyCode),
       updatedAt = Value(updatedAt);
  static Insertable<CurrentCountyData> custom({
    Expression<int>? id,
    Expression<int>? countyCode,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (countyCode != null) 'county_code': countyCode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CurrentCountyCompanion copyWith({
    Value<int>? id,
    Value<int>? countyCode,
    Value<DateTime>? updatedAt,
  }) {
    return CurrentCountyCompanion(
      id: id ?? this.id,
      countyCode: countyCode ?? this.countyCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (countyCode.present) {
      map['county_code'] = Variable<int>(countyCode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrentCountyCompanion(')
          ..write('id: $id, ')
          ..write('countyCode: $countyCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DetectionOwnerTable extends DetectionOwner
    with TableInfo<$DetectionOwnerTable, DetectionOwnerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetectionOwnerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [id, userId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detection_owner';
  @override
  VerificationContext validateIntegrity(
    Insertable<DetectionOwnerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DetectionOwnerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetectionOwnerData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
    );
  }

  @override
  $DetectionOwnerTable createAlias(String alias) {
    return $DetectionOwnerTable(attachedDatabase, alias);
  }
}

class DetectionOwnerData extends DataClass
    implements Insertable<DetectionOwnerData> {
  final int id;
  final String userId;
  const DetectionOwnerData({required this.id, required this.userId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    return map;
  }

  DetectionOwnerCompanion toCompanion(bool nullToAbsent) {
    return DetectionOwnerCompanion(id: Value(id), userId: Value(userId));
  }

  factory DetectionOwnerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetectionOwnerData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
    };
  }

  DetectionOwnerData copyWith({int? id, String? userId}) =>
      DetectionOwnerData(id: id ?? this.id, userId: userId ?? this.userId);
  DetectionOwnerData copyWithCompanion(DetectionOwnerCompanion data) {
    return DetectionOwnerData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetectionOwnerData(')
          ..write('id: $id, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectionOwnerData &&
          other.id == this.id &&
          other.userId == this.userId);
}

class DetectionOwnerCompanion extends UpdateCompanion<DetectionOwnerData> {
  final Value<int> id;
  final Value<String> userId;
  const DetectionOwnerCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
  });
  DetectionOwnerCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
  }) : userId = Value(userId);
  static Insertable<DetectionOwnerData> custom({
    Expression<int>? id,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
    });
  }

  DetectionOwnerCompanion copyWith({Value<int>? id, Value<String>? userId}) {
    return DetectionOwnerCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetectionOwnerCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

abstract class _$DetectionDatabase extends GeneratedDatabase {
  _$DetectionDatabase(QueryExecutor e) : super(e);
  $DetectionDatabaseManager get managers => $DetectionDatabaseManager(this);
  late final $CandidatesTable candidates = $CandidatesTable(this);
  late final $PendingSyncOpsTable pendingSyncOps = $PendingSyncOpsTable(this);
  late final $CurrentCountyTable currentCounty = $CurrentCountyTable(this);
  late final $DetectionOwnerTable detectionOwner = $DetectionOwnerTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    candidates,
    pendingSyncOps,
    currentCounty,
    detectionOwner,
  ];
}

typedef $$CandidatesTableCreateCompanionBuilder =
    CandidatesCompanion Function({
      Value<int> countyCode,
      required DateTime enteredAt,
    });
typedef $$CandidatesTableUpdateCompanionBuilder =
    CandidatesCompanion Function({
      Value<int> countyCode,
      Value<DateTime> enteredAt,
    });

class $$CandidatesTableFilterComposer
    extends Composer<_$DetectionDatabase, $CandidatesTable> {
  $$CandidatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get enteredAt => $composableBuilder(
    column: $table.enteredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CandidatesTableOrderingComposer
    extends Composer<_$DetectionDatabase, $CandidatesTable> {
  $$CandidatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get enteredAt => $composableBuilder(
    column: $table.enteredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CandidatesTableAnnotationComposer
    extends Composer<_$DetectionDatabase, $CandidatesTable> {
  $$CandidatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get enteredAt =>
      $composableBuilder(column: $table.enteredAt, builder: (column) => column);
}

class $$CandidatesTableTableManager
    extends
        RootTableManager<
          _$DetectionDatabase,
          $CandidatesTable,
          Candidate,
          $$CandidatesTableFilterComposer,
          $$CandidatesTableOrderingComposer,
          $$CandidatesTableAnnotationComposer,
          $$CandidatesTableCreateCompanionBuilder,
          $$CandidatesTableUpdateCompanionBuilder,
          (
            Candidate,
            BaseReferences<_$DetectionDatabase, $CandidatesTable, Candidate>,
          ),
          Candidate,
          PrefetchHooks Function()
        > {
  $$CandidatesTableTableManager(_$DetectionDatabase db, $CandidatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CandidatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CandidatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CandidatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> countyCode = const Value.absent(),
                Value<DateTime> enteredAt = const Value.absent(),
              }) => CandidatesCompanion(
                countyCode: countyCode,
                enteredAt: enteredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> countyCode = const Value.absent(),
                required DateTime enteredAt,
              }) => CandidatesCompanion.insert(
                countyCode: countyCode,
                enteredAt: enteredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CandidatesTableProcessedTableManager =
    ProcessedTableManager<
      _$DetectionDatabase,
      $CandidatesTable,
      Candidate,
      $$CandidatesTableFilterComposer,
      $$CandidatesTableOrderingComposer,
      $$CandidatesTableAnnotationComposer,
      $$CandidatesTableCreateCompanionBuilder,
      $$CandidatesTableUpdateCompanionBuilder,
      (
        Candidate,
        BaseReferences<_$DetectionDatabase, $CandidatesTable, Candidate>,
      ),
      Candidate,
      PrefetchHooks Function()
    >;
typedef $$PendingSyncOpsTableCreateCompanionBuilder =
    PendingSyncOpsCompanion Function({
      Value<int> id,
      Value<String?> userId,
      Value<DateTime?> nextAttemptAt,
      required int countyCode,
      required String outcome,
      required DateTime enteredAt,
      required DateTime resolvedAt,
      Value<DateTime> queuedAt,
      Value<int> attempts,
    });
typedef $$PendingSyncOpsTableUpdateCompanionBuilder =
    PendingSyncOpsCompanion Function({
      Value<int> id,
      Value<String?> userId,
      Value<DateTime?> nextAttemptAt,
      Value<int> countyCode,
      Value<String> outcome,
      Value<DateTime> enteredAt,
      Value<DateTime> resolvedAt,
      Value<DateTime> queuedAt,
      Value<int> attempts,
    });

class $$PendingSyncOpsTableFilterComposer
    extends Composer<_$DetectionDatabase, $PendingSyncOpsTable> {
  $$PendingSyncOpsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get enteredAt => $composableBuilder(
    column: $table.enteredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncOpsTableOrderingComposer
    extends Composer<_$DetectionDatabase, $PendingSyncOpsTable> {
  $$PendingSyncOpsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get enteredAt => $composableBuilder(
    column: $table.enteredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncOpsTableAnnotationComposer
    extends Composer<_$DetectionDatabase, $PendingSyncOpsTable> {
  $$PendingSyncOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get enteredAt =>
      $composableBuilder(column: $table.enteredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$PendingSyncOpsTableTableManager
    extends
        RootTableManager<
          _$DetectionDatabase,
          $PendingSyncOpsTable,
          PendingSyncOp,
          $$PendingSyncOpsTableFilterComposer,
          $$PendingSyncOpsTableOrderingComposer,
          $$PendingSyncOpsTableAnnotationComposer,
          $$PendingSyncOpsTableCreateCompanionBuilder,
          $$PendingSyncOpsTableUpdateCompanionBuilder,
          (
            PendingSyncOp,
            BaseReferences<
              _$DetectionDatabase,
              $PendingSyncOpsTable,
              PendingSyncOp
            >,
          ),
          PendingSyncOp,
          PrefetchHooks Function()
        > {
  $$PendingSyncOpsTableTableManager(
    _$DetectionDatabase db,
    $PendingSyncOpsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> countyCode = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<DateTime> enteredAt = const Value.absent(),
                Value<DateTime> resolvedAt = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => PendingSyncOpsCompanion(
                id: id,
                userId: userId,
                nextAttemptAt: nextAttemptAt,
                countyCode: countyCode,
                outcome: outcome,
                enteredAt: enteredAt,
                resolvedAt: resolvedAt,
                queuedAt: queuedAt,
                attempts: attempts,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                required int countyCode,
                required String outcome,
                required DateTime enteredAt,
                required DateTime resolvedAt,
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => PendingSyncOpsCompanion.insert(
                id: id,
                userId: userId,
                nextAttemptAt: nextAttemptAt,
                countyCode: countyCode,
                outcome: outcome,
                enteredAt: enteredAt,
                resolvedAt: resolvedAt,
                queuedAt: queuedAt,
                attempts: attempts,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$DetectionDatabase,
      $PendingSyncOpsTable,
      PendingSyncOp,
      $$PendingSyncOpsTableFilterComposer,
      $$PendingSyncOpsTableOrderingComposer,
      $$PendingSyncOpsTableAnnotationComposer,
      $$PendingSyncOpsTableCreateCompanionBuilder,
      $$PendingSyncOpsTableUpdateCompanionBuilder,
      (
        PendingSyncOp,
        BaseReferences<
          _$DetectionDatabase,
          $PendingSyncOpsTable,
          PendingSyncOp
        >,
      ),
      PendingSyncOp,
      PrefetchHooks Function()
    >;
typedef $$CurrentCountyTableCreateCompanionBuilder =
    CurrentCountyCompanion Function({
      Value<int> id,
      required int countyCode,
      required DateTime updatedAt,
    });
typedef $$CurrentCountyTableUpdateCompanionBuilder =
    CurrentCountyCompanion Function({
      Value<int> id,
      Value<int> countyCode,
      Value<DateTime> updatedAt,
    });

class $$CurrentCountyTableFilterComposer
    extends Composer<_$DetectionDatabase, $CurrentCountyTable> {
  $$CurrentCountyTableFilterComposer({
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

  ColumnFilters<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CurrentCountyTableOrderingComposer
    extends Composer<_$DetectionDatabase, $CurrentCountyTable> {
  $$CurrentCountyTableOrderingComposer({
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

  ColumnOrderings<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CurrentCountyTableAnnotationComposer
    extends Composer<_$DetectionDatabase, $CurrentCountyTable> {
  $$CurrentCountyTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get countyCode => $composableBuilder(
    column: $table.countyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CurrentCountyTableTableManager
    extends
        RootTableManager<
          _$DetectionDatabase,
          $CurrentCountyTable,
          CurrentCountyData,
          $$CurrentCountyTableFilterComposer,
          $$CurrentCountyTableOrderingComposer,
          $$CurrentCountyTableAnnotationComposer,
          $$CurrentCountyTableCreateCompanionBuilder,
          $$CurrentCountyTableUpdateCompanionBuilder,
          (
            CurrentCountyData,
            BaseReferences<
              _$DetectionDatabase,
              $CurrentCountyTable,
              CurrentCountyData
            >,
          ),
          CurrentCountyData,
          PrefetchHooks Function()
        > {
  $$CurrentCountyTableTableManager(
    _$DetectionDatabase db,
    $CurrentCountyTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrentCountyTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrentCountyTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurrentCountyTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> countyCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CurrentCountyCompanion(
                id: id,
                countyCode: countyCode,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int countyCode,
                required DateTime updatedAt,
              }) => CurrentCountyCompanion.insert(
                id: id,
                countyCode: countyCode,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CurrentCountyTableProcessedTableManager =
    ProcessedTableManager<
      _$DetectionDatabase,
      $CurrentCountyTable,
      CurrentCountyData,
      $$CurrentCountyTableFilterComposer,
      $$CurrentCountyTableOrderingComposer,
      $$CurrentCountyTableAnnotationComposer,
      $$CurrentCountyTableCreateCompanionBuilder,
      $$CurrentCountyTableUpdateCompanionBuilder,
      (
        CurrentCountyData,
        BaseReferences<
          _$DetectionDatabase,
          $CurrentCountyTable,
          CurrentCountyData
        >,
      ),
      CurrentCountyData,
      PrefetchHooks Function()
    >;
typedef $$DetectionOwnerTableCreateCompanionBuilder =
    DetectionOwnerCompanion Function({Value<int> id, required String userId});
typedef $$DetectionOwnerTableUpdateCompanionBuilder =
    DetectionOwnerCompanion Function({Value<int> id, Value<String> userId});

class $$DetectionOwnerTableFilterComposer
    extends Composer<_$DetectionDatabase, $DetectionOwnerTable> {
  $$DetectionOwnerTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DetectionOwnerTableOrderingComposer
    extends Composer<_$DetectionDatabase, $DetectionOwnerTable> {
  $$DetectionOwnerTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DetectionOwnerTableAnnotationComposer
    extends Composer<_$DetectionDatabase, $DetectionOwnerTable> {
  $$DetectionOwnerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);
}

class $$DetectionOwnerTableTableManager
    extends
        RootTableManager<
          _$DetectionDatabase,
          $DetectionOwnerTable,
          DetectionOwnerData,
          $$DetectionOwnerTableFilterComposer,
          $$DetectionOwnerTableOrderingComposer,
          $$DetectionOwnerTableAnnotationComposer,
          $$DetectionOwnerTableCreateCompanionBuilder,
          $$DetectionOwnerTableUpdateCompanionBuilder,
          (
            DetectionOwnerData,
            BaseReferences<
              _$DetectionDatabase,
              $DetectionOwnerTable,
              DetectionOwnerData
            >,
          ),
          DetectionOwnerData,
          PrefetchHooks Function()
        > {
  $$DetectionOwnerTableTableManager(
    _$DetectionDatabase db,
    $DetectionOwnerTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetectionOwnerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DetectionOwnerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DetectionOwnerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
              }) => DetectionOwnerCompanion(id: id, userId: userId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
              }) => DetectionOwnerCompanion.insert(id: id, userId: userId),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DetectionOwnerTableProcessedTableManager =
    ProcessedTableManager<
      _$DetectionDatabase,
      $DetectionOwnerTable,
      DetectionOwnerData,
      $$DetectionOwnerTableFilterComposer,
      $$DetectionOwnerTableOrderingComposer,
      $$DetectionOwnerTableAnnotationComposer,
      $$DetectionOwnerTableCreateCompanionBuilder,
      $$DetectionOwnerTableUpdateCompanionBuilder,
      (
        DetectionOwnerData,
        BaseReferences<
          _$DetectionDatabase,
          $DetectionOwnerTable,
          DetectionOwnerData
        >,
      ),
      DetectionOwnerData,
      PrefetchHooks Function()
    >;

class $DetectionDatabaseManager {
  final _$DetectionDatabase _db;
  $DetectionDatabaseManager(this._db);
  $$CandidatesTableTableManager get candidates =>
      $$CandidatesTableTableManager(_db, _db.candidates);
  $$PendingSyncOpsTableTableManager get pendingSyncOps =>
      $$PendingSyncOpsTableTableManager(_db, _db.pendingSyncOps);
  $$CurrentCountyTableTableManager get currentCounty =>
      $$CurrentCountyTableTableManager(_db, _db.currentCounty);
  $$DetectionOwnerTableTableManager get detectionOwner =>
      $$DetectionOwnerTableTableManager(_db, _db.detectionOwner);
}
