import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';

class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key});
  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final Set<String> _payingWorkers = {};

  Future<void> _pay(SettlementWorker w) async {
    setState(() => _payingWorkers.add(w.workerProfileId));
    try {
      await ref.read(bizRepoProvider).pay(w.ledgerEntryIds);
      ref.invalidate(settlementsProvider);
      invalidateAll(ref); // 작업자 장부 대칭 반영
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l.settlePaidSnack(
                w.workerName, formatMoney(w.outstanding, context.lang)))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.settlePayFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _payingWorkers.remove(w.workerProfileId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final month = monthParam(_month);
    final workers = ref.watch(settlementsProvider(month));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.settleTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => setState(() =>
                          _month = DateTime(_month.year, _month.month - 1)),
                      icon: const Icon(Icons.chevron_left_rounded)),
                  Text(fmtMonth(_month, context.lang),
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.ink)),
                  IconButton(
                      onPressed: () => setState(() =>
                          _month = DateTime(_month.year, _month.month + 1)),
                      icon: const Icon(Icons.chevron_right_rounded)),
                ],
              ),
            ),
            Expanded(
              child: workers.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: c.primary)),
                error: (e, _) => Center(child: Text(l.bizLoadFailed('$e'))),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                        child: Text(l.settleEmpty,
                            style: TextStyle(color: c.ink2, fontSize: 15)));
                  }
                  final total =
                      list.fold<int>(0, (s, w) => s + w.outstanding);
                  return Column(
                    children: [
                      // 핵심 숫자·다음 행동을 상단 1스크린에 — 이번 달 지급할 돈 합계.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.settleMonthTotal,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: c.ink2)),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                    formatMoney(total, context.lang),
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: total > 0
                                            ? c.receivable
                                            : c.deposited,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ])),
                              ),
                              const SizedBox(height: 2),
                              Text(l.settleEntryCount(list.length),
                                  style:
                                      TextStyle(fontSize: 13, color: c.ink3)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final w = list[i];
                          final paying =
                              _payingWorkers.contains(w.workerProfileId);
                          return Container(
                            decoration: BoxDecoration(
                              color: c.surface,
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CompanyAvatar(name: w.workerName),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(w.workerName,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: c.ink)),
                                          Text(l.settleEntryCount(w.entryCount),
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: c.ink2)),
                                        ],
                                      ),
                                    ),
                                    MoneyLine(w.outstanding, received: false),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: FilledButton(
                                    onPressed: (paying || w.outstanding <= 0)
                                        ? null
                                        : () => _pay(w),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: c.primary,
                                      foregroundColor: c.primaryInk,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: paying
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: c.primaryInk))
                                        : Text(
                                            w.outstanding <= 0
                                                ? l.settlePaidDone
                                                : l.settlePayAmount(formatMoney(
                                                    w.outstanding, context.lang)),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
