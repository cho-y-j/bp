import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/home_widget_bridge.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../providers/drafts.dart';
import '../../providers/notifications.dart';
import '../../widgets/common.dart';
import '../confirmation/confirmation_form_screen.dart';
import '../drafts/draft_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../wallet/wallet_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final now = DateTime.now();
    final month = monthParam(now);
    final today = dateParam(now);
    final profile = ref.watch(authControllerProvider).profile;
    final summary = ref.watch(ledgerSummaryProvider(month));
    final confirmations = ref.watch(confirmationsProvider(month));
    final expiring = ref.watch(expiringDocsProvider);

    // 홈 데이터가 로드되면 홈 화면 위젯(iOS/Android)에 오늘 일정·이번 달 미수금을
    // 공유 저장한다. 위젯은 네트워크 호출 없이 이 값을 렌더만 한다.
    if (profile != null && confirmations.hasValue && summary.hasValue) {
      final todays =
          confirmations.value!.items.where((x) => x.date == today).toList();
      final first = todays.isEmpty ? null : todays.first;
      final site = first?.siteName ?? '';
      final time = first == null
          ? ''
          : '${fmtAmpm(first.startTime, context.lang)} ~ ${fmtAmpm(first.endTime, context.lang)}';
      HomeWidgetBridge.push(HomeWidgetBridge.buildLoggedIn(
        l: l,
        lang: context.lang,
        site: site,
        time: time,
        outstanding: summary.value!.totalOutstanding,
        syncedAt: DateTime.now(),
      ));
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () async {
            invalidateAll(ref);
            // 새로고침 실패는 각 섹션의 ErrorRetry 로 표시되므로 여기서는 삼킨다.
            try {
              await ref.read(ledgerSummaryProvider(month).future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              // 인사 + 날짜
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 0, 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.homeGreeting(profile?.name ?? ''),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: c.ink)),
                          const SizedBox(height: 3),
                          Text(fmtFullDate(now, context.lang),
                              style: TextStyle(fontSize: 13.5, color: c.ink2)),
                        ],
                      ),
                    ),
                    _BellButton(),
                  ],
                ),
              ),

              // 전송 대기 초안 배너(오프라인 임시저장)
              const _DraftsBanner(),

              // 상황 무관 상시 노출 주 CTA — "확인서 쓰기".
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: PrimaryButton(
                  label: l.homeWriteConfirmation,
                  icon: Icons.add_rounded,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ConfirmationFormScreen(),
                    fullscreenDialog: true,
                  )),
                ),
              ),

              // 오늘 일정
              SectionTitle(l.homeToday),
              confirmations.when(
                loading: () => const _CardSkeleton(height: 120),
                error: (e, _) =>
                    ErrorRetry(onRetry: () => ref.invalidate(confirmationsProvider)),
                data: (list) {
                  final todays =
                      list.items.where((x) => x.date == today).toList();
                  if (todays.isEmpty) {
                    return _EmptyToday();
                  }
                  return Column(
                    children: [
                      for (final conf in todays)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TodayCard(conf: conf),
                        ),
                    ],
                  );
                },
              ),

              // 이번 달 요약
              SectionTitle(l.homeMonthSummary,
                  trailing: Text('${now.year}.${now.month.toString().padLeft(2, '0')} ›',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: c.accentText))),
              summary.when(
                loading: () => const _CardSkeleton(height: 150),
                error: (e, _) =>
                    ErrorRetry(onRetry: () => ref.invalidate(ledgerSummaryProvider)),
                data: (s) => _SummaryCard(summary: s),
              ),

              // 만료 임박 서류
              expiring.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (docs) {
                  final soon = docs.where((d) => (d.dday ?? 999) <= 30).toList()
                    ..sort((a, b) => (a.dday ?? 0).compareTo(b.dday ?? 0));
                  if (soon.isEmpty) return const SizedBox.shrink();
                  final d = soon.first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: Text(l.homeCheckNeeded,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.ink2)),
                        ),
                        WarnBanner(
                          title: l.homeDocExpiry(
                              d.type,
                              (d.dday ?? 0) < 0
                                  ? l.docExpired
                                  : ddayUnified(l, d.dday)),
                          subtitle: l.homeDocExpirySub,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const WalletScreen())),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 전송 대기 중인 오프라인 초안 배너(N건). 탭 → 초안 목록.
