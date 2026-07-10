import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/amount_calc.dart';
import '../../core/api_client.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import 'share_helper.dart';

class _ExtraItem {
  String type; // OVERTIME/NIGHT/OTHER
  final TextEditingController rate = TextEditingController();
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController label = TextEditingController();
  _ExtraItem(this.type);
  void dispose() {
    rate.dispose();
    qty.dispose();
    label.dispose();
  }
}

class ConfirmationFormScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final Confirmation? copyFrom;
  const ConfirmationFormScreen({super.key, this.initialDate, this.copyFrom});
  @override
  ConsumerState<ConfirmationFormScreen> createState() => _FormState();
}

class _FormState extends ConsumerState<ConfirmationFormScreen> {
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  final _site = TextEditingController();
  bool _useBusiness = false;
  String? _businessId;
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _work = TextEditingController();
  String _rateType = 'DAILY';
  final _rate = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final List<_ExtraItem> _extras = [];
  bool _equipOn = false;
  final _equipName = TextEditingController();
  final _equipVehicle = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    final cf = widget.copyFrom;
    if (cf != null) _applyCopy(cf);
    for (final ctl in [_rate, _qty, _company, _contact, _site, _work]) {
      ctl.addListener(() => setState(() {}));
    }
  }

  void _applyCopy(Confirmation cf) {
    _site.text = cf.siteName;
    _work.text = cf.workDescription;
    _rateType = cf.rateType;
    _company.text = cf.companyName;
    _contact.text = cf.contact ?? '';
    _businessId = cf.businessId;
    _useBusiness = cf.businessId != null;
    final base = cf.amountCalc?['items'];
    if (base is List && base.isNotEmpty) {
      final b = base.first as Map;
      _rate.text = '${b['rate'] ?? ''}';
      _qty.text = '${b['quantity'] ?? 1}';
    }
    final eq = cf.equipmentSection;
    if (eq != null && (eq['name'] ?? '').toString().isNotEmpty) {
      _equipOn = true;
      _equipName.text = eq['name']?.toString() ?? '';
      _equipVehicle.text = eq['vehicleNumber']?.toString() ?? '';
    }
    final parts = cf.startTime.split(':');
    if (parts.length == 2) {
      _start = TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0);
    }
    final ep = cf.endTime.split(':');
    if (ep.length == 2) {
      _end = TimeOfDay(hour: int.tryParse(ep[0]) ?? 17, minute: int.tryParse(ep[1]) ?? 0);
    }
  }

  @override
  void dispose() {
    for (final ctl in [_site, _company, _contact, _work, _rate, _qty, _equipName, _equipVehicle]) {
      ctl.dispose();
    }
    for (final e in _extras) {
      e.dispose();
    }
    super.dispose();
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  AmountCalcResult _preview() {
    final rate = num.tryParse(_rate.text.trim()) ?? 0;
    final qty = num.tryParse(_qty.text.trim()) ?? 0;
    final extras = <AdditionalItemInput>[];
    for (final e in _extras) {
      extras.add(AdditionalItemInput(
        type: e.type,
        label: e.label.text.trim().isEmpty ? null : e.label.text.trim(),
        rate: num.tryParse(e.rate.text.trim()) ?? 0,
        quantity: num.tryParse(e.qty.text.trim()) ?? 0,
      ));
    }
    return calcAmount(rateType: _rateType, rate: rate, quantity: qty, additionalItems: extras);
  }

  num get _qtyValue => num.tryParse(_qty.text.trim()) ?? 0;

  bool get _valid {
    final rate = num.tryParse(_rate.text.trim()) ?? 0;
    final counterpartyOk = _useBusiness
        ? _businessId != null
        : _company.text.trim().isNotEmpty;
    return _site.text.trim().isNotEmpty &&
        _work.text.trim().isNotEmpty &&
        counterpartyOk &&
        rate > 0 &&
        _qtyValue > 0;
  }

  Future<void> _pickCopyFrom() async {
    final month = monthParam(DateTime.now());
    final list = await ref.read(confirmationsProvider(month).future);
    if (!mounted) return;
    if (list.items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('복사할 이전 확인서가 없어요.')));
      return;
    }
    final recent = list.items.reversed.take(10).toList();
    final picked = await showModalBottomSheet<Confirmation>(
      context: context,
      backgroundColor: context.c.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            Text('이전 확인서 복사',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: ctx.c.ink)),
            const SizedBox(height: 12),
            for (final conf in recent)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(conf.siteName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: ctx.c.ink, fontSize: 15)),
                subtitle: Text(
                    '${formatShortDate(conf.dateTime)} · ${conf.companyName} · ${formatWonUnit(conf.total)}',
                    style: TextStyle(color: ctx.c.ink2, fontSize: 13)),
                trailing: Icon(Icons.copy_rounded, color: ctx.c.accentText, size: 20),
                onTap: () => Navigator.of(ctx).pop(conf),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _applyCopy(picked));
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'date': dateParam(_date),
        'siteName': _site.text.trim(),
        'workDescription': _work.text.trim(),
        'startTime': _hhmm(_start),
        'endTime': _hhmm(_end),
        'rateType': _rateType,
        'rate': num.tryParse(_rate.text.trim()) ?? 0,
        'quantity': num.tryParse(_qty.text.trim()) ?? 0,
      };
      if (_useBusiness && _businessId != null) {
        body['businessId'] = _businessId;
      } else {
        body['companyName'] = _company.text.trim();
        if (_contact.text.trim().isNotEmpty) body['contact'] = _contact.text.trim();
      }
      final extras = _extras
          .where((e) => (num.tryParse(e.rate.text.trim()) ?? 0) > 0)
          .map((e) => {
                'type': e.type,
                if (e.type == 'OTHER' && e.label.text.trim().isNotEmpty)
                  'label': e.label.text.trim(),
                'rate': num.tryParse(e.rate.text.trim()) ?? 0,
                'quantity': num.tryParse(e.qty.text.trim()) ?? 0,
              })
          .toList();
      if (extras.isNotEmpty) body['additionalItems'] = extras;
      if (_equipOn && _equipName.text.trim().isNotEmpty) {
        body['equipmentSection'] = {
          'name': _equipName.text.trim(),
          if (_equipVehicle.text.trim().isNotEmpty)
            'vehicleNumber': _equipVehicle.text.trim(),
        };
      }
      if (_dueDate != null) body['dueDate'] = dateParam(_dueDate!);

      final repo = ref.read(repoProvider);
      final created = await repo.createConfirmation(body);
      final sendRes = await repo.send(created.id);
      invalidateAll(ref);
      if (!mounted) return;
      final linked = sendRes['linked'] == true;
      final url = sendRes['url']?.toString() ?? '';
      // 루트 메신저를 pop 이전에 캡처 → pop 후에도 안전하게 스낵바 표시.
      final messenger = ScaffoldMessenger.of(context);
      // 공유 시트는 화면이 살아있는 동안(pop 이전) 띄운다.
      if (!linked) {
        await shareConfirmationLink(context, created, url);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
          content: Text(linked
              ? '저장 완료 · 연결된 사업장에 전송했어요.'
              : '저장 완료 · 장부에 반영되었어요.')));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장 실패: ${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final calc = _preview();
    final connections = ref.watch(connectionsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop()),
        title: const Text('작업확인서 작성'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              children: [
                // 이전 확인서 복사
                _CopyButton(onTap: _pickCopyFrom),
                const SizedBox(height: 14),
                PaperCard(
                  stamp: '작 업 확 인 서',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: _FieldBox(
                            label: '작업일',
                            icon: Icons.calendar_today_outlined,
                            value: formatShortDate(_date),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FieldBox(
                            label: '시간',
                            icon: Icons.schedule_rounded,
                            value: '${_hhmm(_start)}~${_hhmm(_end)}',
                            onTap: _pickTimes,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _Label('현장'),
                      _input(_site, hint: '예) 래미안 원펜타스 3공구',
                          icon: Icons.location_on_outlined),
                      const SizedBox(height: 12),
                      _CounterpartySection(
                        useBusiness: _useBusiness,
                        businessId: _businessId,
                        connections: connections,
                        company: _company,
                        contact: _contact,
                        onModeChanged: (v) => setState(() => _useBusiness = v),
                        onBusinessChanged: (id) => setState(() => _businessId = id),
                      ),
                      const SizedBox(height: 12),
                      _Label('작업 내용'),
                      _input(_work,
                          hint: '작업한 내용을 적어주세요', maxLines: 3,
                          icon: null),
                      const SizedBox(height: 6),
                      _EquipmentToggle(
                        on: _equipOn,
                        name: _equipName,
                        vehicle: _equipVehicle,
                        onChanged: (v) => setState(() => _equipOn = v),
                      ),
                      const SizedBox(height: 12),
                      _Label('단가 유형'),
                      _RateSegments(
                        value: _rateType,
                        onChanged: (v) => setState(() => _rateType = v),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label(_rateType == 'HOURLY'
                                  ? '시급'
                                  : _rateType == 'PER_CASE'
                                      ? '건당 단가'
                                      : '일당'),
                              _numInput(_rate, hint: '0'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label(_rateType == 'HOURLY'
                                  ? '시간'
                                  : _rateType == 'PER_CASE'
                                      ? '건수'
                                      : '일수'),
                              _numInput(_qty, hint: '1'),
                            ],
                          ),
                        ),
                      ]),
                      if (_qtyValue <= 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 2),
                          child: Text(
                              _rateType == 'HOURLY'
                                  ? '시간을 1 이상 입력해 주세요.'
                                  : _rateType == 'PER_CASE'
                                      ? '건수를 1 이상 입력해 주세요.'
                                      : '일수를 1 이상 입력해 주세요.',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.receivable)),
                        ),
                      const SizedBox(height: 10),
                      _ExtrasSection(
                        extras: _extras,
                        onAdd: () => setState(() => _extras.add(_ExtraItem('OVERTIME'))),
                        onRemove: (e) => setState(() {
                          _extras.remove(e);
                          e.dispose();
                        }),
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      _CalcPreview(calc: calc, rateType: _rateType),
                      const SizedBox(height: 12),
                      _FieldBox(
                        label: '수금 예정일 (선택)',
                        icon: Icons.event_available_outlined,
                        value: _dueDate == null ? '미설정' : formatShortDate(_dueDate!),
                        onTap: _pickDueDate,
                      ),
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
              child: Column(
                children: [
                  PrimaryButton(
                    label: '저장하고 보내기',
                    icon: Icons.send_rounded,
                    loading: _saving,
                    onPressed: _valid ? _submit : null,
                  ),
                  const SizedBox(height: 8),
                  Text('저장 즉시 장부에 반영됩니다 · 링크로 전송',
                      style: TextStyle(fontSize: 13, color: c.ink3)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickDueDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  Future<void> _pickTimes() async {
    final s = await showTimePicker(
        context: context, initialTime: _start, helpText: '시작 시각');
    if (s == null) return;
    if (!mounted) return;
    final e = await showTimePicker(
        context: context, initialTime: _end, helpText: '종료 시각');
    setState(() {
      _start = s;
      if (e != null) _end = e;
    });
  }

  Widget _input(TextEditingController ctl,
      {required String hint, IconData? icon, int maxLines = 1}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      maxLines: maxLines,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: c.ink3) : null,
      ),
    );
  }

  Widget _numInput(TextEditingController ctl, {required String hint}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: c.ink,
          fontFeatures: const [FontFeature.tabularFigures()]),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

// ── 하위 위젯들 ─────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: context.c.ink2)),
      );
}

