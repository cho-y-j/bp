import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';

/// 서류 유형별 아이콘.
IconData docTypeIcon(String type) {
  switch (type) {
    case '신분증':
      return Icons.badge_outlined;
    case '사업자등록증':
      return Icons.storefront_outlined;
    case '통장사본':
      return Icons.account_balance_outlined;
    case '자격증':
    case '면허증':
      return Icons.workspace_premium_outlined;
    case '경력증명서':
      return Icons.assignment_ind_outlined;
    case '보험증권':
    case '보험가입증명서':
      return Icons.verified_user_outlined;
    case '장비등록증':
      return Icons.agriculture_outlined;
    case '장비검사증':
      return Icons.fact_check_outlined;
    case '안전보건교육수료증':
      return Icons.health_and_safety_outlined;
    case '건강진단서':
      return Icons.monitor_heart_outlined;
    default:
      return Icons.description_outlined;
  }
}

/// 서류 만료 상태 색 (derivedStatus 기준).
class DocStatusBadge extends StatelessWidget {
  final DocumentItem doc;
  const DocStatusBadge({super.key, required this.doc});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (doc.expiryDate == null) {
      return _pill(c.ink2.withValues(alpha: 0.12), c.ink2, '만료일 없음', null);
    }
    final status = doc.derivedStatus;
    Color bg, fg;
    IconData icon;
    if (status == 'EXPIRED') {
      bg = c.warnBg;
      fg = c.warnInk;
      icon = Icons.warning_amber_rounded;
    } else if (status == 'EXPIRING_SOON') {
      bg = c.receivable.withValues(alpha: 0.12);
      fg = c.receivableBadge;
      icon = Icons.schedule_rounded;
    } else {
      bg = c.deposited.withValues(alpha: 0.12);
      fg = c.depositedBadge;
      icon = Icons.check_rounded;
    }
    final label = status == 'EXPIRED' ? '만료됨' : ddayLabel(doc.dday);
    return _pill(bg, fg, label, icon);
  }

  Widget _pill(Color bg, Color fg, String label, IconData? icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 3),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      );
}
