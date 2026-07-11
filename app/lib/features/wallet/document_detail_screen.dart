import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../providers/wallet.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';
import 'doc_ui.dart';
import 'mask_editor.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final DocumentItem doc;
  const DocumentDetailScreen({super.key, required this.doc});
  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  Uint8List? _preview;
  bool _loadingPreview = true;
  late DocumentItem _doc = widget.doc;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (!_doc.isImage) {
      setState(() => _loadingPreview = false);
      return;
    }
    try {
      final bytes = await ref.read(walletRepoProvider).fileBytes(_doc.id);
      if (mounted) setState(() => _preview = bytes);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _openPdf() async {
    try {
      final bytes =
          await ref.read(walletRepoProvider).fileBytes(_doc.id, variant: 'normalized');
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/${_doc.type}_${_doc.id}.pdf');
      await f.writeAsBytes(bytes);
      await OpenFilex.open(f.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.docOpenFailed('$e'))));
      }
    }
  }

  Future<void> _editExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _doc.expiryDate ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 20),
    );
    if (d == null) return;
    try {
      final updated =
          await ref.read(walletRepoProvider).updateExpiry(_doc.id, dateParam(d));
      invalidateWallet(ref);
      setState(() => _doc = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.docUpdateFailed('$e'))));
      }
    }
  }

  Future<void> _openMaskEditor() async {
    final bytes =
        _preview ?? await ref.read(walletRepoProvider).fileBytes(_doc.id);
    if (!mounted) return;
    final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) =>
          MaskEditorScreen(documentId: _doc.id, imageBytes: bytes),
    ));
    if (done == true) {
      setState(() => _doc = DocumentItem.fromJson({
            ..._docToJson(_doc),
            'hasMask': true,
          }));
    }
  }

  Map _docToJson(DocumentItem d) => {
        'id': d.id,
        'type': d.type,
        'ownerType': d.ownerType,
        'equipmentId': d.equipmentId,
        'status': d.status,
        'derivedStatus': d.derivedStatus,
        'dday': d.dday,
        'issuedDate': d.issuedDate?.toIso8601String(),
        'expiryDate': d.expiryDate?.toIso8601String(),
        'hasMask': d.hasMask,
        'mimeType': d.mimeType,
        'originalFileName': d.originalFileName,
      };

  Future<void> _delete() async {
    final l = context.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.docDeleteConfirmTitle),
        content: Text(l.docDeleteConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(walletRepoProvider).deleteDocument(_doc.id);
      invalidateWallet(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.docDeleteFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: Text(_doc.type),
        actions: [
          IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: c.receivable),
              onPressed: _delete),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            // 미리보기
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: _loadingPreview
                  ? Center(
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: c.primary)))
                  : _preview != null
                      ? Image.memory(_preview!, fit: BoxFit.contain)
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(docTypeIcon(_doc.type),
                                  size: 56, color: c.ink3),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _openPdf,
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: Text(l.docOpenPdf),
                              ),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            // 상태 배지 + 만료
            Row(
              children: [
                DocStatusBadge(doc: _doc),
                const SizedBox(width: 8),
                if (_doc.hasMask)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: c.deposited.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(l.docHasMask,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.depositedBadge)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _row(context, l.docExpiryDate,
                _doc.expiryDate == null ? l.docNone : dateParam(_doc.expiryDate!),
                onEdit: _editExpiry),
            if (_doc.issuedDate != null)
              _row(context, l.docIssuedDate, dateParam(_doc.issuedDate!)),
            const SizedBox(height: 20),
            if (_doc.isImage)
              PrimaryButton(
                label: _doc.hasMask ? l.docReMask : l.docMaskEdit,
                icon: Icons.security_rounded,
                onPressed: _openMaskEditor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {VoidCallback? onEdit}) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: TextStyle(fontSize: 14, color: c.ink2))),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
          const Spacer(),
          if (onEdit != null)
            TextButton(onPressed: onEdit, child: Text(context.l.docModify)),
        ],
      ),
    );
  }
}
