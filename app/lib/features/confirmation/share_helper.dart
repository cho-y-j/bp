import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';

/// 시스템 공유 시트(카톡 등)로 확인서 열람 링크를 공유.
Future<void> shareConfirmationLink(
    BuildContext context, Confirmation conf, String url) async {
  final l = context.l;
  final lang = context.lang;
  final text = '${l.confShareHeader(conf.siteName)}\n'
      '${fmtShortDate(conf.dateTime, lang)} · ${formatMoney(conf.total, lang)}\n'
      '${l.confShareBody}\n$url';
  final box = context.findRenderObject() as RenderBox?;
  await Share.share(
    text,
    subject: l.confShareSubject(conf.siteName),
    sharePositionOrigin:
        box != null ? box.localToGlobal(Offset.zero) & box.size : null,
  );
}
