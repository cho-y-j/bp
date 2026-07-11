import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/auth.dart';

/// 인증 헤더가 붙은 이미지 로더(사진 열람). path 는 apiClient base 기준(예: /biz/tbm/:id/photos/0).
class AuthImage extends ConsumerWidget {
  final String path;
  final double size;
  const AuthImage({super.key, required this.path, this.size = 88});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return FutureBuilder<List<int>>(
      future: ref.read(apiClientProvider).getBytes(path),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _box(c,
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: c.primary)));
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return _box(c,
              child: Icon(Icons.broken_image_outlined, color: c.ink3));
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(Uint8List.fromList(snap.data!),
              width: size, height: size, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _box(AppColors c, {required Widget child}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: c.fieldBg, borderRadius: BorderRadius.circular(10)),
        child: child,
      );
}
