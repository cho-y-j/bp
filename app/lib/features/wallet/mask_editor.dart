import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/mask_geometry.dart';
import '../../providers/wallet.dart';
import '../../widgets/common.dart';

/// 마스킹 편집기 — 문서 미리보기 위에 드래그로 사각형 영역 지정 →
/// 정규화 좌표(0~1)로 `POST /documents/:id/mask`.
class MaskEditorScreen extends ConsumerStatefulWidget {
  final String documentId;
  final Uint8List imageBytes;
  const MaskEditorScreen(
      {super.key, required this.documentId, required this.imageBytes});
  @override
  ConsumerState<MaskEditorScreen> createState() => _MaskEditorScreenState();
}

class _MaskEditorScreenState extends ConsumerState<MaskEditorScreen> {
  double _aspect = 0.7; // width/height
  final List<MaskRegion> _regions = [];
  Offset? _start;
  Offset? _end;
  Size _displaySize = Size.zero;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ui.decodeImageFromList(widget.imageBytes, (img) {
      if (mounted && img.height > 0) {
        setState(() => _aspect = img.width / img.height);
      }
    });
  }

  Future<void> _save() async {
    if (_regions.isEmpty) return;
    setState(() => _saving = true);
    // 루트 메신저/네비게이터를 await 이전에 캡처 → pop 후에도 안전.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(walletRepoProvider)
          .mask(widget.documentId, _regions);
      invalidateWallet(ref);
      if (!mounted) return;
      navigator.pop(true);
      messenger.showSnackBar(
          const SnackBar(content: Text('마스킹본을 만들었어요. 공유 시 개인정보가 가려집니다.')));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text('마스킹 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('개인정보 마스킹'),
        actions: [
          if (_regions.isNotEmpty)
            TextButton(
                onPressed: () => setState(() {
                      _regions.clear();
                    }),
                child: const Text('초기화')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Text('가릴 영역을 손가락으로 드래그해 사각형으로 지정하세요. (예: 주민번호·주소)',
                  style: TextStyle(fontSize: 14, color: c.ink2)),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(builder: (context, constraints) {
                    var w = constraints.maxWidth;
                    var h = w / _aspect;
                    if (h > constraints.maxHeight) {
                      h = constraints.maxHeight;
                      w = h * _aspect;
                    }
                    _displaySize = Size(w, h);
                    return GestureDetector(
                      onPanStart: (d) => setState(() {
                        _start = d.localPosition;
                        _end = d.localPosition;
                      }),
                      onPanUpdate: (d) => setState(() => _end = d.localPosition),
                      onPanEnd: (_) => setState(() {
                        if (_start != null && _end != null) {
                          final r = normalizeDragRect(
                              _start!, _end!, _displaySize);
                          if (r.width > 0.01 && r.height > 0.01) {
                            _regions.add(r);
                          }
                        }
                        _start = null;
                        _end = null;
                      }),
                      child: Container(
                        width: w,
                        height: h,
                        decoration: BoxDecoration(
                          border: Border.all(color: c.borderStrong),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned.fill(
                                child: Image.memory(widget.imageBytes,
                                    fit: BoxFit.fill)),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MaskPainter(
                                    _regions, _start, _end, _displaySize),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text('지정한 영역 ${_regions.length}개',
                      style: TextStyle(fontSize: 13, color: c.ink3)),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: '마스킹본 저장',
                    icon: Icons.security_rounded,
                    loading: _saving,
                    onPressed: _regions.isEmpty ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final List<MaskRegion> regions;
  final Offset? start;
  final Offset? end;
  final Size displaySize;
  _MaskPainter(this.regions, this.start, this.end, this.displaySize);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xE6111111);
    for (final r in regions) {
      canvas.drawRect(regionToDisplayRect(r, displaySize), fill);
    }
    if (start != null && end != null) {
      final rect = Rect.fromPoints(start!, end!);
      canvas.drawRect(rect, Paint()..color = const Color(0x66F4770C));
      canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0xFFF4770C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_MaskPainter old) => true;
}
