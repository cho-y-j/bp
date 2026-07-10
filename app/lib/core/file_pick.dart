import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// 선택된 파일(바이트 + 메타).
class PickedDoc {
  final Uint8List bytes;
  final String filename;
  final String mime;
  const PickedDoc(
      {required this.bytes, required this.filename, required this.mime});
}

/// 파일 선택 소스 추상화 — 통합 테스트에서 네이티브 피커 대신 주입 가능.
abstract class FilePickSource {
  Future<PickedDoc?> pickImage({required bool fromCamera});
  Future<PickedDoc?> pickPdf();
}

String _mimeForExt(String? ext) {
  switch ((ext ?? '').toLowerCase()) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'heic':
      return 'image/heic';
    case 'webp':
      return 'image/webp';
    case 'pdf':
      return 'application/pdf';
    default:
      return 'application/octet-stream';
  }
}

class DefaultFilePickSource implements FilePickSource {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<PickedDoc?> pickImage({required bool fromCamera}) async {
    final x = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    final name = x.name.isNotEmpty ? x.name : 'photo.jpg';
    final ext = name.contains('.') ? name.split('.').last : 'jpg';
    return PickedDoc(bytes: bytes, filename: name, mime: _mimeForExt(ext));
  }

  @override
  Future<PickedDoc?> pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final f = res?.files.single;
    if (f == null || f.bytes == null) return null;
    return PickedDoc(
        bytes: f.bytes!,
        filename: f.name,
        mime: _mimeForExt(f.extension));
  }
}

/// 기본은 실제 네이티브 피커. 테스트에서 override 로 교체.
final filePickSourceProvider =
    Provider<FilePickSource>((ref) => DefaultFilePickSource());
