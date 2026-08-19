import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor connect(String dbName) => driftDatabase(name: dbName);
