import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// 통합 테스트 스크린샷을 `app/screenshots/<name>.png` 로 저장하는 드라이버.
Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes,
        [Map<String, Object?>? args]) async {
      final file = File('screenshots/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
