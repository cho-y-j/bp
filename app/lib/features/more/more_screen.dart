import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth.dart';
import '../wallet/wallet_screen.dart';
import '../biz/business_mode_screen.dart';
import '../jobs/my_jobs_screen.dart';
import '../notifications/notifications_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final profile = ref.watch(authControllerProvider).profile;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 2, 14),
              child: Text('더보기',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
            ),
            // 프로필 카드
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(15)),
                    alignment: Alignment.center,
                    child: Text(
                        (profile?.name?.isNotEmpty ?? false)
                            ? profile!.name!.characters.first
                            : '?',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: c.accentText)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.name ?? '이름 없음',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: c.ink)),
                        const SizedBox(height: 3),
                        Text(profile?.phone ?? '',
                            style: TextStyle(
                                fontSize: 14,
                                color: c.ink2,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                        if ((profile?.industryTags.isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              children: [
                                for (final t in profile!.industryTags)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: c.surface2,
                                      border: Border.all(color: c.border),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(t,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: c.ink2,
                                            fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('관리'),
            _Tile(
              icon: Icons.folder_outlined,
              title: '서류 지갑',
              subtitle: '자격증·보험·검사증 만료 관리 · 묶음 전송',
              onTap: () => _push(context, const WalletScreen()),
            ),
            _Tile(
              icon: Icons.storefront_outlined,
              title: profile?.hasBusiness == true ? '사업장 홈' : '사업장 모드',
              subtitle: '작업 지시·수신 확인서·정산·안전 리포트',
              onTap: () => _push(context, const BusinessModeScreen()),
            ),
            _Tile(
              icon: Icons.assignment_turned_in_outlined,
              title: '받은 작업',
              subtitle: '작업 지시 수락·시작·완료',
              onTap: () => _push(context, const MyJobsScreen()),
            ),
            const SizedBox(height: 20),
            _SectionLabel('설정'),
            _Tile(
              icon: Icons.notifications_none_rounded,
              title: '알림',
              subtitle: '수금·서류 만료·작업 예약·폭염 안전',
              onTap: () => _push(context, const NotificationsScreen()),
            ),
            _ConsentTile(
              value: profile?.phoneSearchConsent ?? false,
              onChanged: (v) =>
                  ref.read(authControllerProvider.notifier).setPhoneSearchConsent(v),
            ),
            _Tile(
              icon: Icons.logout_rounded,
              title: '로그아웃',
              danger: true,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('로그아웃 하시겠어요?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('취소')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('로그아웃')),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                }
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Text('작업온 v1.0.0 (S4b)',
                  style: TextStyle(fontSize: 12, color: c.ink3)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 전화검색 동의 토글.
class _ConsentTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ConsentTile({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.person_search_outlined, size: 22, color: c.ink2),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('전화번호 검색 허용',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.ink)),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('사업장이 내 번호로 나를 찾아 연결할 수 있어요',
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                  ),
                ],
              ),
            ),
            Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: c.primary),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(text,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: context.c.ink3)),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool danger;
  final VoidCallback? onTap;
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.danger = false,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: danger ? c.receivable : c.ink2),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: danger ? c.receivable : c.ink)),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!,
                              style: TextStyle(fontSize: 13, color: c.ink2)),
                        ),
                    ],
                  ),
                ),
                if (!danger)
                  Icon(Icons.chevron_right_rounded, color: c.ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
