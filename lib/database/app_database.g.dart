// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $InstrumentsTable extends Instruments
    with TableInfo<$InstrumentsTable, InstrumentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _isinMeta = const VerificationMeta('isin');
  @override
  late final GeneratedColumn<String> isin = GeneratedColumn<String>(
    'isin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<String> series = GeneratedColumn<String>(
    'series',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, isin, symbol, name, type, series];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instruments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstrumentData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('isin')) {
      context.handle(
        _isinMeta,
        isin.isAcceptableOrUnknown(data['isin']!, _isinMeta),
      );
    } else if (isInserting) {
      context.missing(_isinMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('series')) {
      context.handle(
        _seriesMeta,
        series.isAcceptableOrUnknown(data['series']!, _seriesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstrumentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isin'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      series: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series'],
      ),
    );
  }

  @override
  $InstrumentsTable createAlias(String alias) {
    return $InstrumentsTable(attachedDatabase, alias);
  }
}

class InstrumentData extends DataClass implements Insertable<InstrumentData> {
  final int id;

  /// Identity across files; symbols can change.
  final String isin;
  final String symbol;
  final String name;

  /// `stock` | `etf`.
  final String type;
  final String? series;
  const InstrumentData({
    required this.id,
    required this.isin,
    required this.symbol,
    required this.name,
    required this.type,
    this.series,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['isin'] = Variable<String>(isin);
    map['symbol'] = Variable<String>(symbol);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || series != null) {
      map['series'] = Variable<String>(series);
    }
    return map;
  }

  InstrumentsCompanion toCompanion(bool nullToAbsent) {
    return InstrumentsCompanion(
      id: Value(id),
      isin: Value(isin),
      symbol: Value(symbol),
      name: Value(name),
      type: Value(type),
      series: series == null && nullToAbsent
          ? const Value.absent()
          : Value(series),
    );
  }

  factory InstrumentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentData(
      id: serializer.fromJson<int>(json['id']),
      isin: serializer.fromJson<String>(json['isin']),
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      series: serializer.fromJson<String?>(json['series']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isin': serializer.toJson<String>(isin),
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'series': serializer.toJson<String?>(series),
    };
  }

