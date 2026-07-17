import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:workon/core/image_compress.dart';

Uint8List _noisyPng(int w, int h) {
  final im = img.Image(width: w, height: h);
  final rnd = Random(7);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      im.setPixelRgb(x, y, rnd.nextInt(256), rnd.nextInt(256), rnd.nextInt(256));
    }
  }
  return Uint8List.fromList(img.encodePng(im));
}

void main() {
  group('MMS 이미지 압축', () {
    test('큰 이미지 → 긴 변 1024px 이하 & 300KB 이하', () {
      final input = _noisyPng(2400, 1600);
      final r = compressForMms(input);
      expect(r, isNotNull);
      expect(r!.width <= 1024 && r.height <= 1024, isTrue,
          reason: '${r.width}x${r.height} 가 1024 이하여야 함');
      expect(r.sizeBytes <= 300 * 1024, isTrue,
          reason: '${r.sizeBytes} bytes 가 300KB 이하여야 함');
      // 가로가 더 길므로 가로가 1024 에 맞춰짐.
      expect(r.width, 1024);
    });

    test('작은 이미지는 확대하지 않음', () {
      final input = _noisyPng(400, 300);
      final r = compressForMms(input);
      expect(r, isNotNull);
      expect(r!.width, 400);
      expect(r.height, 300);
    });

    test('세로가 긴 이미지는 세로를 1024 에 맞춤', () {
      final input = _noisyPng(800, 2000);
      final r = compressForMms(input);
      expect(r, isNotNull);
      expect(r!.height, 1024);
      expect(r.width <= 1024, isTrue);
    });

    test('디코드 불가 입력은 null', () {
      final r = compressForMms(Uint8List.fromList([1, 2, 3, 4]));
      expect(r, isNull);
    });
  });
}
