import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/notifications.dart';
import '../../widgets/common.dart';

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
    default:
      return Icons.notifications_none_rounded;
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final notis = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('알림')),
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
                  child: Text('알림이 없어요',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final isHeat = noti.type == 'HEAT_ALERT';
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
                          onPressed: () async {
                            try {
                              await ref
                                  .read(notificationsRepoProvider)
                                  .ackSafety(noti.safetyLogId!);
                              if (!noti.read) {
                                await ref
                                    .read(notificationsRepoProvider)
                                    .markRead(noti.id);
                              }
                              ref.invalidate(notificationsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('확인 처리되었습니다.')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('확인 실패: $e')));
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                              backgroundColor: c.warnInk,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('확인'),
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
