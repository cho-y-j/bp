import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';

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
            content: Text('${w.workerName}님에게 ${formatWonUnit(w.outstanding)} 지급 처리')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('지급 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _payingWorkers.remove(w.workerProfileId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final month = monthParam(_month);
    final workers = ref.watch(settlementsProvider(month));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('정산')),
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
                  Text(formatMonthK(_month),
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
                error: (e, _) => Center(child: Text('불러오지 못했습니다: $e')),
                data: (list) => list.isEmpty
                    ? Center(
                        child: Text('이번 달 미지급 내역이 없어요',
                            style: TextStyle(color: c.ink2, fontSize: 15)))
                    : ListView.separated(
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
                                          Text('${w.entryCount}건',
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
                                                ? '지급 완료'
                                                : '${formatWonUnit(w.outstanding)} 지급',
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
            ),
          ],
        ),
      ),
    );
  }
}
