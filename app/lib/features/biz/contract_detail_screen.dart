import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../widgets/signature_pad.dart';
import '../../widgets/paper_labor_contract.dart';

/// 사업장(대표) 계약서 상세 — 열람 · 내 서명(사업주) · 전송 · PDF · 삭제.
class ContractDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ContractDetailScreen({super.key, required this.id});
  @override
  ConsumerState<ContractDetailScreen> createState() =>
      _ContractDetailScreenState();
}

class _ContractDetailScreenState extends ConsumerState<ContractDetailScreen> {
  final _sig = SignaturePadController();
  final _nameCtl = TextEditingController();
  bool _signing = false;
  bool _sending = false;
  bool _openingPdf = false;
  LaborContract? _contract;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sig.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ct = await ref.read(repoProvider).bizContract(widget.id);
      final me = ref.read(authControllerProvider).profile;
      if (mounted) {
        setState(() {
          _contract = ct;
          if (_nameCtl.text.isEmpty) _nameCtl.text = me?.name ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _sign() async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    if (_sig.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.lcSignErrPad)));
      return;
    }
    if (_nameCtl.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.lcSignErrName)));
      return;
    }
    setState(() => _signing = true);
    try {
      final dataUri = await _sig.exportDataUri();
      await ref.read(repoProvider).signEmployerContract(widget.id,
          signerName: _nameCtl.text.trim(), signImageBase64: dataUri);
      ref.invalidate(bizContractsProvider);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      setState(() => _signing = false);
      messenger.showSnackBar(SnackBar(content: Text(l.lcSigned)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _signing = false);
      messenger.showSnackBar(SnackBar(content: Text(l.lcSignFailed(e.message))));
    }
  }

  Future<void> _send() async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    final box = context.findRenderObject() as RenderBox?;
    try {
      final res = await ref.read(repoProvider).sendContract(widget.id);
      ref.invalidate(bizContractsProvider);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      setState(() => _sending = false);
      final linked = res['linked'] == true;
      final url = res['url']?.toString() ?? '';
      if (linked) {
        messenger.showSnackBar(SnackBar(content: Text(l.lcSentLinked)));
      } else if (url.isNotEmpty) {
        await Share.share('${l.lcKicker}\n${l.lcShareBody}\n$url',
            subject: l.lcKicker,
            sharePositionOrigin:
                box != null ? box.localToGlobal(Offset.zero) & box.size : null);
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(l.lcSentShare)));
        }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(l.lcSendFailed(e.message))));
    }
  }

  Future<void> _openPdf() async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _openingPdf = true);
    try {
      final api = ref.read(apiClientProvider);
      final bytes = await api.getBytes('/biz/contracts/${widget.id}/pdf');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/contract-${widget.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path, type: 'application/pdf');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.lcPdfFailed('$e'))));
    } finally {
      if (mounted) setState(() => _openingPdf = false);
    }
  }

  Future<void> _delete() async {
    final l = context.l;
    final c = context.c;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        content: Text(l.lcDeleteConfirm,
            style: TextStyle(color: c.ink, fontSize: 15)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete, style: TextStyle(color: c.receivable))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(repoProvider).deleteLaborContract(widget.id);
      ref.invalidate(bizContractsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.lcDeleted)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(l.lcDetailTitle),
        actions: [
          if (_contract != null && _contract!.isDraft)
            IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _delete),
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
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              _load();
                            })))
                : _content(context, _contract!),
      ),
    );
  }

  Widget _content(BuildContext context, LaborContract ct) {
    final l = context.l;
    final c = context.c;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaperLaborContract(c: ct),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openingPdf ? null : _openPdf,
            icon: _openingPdf
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: c.ink))
                : Icon(Icons.picture_as_pdf_outlined, size: 18, color: c.ink),
            label: Text(l.lcViewPdf,
                style: TextStyle(
                    color: c.ink, fontSize: 15, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.borderStrong),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          // 사업주 미서명 → 내 서명
          if (!ct.employerSigned) ...[
            Text(l.lcSignEmployerTitle,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 4),
            Text(l.lcSignEmployerDesc,
                style: TextStyle(fontSize: 13, color: c.ink2)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtl,
              decoration: InputDecoration(
                labelText: l.lcSignerNameLabel,
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
            const SizedBox(height: 12),
            SignaturePad(controller: _sig),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: () => setState(() => _sig.clear()),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l.lcSignRedraw)),
            ),
            const SizedBox(height: 4),
            PrimaryButton(
                label: l.lcSignSubmit,
                icon: Icons.draw_outlined,
                loading: _signing,
                onPressed: _sign),
          ] else if (ct.isDraft) ...[
            // 서명 완료 + 아직 미전송(DRAFT) → 전송
            PrimaryButton(
                label: l.lcSend,
                icon: Icons.send_outlined,
                loading: _sending,
                onPressed: _send),
          ] else if (ct.isSent) ...[
            // 전송됨, 작업자 서명 대기
            _statusBanner(context, Icons.hourglass_bottom_rounded,
                l.lcWaitingWorker, c.accentText),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _sending ? null : _send,
              icon: Icon(Icons.send_outlined, size: 18, color: c.ink),
              label: Text(l.lcSend,
                  style: TextStyle(
                      color: c.ink, fontSize: 15, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.borderStrong),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(
      BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
