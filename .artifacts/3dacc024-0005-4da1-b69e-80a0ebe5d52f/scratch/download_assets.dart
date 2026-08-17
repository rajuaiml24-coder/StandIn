import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final files = {
    'web/sqlite3.wasm': 'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.4.3/sqlite3.wasm',
    'web/drift_worker.js': 'https://raw.githubusercontent.com/simolus3/drift/main/extras/web_worker/drift_worker.js',
  };

  for (final entry in files.entries) {
    print('Downloading ${entry.key}...');
    try {
      final response = await http.get(Uri.parse(entry.value));
      if (response.statusCode == 200) {
        File(entry.key).writeAsBytesSync(response.bodyBytes);
        print('SUCCESS: ${entry.key}');
      } else {
        print('FAIL: ${entry.key} (Status ${response.statusCode})');
      }
    } catch (e) {
      print('ERROR: ${entry.key} ($e)');
    }
  }
}
