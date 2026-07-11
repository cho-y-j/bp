import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/file_pick.dart';
import '../../core/format.dart';
import '../../providers/wallet.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';

const kDocTypes = [
  '신분증',
  '사업자등록증',
  '자격증',
  '면허증',
  '장비등록증',
  '장비검사증',
  '보험증권',
  '보험가입증명서',
  '안전보건교육수료증',
  '건강진단서',
  '기타',
];

/// 업로드 플로우: 소스 선택 → 파일 픽 → 메타 입력 → 업로드.
/// 성공 시 생성된 DocumentItem 반환(마스킹 편집기로 이어질 수 있게 bytes 포함).
class UploadResult {
  final DocumentItem doc;
  final PickedDoc picked;
  UploadResult(this.doc, this.picked);
}

Future<UploadResult?> runUploadFlow(BuildContext context, WidgetRef ref,
    {String? presetType}) async {
  final source = ref.read(filePickSourceProvider);
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: context.c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _SourceSheet(),
  );
  if (choice == null) return null;

  PickedDoc? picked;
  try {
    picked = choice == 'pdf'
        ? await source.pickPdf()
        : await source.pickImage(fromCamera: choice == 'camera');
  } catch (_) {
    picked = null;
  }
  if (picked == null || !context.mounted) return null;

  final meta = await showModalBottomSheet<_UploadMeta>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _MetaSheet(preset: presetType, picked: picked!, ref: ref),
    ),
  );
  if (meta == null || !context.mounted) return null;

  try {
    final repo = ref.read(walletRepoProvider);
    final doc = await repo.upload(
      bytes: picked.bytes,
      filename: picked.filename,
      mime: picked.mime,
      type: meta.type,
      ownerType: meta.equipmentId != null ? 'EQUIPMENT' : 'PROFILE',
      equipmentId: meta.equipmentId,
      expiryDate: meta.expiryDate,
    );
    invalidateWallet(ref);
    return UploadResult(doc, picked);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l.docUploadFailed('$e'))));
    }
    return null;
  }
}

class _SourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    Widget tile(IconData icon, String label, String value) => ListTile(
          leading: Icon(icon, color: c.accentText),
          title: Text(label,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
          onTap: () => Navigator.pop(context, value),
        );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: c.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 6),
          tile(Icons.photo_camera_outlined, l.docSourceCamera, 'camera'),
          tile(Icons.photo_library_outlined, l.docSourceGallery, 'gallery'),
          tile(Icons.picture_as_pdf_outlined, l.docSourcePdf, 'pdf'),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _UploadMeta {
  final String type;
  final String? expiryDate;
  final String? equipmentId;
  _UploadMeta(this.type, this.expiryDate, this.equipmentId);
}

class _MetaSheet extends ConsumerStatefulWidget {
  final String? preset;
  final PickedDoc picked;
  final WidgetRef ref;
  const _MetaSheet({this.preset, required this.picked, required this.ref});
  @override
  ConsumerState<_MetaSheet> createState() => _MetaSheetState();
}

class _MetaSheetState extends ConsumerState<_MetaSheet> {
  late String _type = widget.preset ?? kDocTypes.first;
  DateTime? _expiry;
  String? _equipmentId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final equipments = ref.watch(equipmentsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.docInfoTitle,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 4),
            Text(widget.picked.mime == 'application/pdf'
                ? l.docFilePdf(widget.picked.filename)
                : l.docFileImage((widget.picked.bytes.length / 1024).round()),
                style: TextStyle(fontSize: 13, color: c.ink3)),
            const SizedBox(height: 16),
            Text(l.docTypeLabel,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.ink2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in kDocTypes)
                  ChoiceChip(
                    label: Text(t),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: c.primary.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _type == t ? c.accentText : c.ink2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 장비 연결 옵션
            equipments.maybeWhen(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.docLinkEquip,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.ink2)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                                label: Text(l.docPersonal),
                                selected: _equipmentId == null,
                                onSelected: (_) =>
                                    setState(() => _equipmentId = null)),
                            for (final eq in list)
                              ChoiceChip(
                                  label: Text(eq.vehicleNumber ?? eq.type),
                                  selected: _equipmentId == eq.id,
                                  onSelected: (_) =>
                                      setState(() => _equipmentId = eq.id)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            // 만료일
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _expiry ?? DateTime(now.year + 1, now.month, now.day),
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 20),
                );
                if (d != null) setState(() => _expiry = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                    color: c.fieldBg,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: 20, color: c.ink3),
                    const SizedBox(width: 10),
                    Text(
                        _expiry == null
                            ? l.docPickExpiry
                            : l.shareExpiry(dateParam(_expiry!)),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _expiry == null ? c.ink3 : c.ink)),
                    const Spacer(),
                    if (_expiry != null)
                      IconButton(
                          icon: Icon(Icons.close, size: 18, color: c.ink3),
                          onPressed: () => setState(() => _expiry = null)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l.docUpload,
              icon: Icons.upload_rounded,
              onPressed: () => Navigator.pop(
                  context,
                  _UploadMeta(
                      _type,
                      _expiry == null ? null : dateParam(_expiry!),
                      _equipmentId)),
            ),
          ],
        ),
      ),
    );
  }
}
