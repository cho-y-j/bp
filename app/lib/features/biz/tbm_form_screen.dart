import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/file_pick.dart';
import '../../core/tbm_hazards.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';

/// 간편 TBM 작성/수정 폼 (사업장 모드).
class TbmFormScreen extends ConsumerStatefulWidget {
  final String businessId;
  final TbmRecord? editing; // null = 신규
  const TbmFormScreen({super.key, required this.businessId, this.editing});
  @override
  ConsumerState<TbmFormScreen> createState() => _TbmFormScreenState();
}

class _TbmFormScreenState extends ConsumerState<TbmFormScreen> {
  final _site = TextEditingController();
  final _measures = TextEditingController();
  final _notes = TextEditingController();
  final _customHazard = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);

  final Set<String> _codes = {}; // 선택된 기본 프리셋 코드
  final List<String> _customHazards = []; // 커스텀/직접입력 위험요인 문구
  final Set<String> _attendeeProfileIds = {}; // 선택된 연결 작업자
  final Map<String, String> _attendeeNames = {}; // profileId -> name
  final List<String> _manualAttendees = []; // 수기 참석자 이름
  final List<PickedDoc> _photos = [];
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _site.addListener(() => setState(() {}));
    final e = widget.editing;
    if (e != null) {
      _site.text = e.site;
      _measures.text = e.measures ?? '';
      _notes.text = e.notes ?? '';
      final parts = e.date.split('-');
      if (parts.length == 3) {
        _date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
      final hm = e.occurredAt.split(' ');
      if (hm.length == 2) {
        final t = hm[1].split(':');
        if (t.length == 2) _time = TimeOfDay(hour: int.parse(t[0]), minute: int.parse(t[1]));
      }
      for (final h in e.hazards) {
        if (h.code != null && h.code!.isNotEmpty) {
          _codes.add(h.code!);
        } else if ((h.text ?? '').isNotEmpty) {
          _customHazards.add(h.text!);
        }
      }
      for (final a in e.attendees) {
        if (a.linked && a.profileId != null) {
          _attendeeProfileIds.add(a.profileId!);
          _attendeeNames[a.profileId!] = a.name;
        } else {
          _manualAttendees.add(a.name);
        }
      }
    }
  }

  @override
  void dispose() {
    _site.dispose();
    _measures.dispose();
    _notes.dispose();
    _customHazard.dispose();
    super.dispose();
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _valid =>
      _site.text.trim().isNotEmpty && (_codes.isNotEmpty || _customHazards.isNotEmpty);

  Map<String, dynamic> _body() {
    final hazards = <Map<String, dynamic>>[
      for (final code in _codes) {'code': code},
      for (final t in _customHazards) {'text': t},
    ];
    final attendees = <Map<String, dynamic>>[
      for (final pid in _attendeeProfileIds)
        {'profileId': pid, if (_attendeeNames[pid] != null) 'name': _attendeeNames[pid]},
      for (final n in _manualAttendees) {'name': n},
    ];
    return {
      if (!_isEdit) 'businessId': widget.businessId,
      'site': _site.text.trim(),
      'date': dateParam(_date),
      'time': _hhmm(_time),
      'hazards': hazards,
      if (_measures.text.trim().isNotEmpty) 'measures': _measures.text.trim(),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      'attendees': attendees,
    };
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(repoProvider);
      final TbmRecord rec = _isEdit
          ? await repo.updateTbm(widget.editing!.id, _body())
          : await repo.createTbm(_body());
      if (_photos.isNotEmpty) {
        await repo.uploadTbmPhotos(rec.id, _photos);
      }
      ref.invalidate(bizTbmProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
          SnackBar(content: Text(_isEdit ? l.tbmSaveUpdated : l.tbmSaved)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l.tbmSaveFailed(e.message))));
    }
  }

  Future<void> _addPhoto() async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final src = ref.read(filePickSourceProvider);
      final doc = await src.pickImage(fromCamera: false);
      if (doc != null && mounted) setState(() => _photos.add(doc));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.tbmPhotoFailed('$e'))));
    }
  }

  Future<void> _savePreset(String kind, String text) async {
    if (text.trim().isEmpty) return;
    try {
      await ref
          .read(repoProvider)
          .createTbmPreset(widget.businessId, kind, text.trim());
      ref.invalidate(tbmPresetsProvider(widget.businessId));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    final presets = ref.watch(tbmPresetsProvider(widget.businessId));
    final connections = ref.watch(allConnectionsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop()),
        title: Text(_isEdit ? l.tbmEdit : l.tbmFormTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              children: [
                PaperCard(
                  stamp: l.tbmStamp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(l.tbmSite),
                      _input(_site, l.tbmSiteHint,
                          icon: Icons.location_on_outlined),
                      const SizedBox(height: 14),
                      _Label(l.tbmDate),
                      _dateTimeBox(context, lang),
                      const SizedBox(height: 16),
                      _Label(l.tbmHazards),
                      Text(l.tbmHazardsHint,
                          style: TextStyle(fontSize: 12.5, color: c.ink3)),
                      const SizedBox(height: 8),
                      _hazardChips(context, presets.valueOrNull ?? const []),
                      const SizedBox(height: 10),
                      _customHazardAdder(context),
                      const SizedBox(height: 16),
                      _Label(l.tbmMeasures),
                      _measurePresetChips(context, presets.valueOrNull ?? const []),
                      _input(_measures, l.tbmMeasuresHint, maxLines: 2),
                      const SizedBox(height: 14),
                      _Label(l.tbmAttendees),
                      _attendeeSection(context, connections.valueOrNull ?? const []),
                      const SizedBox(height: 16),
                      _Label(l.tbmNotes),
                      _input(_notes, l.tbmNotesHint, maxLines: 2),
                      const SizedBox(height: 16),
                      _Label(l.tbmPhotos),
                      _photoSection(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: l.tbmSave,
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _valid ? _submit : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 위험요인 칩 (기본 프리셋 + 커스텀 프리셋) ──
  Widget _hazardChips(BuildContext context, List<TbmPreset> presets) {
    final l = context.l;
    final customs = presets.where((p) => p.kind == 'HAZARD').toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final code in tbmDefaultHazardCodes)
          _chip(tbmHazardCodeLabel(l, code), _codes.contains(code), () {
            setState(() {
              _codes.contains(code) ? _codes.remove(code) : _codes.add(code);
            });
          }),
        for (final p in customs)
          _chip(p.text, _customHazards.contains(p.text), () {
            setState(() {
              _customHazards.contains(p.text)
                  ? _customHazards.remove(p.text)
                  : _customHazards.add(p.text);
            });
          }, onLong: () => _confirmDeletePreset(p)),
      ],
    );
  }

  Widget _customHazardAdder(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미 추가된 직접입력 문구(칩 목록에 없는 것) 표시
        if (_customHazards.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _customHazards.where((x) => !_isPresetText(x)))
                  Chip(
                    label: Text(t),
                    onDeleted: () => setState(() => _customHazards.remove(t)),
                    backgroundColor: c.primary.withValues(alpha: 0.10),
                  ),
              ],
            ),
          ),
        Row(children: [
          Expanded(child: _input(_customHazard, l.tbmCustomHint)),
          const SizedBox(width: 8),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                final t = _customHazard.text.trim();
                if (t.isEmpty) return;
                setState(() {
                  if (!_customHazards.contains(t)) _customHazards.add(t);
                  _customHazard.clear();
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.primaryInk,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                final t = _customHazard.text.trim();
                if (t.isEmpty) return;
                await _savePreset('HAZARD', t);
                setState(() {
                  if (!_customHazards.contains(t)) _customHazards.add(t);
                  _customHazard.clear();
                });
              },
              child: Text(l.tbmPresetAddChip,
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
        ]),
      ],
    );
  }

  bool _isPresetText(String t) {
    final presets = ref.read(tbmPresetsProvider(widget.businessId)).valueOrNull ?? const [];
    return presets.any((p) => p.kind == 'HAZARD' && p.text == t);
  }

  Widget _measurePresetChips(BuildContext context, List<TbmPreset> presets) {
    final measures = presets.where((p) => p.kind == 'MEASURE').toList();
    if (measures.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in measures)
            ActionChip(
              label: Text(p.text),
              onPressed: () {
                final cur = _measures.text.trim();
                _measures.text = cur.isEmpty ? p.text : '$cur, ${p.text}';
              },
            ),
        ],
      ),
    );
  }

  // ── 참석자 ──
  Widget _attendeeSection(BuildContext context, List<ConnectionItem> conns) {
    final c = context.c;
    final l = context.l;
    final workers = conns
        .where((x) =>
            x.role == 'BUSINESS' &&
            x.businessId == widget.businessId &&
            x.status == 'ACCEPTED')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workers.isEmpty)
          Text(l.tbmNoConnections,
              style: TextStyle(fontSize: 13, color: c.ink3))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in workers)
                _chip(w.workerName, _attendeeProfileIds.contains(w.workerId), () {
                  setState(() {
                    if (_attendeeProfileIds.contains(w.workerId)) {
                      _attendeeProfileIds.remove(w.workerId);
                      _attendeeNames.remove(w.workerId);
                    } else {
                      _attendeeProfileIds.add(w.workerId);
                      _attendeeNames[w.workerId] = w.workerName;
                    }
                  });
                }, icon: Icons.person_outline_rounded),
            ],
          ),
        const SizedBox(height: 8),
        if (_manualAttendees.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in _manualAttendees)
                Chip(
                  avatar: Icon(Icons.edit_outlined, size: 16, color: c.ink3),
                  label: Text(n),
                  onDeleted: () => setState(() => _manualAttendees.remove(n)),
                ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addManualAttendee,
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: Text(l.tbmAddAttendeeManual),
          ),
        ),
      ],
    );
  }

  Future<void> _addManualAttendee() async {
    final l = context.l;
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tbmAddAttendeeManual),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(hintText: l.tbmAttendeeNameHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
              child: Text(l.save)),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _manualAttendees.add(name));
    }
  }

  // ── 사진 ──
  Widget _photoSection(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.editing != null && widget.editing!.photoCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l.tbmPhotoCount(widget.editing!.photoCount),
                style: TextStyle(fontSize: 13, color: c.ink2)),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _photos.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(_photos[i].bytes,
                        width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _photos.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            GestureDetector(
              onTap: _addPhoto,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: c.fieldBg,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_a_photo_outlined, color: c.ink3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeletePreset(TbmPreset p) async {
    final l = context.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(p.text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(repoProvider).deleteTbmPreset(p.id);
      ref.invalidate(tbmPresetsProvider(widget.businessId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.tbmPresetDeleted)));
      }
    }
  }

  // ── 공통 위젯 ──
  Widget _chip(String label, bool on, VoidCallback onTap,
      {IconData? icon, VoidCallback? onLong}) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLong,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: on ? c.primary.withValues(alpha: 0.14) : c.surface,
          border: Border.all(
              color: on ? c.accentText : c.border, width: on ? 1.5 : 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (on)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(Icons.check_rounded, size: 15, color: c.accentText),
              )
            else if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(icon, size: 15, color: c.ink3),
              ),
            Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: on ? c.accentText : c.ink2)),
          ],
        ),
      ),
    );
  }

  Widget _dateTimeBox(BuildContext context, String lang) {
    final c = context.c;
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.fieldBg,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.event_outlined, size: 18, color: c.ink3),
          const SizedBox(width: 10),
          Text('${fmtShortDate(_date, lang)}  ${fmtAmpm(_hhmm(_time), lang)}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: _time);
    setState(() {
      _date = d;
      if (t != null) _time = t;
    });
  }

  Widget _input(TextEditingController ctl, String hint,
      {IconData? icon, int maxLines = 1}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      maxLines: maxLines,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: c.ink3) : null,
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.c.ink2)),
      );
}
