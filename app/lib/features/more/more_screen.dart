import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../core/env.dart';
import '../../core/home_widget_bridge.dart';
import '../../core/kakao_auth.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/auth.dart';
import '../../providers/locale.dart';
import '../wallet/wallet_screen.dart';
import '../biz/business_mode_screen.dart';
import '../jobs/my_jobs_screen.dart';
import '../tax/tax_invoice_screen.dart';
import '../notifications/notifications_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  void _push(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
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
              child: Text(l.moreTitle,
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
                        Text(profile?.name ?? l.noName,
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
            _SectionLabel(l.sectionManage),
            _Tile(
              icon: Icons.folder_outlined,
              title: l.menuWallet,
              subtitle: l.menuWalletSub,
              onTap: () => _push(context, const WalletScreen()),
            ),
            _Tile(
              icon: Icons.storefront_outlined,
              title: profile?.hasBusiness == true ? l.menuBizHome : l.menuBizMode,
              subtitle: l.menuBizSub,
              onTap: () => _push(context, const BusinessModeScreen()),
            ),
            _Tile(
              icon: Icons.assignment_turned_in_outlined,
              title: l.menuJobs,
              subtitle: l.menuJobsSub,
              onTap: () => _push(context, const MyJobsScreen()),
            ),
            _Tile(
              icon: Icons.request_quote_outlined,
              title: l.menuTax,
              subtitle: l.menuTaxSub,
              onTap: () => _push(context, const TaxInvoiceScreen()),
            ),
            const SizedBox(height: 20),
            _SectionLabel(l.sectionSettings),
            _Tile(
              icon: Icons.notifications_none_rounded,
              title: l.menuNotifications,
              subtitle: l.menuNotificationsSub,
              onTap: () => _push(context, const NotificationsScreen()),
            ),
            const _LanguageTile(),
            _ConsentTile(
              value: profile?.phoneSearchConsent ?? false,
              onChanged: (v) =>
                  ref.read(authControllerProvider.notifier).setPhoneSearchConsent(v),
            ),
            // 카카오 계정 연결 — KAKAO_APP_KEY 주입 시에만 노출.
            if (Env.kakaoEnabled) const _KakaoLinkTile(),
            _Tile(
              icon: Icons.logout_rounded,
              title: l.logout,
              danger: true,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l.logoutConfirm),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l.cancel)),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l.logout)),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(authControllerProvider.notifier).logout();
                  // 홈 화면 위젯을 "로그인해 주세요" 상태로 클리어.
                  await HomeWidgetBridge.push(
                      HomeWidgetBridge.buildLoggedOut(l: l));
                }
              },
            ),
            const SizedBox(height: 24),
            Center(
              child: Text('작업온 v1.0.0 (P1)',
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
                  Text(context.l.consentTitle,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.ink)),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(context.l.consentSub,
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

/// 카카오 계정 연결 타일(조건부). 연결됨이면 상태 표시, 아니면 연결 시도.
class _KakaoLinkTile extends ConsumerStatefulWidget {
  const _KakaoLinkTile();
  @override
  ConsumerState<_KakaoLinkTile> createState() => _KakaoLinkTileState();
}

class _KakaoLinkTileState extends ConsumerState<_KakaoLinkTile> {
  bool _linking = false;

  Future<void> _link() async {
    setState(() => _linking = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = await KakaoAuth.obtainAccessToken();
      await ref.read(authControllerProvider.notifier).linkKakao(token);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(context.l.kakaoLinked)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final l = context.l;
      final msg = e.code == 'NOT_IMPLEMENTED'
          ? l.kakaoNotReady
          : e.code == 'KAKAO_ALREADY_LINKED'
              ? l.kakaoAlreadyLinked
              : l.kakaoLinkFailed(e.message);
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(context.l.kakaoLinkCanceled)));
      }
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final linked =
        ref.watch(authControllerProvider).profile?.kakaoLinked ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: (linked || _linking) ? null : _link,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 22, color: c.ink2),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l.kakaoLinkTitle,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.ink)),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                            linked ? context.l.kakaoLinkedSub : context.l.kakaoLinkSub,
                            style: TextStyle(fontSize: 13, color: c.ink2)),
                      ),
                    ],
                  ),
                ),
                if (_linking)
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: c.primary))
                else if (linked)
                  Icon(Icons.check_circle_rounded, color: c.deposited, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 언어 선택 타일 — 시스템 따름 + 6개 언어(자국어 표기). 선택은 shared_preferences 저장.
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final saved = ref.watch(localeControllerProvider);
    final current = saved == null ? l.languageSystem : langNative[saved.languageCode]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pick(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.language_rounded, size: 22, color: c.ink2),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(l.language,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.ink)),
                ),
                Text(current,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: c.ink2)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: c.ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final c = context.c;
    final l = context.l;
    final saved = ref.read(localeControllerProvider);
    final currentCode = saved?.languageCode;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        Widget row(String? code, String label) {
          final selected = code == currentCode;
          return ListTile(
            title: Text(label,
                style: TextStyle(
                    fontSize: 16,
                    color: c.ink,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
            trailing: selected
                ? Icon(Icons.check_rounded, color: c.primary)
                : null,
            onTap: () {
              ref.read(localeControllerProvider.notifier).setLang(code);
              Navigator.pop(ctx);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l.language,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: c.ink)),
                ),
              ),
              row(null, l.languageSystem),
              for (final code in supportedLangs) row(code, langNative[code]!),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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
