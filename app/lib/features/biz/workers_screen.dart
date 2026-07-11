import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';

class WorkersScreen extends ConsumerStatefulWidget {
  final BusinessItem business;
  const WorkersScreen({super.key, required this.business});
  @override
  ConsumerState<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends ConsumerState<WorkersScreen> {
  final _phoneCtl = TextEditingController();
  List<WorkerSearchItem> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    try {
      final res =
          await ref.read(bizRepoProvider).searchWorkers(_phoneCtl.text.trim());
      setState(() => _results = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.workerSearchFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _connect(WorkerSearchItem w) async {
    try {
      await ref.read(bizRepoProvider).requestConnection(
          businessId: widget.business.id, workerProfileId: w.profileId);
      ref.invalidate(allConnectionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l.workerConnectRequested(w.maskedName))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.workerRequestFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final connections = ref.watch(allConnectionsProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.workerTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // 전화 검색
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: l.workerSearchHint,
                      filled: true,
                      fillColor: c.fieldBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: c.border)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _searching ? null : _search,
                    style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.primaryInk),
                    child: Text(l.workerSearchButton),
                  ),
                ),
              ],
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final w in _results)
                _card(context,
                    title: w.maskedName,
                    subtitle: w.industryTags.join(', '),
                    trailing: TextButton(
                        onPressed: () => _connect(w),
                        child: Text(l.workerConnectButton))),
            ],
            const SizedBox(height: 20),
            Text(l.workerConnectedHeading,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 10),
            connections.when(
              loading: () => Center(
                  child: CircularProgressIndicator(color: c.primary)),
              error: (e, _) => ErrorRetry(
                  boxed: false,
                  onRetry: () => ref.invalidate(allConnectionsProvider)),
              data: (list) {
                final workers = list
                    .where((x) =>
                        x.role == 'BUSINESS' &&
                        x.businessId == widget.business.id)
                    .toList();
                if (workers.isEmpty) {
                  return Text(l.workerNoneConnected,
                      style: TextStyle(color: c.ink2, fontSize: 14));
                }
                return Column(
                  children: [
                    for (final conn in workers)
                      _card(context,
                          title: conn.workerName,
                          subtitle: conn.status == 'ACCEPTED'
                              ? l.workerStatusConnected
                              : l.workerStatusPending,
                          trailing: conn.status == 'ACCEPTED'
                              ? FilledButton(
                                  onPressed: () =>
                                      _createJob(context, conn),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: c.primary,
                                      foregroundColor: c.primaryInk),
                                  child: Text(l.workerJobButton),
                                )
                              : (conn.status == 'REQUESTED'
                                  ? TextButton(
                                      onPressed: () async {
                                        await ref
                                            .read(bizRepoProvider)
                                            .acceptConnection(conn.id);
                                        ref.invalidate(allConnectionsProvider);
                                      },
                                      child: Text(l.workerAccept))
                                  : null)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context,
      {required String title, String? subtitle, Widget? trailing}) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            CompanyAvatar(name: title),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.ink)),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _createJob(BuildContext context, ConnectionItem conn) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _JobForm(
          business: widget.business,
          workerProfileId: conn.workerId,
          workerName: conn.workerName),
    );
    if (created == true) {
      ref.invalidate(jobsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l.workerJobSent)));
      }
    }
  }
}

class _JobForm extends ConsumerStatefulWidget {
  final BusinessItem business;
  final String workerProfileId;
  final String workerName;
  const _JobForm(
      {required this.business,
      required this.workerProfileId,
      required this.workerName});
  @override
  ConsumerState<_JobForm> createState() => _JobFormState();
}

class _JobFormState extends ConsumerState<_JobForm> {
  final _siteCtl = TextEditingController();
  final _rateCtl = TextEditingController();
  String _rateType = 'DAILY';
  DateTime _scheduled = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  @override
  void dispose() {
    _siteCtl.dispose();
    _rateCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rate = int.tryParse(_rateCtl.text.replaceAll(',', '')) ?? 0;
    if (_siteCtl.text.trim().isEmpty || rate <= 0) return;
    setState(() => _saving = true);
    try {
      await ref.read(bizRepoProvider).createJob(
            businessId: widget.business.id,
            workerProfileId: widget.workerProfileId,
            site: _siteCtl.text.trim(),
            scheduledAt: _scheduled,
            rateType: _rateType,
            rate: rate,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.jobCreateFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 18,
            right: 18,
            top: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.jobFormTitle(widget.workerName),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 14),
            _field(_siteCtl, l.jobFormSiteHint),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _scheduled,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)));
                if (d == null || !context.mounted) return;
                final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_scheduled));
                setState(() => _scheduled = DateTime(
                    d.year, d.month, d.day, t?.hour ?? 8, t?.minute ?? 0));
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                    color: c.fieldBg,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 20, color: c.ink3),
                    const SizedBox(width: 10),
                    Text(
                        '${fmtShortDate(_scheduled, context.lang)} ${fmtAmpm('${_scheduled.hour.toString().padLeft(2, '0')}:${_scheduled.minute.toString().padLeft(2, '0')}', context.lang)}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.ink)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final rt in [
                  ['DAILY', l.jobRateDaily],
                  ['HOURLY', l.jobRateHourly],
                  ['PER_CASE', l.jobRatePerCase]
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(rt[1]),
                      selected: _rateType == rt[0],
                      onSelected: (_) => setState(() => _rateType = rt[0]),
                      selectedColor: c.primary.withValues(alpha: 0.18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _field(_rateCtl, l.jobFormRateHint, number: true),
            const SizedBox(height: 18),
            PrimaryButton(
                label: l.jobFormSubmit,
                icon: Icons.send_rounded,
                loading: _saving,
                onPressed: _submit),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctl, String hint, {bool number = false}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: c.fieldBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
      ),
    );
  }
}
