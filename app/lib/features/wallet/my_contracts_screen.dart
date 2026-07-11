import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';
import '../biz/contracts_screen.dart' show ContractStatusBadge;
import 'received_contract_screen.dart';

/// 작업자 "내 계약서" — 받은 표준근로계약서 목록(SENT/SIGNED).
class MyContractsScreen extends ConsumerWidget {
  const MyContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final contracts = ref.watch(myContractsProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.lcMyContractsTitle)),
      body: SafeArea(
        child: contracts.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorRetry(
                  boxed: false,
                  onRetry: () => ref.invalidate(myContractsProvider)),
            ),
          ),
          data: (list) => list.isEmpty
              ? _Empty()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    for (final ct in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReceivedCard(
                          contract: ct,
                          onTap: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    ReceivedContractScreen(id: ct.id)));
                            ref.invalidate(myContractsProvider);
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 64, color: c.ink3),
          const SizedBox(height: 12),
          Text(l.lcMyEmptyTitle,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
          const SizedBox(height: 4),
          Text(l.lcMyEmptySub, style: TextStyle(fontSize: 14, color: c.ink2)),
        ],
      ),
    );
  }
}

class _ReceivedCard extends StatelessWidget {
  final LaborContract contract;
  final VoidCallback onTap;
  const _ReceivedCard({required this.contract, required this.onTap});
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
              CompanyAvatar(name: contract.businessName ?? contract.workplace),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(contract.businessName ?? contract.workplace,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: c.ink)),
                      ),
                      const SizedBox(width: 8),
                      ContractStatusBadge(status: contract.status),
                    ]),
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