  InstrumentData copyWith({
    int? id,
    String? isin,
    String? symbol,
    String? name,
    String? type,
    Value<String?> series = const Value.absent(),
  }) => InstrumentData(
    id: id ?? this.id,
    isin: isin ?? this.isin,
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    type: type ?? this.type,
    series: series.present ? series.value : this.series,
  );
  InstrumentData copyWithCompanion(InstrumentsCompanion data) {
    return InstrumentData(
      id: data.id.present ? data.id.value : this.id,
      isin: data.isin.present ? data.isin.value : this.isin,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      series: data.series.present ? data.series.value : this.series,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentData(')
          ..write('id: $id, ')
          ..write('isin: $isin, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('series: $series')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, isin, symbol, name, type, series);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstrumentData &&
          other.id == this.id &&
          other.isin == this.isin &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.type == this.type &&
          other.series == this.series);
}

class InstrumentsCompanion extends UpdateCompanion<InstrumentData> {
  final Value<int> id;
  final Value<String> isin;
  final Value<String> symbol;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> series;
  const InstrumentsCompanion({
    this.id = const Value.absent(),
    this.isin = const Value.absent(),
    this.symbol = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.series = const Value.absent(),
  });
  InstrumentsCompanion.insert({
    this.id = const Value.absent(),
    required String isin,
    required String symbol,
    required String name,
    required String type,
    this.series = const Value.absent(),
  }) : isin = Value(isin),
       symbol = Value(symbol),
       name = Value(name),
       type = Value(type);
  static Insertable<InstrumentData> custom({
    Expression<int>? id,
    Expression<String>? isin,
    Expression<String>? symbol,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? series,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isin != null) 'isin': isin,
      if (symbol != null) 'symbol': symbol,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (series != null) 'series': series,
    });
  }

  InstrumentsCompanion copyWith({
    Value<int>? id,
    Value<String>? isin,
    Value<String>? symbol,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? series,
  }) {
    return InstrumentsCompanion(
      id: id ?? this.id,
      isin: isin ?? this.isin,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      series: series ?? this.series,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isin.present) {
      map['isin'] = Variable<String>(isin.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (series.present) {
      map['series'] = Variable<String>(series.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentsCompanion(')
          ..write('id: $id, ')
          ..write('isin: $isin, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('series: $series')
          ..write(')'))
        .toString();
  }
}

class $InvestmentTransactionsTable extends InvestmentTransactions
    with TableInfo<$InvestmentTransactionsTable, InvestmentTransactionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentTransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES instruments (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityScaledMeta = const VerificationMeta(
    'quantityScaled',
  );
  @override
  late final GeneratedColumn<int> quantityScaled = GeneratedColumn<int>(
    'quantity_scaled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePaiseMeta = const VerificationMeta(
    'pricePaise',
  );
  @override
  late final GeneratedColumn<int> pricePaise = GeneratedColumn<int>(
    'price_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feesPaiseMeta = const VerificationMeta(
    'feesPaise',
  );
  @override
  late final GeneratedColumn<int> feesPaise = GeneratedColumn<int>(
    'fees_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
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
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentId,
    kind,
    quantityScaled,
    pricePaise,
    feesPaise,
    date,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investment_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvestmentTransactionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('quantity_scaled')) {
      context.handle(
        _quantityScaledMeta,
        quantityScaled.isAcceptableOrUnknown(
          data['quantity_scaled']!,
          _quantityScaledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityScaledMeta);
    }
    if (data.containsKey('price_paise')) {
      context.handle(
        _pricePaiseMeta,
        pricePaise.isAcceptableOrUnknown(data['price_paise']!, _pricePaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_pricePaiseMeta);
    }
    if (data.containsKey('fees_paise')) {
      context.handle(
        _feesPaiseMeta,
        feesPaise.isAcceptableOrUnknown(data['fees_paise']!, _feesPaiseMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
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
  InvestmentTransactionData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentTransactionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      quantityScaled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_scaled'],
      )!,
      pricePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_paise'],
      )!,
      feesPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fees_paise'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $InvestmentTransactionsTable createAlias(String alias) {
    return $InvestmentTransactionsTable(attachedDatabase, alias);
  }
}

class InvestmentTransactionData extends DataClass
    implements Insertable<InvestmentTransactionData> {
  final int id;
  final int instrumentId;

  /// `opening` (no date) | `buy`.
  final String kind;

  /// Quantity × 10,000.
  final int quantityScaled;
  final int pricePaise;
  final int feesPaise;

  /// `YYYY-MM-DD`; null means an opening position.
  final String? date;
  final DateTime createdAt;
  const InvestmentTransactionData({
    required this.id,
    required this.instrumentId,
    required this.kind,
    required this.quantityScaled,
    required this.pricePaise,
    required this.feesPaise,
    this.date,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instrument_id'] = Variable<int>(instrumentId);
    map['kind'] = Variable<String>(kind);
    map['quantity_scaled'] = Variable<int>(quantityScaled);
    map['price_paise'] = Variable<int>(pricePaise);
    map['fees_paise'] = Variable<int>(feesPaise);
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<String>(date);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InvestmentTransactionsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentTransactionsCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      kind: Value(kind),
      quantityScaled: Value(quantityScaled),
      pricePaise: Value(pricePaise),
      feesPaise: Value(feesPaise),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      createdAt: Value(createdAt),
    );
  }

  factory InvestmentTransactionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentTransactionData(
      id: serializer.fromJson<int>(json['id']),
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      kind: serializer.fromJson<String>(json['kind']),
      quantityScaled: serializer.fromJson<int>(json['quantityScaled']),
      pricePaise: serializer.fromJson<int>(json['pricePaise']),
      feesPaise: serializer.fromJson<int>(json['feesPaise']),
      date: serializer.fromJson<String?>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instrumentId': serializer.toJson<int>(instrumentId),
      'kind': serializer.toJson<String>(kind),
      'quantityScaled': serializer.toJson<int>(quantityScaled),
      'pricePaise': serializer.toJson<int>(pricePaise),
      'feesPaise': serializer.toJson<int>(feesPaise),
      'date': serializer.toJson<String?>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InvestmentTransactionData copyWith({
    int? id,
    int? instrumentId,
    String? kind,
    int? quantityScaled,
    int? pricePaise,
    int? feesPaise,
    Value<String?> date = const Value.absent(),
    DateTime? createdAt,
  }) => InvestmentTransactionData(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    kind: kind ?? this.kind,
    quantityScaled: quantityScaled ?? this.quantityScaled,
    pricePaise: pricePaise ?? this.pricePaise,
    feesPaise: feesPaise ?? this.feesPaise,
    date: date.present ? date.value : this.date,
    createdAt: createdAt ?? this.createdAt,
  );
  InvestmentTransactionData copyWithCompanion(
    InvestmentTransactionsCompanion data,
  ) {
    return InvestmentTransactionData(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      kind: data.kind.present ? data.kind.value : this.kind,
      quantityScaled: data.quantityScaled.present
          ? data.quantityScaled.value
          : this.quantityScaled,
      pricePaise: data.pricePaise.present
          ? data.pricePaise.value
          : this.pricePaise,
      feesPaise: data.feesPaise.present ? data.feesPaise.value : this.feesPaise,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentTransactionData(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('kind: $kind, ')
          ..write('quantityScaled: $quantityScaled, ')
          ..write('pricePaise: $pricePaise, ')
          ..write('feesPaise: $feesPaise, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    instrumentId,
    kind,
    quantityScaled,
    pricePaise,
    feesPaise,
    date,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentTransactionData &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.kind == this.kind &&
          other.quantityScaled == this.quantityScaled &&
          other.pricePaise == this.pricePaise &&
          other.feesPaise == this.feesPaise &&
          other.date == this.date &&
          other.createdAt == this.createdAt);
}

class InvestmentTransactionsCompanion
    extends UpdateCompanion<InvestmentTransactionData> {
  final Value<int> id;
  final Value<int> instrumentId;
  final Value<String> kind;
  final Value<int> quantityScaled;
  final Value<int> pricePaise;
  final Value<int> feesPaise;
  final Value<String?> date;
  final Value<DateTime> createdAt;
  const InvestmentTransactionsCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.kind = const Value.absent(),
    this.quantityScaled = const Value.absent(),
    this.pricePaise = const Value.absent(),
    this.feesPaise = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InvestmentTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int instrumentId,
    required String kind,
    required int quantityScaled,
    required int pricePaise,
    this.feesPaise = const Value.absent(),
    this.date = const Value.absent(),
    required DateTime createdAt,
  }) : instrumentId = Value(instrumentId),
       kind = Value(kind),
       quantityScaled = Value(quantityScaled),
       pricePaise = Value(pricePaise),
       createdAt = Value(createdAt);
  static Insertable<InvestmentTransactionData> custom({
    Expression<int>? id,
    Expression<int>? instrumentId,
    Expression<String>? kind,
    Expression<int>? quantityScaled,
    Expression<int>? pricePaise,
    Expression<int>? feesPaise,
    Expression<String>? date,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (kind != null) 'kind': kind,
      if (quantityScaled != null) 'quantity_scaled': quantityScaled,
      if (pricePaise != null) 'price_paise': pricePaise,
      if (feesPaise != null) 'fees_paise': feesPaise,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InvestmentTransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? instrumentId,
    Value<String>? kind,
    Value<int>? quantityScaled,
    Value<int>? pricePaise,
    Value<int>? feesPaise,
    Value<String?>? date,
    Value<DateTime>? createdAt,
  }) {
    return InvestmentTransactionsCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      kind: kind ?? this.kind,
      quantityScaled: quantityScaled ?? this.quantityScaled,
      pricePaise: pricePaise ?? this.pricePaise,
      feesPaise: feesPaise ?? this.feesPaise,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (quantityScaled.present) {
      map['quantity_scaled'] = Variable<int>(quantityScaled.value);
    }
    if (pricePaise.present) {
      map['price_paise'] = Variable<int>(pricePaise.value);
    }
    if (feesPaise.present) {
      map['fees_paise'] = Variable<int>(feesPaise.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('kind: $kind, ')
          ..write('quantityScaled: $quantityScaled, ')
          ..write('pricePaise: $pricePaise, ')
          ..write('feesPaise: $feesPaise, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PriceQuotesTable extends PriceQuotes
    with TableInfo<$PriceQuotesTable, PriceQuoteData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceQuotesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES instruments (id)',
    ),
  );
  static const VerificationMeta _tradeDateMeta = const VerificationMeta(
    'tradeDate',
  );
  @override
  late final GeneratedColumn<String> tradeDate = GeneratedColumn<String>(
    'trade_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closePaiseMeta = const VerificationMeta(
    'closePaise',
  );
  @override
  late final GeneratedColumn<int> closePaise = GeneratedColumn<int>(
    'close_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevClosePaiseMeta = const VerificationMeta(
    'prevClosePaise',
  );
  @override
  late final GeneratedColumn<int> prevClosePaise = GeneratedColumn<int>(
    'prev_close_paise',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentId,
    tradeDate,
    closePaise,
    prevClosePaise,
    source,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_quotes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceQuoteData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('trade_date')) {
      context.handle(
        _tradeDateMeta,
        tradeDate.isAcceptableOrUnknown(data['trade_date']!, _tradeDateMeta),
      );
    } else if (isInserting) {
      context.missing(_tradeDateMeta);
    }
    if (data.containsKey('close_paise')) {
      context.handle(
        _closePaiseMeta,
        closePaise.isAcceptableOrUnknown(data['close_paise']!, _closePaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_closePaiseMeta);
    }
    if (data.containsKey('prev_close_paise')) {
      context.handle(
        _prevClosePaiseMeta,
        prevClosePaise.isAcceptableOrUnknown(
          data['prev_close_paise']!,
          _prevClosePaiseMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {instrumentId, tradeDate, source},
  ];
  @override
  PriceQuoteData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceQuoteData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      tradeDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_date'],
      )!,
      closePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}close_paise'],
      )!,
      prevClosePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prev_close_paise'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $PriceQuotesTable createAlias(String alias) {
    return $PriceQuotesTable(attachedDatabase, alias);
  }
}

class PriceQuoteData extends DataClass implements Insertable<PriceQuoteData> {
  final int id;
  final int instrumentId;

  /// `YYYY-MM-DD` (sorts as text).
  final String tradeDate;
  final int closePaise;
  final int? prevClosePaise;

  /// `nse_bhavcopy` | `manual`.
  final String source;
  final DateTime fetchedAt;
  const PriceQuoteData({
    required this.id,
    required this.instrumentId,
    required this.tradeDate,
    required this.closePaise,
    this.prevClosePaise,
    required this.source,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instrument_id'] = Variable<int>(instrumentId);
    map['trade_date'] = Variable<String>(tradeDate);
    map['close_paise'] = Variable<int>(closePaise);
    if (!nullToAbsent || prevClosePaise != null) {
      map['prev_close_paise'] = Variable<int>(prevClosePaise);
    }
    map['source'] = Variable<String>(source);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  PriceQuotesCompanion toCompanion(bool nullToAbsent) {
    return PriceQuotesCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      tradeDate: Value(tradeDate),
      closePaise: Value(closePaise),
      prevClosePaise: prevClosePaise == null && nullToAbsent
          ? const Value.absent()
          : Value(prevClosePaise),
      source: Value(source),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory PriceQuoteData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceQuoteData(
      id: serializer.fromJson<int>(json['id']),
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      tradeDate: serializer.fromJson<String>(json['tradeDate']),
      closePaise: serializer.fromJson<int>(json['closePaise']),
      prevClosePaise: serializer.fromJson<int?>(json['prevClosePaise']),
      source: serializer.fromJson<String>(json['source']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instrumentId': serializer.toJson<int>(instrumentId),
      'tradeDate': serializer.toJson<String>(tradeDate),
      'closePaise': serializer.toJson<int>(closePaise),
      'prevClosePaise': serializer.toJson<int?>(prevClosePaise),
      'source': serializer.toJson<String>(source),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  PriceQuoteData copyWith({
    int? id,
    int? instrumentId,
    String? tradeDate,
    int? closePaise,
    Value<int?> prevClosePaise = const Value.absent(),
    String? source,
    DateTime? fetchedAt,
  }) => PriceQuoteData(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    tradeDate: tradeDate ?? this.tradeDate,
    closePaise: closePaise ?? this.closePaise,
    prevClosePaise: prevClosePaise.present
        ? prevClosePaise.value
        : this.prevClosePaise,
    source: source ?? this.source,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  PriceQuoteData copyWithCompanion(PriceQuotesCompanion data) {
    return PriceQuoteData(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      tradeDate: data.tradeDate.present ? data.tradeDate.value : this.tradeDate,
      closePaise: data.closePaise.present
          ? data.closePaise.value
          : this.closePaise,
      prevClosePaise: data.prevClosePaise.present
          ? data.prevClosePaise.value
          : this.prevClosePaise,
      source: data.source.present ? data.source.value : this.source,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceQuoteData(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('tradeDate: $tradeDate, ')
          ..write('closePaise: $closePaise, ')
          ..write('prevClosePaise: $prevClosePaise, ')
          ..write('source: $source, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    instrumentId,
    tradeDate,
    closePaise,
    prevClosePaise,
    source,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceQuoteData &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.tradeDate == this.tradeDate &&
          other.closePaise == this.closePaise &&
          other.prevClosePaise == this.prevClosePaise &&
          other.source == this.source &&
          other.fetchedAt == this.fetchedAt);
}

class PriceQuotesCompanion extends UpdateCompanion<PriceQuoteData> {
  final Value<int> id;
  final Value<int> instrumentId;
  final Value<String> tradeDate;
  final Value<int> closePaise;
  final Value<int?> prevClosePaise;
  final Value<String> source;
  final Value<DateTime> fetchedAt;
  const PriceQuotesCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.tradeDate = const Value.absent(),
    this.closePaise = const Value.absent(),
    this.prevClosePaise = const Value.absent(),
    this.source = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  PriceQuotesCompanion.insert({
    this.id = const Value.absent(),
    required int instrumentId,
    required String tradeDate,
    required int closePaise,
    this.prevClosePaise = const Value.absent(),
    required String source,
    required DateTime fetchedAt,
  }) : instrumentId = Value(instrumentId),
       tradeDate = Value(tradeDate),
       closePaise = Value(closePaise),
       source = Value(source),
       fetchedAt = Value(fetchedAt);
  static Insertable<PriceQuoteData> custom({
    Expression<int>? id,
    Expression<int>? instrumentId,
    Expression<String>? tradeDate,
    Expression<int>? closePaise,
    Expression<int>? prevClosePaise,
    Expression<String>? source,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (tradeDate != null) 'trade_date': tradeDate,
      if (closePaise != null) 'close_paise': closePaise,
      if (prevClosePaise != null) 'prev_close_paise': prevClosePaise,
      if (source != null) 'source': source,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  PriceQuotesCompanion copyWith({
    Value<int>? id,
    Value<int>? instrumentId,
    Value<String>? tradeDate,
    Value<int>? closePaise,
    Value<int?>? prevClosePaise,
    Value<String>? source,
    Value<DateTime>? fetchedAt,
  }) {
    return PriceQuotesCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      tradeDate: tradeDate ?? this.tradeDate,
      closePaise: closePaise ?? this.closePaise,
      prevClosePaise: prevClosePaise ?? this.prevClosePaise,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (tradeDate.present) {
      map['trade_date'] = Variable<String>(tradeDate.value);
    }
    if (closePaise.present) {
      map['close_paise'] = Variable<int>(closePaise.value);
    }
    if (prevClosePaise.present) {
      map['prev_close_paise'] = Variable<int>(prevClosePaise.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceQuotesCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('tradeDate: $tradeDate, ')
          ..write('closePaise: $closePaise, ')
          ..write('prevClosePaise: $prevClosePaise, ')
          ..write('source: $source, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $SymbolMasterTable extends SymbolMaster
    with TableInfo<$SymbolMasterTable, SymbolMasterData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SymbolMasterTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _isinMeta = const VerificationMeta('isin');
  @override
  late final GeneratedColumn<String> isin = GeneratedColumn<String>(
    'isin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<String> series = GeneratedColumn<String>(
    'series',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('equity_l'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    isin,
    symbol,
    name,
    type,
    series,
    origin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symbol_master';
  @override
  VerificationContext validateIntegrity(
    Insertable<SymbolMasterData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('isin')) {
      context.handle(
        _isinMeta,
        isin.isAcceptableOrUnknown(data['isin']!, _isinMeta),
      );
    } else if (isInserting) {
      context.missing(_isinMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('series')) {
      context.handle(
        _seriesMeta,
        series.isAcceptableOrUnknown(data['series']!, _seriesMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {isin};
  @override
  SymbolMasterData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SymbolMasterData(
      isin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isin'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      series: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series'],
      ),
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
    );
  }

  @override
  $SymbolMasterTable createAlias(String alias) {
    return $SymbolMasterTable(attachedDatabase, alias);
  }
}

class SymbolMasterData extends DataClass
    implements Insertable<SymbolMasterData> {
  final String isin;
  final String symbol;
  final String name;

  /// `stock` | `etf`.
  final String type;

  /// Not in the original spec; kept so a picked instrument gets its series.
  final String? series;

  /// `equity_l` (EQUITY_L.csv) | `bhavcopy` (ETFs, and stocks such as SM/ST
  /// that are not in EQUITY_L). Added in schema v2.
  final String origin;
  const SymbolMasterData({
    required this.isin,
    required this.symbol,
    required this.name,
    required this.type,
    this.series,
    required this.origin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['isin'] = Variable<String>(isin);
    map['symbol'] = Variable<String>(symbol);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || series != null) {
      map['series'] = Variable<String>(series);
    }
    map['origin'] = Variable<String>(origin);
    return map;
  }

  SymbolMasterCompanion toCompanion(bool nullToAbsent) {
    return SymbolMasterCompanion(
      isin: Value(isin),
      symbol: Value(symbol),
      name: Value(name),
      type: Value(type),
      series: series == null && nullToAbsent
          ? const Value.absent()
          : Value(series),
      origin: Value(origin),
    );
  }

  factory SymbolMasterData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SymbolMasterData(
      isin: serializer.fromJson<String>(json['isin']),
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      series: serializer.fromJson<String?>(json['series']),
      origin: serializer.fromJson<String>(json['origin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'isin': serializer.toJson<String>(isin),
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'series': serializer.toJson<String?>(series),
      'origin': serializer.toJson<String>(origin),
    };
  }

  SymbolMasterData copyWith({
    String? isin,
    String? symbol,
    String? name,
    String? type,
    Value<String?> series = const Value.absent(),
    String? origin,
  }) => SymbolMasterData(
    isin: isin ?? this.isin,
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    type: type ?? this.type,
    series: series.present ? series.value : this.series,
    origin: origin ?? this.origin,
  );
  SymbolMasterData copyWithCompanion(SymbolMasterCompanion data) {
    return SymbolMasterData(
      isin: data.isin.present ? data.isin.value : this.isin,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      series: data.series.present ? data.series.value : this.series,
      origin: data.origin.present ? data.origin.value : this.origin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SymbolMasterData(')
          ..write('isin: $isin, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('series: $series, ')
          ..write('origin: $origin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(isin, symbol, name, type, series, origin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymbolMasterData &&
          other.isin == this.isin &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.type == this.type &&
          other.series == this.series &&
          other.origin == this.origin);
}

class SymbolMasterCompanion extends UpdateCompanion<SymbolMasterData> {
  final Value<String> isin;
  final Value<String> symbol;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> series;
  final Value<String> origin;
  final Value<int> rowid;
  const SymbolMasterCompanion({
    this.isin = const Value.absent(),
    this.symbol = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.series = const Value.absent(),
    this.origin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SymbolMasterCompanion.insert({
    required String isin,
    required String symbol,
    required String name,
    required String type,
    this.series = const Value.absent(),
    this.origin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : isin = Value(isin),
       symbol = Value(symbol),
       name = Value(name),
       type = Value(type);
  static Insertable<SymbolMasterData> custom({
    Expression<String>? isin,
    Expression<String>? symbol,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? series,
    Expression<String>? origin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (isin != null) 'isin': isin,
      if (symbol != null) 'symbol': symbol,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (series != null) 'series': series,
      if (origin != null) 'origin': origin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SymbolMasterCompanion copyWith({
    Value<String>? isin,
    Value<String>? symbol,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? series,
    Value<String>? origin,
    Value<int>? rowid,
  }) {
    return SymbolMasterCompanion(
      isin: isin ?? this.isin,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      series: series ?? this.series,
      origin: origin ?? this.origin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (isin.present) {
      map['isin'] = Variable<String>(isin.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (series.present) {
      map['series'] = Variable<String>(series.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymbolMasterCompanion(')
          ..write('isin: $isin, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('series: $series, ')
          ..write('origin: $origin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingData extends DataClass implements Insertable<AppSettingData> {
  final String key;
  final String value;
  const AppSettingData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingData copyWith({String? key, String? value}) =>
      AppSettingData(key: key ?? this.key, value: value ?? this.value);
  AppSettingData copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InstrumentsTable instruments = $InstrumentsTable(this);
  late final $InvestmentTransactionsTable investmentTransactions =
      $InvestmentTransactionsTable(this);
  late final $PriceQuotesTable priceQuotes = $PriceQuotesTable(this);
  late final $SymbolMasterTable symbolMaster = $SymbolMasterTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    instruments,
    investmentTransactions,
    priceQuotes,
    symbolMaster,
    appSettings,
  ];
}

typedef $$InstrumentsTableCreateCompanionBuilder =
    InstrumentsCompanion Function({
      Value<int> id,
      required String isin,
      required String symbol,
      required String name,
      required String type,
      Value<String?> series,
    });
typedef $$InstrumentsTableUpdateCompanionBuilder =
    InstrumentsCompanion Function({
      Value<int> id,
      Value<String> isin,
      Value<String> symbol,
      Value<String> name,
      Value<String> type,
      Value<String?> series,
    });

final class $$InstrumentsTableReferences
    extends BaseReferences<_$AppDatabase, $InstrumentsTable, InstrumentData> {
  $$InstrumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $InvestmentTransactionsTable,
    List<InvestmentTransactionData>
  >
  _investmentTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.investmentTransactions,
        aliasName: 'instruments__id__investment_transactions__instrument_id',
      );

  $$InvestmentTransactionsTableProcessedTableManager
  get investmentTransactionsRefs {
    final manager = $$InvestmentTransactionsTableTableManager(
      $_db,
      $_db.investmentTransactions,
    ).filter((f) => f.instrumentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _investmentTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PriceQuotesTable, List<PriceQuoteData>>
  _priceQuotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.priceQuotes,
    aliasName: 'instruments__id__price_quotes__instrument_id',
  );

  $$PriceQuotesTableProcessedTableManager get priceQuotesRefs {
    final manager = $$PriceQuotesTableTableManager(
      $_db,
      $_db.priceQuotes,
    ).filter((f) => f.instrumentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_priceQuotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InstrumentsTableFilterComposer
    extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableFilterComposer({
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

  ColumnFilters<String> get isin => $composableBuilder(
    column: $table.isin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> investmentTransactionsRefs(
    Expression<bool> Function($$InvestmentTransactionsTableFilterComposer f) f,
  ) {
    final $$InvestmentTransactionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.investmentTransactions,
          getReferencedColumn: (t) => t.instrumentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InvestmentTransactionsTableFilterComposer(
                $db: $db,
                $table: $db.investmentTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> priceQuotesRefs(
    Expression<bool> Function($$PriceQuotesTableFilterComposer f) f,
  ) {
    final $$PriceQuotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceQuotes,
      getReferencedColumn: (t) => t.instrumentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceQuotesTableFilterComposer(
            $db: $db,
            $table: $db.priceQuotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InstrumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableOrderingComposer({
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

  ColumnOrderings<String> get isin => $composableBuilder(
    column: $table.isin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstrumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstrumentsTable> {
  $$InstrumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get isin =>
      $composableBuilder(column: $table.isin, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get series =>
      $composableBuilder(column: $table.series, builder: (column) => column);

  Expression<T> investmentTransactionsRefs<T extends Object>(
    Expression<T> Function($$InvestmentTransactionsTableAnnotationComposer a) f,
  ) {
    final $$InvestmentTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.investmentTransactions,
          getReferencedColumn: (t) => t.instrumentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InvestmentTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.investmentTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> priceQuotesRefs<T extends Object>(
    Expression<T> Function($$PriceQuotesTableAnnotationComposer a) f,
  ) {
    final $$PriceQuotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceQuotes,
      getReferencedColumn: (t) => t.instrumentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceQuotesTableAnnotationComposer(
            $db: $db,
            $table: $db.priceQuotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InstrumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstrumentsTable,
          InstrumentData,
          $$InstrumentsTableFilterComposer,
          $$InstrumentsTableOrderingComposer,
          $$InstrumentsTableAnnotationComposer,
          $$InstrumentsTableCreateCompanionBuilder,
          $$InstrumentsTableUpdateCompanionBuilder,
          (InstrumentData, $$InstrumentsTableReferences),
          InstrumentData,
          PrefetchHooks Function({
            bool investmentTransactionsRefs,
            bool priceQuotesRefs,
          })
        > {
  $$InstrumentsTableTableManager(_$AppDatabase db, $InstrumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstrumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstrumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstrumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> isin = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> series = const Value.absent(),
              }) => InstrumentsCompanion(
                id: id,
                isin: isin,
                symbol: symbol,
                name: name,
                type: type,
                series: series,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String isin,
                required String symbol,
                required String name,
                required String type,
                Value<String?> series = const Value.absent(),
              }) => InstrumentsCompanion.insert(
                id: id,
                isin: isin,
                symbol: symbol,
                name: name,
                type: type,
                series: series,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstrumentsTable, InstrumentData>(table),
                  $$InstrumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({investmentTransactionsRefs = false, priceQuotesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (investmentTransactionsRefs) db.investmentTransactions,
                    if (priceQuotesRefs) db.priceQuotes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (investmentTransactionsRefs)
                        await $_getPrefetchedData<
                          InstrumentData,
                          $InstrumentsTable,
                          InvestmentTransactionData
                        >(
                          currentTable: table,
                          referencedTable: $$InstrumentsTableReferences
                              ._investmentTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InstrumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).investmentTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.instrumentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (priceQuotesRefs)
                        await $_getPrefetchedData<
                          InstrumentData,
                          $InstrumentsTable,
                          PriceQuoteData
                        >(
                          currentTable: table,
                          referencedTable: $$InstrumentsTableReferences
                              ._priceQuotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$InstrumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).priceQuotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.instrumentId == item.id,
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

typedef $$InstrumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstrumentsTable,
      InstrumentData,
      $$InstrumentsTableFilterComposer,
      $$InstrumentsTableOrderingComposer,
      $$InstrumentsTableAnnotationComposer,
      $$InstrumentsTableCreateCompanionBuilder,
      $$InstrumentsTableUpdateCompanionBuilder,
      (InstrumentData, $$InstrumentsTableReferences),
      InstrumentData,
      PrefetchHooks Function({
        bool investmentTransactionsRefs,
        bool priceQuotesRefs,
      })
    >;
typedef $$InvestmentTransactionsTableCreateCompanionBuilder =
    InvestmentTransactionsCompanion Function({
      Value<int> id,
      required int instrumentId,
      required String kind,
      required int quantityScaled,
      required int pricePaise,
      Value<int> feesPaise,
      Value<String?> date,
      required DateTime createdAt,
    });
typedef $$InvestmentTransactionsTableUpdateCompanionBuilder =
    InvestmentTransactionsCompanion Function({
      Value<int> id,
      Value<int> instrumentId,
      Value<String> kind,
      Value<int> quantityScaled,
      Value<int> pricePaise,
      Value<int> feesPaise,
      Value<String?> date,
      Value<DateTime> createdAt,
    });

final class $$InvestmentTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InvestmentTransactionsTable,
          InvestmentTransactionData
        > {
  $$InvestmentTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InstrumentsTable _instrumentIdTable(_$AppDatabase db) => db
      .instruments
      .createAlias('investment_transactions__instrument_id__instruments__id');

  $$InstrumentsTableProcessedTableManager get instrumentId {
    final $_column = $_itemColumn<int>('instrument_id')!;

    final manager = $$InstrumentsTableTableManager(
      $_db,
      $_db.instruments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_instrumentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvestmentTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentTransactionsTable> {
  $$InvestmentTransactionsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityScaled => $composableBuilder(
    column: $table.quantityScaled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pricePaise => $composableBuilder(
    column: $table.pricePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feesPaise => $composableBuilder(
    column: $table.feesPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InstrumentsTableFilterComposer get instrumentId {
    final $$InstrumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentId,
      referencedTable: $db.instruments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentsTableFilterComposer(
            $db: $db,
            $table: $db.instruments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvestmentTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentTransactionsTable> {
  $$InvestmentTransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityScaled => $composableBuilder(
    column: $table.quantityScaled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pricePaise => $composableBuilder(
    column: $table.pricePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feesPaise => $composableBuilder(
    column: $table.feesPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InstrumentsTableOrderingComposer get instrumentId {
    final $$InstrumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentId,
      referencedTable: $db.instruments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentsTableOrderingComposer(
            $db: $db,
            $table: $db.instruments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvestmentTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentTransactionsTable> {
  $$InvestmentTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get quantityScaled => $composableBuilder(
    column: $table.quantityScaled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pricePaise => $composableBuilder(
    column: $table.pricePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feesPaise =>
      $composableBuilder(column: $table.feesPaise, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$InstrumentsTableAnnotationComposer get instrumentId {
    final $$InstrumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentId,
      referencedTable: $db.instruments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.instruments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvestmentTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestmentTransactionsTable,
          InvestmentTransactionData,
          $$InvestmentTransactionsTableFilterComposer,
          $$InvestmentTransactionsTableOrderingComposer,
          $$InvestmentTransactionsTableAnnotationComposer,
          $$InvestmentTransactionsTableCreateCompanionBuilder,
          $$InvestmentTransactionsTableUpdateCompanionBuilder,
          (InvestmentTransactionData, $$InvestmentTransactionsTableReferences),
          InvestmentTransactionData,
          PrefetchHooks Function({bool instrumentId})
        > {
  $$InvestmentTransactionsTableTableManager(
    _$AppDatabase db,
    $InvestmentTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentTransactionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InvestmentTransactionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InvestmentTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> instrumentId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> quantityScaled = const Value.absent(),
                Value<int> pricePaise = const Value.absent(),
                Value<int> feesPaise = const Value.absent(),
                Value<String?> date = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => InvestmentTransactionsCompanion(
                id: id,
                instrumentId: instrumentId,
                kind: kind,
                quantityScaled: quantityScaled,
                pricePaise: pricePaise,
                feesPaise: feesPaise,
                date: date,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int instrumentId,
                required String kind,
                required int quantityScaled,
                required int pricePaise,
                Value<int> feesPaise = const Value.absent(),
                Value<String?> date = const Value.absent(),
                required DateTime createdAt,
              }) => InvestmentTransactionsCompanion.insert(
                id: id,
                instrumentId: instrumentId,
                kind: kind,
                quantityScaled: quantityScaled,
                pricePaise: pricePaise,
                feesPaise: feesPaise,
                date: date,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $InvestmentTransactionsTable,
                    InvestmentTransactionData
                  >(table),
                  $$InvestmentTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({instrumentId = false}) {
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
                    if (instrumentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.instrumentId,
                                referencedTable:
                                    $$InvestmentTransactionsTableReferences
                                        ._instrumentIdTable(db),
                                referencedColumn:
                                    $$InvestmentTransactionsTableReferences
                                        ._instrumentIdTable(db)
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

typedef $$InvestmentTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestmentTransactionsTable,
      InvestmentTransactionData,
      $$InvestmentTransactionsTableFilterComposer,
      $$InvestmentTransactionsTableOrderingComposer,
      $$InvestmentTransactionsTableAnnotationComposer,
      $$InvestmentTransactionsTableCreateCompanionBuilder,
      $$InvestmentTransactionsTableUpdateCompanionBuilder,
      (InvestmentTransactionData, $$InvestmentTransactionsTableReferences),
      InvestmentTransactionData,
      PrefetchHooks Function({bool instrumentId})
    >;
typedef $$PriceQuotesTableCreateCompanionBuilder =
    PriceQuotesCompanion Function({
      Value<int> id,
      required int instrumentId,
      required String tradeDate,
      required int closePaise,
      Value<int?> prevClosePaise,
      required String source,
      required DateTime fetchedAt,
    });
typedef $$PriceQuotesTableUpdateCompanionBuilder =
    PriceQuotesCompanion Function({
      Value<int> id,
      Value<int> instrumentId,
      Value<String> tradeDate,
      Value<int> closePaise,
      Value<int?> prevClosePaise,
      Value<String> source,
      Value<DateTime> fetchedAt,
    });

final class $$PriceQuotesTableReferences
    extends BaseReferences<_$AppDatabase, $PriceQuotesTable, PriceQuoteData> {
  $$PriceQuotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InstrumentsTable _instrumentIdTable(_$AppDatabase db) => db
      .instruments
      .createAlias('price_quotes__instrument_id__instruments__id');

  $$InstrumentsTableProcessedTableManager get instrumentId {
    final $_column = $_itemColumn<int>('instrument_id')!;

    final manager = $$InstrumentsTableTableManager(
      $_db,
      $_db.instruments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_instrumentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PriceQuotesTableFilterComposer
    extends Composer<_$AppDatabase, $PriceQuotesTable> {
  $$PriceQuotesTableFilterComposer({
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

  ColumnFilters<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closePaise => $composableBuilder(
    column: $table.closePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prevClosePaise => $composableBuilder(
    column: $table.prevClosePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$InstrumentsTableFilterComposer get instrumentId {
    final $$InstrumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentId,
      referencedTable: $db.instruments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentsTableFilterComposer(
            $db: $db,
            $table: $db.instruments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceQuotesTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceQuotesTable> {
  $$PriceQuotesTableOrderingComposer({
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

  ColumnOrderings<String> get tradeDate => $composableBuilder(
    column: $table.tradeDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closePaise => $composableBuilder(
    column: $table.closePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prevClosePaise => $composableBuilder(
    column: $table.prevClosePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$InstrumentsTableOrderingComposer get instrumentId {
    final $$InstrumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentId,
      referencedTable: $db.instruments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentsTableOrderingComposer(
            $db: $db,
            $table: $db.instruments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceQuotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceQuotesTable> {
  $$PriceQuotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tradeDate =>
      $composableBuilder(column: $table.tradeDate, builder: (column) => column);

  GeneratedColumn<int> get closePaise => $composableBuilder(
    column: $table.closePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prevClosePaise => $composableBuilder(
    column: $table.prevClosePaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  $$InstrumentsTableAnnotationComposer get instrumentId {
    final $$InstrumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instrumentId,
      referencedTable: $db.instruments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.instruments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceQuotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceQuotesTable,
          PriceQuoteData,
          $$PriceQuotesTableFilterComposer,
          $$PriceQuotesTableOrderingComposer,
          $$PriceQuotesTableAnnotationComposer,
          $$PriceQuotesTableCreateCompanionBuilder,
          $$PriceQuotesTableUpdateCompanionBuilder,
          (PriceQuoteData, $$PriceQuotesTableReferences),
          PriceQuoteData,
          PrefetchHooks Function({bool instrumentId})
        > {
  $$PriceQuotesTableTableManager(_$AppDatabase db, $PriceQuotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceQuotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceQuotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceQuotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> instrumentId = const Value.absent(),
                Value<String> tradeDate = const Value.absent(),
                Value<int> closePaise = const Value.absent(),
                Value<int?> prevClosePaise = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => PriceQuotesCompanion(
                id: id,
                instrumentId: instrumentId,
                tradeDate: tradeDate,
                closePaise: closePaise,
                prevClosePaise: prevClosePaise,
                source: source,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int instrumentId,
                required String tradeDate,
                required int closePaise,
                Value<int?> prevClosePaise = const Value.absent(),
                required String source,
                required DateTime fetchedAt,
              }) => PriceQuotesCompanion.insert(
                id: id,
                instrumentId: instrumentId,
                tradeDate: tradeDate,
                closePaise: closePaise,
                prevClosePaise: prevClosePaise,
                source: source,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PriceQuotesTable, PriceQuoteData>(table),
                  $$PriceQuotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({instrumentId = false}) {
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
                    if (instrumentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.instrumentId,
                                referencedTable: $$PriceQuotesTableReferences
                                    ._instrumentIdTable(db),
                                referencedColumn: $$PriceQuotesTableReferences
                                    ._instrumentIdTable(db)
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

typedef $$PriceQuotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceQuotesTable,
      PriceQuoteData,
      $$PriceQuotesTableFilterComposer,
      $$PriceQuotesTableOrderingComposer,
      $$PriceQuotesTableAnnotationComposer,
      $$PriceQuotesTableCreateCompanionBuilder,
      $$PriceQuotesTableUpdateCompanionBuilder,
      (PriceQuoteData, $$PriceQuotesTableReferences),
      PriceQuoteData,
      PrefetchHooks Function({bool instrumentId})
    >;
typedef $$SymbolMasterTableCreateCompanionBuilder =
    SymbolMasterCompanion Function({
      required String isin,
      required String symbol,
      required String name,
      required String type,
      Value<String?> series,
      Value<String> origin,
      Value<int> rowid,
    });
typedef $$SymbolMasterTableUpdateCompanionBuilder =
    SymbolMasterCompanion Function({
      Value<String> isin,
      Value<String> symbol,
      Value<String> name,
      Value<String> type,
      Value<String?> series,
      Value<String> origin,
      Value<int> rowid,
    });

class $$SymbolMasterTableFilterComposer
    extends Composer<_$AppDatabase, $SymbolMasterTable> {
  $$SymbolMasterTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get isin => $composableBuilder(
    column: $table.isin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SymbolMasterTableOrderingComposer
    extends Composer<_$AppDatabase, $SymbolMasterTable> {
  $$SymbolMasterTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get isin => $composableBuilder(
    column: $table.isin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SymbolMasterTableAnnotationComposer
    extends Composer<_$AppDatabase, $SymbolMasterTable> {
  $$SymbolMasterTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get isin =>
      $composableBuilder(column: $table.isin, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get series =>
      $composableBuilder(column: $table.series, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);
}

class $$SymbolMasterTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SymbolMasterTable,
          SymbolMasterData,
          $$SymbolMasterTableFilterComposer,
          $$SymbolMasterTableOrderingComposer,
          $$SymbolMasterTableAnnotationComposer,
          $$SymbolMasterTableCreateCompanionBuilder,
          $$SymbolMasterTableUpdateCompanionBuilder,
          (
            SymbolMasterData,
            BaseReferences<_$AppDatabase, $SymbolMasterTable, SymbolMasterData>,
          ),
          SymbolMasterData,
          PrefetchHooks Function()
        > {
  $$SymbolMasterTableTableManager(_$AppDatabase db, $SymbolMasterTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SymbolMasterTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SymbolMasterTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SymbolMasterTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> isin = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> series = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SymbolMasterCompanion(
                isin: isin,
                symbol: symbol,
                name: name,
                type: type,
                series: series,
                origin: origin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String isin,
                required String symbol,
                required String name,
                required String type,
                Value<String?> series = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SymbolMasterCompanion.insert(
                isin: isin,
                symbol: symbol,
                name: name,
                type: type,
                series: series,
                origin: origin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SymbolMasterTable, SymbolMasterData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SymbolMasterTable,
                    SymbolMasterData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SymbolMasterTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SymbolMasterTable,
      SymbolMasterData,
      $$SymbolMasterTableFilterComposer,
      $$SymbolMasterTableOrderingComposer,
      $$SymbolMasterTableAnnotationComposer,
      $$SymbolMasterTableCreateCompanionBuilder,
      $$SymbolMasterTableUpdateCompanionBuilder,
      (
        SymbolMasterData,
        BaseReferences<_$AppDatabase, $SymbolMasterTable, SymbolMasterData>,
      ),
      SymbolMasterData,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
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
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingData,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingData,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingData>,
          ),
          AppSettingData,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingData,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingData,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingData>,
      ),
      AppSettingData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InstrumentsTableTableManager get instruments =>
      $$InstrumentsTableTableManager(_db, _db.instruments);
  $$InvestmentTransactionsTableTableManager get investmentTransactions =>
      $$InvestmentTransactionsTableTableManager(
        _db,
        _db.investmentTransactions,
      );
  $$PriceQuotesTableTableManager get priceQuotes =>
      $$PriceQuotesTableTableManager(_db, _db.priceQuotes);
  $$SymbolMasterTableTableManager get symbolMaster =>
      $$SymbolMasterTableTableManager(_db, _db.symbolMaster);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
