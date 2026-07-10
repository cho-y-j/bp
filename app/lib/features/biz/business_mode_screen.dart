import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth.dart';
import '../../providers/biz.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'inbox_screen.dart';
import 'settlement_screen.dart';
import 'workers_screen.dart';
import 'jobs_screen.dart';
import 'safety_screen.dart';

/// 사업장 모드 진입 — hasBusiness 없으면 생성 플로우, 있으면 사업장 홈.
class BusinessModeScreen extends ConsumerWidget {
  const BusinessModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final businesses = ref.watch(myBusinessesProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('사업장 모드')),
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
            .showSnackBar(SnackBar(content: Text('생성 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Icon(Icons.storefront_rounded, size: 56, color: c.accentText),
        const SizedBox(height: 16),
        Text('사업장을 만들어 시작하세요',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 6),
        Text('작업자 연결·작업 지시·수신 확인서 서명·정산·안전 리포트를 한 곳에서.',
            style: TextStyle(fontSize: 15, color: c.ink2)),
        const SizedBox(height: 24),
        _field(_nameCtl, '상호 (예: 대성건설)'),
        const SizedBox(height: 12),
        _field(_bnoCtl, '사업자번호 (선택)'),
        const SizedBox(height: 24),
        PrimaryButton(
            label: '사업장 만들기',
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

class _BizHome extends StatelessWidget {
  final BusinessItem business;
  const _BizHome({required this.business});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
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
                      Text('초대코드 ${business.inviteCode}',
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
          title: '수신함',
          subtitle: '받은 작업확인서 확인·앱내 서명',
          onTap: () => _push(context, const InboxScreen()),
        ),
        _MenuCard(
          icon: Icons.payments_outlined,
          title: '정산',
          subtitle: '작업자별 미지급 집계·지급 처리',
          onTap: () => _push(context, const SettlementScreen()),
        ),
        _MenuCard(
          icon: Icons.groups_outlined,
          title: '작업자·지시',
          subtitle: '작업자 검색·연결·작업 지시 생성',
          onTap: () =>
              _push(context, WorkersScreen(business: business)),
        ),
        _MenuCard(
          icon: Icons.assignment_outlined,
          title: '작업 지시 목록',
          subtitle: '예약·진행·완료 상태 조회',
          onTap: () => _push(context, const JobsScreen()),
        ),
        _MenuCard(
          icon: Icons.health_and_safety_outlined,
          title: '안전',
          subtitle: '안전관리 리포트 PDF·최근 안전 기록',
          onTap: () => _push(context, const SafetyScreen()),
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen));
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
