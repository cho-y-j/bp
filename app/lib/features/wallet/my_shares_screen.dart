import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../core/env.dart';
import '../../models/models.dart';
import '../../providers/wallet.dart';

class MySharesScreen extends ConsumerWidget {
  const MySharesScreen({super.key});

  String _shareUrl(ShareItem s) {
    // 백엔드 base(/api) → 웹 오리진 추정. 링크는 목록의 토큰으로 재구성.
    final base = Env.baseUrl.replaceFirst('/api', '');
    return '$base/s/${s.shareToken}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final shares = ref.watch(mySharesProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('내 공유')),
      body: SafeArea(
        child: shares.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(child: Text('불러오지 못했습니다: $e')),
          data: (list) => list.isEmpty
              ? Center(
                  child: Text('아직 공유한 서류 묶음이 없어요',
                      style: TextStyle(color: c.ink2, fontSize: 15)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = list[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: s.active
                                        ? c.deposited.withValues(alpha: 0.12)
                                        : c.ink2.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999)),
                                child: Text(s.active ? '활성' : '만료/무효',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: s.active
                                            ? c.depositedBadge
                                            : c.ink2)),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.visibility_outlined,
                                      size: 15, color: c.ink3),
                                  const SizedBox(width: 4),
                                  Text('열람 ${s.viewCount}회',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: c.ink2)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(s.docTypes.join(', '),
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: c.ink)),
                          const SizedBox(height: 4),
                          Text(
                              s.expiresAt == null
                                  ? ''
                                  : '${s.expiresAt!.year}-${s.expiresAt!.month.toString().padLeft(2, '0')}-${s.expiresAt!.day.toString().padLeft(2, '0')} 만료',
                              style: TextStyle(fontSize: 13, color: c.ink3)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (s.active)
                                TextButton.icon(
                                  onPressed: () {
                                    final box = context.findRenderObject()
                                        as RenderBox?;
                                    Share.share(_shareUrl(s),
                                        sharePositionOrigin: box != null
                                            ? box.localToGlobal(Offset.zero) &
                                                box.size
                                            : null);
                                  },
                                  icon: const Icon(Icons.share_rounded, size: 18),
                                  label: const Text('다시 공유'),
                                ),
                              const Spacer(),
                              if (s.active)
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(walletRepoProvider)
                                        .revokeShare(s.id);
                                    ref.invalidate(mySharesProvider);
                                  },
                                  child: Text('무효화',
                                      style: TextStyle(color: c.receivable)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
