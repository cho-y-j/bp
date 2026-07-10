import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../providers/biz.dart';
import '../../widgets/common.dart';

class SafetyScreen extends ConsumerStatefulWidget {
  const SafetyScreen({super.key});
  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen> {
  bool _loading = false;

  Future<void> _openReport() async {
    setState(() => _loading = true);
    try {
      final month = monthParam(DateTime.now());
      final bytes = await ref.read(bizRepoProvider).safetyReport(month);
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/safety-report-$month.pdf');
      await f.writeAsBytes(bytes);
      await OpenFilex.open(f.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('리포트 열기 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('안전')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
          children: [
            Container(
              decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety_outlined,
                          color: c.accentText),
                      const SizedBox(width: 10),
                      Text('안전관리 이행 리포트',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.ink)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('컨디션 체크·서류 유효성·폭염 알림 기록을 월별 PDF로 확인하세요.',
                      style: TextStyle(fontSize: 14, color: c.ink2)),
                  const SizedBox(height: 16),
                  PrimaryButton(
                      label: '${formatMonthK(DateTime.now())} 리포트 열기',
                      icon: Icons.picture_as_pdf_rounded,
                      loading: _loading,
                      onPressed: _openReport),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: c.surface2,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: c.ink3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('폭염특보 시 연결된 작업자에게 자동으로 안전 알림이 발송되고 확인 기록이 남습니다.',
                        style: TextStyle(fontSize: 13, color: c.ink2)),
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
