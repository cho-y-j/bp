import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../l10n/l10n_ext.dart';
import '../../l10n/app_localizations.dart';

String jobStatusLabel(String s, [AppLocalizations? l]) {
  switch (s) {
    case 'SCHEDULED':
      return l?.jobStatusScheduled ?? '예약';
    case 'IN_PROGRESS':
      return l?.jobStatusInProgress ?? '진행중';
    case 'DONE':
      return l?.jobStatusDone ?? '완료';
    default:
      return s;
  }
}

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final month = monthParam(DateTime.now());
    final jobs = ref.watch(jobsProvider(month));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.jobTitle)),
      body: SafeArea(
        child: jobs.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(child: Text(l.bizLoadFailed('$e'))),
          data: (list) {
            final bizJobs = list.where((j) => j.role == 'BUSINESS').toList();
            if (bizJobs.isEmpty) {
              return Center(
                  child: Text(l.jobEmpty,
                      style: TextStyle(color: c.ink2, fontSize: 15)));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bizJobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _JobTile(job: bizJobs[i]),
            );
          },
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final JobItem job;
  const _JobTile({required this.job});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    Color badgeColor;
    switch (job.status) {
      case 'DONE':
        badgeColor = c.depositedBadge;
        break;
      case 'IN_PROGRESS':
        badgeColor = c.accentText;
        break;
      default:
        badgeColor = c.ink2;
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
              Text(job.site,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: c.ink)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(jobStatusLabel(job.status, l),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              '${fmtShortDate(job.scheduledAt, context.lang)} · ${formatMoney(job.rate, context.lang)}'
              ' · ${job.acceptedAt != null ? l.jobAccepted : l.jobAcceptPending}',
              style: TextStyle(fontSize: 13, color: c.ink2)),
        ],
      ),
    );
  }
}
