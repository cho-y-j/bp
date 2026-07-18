import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/api_client.dart';
import '../../core/image_compress.dart';
import '../../core/sms_template.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../providers/wallet.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'sms_share.dart';
import 'sms_templates.dart';

/// 빠른 보내기 — 기본 템플릿 3종(명함·사업자등록증·통장사본) + 커스텀 템플릿.
/// 템플릿 탭 → 수신인 입력/선택 + (이미지 첨부) → 문자 작성창 프리필.
class QuickSendScreen extends ConsumerWidget {
  /// 통화 후 카드 등에서 넘어온 수신인 프리필(선택).
  final String? presetRecipient;
  final String? presetRecipientName;
  const QuickSendScreen(
      {super.key, this.presetRecipient, this.presetRecipientName});

  List<SmsTemplate> _builtins(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final me = ref.read(authControllerProvider).profile?.name ?? '';
    return [
      SmsTemplate(
        id: 'builtin_card',
        title: l.tplCardTitle,
        body: l.tplCardBody('', me, ''),
        linkKind: SmsLinkKind.card,
        builtin: true,
        builtinKey: 'card',
      ),
      SmsTemplate(
        id: 'builtin_biz',
        title: l.tplBizTitle,
        body: l.tplBizBody('', me, ''),
        linkKind: SmsLinkKind.docShare,
        docType: '사업자',
        builtin: true,
        builtinKey: 'biz',
      ),
      SmsTemplate(
        id: 'builtin_bank',
        title: l.tplBankTitle,
        body: l.tplBankBody('', me, ''),
        linkKind: SmsLinkKind.docShare,
        docType: '통장',
        builtin: true,
        builtinKey: 'bank',
      ),
    ];
  }

