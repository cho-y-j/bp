import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// 문자(MMS) 첨부용 이미지 전처리 — bizconnect-v2 `compressImageWithExif` 로직을
/// 순수 Dart 로 재구현. 네이티브 의존 없이 단위 테스트로 크기를 검증할 수 있다.
///
/// 원칙(참고: SmsSender.kt:457):
///  - EXIF 회전 보정(`bakeOrientation`).
///  - 긴 변을 [maxDimension] 이하로 축소(기본 1024px).
///  - JPEG 품질을 낮춰가며 목표 바이트([maxBytes], 기본 300KB) 이하로 반복 압축.
class ImageCompressResult {
  final Uint8List bytes;
  final int width;
  final int height;
  final int quality;
  const ImageCompressResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.quality,
  });
  int get sizeBytes => bytes.length;
}

/// [input] 이미지를 MMS 첨부 규격으로 압축한다.
///  - [maxDimension]: 긴 변 최대 픽셀(기본 1024).
///  - [maxBytes]: 목표 최대 바이트(기본 300KB).
///  - [minQuality]: 더 낮추지 않는 하한 품질(기본 25).
///
/// 디코드 실패 시 null.
ImageCompressResult? compressForMms(
  Uint8List input, {
  int maxDimension = 1024,
  int maxBytes = 300 * 1024,
  int startQuality = 80,
  int minQuality = 25,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  // EXIF 회전 보정(세로/가로 방향 실물에 맞춤).
  decoded = img.bakeOrientation(decoded);

  // 긴 변 기준 축소(원본이 더 작으면 그대로).
  if (decoded.width > maxDimension || decoded.height > maxDimension) {
    if (decoded.width >= decoded.height) {
      decoded = img.copyResize(decoded, width: maxDimension);
    } else {
      decoded = img.copyResize(decoded, height: maxDimension);
    }
  }

  var quality = startQuality;
  Uint8List out = img.encodeJpg(decoded, quality: quality);
  while (out.length > maxBytes && quality > minQuality) {
    quality -= 10;
    out = img.encodeJpg(decoded, quality: quality);
  }

  return ImageCompressResult(
    bytes: out,
    width: decoded.width,
    height: decoded.height,
    quality: quality,
  );
}
