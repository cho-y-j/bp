import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth.dart';
import '../../providers/biz.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';
import 'inbox_screen.dart';
import 'settlement_screen.dart';
import 'workers_screen.dart';
import 'jobs_screen.dart';
import 'safety_screen.dart';
import 'contracts_screen.dart';
import 'tbm_records_screen.dart';
import 'attendance_board_screen.dart';
import 'site_costs_screen.dart';
import 'wage_statement_screen.dart';

/// 사업장 모드 진입 — hasBusiness 없으면 생성 플로우, 있으면 사업장 홈.
class BusinessModeScreen extends ConsumerWidget {
  const BusinessModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final businesses = ref.watch(myBusinessesProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.bizModeTitle)),
      body: SafeArea(
        child: businesses.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorRetry(
                      boxed: false,
                      onRetry: () => ref.invalidate(myBusinessesProvider)))),
          data: (list) => list.isEmpty
              ? _CreateFlow()
              : _BizHome(business: list.first),
        ),
      ),
    );
  }
}

class _CreateFlow extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateFlow> createState() => _CreateFlowState();
}

class _CreateFlowState extends ConsumerState<_CreateFlow> {
  final _nameCtl = TextEditingController();
  final _bnoCtl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _bnoCtl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameCtl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(bizRepoProvider).createBusiness(
          name: _nameCtl.text.trim(), businessNumber: _bnoCtl.text.trim());
      ref.invalidate(myBusinessesProvider);
      await ref.read(authControllerProvider.notifier).refreshProfile();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.bizCreateFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Icon(Icons.storefront_rounded, size: 56, color: c.accentText),
        const SizedBox(height: 16),
        Text(l.bizCreateHeading,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 6),
        Text(l.bizCreateDesc,
            style: TextStyle(fontSize: 15, color: c.ink2)),
        const SizedBox(height: 24),
        _field(_nameCtl, l.bizNameHint),
        const SizedBox(height: 12),
        _field(_bnoCtl, l.bizBnoHint),
        const SizedBox(height: 24),
        PrimaryButton(
            label: l.bizCreateButton,
            icon: Icons.add_business_rounded,
            loading: _saving,
            onPressed: _create),
      ],
    );
  }

  Widget _field(TextEditingController ctl, String hint) {
    final c = context.c;
    return TextField(
      controller: ctl,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: c.fieldBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
      ),
    );
  }
}

class _BizHome extends ConsumerWidget {
  final BusinessItem business;
  const _BizHome({required this.business});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        const AttendanceBoardCard(),
        const _SelfBadgeCard(),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CompanyAvatar(name: business.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.ink)),
                    if (business.inviteCode != null)
                      Text(l.bizInviteCode(business.inviteCode!),
                          style: TextStyle(
                              fontSize: 13,
                              color: c.ink2,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _MenuCard(
          icon: Icons.inbox_rounded,
          title: l.inboxTitle,
          subtitle: l.bizMenuInboxDesc,
          onTap: () => _push(context, const InboxScreen()),
        ),
        _MenuCard(
          icon: Icons.payments_outlined,
          title: l.settleTitle,
          subtitle: l.bizMenuSettleDesc,
          onTap: () => _push(context, const SettlementScreen()),
        ),
        _MenuCard(
          icon: Icons.description_outlined,
          title: l.lcKicker,
          subtitle: l.lcMenuDesc,
          onTap: () => _push(context, const ContractsScreen()),
        ),
        _MenuCard(
          icon: Icons.receipt_long_outlined,
          title: l.siteCostsTitle,
          subtitle: l.bizMenuSiteCostsDesc,
          onTap: () => _push(context, const SiteCostsScreen()),
        ),
        _MenuCard(
          icon: Icons.request_quote_outlined,
          title: l.wageStmtTitle,
          subtitle: l.bizMenuWageStmtDesc,
          onTap: () => _push(context, const WageStatementScreen()),
        ),
        _MenuCard(
          icon: Icons.groups_outlined,
          title: l.workerTitle,
          subtitle: l.bizMenuWorkerDesc,
          onTap: () =>
              _push(context, WorkersScreen(business: business)),
        ),
        _MenuCard(
          icon: Icons.assignment_outlined,
          title: l.jobTitle,
          subtitle: l.bizMenuJobDesc,
          onTap: () => _push(context, const JobsScreen()),
        ),
        _MenuCard(
          icon: Icons.fact_check_outlined,
          title: l.tbmMenuTitle,
          subtitle: l.tbmMenuDesc,
          onTap: () =>
              _push(context, TbmRecordsScreen(businessId: business.id)),
        ),
        _MenuCard(
          icon: Icons.health_and_safety_outlined,
          title: l.safetyTitle,
          subtitle: l.bizMenuSafetyDesc,
          onTap: () => _push(context, const SafetyScreen()),
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen));
}

/// 사업장 지급 신뢰도 자체 배지 카드 (P3a).
/// EXCELLENT/GOOD 만 등급 라벨, NONE/INSUFFICIENT 는 개선 안내만(부정 배지 없음).
class _SelfBadgeCard extends ConsumerWidget {
  const _SelfBadgeCard();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final badge = ref.watch(myPaymentBadgeProvider);
    final data = badge.valueOrNull;
    if (data == null) return const SizedBox.shrink();
    final status = data['status']?.toString() ?? 'NONE';
    final avgDays = (data['avgDays'] as num?)?.round();
    final sample = (data['sampleSize'] as num?)?.toInt() ?? 0;
    final excellent = status == 'EXCELLENT';
    final good = status == 'GOOD';
    final graded = excellent || good;

    final String title;
    final String note;
    if (excellent) {
      title = '⚡ ${l.badgeExcellent}';
      note = avgDays != null
          ? '${l.badgeAvgDays(avgDays)} · ${l.badgeSampleCount(sample)}'
          : l.badgeSampleCount(sample);
    } else if (good) {
      title = l.badgeGood;
      note = l.badgeSelfImproveGood;
    } else if (status == 'INSUFFICIENT') {
      title = l.badgeSelfTitle;
      note = l.badgeInsufficient(sample);
    } else {
      title = l.badgeSelfTitle;
      note = l.badgeSelfImproveNone;
    }

    final accent = excellent ? c.deposited : (good ? c.primary : c.ink3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: graded ? accent.withValues(alpha: 0.08) : c.surface,
          border: Border.all(
              color: graded ? accent.withValues(alpha: 0.35) : c.border),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
                excellent
                    ? Icons.verified_rounded
                    : (good
                        ? Icons.thumb_up_alt_outlined
                        : Icons.insights_outlined),
                color: graded ? accent : c.ink3,
                size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: graded ? accent : c.ink)),
                  const SizedBox(height: 3),
                  Text(note,
                      style: TextStyle(fontSize: 13, color: c.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: c.accentText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.ink)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(fontSize: 13, color: c.ink2)),
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
