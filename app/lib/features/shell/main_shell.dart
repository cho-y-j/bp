import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/push.dart';
import '../home/home_screen.dart';
import '../calendar/calendar_screen.dart';
import '../ledger/ledger_screen.dart';
import '../more/more_screen.dart';
import '../confirmation/confirmation_form_screen.dart';

/// 탭 인덱스 (다른 화면에서 탭 전환 시 사용).
final shellTabProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabs = [
    HomeScreen(),
    CalendarScreen(),
    LedgerScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 인증 완료 상태에서 진입하므로 FCM 토큰 등록 시도(설정 없으면 skip).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushServiceProvider).initAndRegister(ref);
    });
  }

  Future<void> _openNewConfirmation(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ConfirmationFormScreen(),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellTabProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: _WonTabBar(
        index: index,
        onTap: (i) => ref.read(shellTabProvider.notifier).state = i,
        onPlus: () => _openNewConfirmation(context),
      ),
    );
  }
}

class _WonTabBar extends StatelessWidget {
  final int index; // 0홈 1캘린더 2장부 3더보기 (탭 슬롯은 5개, 가운데 FAB)
  final ValueChanged<int> onTap;
  final VoidCallback onPlus;
  const _WonTabBar(
      {required this.index, required this.onTap, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _tab(context, 0, Icons.home_outlined, Icons.home_rounded, '홈'),
              _tab(context, 1, Icons.calendar_today_outlined,
                  Icons.calendar_today_rounded, '캘린더'),
              _plus(context),
              _tab(context, 2, Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded, '장부'),
              _tab(context, 3, Icons.menu_rounded, Icons.menu_rounded, '더보기'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i, IconData icon, IconData activeIcon,
      String label) {
    final c = context.c;
    final active = index == i;
    return Expanded(
      child: InkResponse(
        onTap: () => onTap(i),
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon,
                size: 24, color: active ? c.accentText : c.ink3),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? c.accentText : c.ink3)),
          ],
        ),
      ),
    );
  }

  Widget _plus(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: GestureDetector(
        onTap: onPlus,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 38,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: c.primary.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(Icons.add_rounded, color: c.primaryInk, size: 26),
            ),
            const SizedBox(height: 2),
            Text('작성',
                style: TextStyle(
                    height: 1.0,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.ink3)),
          ],
        ),
      ),
    );
  }
}
