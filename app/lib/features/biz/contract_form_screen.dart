import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import 'contract_prefs.dart';

/// 표준근로계약서 작성 폼(사업장 모드).
class ContractFormScreen extends ConsumerStatefulWidget {
  const ContractFormScreen({super.key});
  @override
  ConsumerState<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends ConsumerState<ContractFormScreen> {
  // 작업자
  bool _byPhone = false; // 기본 직접 입력
  final _searchPhone = TextEditingController();
  bool _searching = false;
  List<WorkerSearchItem>? _results;
  String? _pickedProfileId;
  String? _pickedName;
  final _workerName = TextEditingController();
  final _workerPhone = TextEditingController();
  // 기간
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  // 근무
  final _workplace = TextEditingController();
  final _job = TextEditingController();
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  final _break = TextEditingController();
  // 임금
  String _wageType = 'DAILY';
  final _wageAmount = TextEditingController();
  final _payday = TextEditingController();
  final _payMethod = TextEditingController();
  // 수당
  bool _weeklyHoliday = false;
  bool _overtime = true;
  // 4대보험
  bool _insEmployment = false;
  bool _insHealth = false;
  bool _insPension = false;
  bool _insAccident = false;
  // 특약
  final _special = TextEditingController();
  // 저장
  bool _saveCommon = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
    for (final ctl in [_workerName, _workplace, _job, _wageAmount, _payday, _payMethod]) {
      ctl.addListener(() => setState(() {}));
    }
  }

  Future<void> _prefill() async {
    final v = await ContractPrefs.load();
    if (v == null || !mounted) return;
    setState(() {
      if (_workplace.text.isEmpty) _workplace.text = v.workplace;
      _wageType = v.wageType;
      if (_wageAmount.text.isEmpty) _wageAmount.text = v.wageAmount;
      if (_payday.text.isEmpty) _payday.text = v.payday;
      if (_payMethod.text.isEmpty) _payMethod.text = v.payMethod;
      _insEmployment = v.insEmployment;
      _insHealth = v.insHealth;
      _insPension = v.insPension;
      _insAccident = v.insAccident;
    });
  }

