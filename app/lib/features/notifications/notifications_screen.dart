import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/notifications.dart';
import '../../widgets/common.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';

IconData _iconFor(String type) {
  switch (type) {
    case 'PAYMENT_DUE':
      return Icons.payments_outlined;
    case 'DOCUMENT_EXPIRY':
      return Icons.description_outlined;
    case 'RESERVATION':
      return Icons.event_available_outlined;
    case 'HEAT_ALERT':
      return Icons.wb_sunny_outlined;
    case 'TBM':
      return Icons.health_and_safety_outlined;
    default:
      return Icons.notifications_none_rounded;
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final notis = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.notiTitle)),
      body: SafeArea(
        child: notis.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorRetry(
                      boxed: false,
                      onRetry: () => ref.invalidate(notificationsProvider)))),
          data: (list) => list.items.isEmpty
              ? Center(
                  child: Text(l.notiEmpty,
                      style: TextStyle(color: c.ink2, fontSize: 15)))
              : RefreshIndicator(
                  color: c.primary,
                  onRefresh: () async => ref.invalidate(notificationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _NotiTile(noti: list.items[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotiTile extends ConsumerWidget {
  final NotificationItem noti;
  const _NotiTile({required this.noti});

  Future<void> _ack(BuildContext context, WidgetRef ref, AppLocalizations l,
      Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (!noti.read) {
        await ref.read(notificationsRepoProvider).markRead(noti.id);
      }
      ref.invalidate(notificationsProvider);
      messenger.showSnackBar(SnackBar(content: Text(l.notiAckDone)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.notiAckFailed('$e'))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final isHeat = noti.type == 'HEAT_ALERT';
    final isTbmAck = noti.type == 'TBM' && noti.tbmAttendeeId != null;
    return Material(
      color: noti.read ? c.surface : c.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: noti.read
            ? null
            : () async {
                await ref.read(notificationsRepoProvider).markRead(noti.id);
                ref.invalidate(notificationsProvider);
              },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: (isHeat ? c.warnInk : c.accentText)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(_iconFor(noti.type),
                    color: isHeat ? c.warnInk : c.accentText, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(noti.title,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: c.ink)),
                        ),
                        if (!noti.read)
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: c.primary, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(noti.body,
                        style: TextStyle(fontSize: 14, color: c.ink2)),
                    if (isHeat && noti.safetyLogId != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: FilledButton.icon(
                          onPressed: () => _ack(context, ref, l,
                              () => ref
                                  .read(notificationsRepoProvider)
                                  .ackSafety(noti.safetyLogId!)),
                          style: FilledButton.styleFrom(
                              backgroundColor: c.warnInk,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(l.confirm),
                        ),
                      ),
                    ],
                    if (isTbmAck) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: FilledButton.icon(
                          onPressed: () => _ack(context, ref, l,
                              () => ref
                                  .read(notificationsRepoProvider)
                                  .ackTbm(noti.tbmAttendeeId!)),
                          style: FilledButton.styleFrom(
                              backgroundColor: c.accentText,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(l.tbmAckButton),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
