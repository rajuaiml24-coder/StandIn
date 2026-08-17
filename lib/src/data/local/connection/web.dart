import 'package:drift/drift.dart';
import 'package:drift/wasm.dart'; // Future-proof if we ever add wasm manually
import 'package:drift/web.dart';

QueryExecutor connect() {
  // Use the established IndexedDB-based WebDatabase for maximum reliability
  // on PWA without requiring external .wasm files.
  return WebDatabase('standin');
}