  /// 최종 본문 생성 — 기본 템플릿은 l10n 실값, 커스텀은 변수 치환 엔진.
  String _renderBody(BuildContext context, WidgetRef ref, SmsTemplate t,
      {String? counterpartName, String? link}) {
    final l = context.l;
    final me = ref.read(authControllerProvider).profile?.name ?? '';
    final name = counterpartName ?? '';
    final lk = link ?? '';
    switch (t.builtinKey) {
      case 'card':
        return l.tplCardBody(name, me, lk);
      case 'biz':
        return l.tplBizBody(name, me, lk);
      case 'bank':
        return l.tplBankBody(name, me, lk);
    }
    return renderSmsTemplate(
      t.body,
      SmsTemplateContext(myName: me, counterpartName: counterpartName, link: link),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final builtins = _builtins(context, ref);
    final custom = ref.watch(customTemplatesProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.quickSendTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        backgroundColor: c.primary,
        foregroundColor: c.primaryInk,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.quickSendAddTemplate,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
          children: [
            Text(l.quickSendPickTemplate,
                style: TextStyle(fontSize: 14, color: c.ink2)),
            const SizedBox(height: 12),
            _sectionLabel(context, l.quickSendBuiltinSection),
            for (final t in builtins)
              _TemplateTile(
                template: t,
                onTap: () => _send(context, ref, t),
              ),
            if (custom.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionLabel(context, l.quickSendCustomSection),
              for (final t in custom)
                _TemplateTile(
                  template: t,
                  onTap: () => _send(context, ref, t),
                  onDelete: () =>
                      ref.read(customTemplatesProvider.notifier).remove(t.id),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.c.ink3)),
      );

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final t = await showModalBottomSheet<SmsTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _TemplateEditorSheet(),
    );
    if (t != null) {
      await ref.read(customTemplatesProvider.notifier).add(t);
    }
  }

  /// 템플릿 실행: 수신인/이미지 시트 → 링크·첨부 해석 → 문자 작성창.
  Future<void> _send(
      BuildContext context, WidgetRef ref, SmsTemplate t) async {
    final canImage = t.linkKind == SmsLinkKind.docShare ||
        t.linkKind == SmsLinkKind.docImage;
    final config = await showModalBottomSheet<_SendConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RecipientSheet(
        canAttachImage: canImage,
        presetRecipient: presetRecipient,
      ),
    );
    if (config == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // 링크/첨부 해석.
    String? link;
    final attachments = <String>[];
    try {
      switch (t.linkKind) {
        case SmsLinkKind.card:
          final card = await ref.read(myCardProvider.future);
          link = card.url;
          break;
        case SmsLinkKind.none:
          break;
        case SmsLinkKind.docShare:
        case SmsLinkKind.docImage:
          final docs = await ref.read(documentsProvider.future);
          final doc = _findDoc(docs, t.docType);
          if (doc == null) {
            if (context.mounted) {
              messenger.showSnackBar(SnackBar(
                  content: Text(context.l.quickSendNoDoc(t.docType ?? ''))));
            }
            return;
          }
          final wantImage =
              config.attachImage || t.linkKind == SmsLinkKind.docImage;
          if (wantImage) {
            final path = await _resolveAttachment(ref, doc);
            if (path != null) attachments.add(path);
          } else {
            final share = await ref.read(walletRepoProvider).createShare(
                documentIds: [doc.id], expiresInDays: 7);
            ref.invalidate(mySharesProvider);
            link = share.url;
          }
          break;
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    if (!context.mounted) return;

    // 본문 렌더(기본=l10n 실값 / 커스텀=변수 치환).
    var body = _renderBody(context, ref, t,
        counterpartName: config.recipientName, link: link);
    // 링크가 없으면(이미지 첨부) 끝에 남은 콜론/공백 정리.
    if (link == null || link.isEmpty) {
      body = body.replaceAll(RegExp(r'[:：]\s*$'), '').trimRight();
    }

    await composeSms(
      context,
      ref,
      recipients: config.recipient.isEmpty ? const [] : [config.recipient],
      body: body,
      attachments: attachments,
    );
  }

  DocumentItem? _findDoc(List<DocumentItem> docs, String? typeKeyword) {
    if (typeKeyword == null) return null;
    DocumentItem? match;
    for (final d in docs) {
      if (d.type.contains(typeKeyword)) {
        // 마스킹본이 있으면 우선.
        if (d.hasMask) return d;
        match ??= d;
      }
    }
    return match;
  }

  /// 첨부 파일 경로 해석 — 마스킹본(PDF) 우선, 없으면 원본 이미지 압축, 그 외 정규화 PDF.
  Future<String?> _resolveAttachment(
      WidgetRef ref, DocumentItem doc) async {
    final repo = ref.read(walletRepoProvider);
    final dir = await getTemporaryDirectory();
    if (doc.hasMask) {
      // 마스킹본은 PDF — 개인정보 보호를 위해 원본 대신 마스킹본을 첨부.
      final bytes = await repo.fileBytes(doc.id, variant: 'masked');
      final f = File('${dir.path}/${doc.type}_${doc.id}_masked.pdf');
      await f.writeAsBytes(bytes);
      return f.path;
    }
    if (doc.isImage) {
      final bytes = await repo.fileBytes(doc.id, variant: 'original');
      final compressed = compressForMms(bytes);
      final out = compressed?.bytes ?? bytes;
      final f = File('${dir.path}/${doc.type}_${doc.id}.jpg');
      await f.writeAsBytes(out);
      return f.path;
    }
    // 이미지 아님 → 정규화 PDF 첨부.
    final bytes = await repo.fileBytes(doc.id, variant: 'normalized');
    final f = File('${dir.path}/${doc.type}_${doc.id}.pdf');
    await f.writeAsBytes(bytes);
    return f.path;
  }
}

/// 수신인/첨부 설정 결과.
class _SendConfig {
  final String recipient; // 전화번호(빈 문자열 허용)
  final String? recipientName;
  final bool attachImage;
  const _SendConfig(
      {required this.recipient, this.recipientName, this.attachImage = false});
}

class _TemplateTile extends StatelessWidget {
  final SmsTemplate template;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _TemplateTile(
      {required this.template, required this.onTap, this.onDelete});

  IconData get _icon => switch (template.linkKind) {
        SmsLinkKind.card => Icons.badge_outlined,
        SmsLinkKind.docShare => Icons.description_outlined,
        SmsLinkKind.docImage => Icons.image_outlined,
        SmsLinkKind.none => Icons.sms_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(_icon, size: 22, color: c.accentText),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.ink)),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(template.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, color: c.ink3)),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: c.ink3),
                    onPressed: onDelete,
                  )
                else
                  Icon(Icons.send_outlined, size: 18, color: c.ink3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 수신인 입력 + 팀원 빠른 선택 + 이미지 첨부 옵션.
class _RecipientSheet extends ConsumerStatefulWidget {
  final bool canAttachImage;
  final String? presetRecipient;
  const _RecipientSheet(
      {required this.canAttachImage, this.presetRecipient});
  @override
  ConsumerState<_RecipientSheet> createState() => _RecipientSheetState();
}

class _RecipientSheetState extends ConsumerState<_RecipientSheet> {
  late final TextEditingController _phone;
  final _name = TextEditingController();
  bool _attachImage = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.presetRecipient ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final teams = ref.watch(teamsProvider).valueOrNull ?? const <Team>[];
    // 전화번호가 있는 팀원(연결 상대 후보).
    final candidates = <TeamMember>[
      for (final t in teams)
        for (final m in t.members)
          if ((m.phone ?? '').trim().isNotEmpty) m
    ];
    return Padding(
      padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.smsRecipientTitle,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 17, color: c.ink),
            decoration: InputDecoration(
              hintText: l.smsRecipientHint,
              prefixIcon: Icon(Icons.phone_outlined, size: 20, color: c.ink3),
              filled: true,
              fillColor: c.fieldBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border)),
            ),
          ),
          if (candidates.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l.smsPickConnection,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.ink3)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in candidates)
                  ActionChip(
                    label: Text(m.name),
                    onPressed: () => setState(() {
                      _phone.text = m.phone ?? '';
                      _name.text = m.name;
                    }),
                    backgroundColor: c.surface2,
                    side: BorderSide(color: c.border),
                  ),
              ],
            ),
          ],
          if (widget.canAttachImage) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.quickSendAttachImage,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.ink)),
                        Text(l.quickSendAttachImageSub,
                            style: TextStyle(fontSize: 12.5, color: c.ink3)),
                      ],
                    ),
                  ),
                  Switch(
                      value: _attachImage,
                      activeTrackColor: c.primary,
                      onChanged: (v) => setState(() => _attachImage = v)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: l.smsOpenCompose,
            icon: Icons.sms_outlined,
            onPressed: () => Navigator.pop(
              context,
              _SendConfig(
                recipient: _phone.text.trim(),
                recipientName:
                    _name.text.trim().isEmpty ? null : _name.text.trim(),
                attachImage: _attachImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 커스텀 템플릿 추가 편집기.
class _TemplateEditorSheet extends StatefulWidget {
  const _TemplateEditorSheet();
  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _docType = TextEditingController();
  SmsLinkKind _kind = SmsLinkKind.none;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _docType.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Padding(
      padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.tplEditorTitle,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 14),
            _field(_title, l.tplFieldTitle),
            const SizedBox(height: 10),
            _field(_body, l.tplFieldBody,
                hint: l.tplFieldBodyHint, maxLines: 3),
            const SizedBox(height: 6),
            Text('${l.tplVarsHelp}: ${smsTemplateVariables.join('  ')}',
                style: TextStyle(fontSize: 12.5, color: c.ink3)),
            const SizedBox(height: 12),
            Text(l.tplFieldLink,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.ink2)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              _kindChip(l.tplLinkNone, SmsLinkKind.none),
              _kindChip(l.tplLinkCard, SmsLinkKind.card),
              _kindChip(l.tplLinkDoc, SmsLinkKind.docShare),
            ]),
            if (_kind == SmsLinkKind.docShare) ...[
              const SizedBox(height: 10),
              _field(_docType, l.tplFieldDocType, hint: l.tplDocTypeHint),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: l.tplSaveTemplate,
              icon: Icons.check_rounded,
              onPressed: () {
                if (_title.text.trim().isEmpty ||
                    _body.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.tplNeedTitleBody)));
                  return;
                }
                Navigator.pop(
                  context,
                  SmsTemplate(
                    id: 'c_${DateTime.now().microsecondsSinceEpoch}',
                    title: _title.text.trim(),
                    body: _body.text.trim(),
                    linkKind: _kind,
                    docType: _kind == SmsLinkKind.docShare &&
                            _docType.text.trim().isNotEmpty
                        ? _docType.text.trim()
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindChip(String label, SmsLinkKind kind) {
    final c = context.c;
    final on = _kind == kind;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => setState(() => _kind = kind),
      selectedColor: c.primary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
          fontWeight: FontWeight.w700, color: on ? c.accentText : c.ink2),
    );
  }

  Widget _field(TextEditingController ctl, String label,
      {String? hint, int maxLines = 1}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      maxLines: maxLines,
      style: TextStyle(fontSize: 16, color: c.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: c.fieldBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
      ),
    );
  }
}
