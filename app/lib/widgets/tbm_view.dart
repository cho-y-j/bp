import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../core/tbm_hazards.dart';
import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import 'auth_image.dart';

/// TBM 기록 내용 렌더(사업장/작업자 공용). 위험요인은 현재 언어로 표시.
class TbmView extends StatelessWidget {
  final TbmRecord record;
  final String photoBase; // 'biz' | 'worker' (사진 열람 경로 표시용)
  const TbmView({super.key, required this.record, this.photoBase = 'biz'});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final labels = tbmHazardLabels(l, record.hazards);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.health_and_safety_outlined, color: c.accentText),
            const SizedBox(width: 8),
            Expanded(
              child: Text(record.site,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(record.occurredAt,
              style: TextStyle(
                  fontSize: 13,
                  color: c.ink2,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          if (record.businessName != null) ...[
            const SizedBox(height: 2),
            Text(record.businessName!,
                style: TextStyle(fontSize: 13, color: c.ink3)),
          ],
          const Divider(height: 24),
          _label(context, l.tbmHazards),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in labels)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.warnInk.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.warnInk.withValues(alpha: 0.4)),
                  ),
                  child: Text(h,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.warnInk)),
                ),
            ],
          ),
          if ((record.measures ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            _label(context, l.tbmMeasures),
            const SizedBox(height: 4),
            Text(record.measures!,
                style: TextStyle(fontSize: 14.5, color: c.ink, height: 1.4)),
          ],
          if ((record.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            _label(context, l.tbmNotes),
            const SizedBox(height: 4),
            Text(record.notes!,
                style: TextStyle(fontSize: 14, color: c.ink2, height: 1.4)),
          ],
          if (record.photoCount > 0) ...[
            const SizedBox(height: 16),
            _label(context, l.tbmPhotos),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final url in record.photoUrls)
                  AuthImage(path: _stripApi(url)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 서버 photoUrl 은 /api 프리픽스 포함 → apiClient base 가 /api 이므로 제거.
  String _stripApi(String url) =>
      url.startsWith('/api') ? url.substring(4) : url;

  Widget _label(BuildContext context, String text) => Text(text,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: context.c.ink3));
}
