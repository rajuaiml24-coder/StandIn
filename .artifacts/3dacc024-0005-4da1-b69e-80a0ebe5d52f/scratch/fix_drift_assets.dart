import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final assets = {
    'web/sqlite3.wasm': 'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.4.3/sqlite3.wasm',
    'web/drift_worker.js': 'https://raw.githubusercontent.com/simolus3/drift/drift-2.31.0/extras/web_worker/drift_worker.js',
  };

  for (final entry in assets.entries) {
    print('Downloading ${entry.key}...');
    final response = await http.get(Uri.parse(entry.value));
    if (response.statusCode == 200) {
      File(entry.key).writeAsBytesSync(response.bodyBytes);
      print('SUCCESS: ${entry.key} saved.');
    } else {
      print('FAIL: ${entry.key} (Status ${response.statusCode})');
    }
  }
}