  @override
  void dispose() {
    for (final ctl in [
      _searchPhone, _workerName, _workerPhone, _workplace, _job,
      _break, _wageAmount, _payday, _payMethod, _special
    ]) {
      ctl.dispose();
    }
    super.dispose();
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _workerOk => _byPhone
      ? _pickedProfileId != null
      : _workerName.text.trim().isNotEmpty;

  bool get _valid =>
      _workerOk &&
      _workplace.text.trim().isNotEmpty &&
      _job.text.trim().isNotEmpty &&
      (int.tryParse(_wageAmount.text.trim()) ?? 0) > 0 &&
      _payday.text.trim().isNotEmpty &&
      _payMethod.text.trim().isNotEmpty;

  Future<void> _search() async {
    final phone = _searchPhone.text.trim();
    if (phone.length < 8) return;
    setState(() => _searching = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await ref.read(repoProvider).searchWorkers(phone);
      if (mounted) setState(() => _results = res);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Map<String, dynamic> _buildBody(String businessId) {
    final body = <String, dynamic>{
      'businessId': businessId,
      'startDate': dateParam(_startDate),
      if (_endDate != null) 'endDate': dateParam(_endDate!),
      'workplace': _workplace.text.trim(),
      'jobDescription': _job.text.trim(),
      'workStartTime': _hhmm(_start),
      'workEndTime': _hhmm(_end),
      if (_break.text.trim().isNotEmpty) 'breakTime': _break.text.trim(),
      'wageType': _wageType,
      'wageAmount': int.tryParse(_wageAmount.text.trim()) ?? 0,
      'payday': _payday.text.trim(),
      'payMethod': _payMethod.text.trim(),
      'weeklyHolidayAllowance': _weeklyHoliday,
      'overtimeAllowance': _overtime,
      'socialInsurance': {
        'employment': _insEmployment,
        'health': _insHealth,
        'pension': _insPension,
        'industrialAccident': _insAccident,
      },
      if (_special.text.trim().isNotEmpty) 'specialTerms': _special.text.trim(),
    };
    if (_byPhone && _pickedProfileId != null) {
      body['workerProfileId'] = _pickedProfileId;
    } else {
      body['workerName'] = _workerName.text.trim();
      if (_workerPhone.text.trim().isNotEmpty) {
        body['workerPhone'] = _workerPhone.text.trim();
      }
    }
    return body;
  }

  Future<void> _submit() async {
    final businesses = ref.read(myBusinessesProvider).valueOrNull ?? const [];
    if (businesses.isEmpty) return;
    setState(() => _saving = true);
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final body = _buildBody(businesses.first.id);
      await ref.read(repoProvider).createLaborContract(body);
      if (_saveCommon) {
        await ContractPrefs.save(ContractCommonValues(
          workplace: _workplace.text.trim(),
          wageType: _wageType,
          wageAmount: _wageAmount.text.trim(),
          payday: _payday.text.trim(),
          payMethod: _payMethod.text.trim(),
          insEmployment: _insEmployment,
          insHealth: _insHealth,
          insPension: _insPension,
          insAccident: _insAccident,
        ));
      }
      ref.invalidate(bizContractsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.lcCreated)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l.lcCreateFailed(e.message))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop()),
        title: Text(l.lcNewContract),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              children: [
                PaperCard(
                  stamp: l.lcStamp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 작업자 ──
                      _Label(l.lcWorkerSection),
                      _workerSection(context),
                      const SizedBox(height: 14),
                      // ── 계약기간 ──
                      _Label(l.lcPeriod),
                      Row(children: [
                        Expanded(
                          child: _dateBox(context, l.lcStartDate,
                              fmtShortDate(_startDate, lang), _pickStart),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateBox(
                              context,
                              l.lcEndDate,
                              _endDate == null
                                  ? l.lcEndDateNotSet
                                  : fmtShortDate(_endDate!, lang),
                              _pickEnd),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      // ── 근무장소 / 업무 ──
                      _Label(l.lcWorkplace),
                      _input(_workplace, l.lcWorkplaceHint,
                          icon: Icons.location_on_outlined),
                      const SizedBox(height: 12),
                      _Label(l.lcJob),
                      _input(_job, l.lcJobHint, maxLines: 2),
                      const SizedBox(height: 14),
                      // ── 근로시간 ──
                      _Label(l.lcWorkTime),
                      Row(children: [
                        Expanded(
                          child: _dateBox(
                              context,
                              '',
                              '${fmtAmpm(_hhmm(_start), lang)} ~ ${fmtAmpm(_hhmm(_end), lang)}',
                              _pickTimes,
                              icon: Icons.schedule_rounded),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _Label(l.lcBreak),
                      _input(_break, l.lcBreakHint),
                      const SizedBox(height: 14),
                      // ── 임금 ──
                      _Label(l.lcWage),
                      _WageSegments(
                          value: _wageType,
                          onChanged: (v) => setState(() => _wageType = v)),
                      const SizedBox(height: 10),
                      _numInput(_wageAmount, l.lcWageAmountHint),
                      const SizedBox(height: 12),
                      _Label(l.lcPayday),
                      _input(_payday, l.lcPaydayHint),
                      const SizedBox(height: 12),
                      _Label(l.lcPayMethod),
                      _input(_payMethod, l.lcPayMethodHint),
                      const SizedBox(height: 14),
                      // ── 수당 ──
                      _Label(l.lcAllowance),
                      _switchRow(l.lcWeeklyHolidaySwitch, _weeklyHoliday,
                          (v) => setState(() => _weeklyHoliday = v)),
                      _switchRow(l.lcOvertimeSwitch, _overtime,
                          (v) => setState(() => _overtime = v)),
                      const SizedBox(height: 14),
                      // ── 4대보험 ──
                      _Label(l.lcInsurance),
                      _checkRow(l.lcInsEmployment, _insEmployment,
                          (v) => setState(() => _insEmployment = v)),
                      _checkRow(l.lcInsHealth, _insHealth,
                          (v) => setState(() => _insHealth = v)),
                      _checkRow(l.lcInsPension, _insPension,
                          (v) => setState(() => _insPension = v)),
                      _checkRow(l.lcInsAccident, _insAccident,
                          (v) => setState(() => _insAccident = v)),
                      const SizedBox(height: 14),
                      // ── 특약 ──
                      _Label(l.lcSpecial),
                      _input(_special, l.lcSpecialHint, maxLines: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _saveCommonToggle(context),
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
                label: l.lcSubmit,
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

  // ── 작업자 섹션(전화 검색 / 직접 입력) ──
  Widget _workerSection(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          _modeChip(l.lcWorkerByPhone, _byPhone,
              () => setState(() => _byPhone = true)),
          _modeChip(l.lcWorkerManual, !_byPhone,
              () => setState(() => _byPhone = false)),
        ]),
        const SizedBox(height: 10),
        if (_byPhone) ...[
          Row(children: [
            Expanded(
                child: _input(_searchPhone, l.lcSearchPhoneHint,
                    keyboard: TextInputType.phone)),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _searching ? null : _search,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.primaryInk,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _searching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: c.primaryInk))
                    : const Icon(Icons.search_rounded),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(l.lcSearchHint,
              style: TextStyle(fontSize: 12.5, color: c.ink3)),
          if (_results != null && _results!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.lcSearchNoResult,
                  style: TextStyle(fontSize: 14, color: c.ink3)),
            ),
          if (_results != null && _results!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  for (final w in _results!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _WorkerResultTile(
                        name: w.maskedName,
                        selected: _pickedProfileId == w.profileId,
                        onTap: () => setState(() {
                          _pickedProfileId = w.profileId;
                          _pickedName = w.maskedName;
                        }),
                      ),
                    ),
                ],
              ),
            ),
          if (_pickedName != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Icon(Icons.check_circle_outline_rounded, size: 18, color: c.depositedBadge),
                const SizedBox(width: 6),
                Text('${l.lcWorkerLinkedBadge} · $_pickedName',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.depositedBadge)),
              ]),
            ),
        ] else ...[
          _input(_workerName, l.lcWorkerNameHint,
              icon: Icons.person_outline_rounded),
          const SizedBox(height: 8),
          _input(_workerPhone, l.lcWorkerPhoneHint,
              keyboard: TextInputType.phone),
        ],
      ],
    );
  }

  Widget _saveCommonToggle(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        Icon(Icons.bookmark_border_rounded, size: 20, color: c.accentText),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.lcSaveCommon,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
              Text(l.lcSaveCommonSub,
                  style: TextStyle(fontSize: 13, color: c.ink3)),
            ],
          ),
        ),
        Switch(
            value: _saveCommon,
            onChanged: (v) => setState(() => _saveCommon = v),
            activeTrackColor: c.primary),
      ]),
    );
  }

  Widget _modeChip(String label, bool on, VoidCallback onTap) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? c.primary.withValues(alpha: 0.12) : c.surface,
          border: Border.all(
              color: on ? c.accentText : c.border, width: on ? 1.5 : 1),
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

  Widget _dateBox(
      BuildContext context, String label, String value, VoidCallback onTap,
      {IconData icon = Icons.calendar_today_outlined}) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) _Label(label),
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: c.ink)),
        ),
        Switch(value: value, onChanged: onChanged, activeTrackColor: c.primary),
      ]),
    );
  }

  Widget _checkRow(String label, bool value, ValueChanged<bool> onChanged) {
    final c = context.c;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(
              value
                  ? Icons.check_box_outlined
                  : Icons.check_box_outline_blank_rounded,
              color: value ? c.accentText : c.ink3,
              size: 24),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w600, color: c.ink)),
        ]),
      ),
    );
  }

  Widget _input(TextEditingController ctl, String hint,
      {IconData? icon, int maxLines = 1, TextInputType? keyboard}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      maxLines: maxLines,
      keyboardType: keyboard,
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

  Widget _numInput(TextEditingController ctl, String hint) {
    final c = context.c;
    return TextField(
      controller: ctl,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: c.ink,
          fontFeatures: const [FontFeature.tabularFigures()]),
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

  Future<void> _pickStart() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _startDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035));
    if (d != null) setState(() => _startDate = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _endDate ?? _startDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035));
    if (d != null) setState(() => _endDate = d);
  }

  Future<void> _pickTimes() async {
    final l = context.l;
    final s = await showTimePicker(
        context: context, initialTime: _start, helpText: l.lcWorkTime);
    if (s == null || !mounted) return;
    final e = await showTimePicker(
        context: context, initialTime: _end, helpText: l.lcWorkTime);
    setState(() {
      _start = s;
      if (e != null) _end = e;
    });
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

class _WageSegments extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _WageSegments({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
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
              border: Border.all(
                  color: on ? c.accentText : c.border, width: 1.5),
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
      seg('DAILY', l.lcWageDaily),
      const SizedBox(width: 8),
      seg('HOURLY', l.lcWageHourly),
    ]);
  }
}

class _WorkerResultTile extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _WorkerResultTile(
      {required this.name, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.fieldBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
                color: selected ? c.accentText : c.border,
                width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(Icons.person_outline_rounded, color: c.accentText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.ink)),
            ),
            Icon(
                selected
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked,
                color: selected ? c.accentText : c.ink3),
          ]),
        ),
      ),
    );
  }
}
