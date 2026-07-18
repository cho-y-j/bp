import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/wallet.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';
import 'doc_ui.dart';
import 'document_detail_screen.dart';
import 'upload_sheet.dart';
import 'mask_editor.dart';
import 'my_shares_screen.dart';
import 'equipment_screen.dart';
import 'my_contracts_screen.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});
  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _selectMode = false;
  final Set<String> _selected = {};

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _upload() async {
    final result = await runUploadFlow(context, ref);
    if (result != null && result.doc.isImage && mounted) {
      final l = context.l;
      // 업로드 직후 마스킹 편집 제안(방금 고른 이미지 바이트 재사용).
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.walletMaskPromptTitle),
          content: Text(l.walletMaskPromptBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.walletLater)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.walletMaskEdit)),
          ],
        ),
      );
      if (go == true && mounted) {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MaskEditorScreen(
              documentId: result.doc.id, imageBytes: result.picked.bytes),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final docs = ref.watch(documentsProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(_selectMode ? l.walletSelectedCount(_selected.length) : l.walletTitle,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
        actions: [
          if (!_selectMode) ...[
            IconButton(
                tooltip: l.lcMyContractsTitle,
                icon: const Icon(Icons.description_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MyContractsScreen()))),
            IconButton(
                tooltip: l.equipTitle,
                icon: const Icon(Icons.agriculture_outlined),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const EquipmentScreen()))),
            IconButton(
                tooltip: l.wshareTitle,
                icon: const Icon(Icons.link),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MySharesScreen()))),
          ],
          if (_selectMode)
            TextButton(
                onPressed: () => setState(() {
                      _selectMode = false;
                      _selected.clear();
                    }),
                child: Text(l.cancel)),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _upload,
              backgroundColor: c.primary,
              foregroundColor: c.primaryInk,
              icon: const Icon(Icons.add_rounded),
              label: Text(l.walletAddDoc,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: SafeArea(
        child: docs.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorRetry(
                      boxed: false,
                      onRetry: () => ref.invalidate(documentsProvider)))),
          data: (list) {
            final expiring = list
                .where((d) => d.derivedStatus == 'EXPIRED' ||
                    d.derivedStatus == 'EXPIRING' ||
                    d.derivedStatus == 'EXPIRING_SOON')
                .toList()
              ..sort((a, b) => (a.dday ?? 9999).compareTo(b.dday ?? 9999));
            return Column(
              children: [
                if (expiring.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: WarnBanner(
                      title: expiring.first.derivedStatus == 'EXPIRED'
                          ? l.walletExpiredTitle(expiring.first.type)
                          : l.walletExpiringTitle(expiring.first.type,
                              ddayUnified(l, expiring.first.dday)),
                      subtitle: expiring.length > 1
                          ? l.walletExpiringMultiSub(expiring.length)
                          : l.walletRenewHint,
                    ),
                  ),
                // 상시 노출 "선택해서 보내기" 버튼 — 롱프레스 은닉 대신 발견성 확보.
                if (list.isNotEmpty && !_selectMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _selectMode = true;
                          _selected.clear();
                        }),
                        icon: Icon(Icons.checklist_rounded,
                            size: 20, color: c.accentText),
                        label: Text(l.walletSelectSend,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.accentText)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: c.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: list.isEmpty
                      ? _empty(context)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, i) => _DocCard(
                            doc: list[i],
                            selectMode: _selectMode,
                            selected: _selected.contains(list[i].id),
                            onTap: () {
                              if (_selectMode) {
                                _toggleSelect(list[i].id);
                              } else {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) =>
                                        DocumentDetailScreen(doc: list[i])));
                              }
                            },
                            onLongPress: () => setState(() {
                              _selectMode = true;
                              _selected.add(list[i].id);
                            }),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _selectMode && _selected.isNotEmpty
          ? _SendBar(
              count: _selected.length,
              onSend: () => _openShareFlow(list: docs.value ?? []),
            )
          : null,
    );
  }

  Widget _empty(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: c.ink3),
          const SizedBox(height: 12),
          Text(l.walletEmptyTitle,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
          const SizedBox(height: 4),
          Text(l.walletEmptySub,
              style: TextStyle(fontSize: 14, color: c.ink2)),
        ],
      ),
    );
  }

  Future<void> _openShareFlow({required List<DocumentItem> list}) async {
    final selectedDocs =
        list.where((d) => _selected.contains(d.id)).toList();
    final anyMasked = selectedDocs.any((d) => d.hasMask);
    final days = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ShareOptionsSheet(anyMasked: anyMasked),
    );
    if (days == null || !mounted) return;
    try {
      final result = await ref.read(walletRepoProvider).createShare(
            documentIds: selectedDocs.map((d) => d.id).toList(),
            expiresInDays: days,
          );
      ref.invalidate(mySharesProvider);
      if (!mounted) return;
      setState(() {
        _selectMode = false;
        _selected.clear();
      });
      final box = context.findRenderObject() as RenderBox?;
      if (!mounted) return;
      final l = context.l;
      await Share.share(
        l.walletShareMessage(result.documentCount, days, result.url),
        subject: l.walletShareSubject,
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l.walletShareFailed('$e'))));
      }
    }
  }
}

class _DocCard extends StatelessWidget {
  final DocumentItem doc;
  final bool selectMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _DocCard({
    required this.doc,
    required this.selectMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(docTypeIcon(doc.type), size: 30, color: c.accentText),
                const Spacer(),
                if (selectMode)
                  Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: selected ? c.primary : c.ink3)
                else if (doc.hasMask)
                  Icon(Icons.security_rounded, size: 16, color: c.depositedBadge),
              ],
            ),
            const Spacer(),
            Text(doc.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 8),
            DocStatusBadge(doc: doc),
          ],
        ),
      ),
    );
  }
}

class _SendBar extends StatelessWidget {
  final int count;
  final VoidCallback onSend;
  const _SendBar({required this.count, required this.onSend});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: PrimaryButton(
          label: context.l.walletSendBundle(count),
          icon: Icons.send_outlined,
          onPressed: onSend,
        ),
      ),
    );
  }
}

class _ShareOptionsSheet extends StatefulWidget {
  final bool anyMasked;
  const _ShareOptionsSheet({required this.anyMasked});
  @override
  State<_ShareOptionsSheet> createState() => _ShareOptionsSheetState();
}

class _ShareOptionsSheetState extends State<_ShareOptionsSheet> {
  int _days = 7;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.walletBundleSend,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 12),
            Text(l.walletValidPeriod,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.ink2)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final d in [7, 14, 30])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l.daysCount(d)),
                      selected: _days == d,
                      onSelected: (_) => setState(() => _days = d),
                      selectedColor: c.primary.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _days == d ? c.accentText : c.ink2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: c.surface2,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(
                      widget.anyMasked
                          ? Icons.security_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: widget.anyMasked ? c.depositedBadge : c.ink3),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        widget.anyMasked
                            ? l.walletMaskedInfo
                            : l.walletUnmaskedInfo,
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: l.walletMakeLinkShare,
              icon: Icons.share_outlined,
              onPressed: () => Navigator.pop(context, _days),
            ),
          ],
        ),
      ),
    );
  }
}