class _CopyButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CopyButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: c.borderStrong),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.content_copy_rounded, size: 20, color: c.accentText),
            const SizedBox(width: 11),
            Text('이전 확인서 복사',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: c.ink3),
          ]),
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  const _FieldBox(
      {required this.label,
      required this.icon,
      required this.value,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        InkWell(
          onTap: onTap,
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
              Icon(icon, size: 18, color: c.ink3),
              const SizedBox(width: 10),
              Expanded(
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _CounterpartySection extends StatelessWidget {
  final bool useBusiness;
  final String? businessId;
  final AsyncValue<List<ConnectionItem>> connections;
  final TextEditingController company;
  final TextEditingController contact;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<String?> onBusinessChanged;
  const _CounterpartySection({
    required this.useBusiness,
    required this.businessId,
    required this.connections,
    required this.company,
    required this.contact,
    required this.onModeChanged,
    required this.onBusinessChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final conns = connections.valueOrNull ?? const [];
    final hasConns = conns.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('지시자 (회사)'),
        if (hasConns)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              _modeChip(context, '연결 사업장', useBusiness, () => onModeChanged(true)),
              const SizedBox(width: 8),
              _modeChip(context, '직접 입력', !useBusiness, () => onModeChanged(false)),
            ]),
          ),
        if (useBusiness && hasConns)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.fieldBg,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: businessId,
                hint: Text('연결 사업장 선택',
                    style: TextStyle(color: c.ink3, fontSize: 16)),
                icon: Icon(Icons.expand_more_rounded, color: c.ink3),
                items: [
                  for (final conn in conns)
                    DropdownMenuItem(
                      value: conn.businessId,
                      child: Text(conn.businessName,
                          style: TextStyle(
                              color: c.ink, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                ],
                onChanged: onBusinessChanged,
              ),
            ),
          )
        else
          Column(children: [
            TextField(
              controller: company,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
              decoration: InputDecoration(
                hintText: '회사/현장 담당 상호',
                prefixIcon: Icon(Icons.business_rounded, size: 20, color: c.ink3),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contact,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
              decoration: InputDecoration(
                hintText: '담당자/연락처 (선택)',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: c.ink3),
              ),
            ),
          ]),
      ],
    );
  }

  Widget _modeChip(BuildContext context, String label, bool on, VoidCallback onTap) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? c.primary.withValues(alpha: 0.12) : c.surface,
          border: Border.all(color: on ? c.accentText : c.border, width: on ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: on ? c.accentText : c.ink2)),
      ),
    );
  }
}

