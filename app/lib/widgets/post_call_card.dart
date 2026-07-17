import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/call_log.dart';
import '../l10n/l10n_ext.dart';
import '../providers/auth.dart';
import '../providers/data.dart';
import '../theme/app_colors.dart';
import '../features/sms/quick_send_screen.dart';
import '../features/sms/sms_share.dart';

/// 통화 후 제안 카드 — 앱 복귀 시 최근 통화가 있으면 상단에 노출.
/// [명함 보내기] [빠른 보내기] [닫기]. 같은 통화 1회, 설정 OFF 면 미노출.
class PostCallCard extends ConsumerWidget {
  const PostCallCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(callLogControllerProvider);
    final call = state.suggestion;
    if (call == null) return const SizedBox.shrink();
    final c = context.c;
    final l = context.l;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.10),
        border: Border.all(color: c.borderStrong),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.call_end_rounded, size: 20, color: c.accentText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    l.postCallTitle(call.name.isEmpty ? call.phone ?? '' : call.name),
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: c.ink)),
              ),
              InkResponse(
                onTap: () =>
                    ref.read(callLogControllerProvider.notifier).dismiss(),
                radius: 20,
                child: Icon(Icons.close_rounded, size: 20, color: c.ink3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.badge_outlined,
                  label: l.postCallSendCard,
                  filled: true,
                  onTap: () => _sendCard(context, ref, call),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.bolt_rounded,
                  label: l.postCallQuickSend,
                  filled: false,
                  onTap: () {
                    ref.read(callLogControllerProvider.notifier).dismiss();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => QuickSendScreen(
                        presetRecipient: call.phone,
                        presetRecipientName: call.name,
                      ),
                    ));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendCard(
      BuildContext context, WidgetRef ref, RecordedCall call) async {
    final messenger = ScaffoldMessenger.of(context);
    ref.read(callLogControllerProvider.notifier).dismiss();
    try {
      final card = await ref.read(myCardProvider.future);
      if (!context.mounted) return;
      final myName = ref.read(authControllerProvider).profile?.name ?? '';
      final body = context.l.tplCardBody(call.name, myName, card.url);
      await composeSms(
        context,
        ref,
        recipients: (call.phone ?? '').isEmpty ? const [] : [call.phone!],
        body: body,
      );
    } on ApiException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.filled,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: filled ? c.primary : c.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: filled ? c.primary : c.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18, color: filled ? c.primaryInk : c.accentText),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: filled ? c.primaryInk : c.accentText)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
