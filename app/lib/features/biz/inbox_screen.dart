import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../providers/biz.dart';
import 'biz_confirmation_detail_screen.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final inbox = ref.watch(inboxProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('수신함')),
      body: SafeArea(
        child: inbox.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(child: Text('불러오지 못했습니다: $e')),
          data: (list) => list.isEmpty
              ? Center(
                  child: Text('받은 확인서가 없어요',
                      style: TextStyle(color: c.ink2, fontSize: 15)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final it = list[i];
                    return Material(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  BizConfirmationDetailScreen(id: it.id)));
                          ref.invalidate(inboxProvider);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(it.site,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: c.ink)),
                                        const SizedBox(width: 8),
                                        _statusPill(c, it.signed),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                        '${it.workerName} · ${it.date} · ${formatWonUnit(it.total)}',
                                        style: TextStyle(
                                            fontSize: 13, color: c.ink2)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: c.ink3),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _statusPill(AppColors c, bool signed) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: signed
                ? c.deposited.withValues(alpha: 0.12)
                : c.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999)),
        child: Text(signed ? '서명완료' : '서명대기',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: signed ? c.depositedBadge : c.accentText)),
      );
}
