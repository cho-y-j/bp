import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/tbm_view.dart';

/// 작업자 "받은 TBM" 목록 — 내 안전 기록 · 확인.
class MyTbmScreen extends ConsumerWidget {
  const MyTbmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final items = ref.watch(myTbmProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.tbmMyTitle)),
      body: SafeArea(
        child: items.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorRetry(
                  boxed: false, onRetry: () => ref.invalidate(myTbmProvider)),
            ),
          ),
          data: (list) => list.isEmpty
              ? Center(
                  child: Text(l.tbmReceivedEmpty,
                      style: TextStyle(color: c.ink2, fontSize: 15)))
              : RefreshIndicator(
                  color: c.primary,
                  onRefresh: () async => ref.invalidate(myTbmProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      for (final it in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ReceivedCard(item: it),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ReceivedCard extends ConsumerStatefulWidget {
  final TbmReceivedItem item;
  const _ReceivedCard({required this.item});
  @override
  ConsumerState<_ReceivedCard> createState() => _ReceivedCardState();
}

class _ReceivedCardState extends ConsumerState<_ReceivedCard> {
  bool _acking = false;

  Future<void> _ack() async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _acking = true);
    try {
      await ref.read(repoProvider).ackTbm(widget.item.attendeeId);
      ref.invalidate(myTbmProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.tbmAckDone)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _acking = false);
      final msg = e.code == 'ALREADY_ACKED' ? l.tbmAlreadyAcked : e.message;
      messenger.showSnackBar(SnackBar(content: Text(l.tbmAckFailed(msg))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final it = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TbmView(record: it.record, photoBase: 'worker'),
        const SizedBox(height: 10),
        if (it.acked)
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: c.deposited.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.verified_rounded, color: c.depositedBadge, size: 20),
              const SizedBox(width: 8),
              Text(l.tbmAlreadyAcked,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.depositedBadge)),
            ]),
          )
        else
          PrimaryButton(
            label: l.tbmAckButton,
            icon: Icons.check_rounded,
            loading: _acking,
            onPressed: _ack,
          ),
      ],
    );
  }
}
