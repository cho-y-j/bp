import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../providers/auth.dart';

/// 인증 헤더로 월간 명세서 PDF blob 을 받아 임시 파일로 저장 후 시스템 뷰어로 연다.
Future<void> openMonthlyStatement(WidgetRef ref, String month) async {
  final api = ref.read(apiClientProvider);
  final bytes = await api.getBytes('/ledger/statement', query: {'month': month});
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/statement-$month.pdf');
  await file.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(file.path, type: 'application/pdf');
}
