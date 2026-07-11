import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../core/location.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../providers/data.dart';
import '../biz/jobs_screen.dart' show jobStatusLabel;

/// 작업자가 받은 작업 지시 — 수락/시작(컨디션)/완료.
class MyJobsScreen extends ConsumerStatefulWidget {
  const MyJobsScreen({super.key});
  @override
  ConsumerState<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends ConsumerState<MyJobsScreen> {
  final Set<String> _busy = {};

  Future<void> _run(String id, Future<void> Function() action) async {
    setState(() => _busy.add(id));
    try {
      await action();
      ref.invalidate(jobsProvider);
      invalidateAll(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.myjobFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _accept(JobItem j) =>
      _run(j.id, () => ref.read(bizRepoProvider).confirmJob(j.id));

  Future<void> _start(JobItem j) async {
    final condition = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l.myjobConditionTitle),
        content: Text(ctx.l.myjobConditionBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'BAD'),
              child: Text(ctx.l.myjobConditionBad)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, 'OK'),
              child: Text(ctx.l.myjobConditionGood)),
        ],
      ),
    );
    if (condition == null) return;
    await _run(j.id, () async {
      final gps = await tryGetPosition();
      await ref.read(bizRepoProvider).startJob(j.id,
          lat: gps.lat, lng: gps.lng, condition: condition);
    });
    if (mounted && condition == 'BAD') {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l.myjobConditionReported)));
    }
  }

  Future<void> _complete(JobItem j) => _run(j.id, () async {
        final gps = await tryGetPosition();
        await ref
            .read(bizRepoProvider)
            .completeJob(j.id, lat: gps.lat, lng: gps.lng);
      });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final month = monthParam(DateTime.now());
    final jobs = ref.watch(jobsProvider(month));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(context.l.menuJobs)),
      body: SafeArea(
        child: jobs.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(child: Text(context.l.myjobLoadFailed('$e'))),
          data: (list) {
            final mine = list.where((j) => j.role == 'WORKER').toList();
            if (mine.isEmpty) {
              return Center(
                  child: Text(context.l.myjobEmpty,
                      style: TextStyle(color: c.ink2, fontSize: 15)));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mine.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _tile(context, mine[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, JobItem j) {
    final c = context.c;
    final busy = _busy.contains(j.id);
    Widget? action;
    if (j.status == 'SCHEDULED' && j.acceptedAt == null) {
      action = _btn(context.l.myjobAccept, () => _accept(j), busy, c);
    } else if (j.status == 'SCHEDULED' && j.acceptedAt != null) {
      action = _btn(context.l.myjobStart, () => _start(j), busy, c);
    } else if (j.status == 'IN_PROGRESS') {
      action = _btn(context.l.myjobComplete, () => _complete(j), busy, c);
    }
    return Container(
      decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${j.businessName ?? ''} · ${j.site}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.ink)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: c.surface2, borderRadius: BorderRadius.circular(999)),
                child: Text(jobStatusLabel(j.status, context.l),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: c.ink2)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              '${fmtShortDate(j.scheduledAt, context.lang)} ${fmtAmpm('${j.scheduledAt.hour.toString().padLeft(2, '0')}:${j.scheduledAt.minute.toString().padLeft(2, '0')}', context.lang)} · ${formatMoney(j.rate, context.lang)}',
              style: TextStyle(fontSize: 13, color: c.ink2)),
          if (action != null) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, bool busy, AppColors c) =>
      SizedBox(
        height: 46,
        child: FilledButton(
          onPressed: busy ? null : onTap,
          style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.primaryInk,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: c.primaryInk))
              : Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}
