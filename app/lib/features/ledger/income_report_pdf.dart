import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth.dart';

/// 인증 헤더로 연간 소득 리포트 PDF blob 을 받아 임시 파일로 저장한 뒤,
/// 시스템 공유 시트(저장·카톡·메일 등)로 내보낸다.
Future<void> shareIncomeReport(
  WidgetRef ref,
  int year, {
  BuildContext? context,
}) async {
  final api = ref.read(apiClientProvider);
  final bytes =
      await api.getBytes('/ledger/income-report/pdf', query: {'year': '$year'});
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/income-report-$year.pdf');
  await file.writeAsBytes(bytes, flush: true);

  final box = context?.findRenderObject() as RenderBox?;
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    subject: '$year',
    sharePositionOrigin:
        box != null ? box.localToGlobal(Offset.zero) & box.size : null,
  );
}
