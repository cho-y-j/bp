import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/tbm_view.dart';
import 'tbm_form_screen.dart';

/// 사업장 TBM 상세 — 내용 + 참석자 확인 현황 + 수정/삭제(당일).
class TbmDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final String businessId;
  const TbmDetailScreen({super.key, required this.id, required this.businessId});
  @override
  ConsumerState<TbmDetailScreen> createState() => _TbmDetailScreenState();
}

class _TbmDetailScreenState extends ConsumerState<TbmDetailScreen> {
  TbmRecord? _record;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ref.read(repoProvider).bizTbm(widget.id);
      if (mounted) setState(() { _record = r; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _delete() async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.tbmDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repoProvider).deleteTbm(widget.id);
      ref.invalidate(bizTbmProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.tbmDeleted)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final r = _record;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(l.tbmDetailTitle),
        actions: [
          if (r != null && r.editable) ...[
            IconButton(
              tooltip: l.tbmEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TbmFormScreen(
                        businessId: widget.businessId, editing: r)));
                setState(() => _loading = true);
                _load();
              },
            ),
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: c.primary))
            : _error != null
                ? Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ErrorRetry(
                            boxed: false,
                            onRetry: () {
                              setState(() { _loading = true; _error = null; });
                              _load();
                            })))
                : _content(context, r!),
      ),
    );
  }

  Widget _content(BuildContext context, TbmRecord r) {
    final c = context.c;
    final l = context.l;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TbmView(record: r, photoBase: 'biz'),
          const SizedBox(height: 18),
          if (!r.editable)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border)),
              child: Row(children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: c.ink3),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(l.tbmReadonly,
                        style: TextStyle(fontSize: 13, color: c.ink2))),
              ]),
            ),
          Text(l.tbmAttendeesStatus,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
          const SizedBox(height: 4),
          Text(l.tbmAckSummary(r.attendeeCount, r.ackCount),
              style: TextStyle(fontSize: 13, color: c.ink2)),
          const SizedBox(height: 10),
          for (final a in r.attendees) _AttendeeRow(a: a),
        ],
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  final TbmAttendee a;
  const _AttendeeRow({required this.a});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(a.linked ? Icons.link_rounded : Icons.edit_outlined,
            size: 18, color: c.ink3),
        const SizedBox(width: 10),
        Expanded(
          child: Text(a.name,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
        ),
        if (a.acked)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_rounded, size: 16, color: c.depositedBadge),
            const SizedBox(width: 4),
            Text(a.ackAt ?? l.tbmAcked,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.depositedBadge)),
          ])
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: c.ink3.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999)),
            child: Text(l.tbmNotAcked,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: c.ink3)),
          ),
      ]),
    );
  }
}
