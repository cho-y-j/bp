import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/format.dart';
import '../../models/models.dart';

/// 시스템 공유 시트(카톡 등)로 확인서 열람 링크를 공유.
Future<void> shareConfirmationLink(
    BuildContext context, Confirmation conf, String url) async {
  final text = '[작업확인서] ${conf.siteName}\n'
      '${formatShortDate(conf.dateTime)} · ${formatWonUnit(conf.total)}\n'
      '아래 링크에서 내용을 확인하고 서명해 주세요.\n$url';
  final box = context.findRenderObject() as RenderBox?;
  await Share.share(
    text,
    subject: '작업확인서 · ${conf.siteName}',
    sharePositionOrigin:
        box != null ? box.localToGlobal(Offset.zero) & box.size : null,
  );
}