class _EquipmentToggle extends StatelessWidget {
  final bool on;
  final TextEditingController name;
  final TextEditingController vehicle;
  final ValueChanged<bool> onChanged;
  const _EquipmentToggle(
      {required this.on,
      required this.name,
      required this.vehicle,
      required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Column(
        children: [
          Row(children: [
            Icon(Icons.agriculture_outlined, size: 20, color: c.accentText),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('장비 섹션',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                Text('확인서에 자동 포함',
                    style: TextStyle(fontSize: 13, color: c.ink3)),
              ],
            ),
            const Spacer(),
            Switch(
              value: on,
              onChanged: onChanged,
              activeTrackColor: c.primary,
            ),
          ]),
          if (on) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                  decoration: const InputDecoration(hintText: '장비명', isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: vehicle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                  decoration: const InputDecoration(hintText: '차량번호', isDense: true),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _RateSegments extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RateSegments({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget seg(String key, String label) {
      final on = value == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(key),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? c.primary.withValues(alpha: 0.12) : c.surface,
              border: Border.all(color: on ? c.accentText : c.border, width: on ? 1.5 : 1.5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: on ? c.accentText : c.ink2)),
          ),
        ),
      );
    }

    return Row(children: [
      seg('DAILY', '일당'),
      const SizedBox(width: 8),
      seg('HOURLY', '시급'),
      const SizedBox(width: 8),
      seg('PER_CASE', '건당'),
    ]);
  }
}

class _ExtrasSection extends StatelessWidget {
  final List<_ExtraItem> extras;
  final VoidCallback onAdd;
  final ValueChanged<_ExtraItem> onRemove;
  final VoidCallback onChanged;
  const _ExtrasSection(
      {required this.extras,
      required this.onAdd,
      required this.onRemove,
      required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in extras)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(
                width: 96,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: e.type,
                    icon: Icon(Icons.expand_more_rounded, color: c.ink3, size: 20),
                    items: const [
                      DropdownMenuItem(value: 'OVERTIME', child: Text('연장')),
                      DropdownMenuItem(value: 'NIGHT', child: Text('야간')),
                      DropdownMenuItem(value: 'EARLY', child: Text('조출')),
                      DropdownMenuItem(value: 'OTHER', child: Text('기타')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        e.type = v;
                        onChanged();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: e.rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (_) => onChanged(),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                  decoration: const InputDecoration(hintText: '단가', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: e.qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  onChanged: (_) => onChanged(),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                  decoration: const InputDecoration(hintText: '수량', isDense: true),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded, color: c.ink3),
                onPressed: () => onRemove(e),
              ),
            ]),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_rounded, size: 18, color: c.accentText),
            label: Text('연장·야간 항목 추가',
                style: TextStyle(color: c.accentText, fontSize: 14, fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
          ),
        ),
      ],
    );
  }
}

class _CalcPreview extends StatelessWidget {
  final AmountCalcResult calc;
  final String rateType;
  const _CalcPreview({required this.calc, required this.rateType});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          for (final it in calc.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Text(it.label,
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink2)),
                const Spacer(),
                Text('${formatWon(it.rate)} × ${_q(it.quantity)}',
                    style: TextStyle(
                        fontSize: 13,
                        color: c.ink3,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                const SizedBox(width: 8),
                Text(formatWon(it.amount),
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.borderStrong)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('받을 금액',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                    const Spacer(),
                    Text.rich(TextSpan(children: [
                      TextSpan(text: formatWon(calc.total)),
                      const TextSpan(text: ' 원', style: TextStyle(fontSize: 17)),
                    ]),
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: c.ink,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _q(num n) => n == n.roundToDouble() ? '${n.round()}' : n.toString();
}