class _DraftsBanner extends ConsumerWidget {
  const _DraftsBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(draftQueueProvider);
    if (drafts.isEmpty) return const SizedBox.shrink();
    final c = context.c;
    final l = context.l;
    final hasError = drafts.any((d) => d.lastError != null);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DraftListScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.08),
              border: Border.all(color: c.borderStrong),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(hasError ? Icons.error_outline_rounded : Icons.cloud_upload_outlined,
                    color: c.accentText, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.homeDraftsPending(drafts.length),
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: c.ink)),
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                            hasError
                                ? l.homeDraftsError
                                : l.homeDraftsAuto,
                            style: TextStyle(fontSize: 13, color: c.ink2)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 홈 우상단 알림 벨 — 미읽음 뱃지.
class _BellButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))
            .then((_) => ref.invalidate(notificationsProvider));
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.notifications_none_rounded, color: c.ink2),
          ),
          if (unread > 0)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: c.receivable,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.bg, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(badgeCount(unread),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()])),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final Confirmation conf;
  const _TodayCard({required this.conf});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final equip = conf.equipmentSection;
    return PaperCard(
      stamp: conf.status == 'DRAFT' ? l.homeStampDraft : l.homeStampScheduled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conf.siteName,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
                    const SizedBox(height: 2),
                    Text(conf.workDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: c.ink2)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(l.homeTodayBadge,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: c.accentText)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metaRow(context, Icons.schedule_rounded,
              '${fmtAmpm(conf.startTime, context.lang)} ~ ${fmtAmpm(conf.endTime, context.lang)}'),
          const SizedBox(height: 7),
          _metaRow(context, Icons.business_rounded,
              conf.contact != null && conf.contact!.isNotEmpty
                  ? '${conf.companyName} · ${conf.contact}'
                  : conf.companyName),
          if (equip != null && (equip['name'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 7),
            _metaRow(context, Icons.agriculture_rounded,
                '${equip['name']}${equip['vehicleNumber'] != null ? ' · ${equip['vehicleNumber']}' : ''}'),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String text) {
    final c = context.c;
    return Row(
      children: [
        Icon(icon, size: 18, color: c.ink3),
        const SizedBox(width: 9),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
        ),
      ],
    );
  }
}

class _EmptyToday extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return PaperCard(
      stamp: l.homeStampToday,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.homeEmptyToday,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
          const SizedBox(height: 4),
          Text(l.homeEmptyTodaySub,
              style: TextStyle(fontSize: 14, color: c.ink2)),
        ],
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final LedgerSummary summary;
  const _SummaryCard({required this.summary});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final worked = summary.totalGongsu > 0
        ? l.daysWithGongsu(summary.daysWorked, formatGongsu(summary.totalGongsu))
        : l.daysCount(summary.daysWorked);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(l.homeDaysWorked,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: c.ink2)),
              const Spacer(),
              Text(worked,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: c.border),
          ),
          Row(
            children: [
              Expanded(
                child: _SumCell(
                  received: false,
                  caption: l.homeReceivable,
                  amount: summary.totalOutstanding,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SumCell(
                  received: true,
                  caption: l.homeReceived,
                  amount: summary.totalPaid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SumCell extends StatelessWidget {
  final bool received;
  final String caption;
  final int amount;
  const _SumCell(
      {required this.received, required this.caption, required this.amount});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = received ? c.deposited : c.receivable;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(received ? Icons.check_circle_outline_rounded : Icons.south_west_rounded,
                  size: 15, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(caption,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 금액은 줄바꿈/잘림 없이 한 줄 축소(scaleDown) — 긴 로케일 표기 대응.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(amount, context.lang),
                maxLines: 1,
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({required this.height});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
          child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: c.primary))),
    );
  }
}

