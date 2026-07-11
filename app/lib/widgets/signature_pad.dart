import 'package:flutter/material.dart';
import '../core/signature.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_colors.dart';

/// 서명 상태(획 벡터) 보관 + PNG 내보내기 컨트롤러.
/// 웹 SignaturePad 처럼 획을 벡터로 보관 → 리사이즈/리빌드에도 보존, PNG 인코딩.
class SignaturePadController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;
  Size size = Size.zero;

  bool get isEmpty => _strokes.isEmpty && _current == null;

  List<List<Offset>> get strokes {
    final all = _strokes.map((s) => List<Offset>.from(s)).toList();
    if (_current != null && _current!.isNotEmpty) {
      all.add(List<Offset>.from(_current!));
    }
    return all;
  }

  void startStroke(Offset p) {
    _current = [p];
    notifyListeners();
  }

  void extend(Offset p) {
    _current?.add(p);
    notifyListeners();
  }

  void endStroke() {
    if (_current != null && _current!.isNotEmpty) {
      _strokes.add(_current!);
    }
    _current = null;
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    _current = null;
    notifyListeners();
  }

  /// 백엔드 서명 페이로드용 data URI (`data:image/png;base64,...`, ≤1MB 보정).
  Future<String> exportDataUri() =>
      encodeSignatureDataUri(strokes, size == Size.zero ? const Size(320, 180) : size);
}

class SignaturePad extends StatelessWidget {
  final SignaturePadController controller;
  final double height;
  const SignaturePad({super.key, required this.controller, this.height = 190});

  Offset _clamp(Offset p, Size s) =>
      Offset(p.dx.clamp(0.0, s.width), p.dy.clamp(0.0, s.height));

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, height);
      controller.size = size;
      return GestureDetector(
        onPanStart: (d) => controller.startStroke(_clamp(d.localPosition, size)),
        onPanUpdate: (d) => controller.extend(_clamp(d.localPosition, size)),
        onPanEnd: (_) => controller.endStroke(),
        child: Container(
          width: size.width,
          height: height,
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.borderStrong),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => CustomPaint(
              painter: _SignaturePainter(controller, c),
              size: size,
              child: controller.isEmpty
                  ? Center(
                      child: Text(context.l.signPadHint,
                          style: TextStyle(color: c.ink3, fontSize: 14)))
                  : const SizedBox.expand(),
            ),
          ),
        ),
      );
    });
  }
}

class _SignaturePainter extends CustomPainter {
  final SignaturePadController controller;
  final AppColors c;
  _SignaturePainter(this.controller, this.c) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // 서명선 아래 기준선.
    if (controller.isEmpty) {
      final base = Paint()
        ..color = c.border
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(24, size.height - 42),
          Offset(size.width - 24, size.height - 42), base);
    }
    final paint = Paint()
      ..color = kSignInk
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in controller.strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      if (stroke.length == 1) {
        path.lineTo(stroke.first.dx + 0.1, stroke.first.dy + 0.1);
      } else {
        for (var i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
