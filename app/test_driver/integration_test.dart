import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final dir = Directory('screenshots');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      File('screenshots/$name.png').writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('SAVED screenshots/$name.png (${bytes.length} bytes)');
      return true;
    },
  );
}
