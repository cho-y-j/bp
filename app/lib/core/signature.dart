import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 서명 잉크 색 (웹 SignaturePad 와 동일한 진한 네이비).
const Color kSignInk = Color(0xFF1A2233);

/// 서명 획(벡터)들을 투명 배경 PNG 바이트로 인코딩.
///
/// 웹 `SignaturePad` 와 동일하게 획을 벡터(캔버스 px 좌표)로 보관했다가
/// 리사이즈에도 보존되도록 리드로우하는 구조를 Flutter 로 이식한 것.
/// [size] 는 논리 캔버스 크기, [pixelRatio] 로 고해상도 렌더.
Future<Uint8List> encodeSignaturePng(
  List<List<Offset>> strokes,
  Size size, {
  double pixelRatio = 2.0,
  Color ink = kSignInk,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(pixelRatio);
  final paint = Paint()
    ..color = ink
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  for (final stroke in strokes) {
    if (stroke.isEmpty) continue;
    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    if (stroke.length == 1) {
      // 단일 탭(점)도 보이도록 아주 짧은 선분.
      path.lineTo(stroke.first.dx + 0.1, stroke.first.dy + 0.1);
    } else {
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  final picture = recorder.endRecording();
  final w = (size.width * pixelRatio).round().clamp(1, 8192);
  final h = (size.height * pixelRatio).round().clamp(1, 8192);
  final image = await picture.toImage(w, h);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return byteData!.buffer.asUint8List();
}

/// PNG 바이트 → data URI (`data:image/png;base64,...`). 백엔드 서명 페이로드 형식.
String toPngDataUri(Uint8List png) => 'data:image/png;base64,${base64Encode(png)}';

/// 최대 1MB 를 넘지 않도록 pixelRatio 를 낮춰가며 인코딩.
///
/// 백엔드는 base64 를 **디코드한 PNG 바이트 길이**를 1MB 와 비교하므로
/// (confirmations.service `decodeSignPng`: `buf.length > MAX_SIGN_BYTES`),
/// 여기서도 data URI 문자열 길이가 아니라 **PNG 바이트(`png.length`)** 기준으로 검사한다.
Future<String> encodeSignatureDataUri(
  List<List<Offset>> strokes,
  Size size, {
  int maxBytes = 1024 * 1024,
}) async {
  for (final ratio in [2.0, 1.5, 1.0]) {
    final png = await encodeSignaturePng(strokes, size, pixelRatio: ratio);
    if (png.length <= maxBytes) return toPngDataUri(png);
  }
  // 최저 해상도로도 초과 시 마지막 결과 반환(백엔드가 최종 거부하면 사용자에게 안내).
  final png = await encodeSignaturePng(strokes, size, pixelRatio: 1.0);
  return toPngDataUri(png);
}
