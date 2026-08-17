import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final assets = {
    'web/sqlite3.wasm': 'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.4.3/sqlite3.wasm',
    'web/drift_worker.js': 'https://raw.githubusercontent.com/simolus3/drift/drift-2.31.0/extras/web_worker/drift_worker.js',
  };

  final webDir = Directory('web');
  if (!webDir.existsSync()) {
    webDir.createSync();
  }

  for (final entry in assets.entries) {
    print('Downloading ${entry.key} from ${entry.value}...');
    try {
      final response = await http.get(Uri.parse(entry.value));
      if (response.statusCode == 200) {
        File(entry.key).writeAsBytesSync(response.bodyBytes);
        print('SUCCESS: ${entry.key} saved (${response.bodyBytes.length} bytes).');
      } else {
        print('FAIL: ${entry.key} (Status ${response.statusCode})');
        exit(1);
      }
    } catch (e) {
      print('ERROR: ${entry.key} - $e');
      exit(1);
    }
  }
  print('All assets downloaded successfully.');
}
