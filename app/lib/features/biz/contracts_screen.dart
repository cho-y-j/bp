import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';
import 'contract_form_screen.dart';
import 'contract_detail_screen.dart';

/// 사업장(대표) 표준근로계약서 목록.
class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final contracts = ref.watch(bizContractsProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.lcKicker)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ContractFormScreen())),
        backgroundColor: c.primary,
        foregroundColor: c.primaryInk,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.lcNewContract,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: contracts.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorRetry(
                  boxed: false,
                  onRetry: () => ref.invalidate(bizContractsProvider)),
            ),
          ),
          data: (list) => list.isEmpty
              ? _Empty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    for (final ct in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ContractCard(
                          contract: ct,
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    ContractDetailScreen(id: ct.id)));
                            ref.invalidate(bizContractsProvider);
                          },
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 40, 18, 24),
      children: [
        PaperCard(
          stamp: l.lcStamp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.lcListEmptyTitle,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
              const SizedBox(height: 4),
              Text(l.lcListEmptySub,
                  style: TextStyle(fontSize: 14, color: c.ink2, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

/// 상태 배지 — 작성됨/전송됨/서명됨.
class ContractStatusBadge extends StatelessWidget {
  final String status;
  const ContractStatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    Color bg, fg;
    String text;
    IconData icon;
    switch (status) {
      case 'SIGNED':
        bg = c.deposited.withValues(alpha: 0.12);
        fg = c.depositedBadge;
        text = l.lcStatusSigned;
        icon = Icons.verified_rounded;
        break;
      case 'SENT':
        bg = c.primary.withValues(alpha: 0.14);
        fg = c.accentText;
        text = l.lcStatusSent;
        icon = Icons.send_outlined;
        break;
      default:
        bg = c.ink2.withValues(alpha: 0.12);
        fg = c.ink2;
        text = l.lcStatusDraft;
        icon = Icons.edit_note_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

class ContractCard extends StatelessWidget {
  final LaborContract contract;
  final VoidCallback onTap;
  const ContractCard({super.key, required this.contract, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
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
              CompanyAvatar(name: contract.workerName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(contract.workerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: c.ink)),
                        ),
                        const SizedBox(width: 8),
                        ContractStatusBadge(status: contract.status),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(contract.workplace,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, color: c.ink2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
