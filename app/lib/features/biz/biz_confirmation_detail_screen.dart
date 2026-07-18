import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../providers/auth.dart';
import '../../widgets/common.dart';
import '../../widgets/signature_pad.dart';
import '../../l10n/l10n_ext.dart';

class BizConfirmationDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BizConfirmationDetailScreen({super.key, required this.id});
  @override
  ConsumerState<BizConfirmationDetailScreen> createState() =>
      _BizConfirmationDetailScreenState();
}

class _BizConfirmationDetailScreenState
    extends ConsumerState<BizConfirmationDetailScreen> {
  final _sig = SignaturePadController();
  final _nameCtl = TextEditingController();
  bool _signing = false;
  BizConfirmationDetail? _detail;
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
      final d = await ref.read(bizRepoProvider).confirmationDetail(widget.id);
      final me = ref.read(authControllerProvider).profile;
      if (mounted) {
        setState(() {
          _detail = d;
          _nameCtl.text = me?.name ?? '';
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
    if (_sig.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l.bizSignErrSign)));
      return;
    }
    if (_nameCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l.bizSignErrName)));
      return;
    }
    setState(() => _signing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dataUri = await _sig.exportDataUri();
      await ref.read(bizRepoProvider).signConfirmation(widget.id,
          signerName: _nameCtl.text.trim(), signImageBase64: dataUri);
      ref.invalidate(inboxProvider);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      setState(() => _signing = false);
      messenger.showSnackBar(
          SnackBar(content: Text(context.l.bizSignDone)));
    } catch (e) {
      if (mounted) {
        setState(() => _signing = false);
        messenger.showSnackBar(SnackBar(content: Text(context.l.bizSignFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(context.l.bizConfirmTitle)),
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
                : _content(context, _detail!),
      ),
    );
  }

  Widget _content(BuildContext context, BizConfirmationDetail d) {
    final c = context.c;
    final l = context.l;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        PaperCard(
          stamp: d.signed ? l.bizStampSigned : l.bizStampDefault,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.site,
                  style: TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 2),
              Text(d.workContent,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: c.ink2)),
              const SizedBox(height: 14),
              _line(context, l.paperWorker, d.workerName),
              _line(context, l.paperDate, d.date),
              _line(context, l.paperTime,
                  '${fmtAmpm(d.startTime, context.lang)} ~ ${fmtAmpm(d.endTime, context.lang)}'),
              _line(context, l.bizLineCounterpart, d.companyName),
              _line(context, l.bizLineRateType, d.rateTypeLabel),
              const Divider(height: 24),
              Row(
                children: [
                  Text(l.paperTotal,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.ink2)),
                  const Spacer(),
                  Text(formatMoney(d.total, context.lang),
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
              if (d.signed) ...[
                const SizedBox(height: 12),
                SignatureSeal(
                  signerName: d.signerName ?? '',
                  signedAtText: d.signedAt,
                  signImageDataUrl: d.signImageDataUrl,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!d.signed) ...[
          Text(l.bizSignInAppTitle,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
          const SizedBox(height: 4),
          Text(l.bizSignInAppDesc,
              style: TextStyle(fontSize: 13, color: c.ink2)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtl,
            decoration: InputDecoration(
              labelText: l.bizSignerNameLabel,
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                onPressed: () => setState(() => _sig.clear()),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l.bizSignRedraw)),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
              label: l.bizSignSubmit,
              icon: Icons.draw_rounded,
              loading: _signing,
              onPressed: _sign),
        ],
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 68,
              child: Text(label,
                  style: TextStyle(fontSize: 13.5, color: c.ink2))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
          ),
        ],
      ),
    );
  }
}
