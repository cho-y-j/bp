import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/amount_calc.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../providers/biz.dart';
import '../../providers/drafts.dart';
import '../../providers/partners.dart';
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

/// 팀 확인서: 팀원 1명의 공수·단가 입력 컨트롤러.
class _TeamRow {
  final TextEditingController gongsu = TextEditingController(text: '1');
  final TextEditingController rate = TextEditingController();
  void dispose() {
    gongsu.dispose();
    rate.dispose();
  }
}

class ConfirmationFormScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final Confirmation? copyFrom;
  final String? prefillCompany; // 거래처 상세에서 넘어온 수기 상대 회사명
  final String? prefillContact; // 거래처 상세에서 넘어온 수기 상대 연락처
  const ConfirmationFormScreen({
    super.key,
    this.initialDate,
    this.copyFrom,
    this.prefillCompany,
    this.prefillContact,
  });
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
  bool _committed = false; // 저장/임시저장 완료 → 자동 초안 재저장 방지
  bool _autoRestoreDismissed = false; // 자동 초안 복원 배너 닫힘
  // 팀(반장) 확인서 모드.
  bool _teamMode = false;
  String? _teamId;
  final Map<String, _TeamRow> _teamRows = {}; // memberId → 컨트롤러

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    final cf = widget.copyFrom;
    if (cf != null) _applyCopy(cf);
    // 거래처 상세 "확인서 쓰기" 프리필(수기 상대). copyFrom 과 병존 시 copyFrom 우선.
    if (cf == null) {
      if ((widget.prefillCompany ?? '').isNotEmpty) {
        _company.text = widget.prefillCompany!;
        _useBusiness = false;
      }
      if ((widget.prefillContact ?? '').isNotEmpty) {
        _contact.text = widget.prefillContact!;
      }
    }
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
    for (final r in _teamRows.values) {
      r.dispose();
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

  bool get _quantityValid => _rateType == 'GONGSU'
      ? validateGongsuQuantity(_qtyValue) != null
      : _qtyValue > 0;

  bool get _counterpartyOk =>
      _useBusiness ? _businessId != null : _company.text.trim().isNotEmpty;

  /// 선택된 팀의 멤버에 맞춰 입력 컨트롤러를 준비(없으면 생성, 없어진 건 정리).
  void _syncTeamRows(Team team) {
    final ids = team.members.map((m) => m.id).toSet();
    for (final stale in _teamRows.keys.where((k) => !ids.contains(k)).toList()) {
      _teamRows.remove(stale)?.dispose();
    }
    for (final m in team.members) {
      _teamRows.putIfAbsent(m.id, () {
        final row = _TeamRow();
        if (m.defaultRate != null) row.rate.text = '${m.defaultRate}';
        return row;
      });
    }
  }

  /// 유효 공수(0.1 단위, >0)를 입력한 팀원의 정규화 공수. 아니면 null.
  double? _memberGongsu(String memberId) {
    final row = _teamRows[memberId];
    if (row == null) return null;
    final q = num.tryParse(row.gongsu.text.trim()) ?? 0;
    return validateGongsuQuantity(q);
  }

  int _memberRate(String memberId) =>
      int.tryParse(_teamRows[memberId]?.rate.text.trim() ?? '') ?? 0;

  /// 팀 합계(공수>0 인 팀원의 단가×공수 합).
  int _teamTotal(Team? team) {
    if (team == null) return 0;
    var sum = 0.0;
    for (final m in team.members) {
      final g = _memberGongsu(m.id);
      if (g != null) sum += _memberRate(m.id) * g;
    }
    return sum.round();
  }

  /// teamEntries 본문(공수>0 인 팀원만).
  List<Map<String, dynamic>> _teamEntries(Team? team) {
    if (team == null) return const [];
    final out = <Map<String, dynamic>>[];
    for (final m in team.members) {
      final g = _memberGongsu(m.id);
      if (g == null) continue;
      final rate = _memberRate(m.id);
      out.add({
        'memberId': m.id,
        'quantity': g,
        if (rate > 0) 'rate': rate,
      });
    }
    return out;
  }

  Team? _selectedTeam(List<Team> teams) {
    if (_teamId == null) return null;
    for (final t in teams) {
      if (t.id == _teamId) return t;
    }
    return null;
  }

  bool _teamValid(List<Team> teams) {
    final team = _selectedTeam(teams);
    if (team == null) return false;
    final hasEntry = team.members.any((m) => _memberGongsu(m.id) != null);
    return _counterpartyOk &&
        _site.text.trim().isNotEmpty &&
        _work.text.trim().isNotEmpty &&
        hasEntry;
  }

  bool get _valid {
    if (_teamMode) {
      final teams = ref.read(teamsProvider).valueOrNull ?? const [];
      return _teamValid(teams);
    }
    final rate = num.tryParse(_rate.text.trim()) ?? 0;
    return _site.text.trim().isNotEmpty &&
        _work.text.trim().isNotEmpty &&
        _counterpartyOk &&
        rate > 0 &&
        _quantityValid;
  }

  Future<void> _pickCopyFrom() async {
    final l = context.l;
    final month = monthParam(DateTime.now());
    final list = await ref.read(confirmationsProvider(month).future);
    if (!mounted) return;
    if (list.items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.confNoCopySource)));
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
            Text(l.confCopyPrevious,
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
                    '${fmtShortDate(conf.dateTime, ctx.lang)} · ${conf.companyName} · ${formatMoney(conf.total, ctx.lang)}',
                    style: TextStyle(color: ctx.c.ink2, fontSize: 13)),
                trailing: Icon(Icons.copy_outlined, color: ctx.c.accentText, size: 20),
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

  /// 상대(사업장/수기) 정보를 본문에 채운다.
  void _fillCounterparty(Map<String, dynamic> body) {
    if (_useBusiness && _businessId != null) {
      body['businessId'] = _businessId;
    } else {
      body['companyName'] = _company.text.trim();
      if (_contact.text.trim().isNotEmpty) body['contact'] = _contact.text.trim();
    }
  }

  /// `POST /confirmations` 요청 본문 구성(초안 큐 저장에도 재사용).
  Map<String, dynamic> _buildBody() {
    // 팀(반장) 확인서 — rateType/rate/quantity/부가·장비 없이 teamEntries 로.
    if (_teamMode) {
      final teams = ref.read(teamsProvider).valueOrNull ?? const [];
      final team = _selectedTeam(teams);
      final body = <String, dynamic>{
        'date': dateParam(_date),
        'siteName': _site.text.trim(),
        'workDescription': _work.text.trim(),
        'startTime': _hhmm(_start),
        'endTime': _hhmm(_end),
        'teamId': _teamId,
        'teamEntries': _teamEntries(team),
      };
      _fillCounterparty(body);
      if (_dueDate != null) body['dueDate'] = dateParam(_dueDate!);
      return body;
    }
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
    _fillCounterparty(body);
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
    return body;
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final body = _buildBody();
    final repo = ref.read(repoProvider);
    final l = context.l;
    // 루트 메신저/네비게이터를 pop 이전에 캡처 → pop 후에도 안전하게 표시.
    final messenger = ScaffoldMessenger.of(context);
    try {
      final created = await repo.createConfirmation(body);
      _committed = true; // 자동 초안 재저장 방지
      await ref.read(autoDraftProvider.notifier).clear();
      Map sendRes = const {};
      try {
        sendRes = await repo.send(created.id);
      } on ApiException {
        // 전송(공유 링크·알림)만 실패 — 확인서는 이미 저장·장부 반영됨.
      }
      invalidateAll(ref);
      if (!mounted) return;
      final linked = sendRes['linked'] == true;
      final url = sendRes['url']?.toString() ?? '';
      // 공유 시트는 화면이 살아있는 동안(pop 이전) 띄운다.
      if (!linked && url.isNotEmpty) {
        await shareConfirmationLink(context, created, url);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
          content: Text(linked ? l.confSavedLinked : l.confSavedBook)));
    } on ApiException catch (e) {
      if (!mounted) return;
      // 공수 수량 검증 실패 — 화면에 머무르며 안내.
      if (e.code == 'INVALID_GONGSU_QUANTITY') {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(l.confErrGongsu)));
        return;
      }
      // 네트워크/서버 문제 → 로컬 초안 큐에 임시저장(연결 복구 시 자동 전송).
      if (isRetriableFailure(e)) {
        await ref.read(draftQueueProvider.notifier).enqueue(body);
        _committed = true;
        await ref.read(autoDraftProvider.notifier).clear();
        if (!mounted) return;
        Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(
            content: Text(l.confDraftQueued),
            duration: const Duration(seconds: 4)));
        return;
      }
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l.confSaveFailed(e.message))));
    }
  }

  /// 작성 중인 의미 있는 내용이 있는가(자동 초안 보존 판단용).
  bool get _isDirty =>
      _site.text.trim().isNotEmpty ||
      _work.text.trim().isNotEmpty ||
      (num.tryParse(_rate.text.trim()) ?? 0) > 0 ||
      _company.text.trim().isNotEmpty;

  /// 폼 이탈 시 자동 초안 1건 보존(저장/임시저장으로 커밋되지 않은 경우만).
  void _maybeSaveAutoDraft() {
    if (_committed || !_isDirty) return;
    ref.read(autoDraftProvider.notifier).save(_buildBody());
  }

  /// 저장/자동 초안 본문을 폼에 복원.
  void _applyBody(Map body) {
    _date = DateTime.tryParse(body['date']?.toString() ?? '') ?? _date;
    _site.text = body['siteName']?.toString() ?? '';
    _work.text = body['workDescription']?.toString() ?? '';
    _rateType = body['rateType']?.toString() ?? 'DAILY';
    _rate.text = body['rate'] == null ? '' : '${body['rate']}';
    _qty.text = '${body['quantity'] ?? 1}';
    final st = (body['startTime']?.toString() ?? '').split(':');
    if (st.length == 2) {
      _start = TimeOfDay(
          hour: int.tryParse(st[0]) ?? 8, minute: int.tryParse(st[1]) ?? 0);
    }
    final et = (body['endTime']?.toString() ?? '').split(':');
    if (et.length == 2) {
      _end = TimeOfDay(
          hour: int.tryParse(et[0]) ?? 17, minute: int.tryParse(et[1]) ?? 0);
    }
    if (body['businessId'] != null) {
      _useBusiness = true;
      _businessId = body['businessId'].toString();
    } else {
      _useBusiness = false;
      _company.text = body['companyName']?.toString() ?? '';
      _contact.text = body['contact']?.toString() ?? '';
    }
    final eq = body['equipmentSection'];
    if (eq is Map && (eq['name'] ?? '').toString().isNotEmpty) {
      _equipOn = true;
      _equipName.text = eq['name']?.toString() ?? '';
      _equipVehicle.text = eq['vehicleNumber']?.toString() ?? '';
    }
    final due = body['dueDate'];
    if (due != null) _dueDate = DateTime.tryParse(due.toString());
    for (final e in _extras) {
      e.dispose();
    }
    _extras.clear();
    final extras = body['additionalItems'];
    if (extras is List) {
      for (final raw in extras.whereType<Map>()) {
        final item = _ExtraItem(raw['type']?.toString() ?? 'OVERTIME');
        item.rate.text = raw['rate'] == null ? '' : '${raw['rate']}';
        item.qty.text = '${raw['quantity'] ?? 1}';
        item.label.text = raw['label']?.toString() ?? '';
        _extras.add(item);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    final calc = _preview();
    final connections = ref.watch(connectionsProvider);
    final teams = ref.watch(teamsProvider).valueOrNull ?? const <Team>[];
    final selTeam = _selectedTeam(teams);
    if (selTeam != null) _syncTeamRows(selTeam);
    // 폼이 비어있을 때만 자동 초안 복원 배너 노출(copyFrom 없을 때).
    final autoDraft = ref.watch(autoDraftProvider);
    final showRestore = autoDraft != null &&
        !_autoRestoreDismissed &&
        !_committed &&
        widget.copyFrom == null;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _maybeSaveAutoDraft();
      },
      child: Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).maybePop()),
        title: Text(l.confFormTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              children: [
                if (showRestore) ...[
                  _RestoreDraftBanner(
                    onRestore: () => setState(() {
                      _applyBody(autoDraft.body);
                      _autoRestoreDismissed = true;
                    }),
                    onDiscard: () {
                      ref.read(autoDraftProvider.notifier).clear();
                      setState(() => _autoRestoreDismissed = true);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                // 이전 확인서 복사
                _CopyButton(onTap: _pickCopyFrom),
                const SizedBox(height: 14),
                PaperCard(
                  stamp: l.paperStamp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: _FieldBox(
                            label: l.paperDate,
                            icon: Icons.calendar_today_outlined,
                            value: fmtShortDate(_date, lang),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FieldBox(
                            label: l.paperTime,
                            icon: Icons.schedule_rounded,
                            value: '${fmtAmpm(_hhmm(_start), lang)}~${fmtAmpm(_hhmm(_end), lang)}',
                            onTap: _pickTimes,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _Label(l.paperSite),
                      _input(_site, hint: l.confSiteHint,
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
                      _Label(l.paperWork),
                      _input(_work,
                          hint: l.confWorkHint, maxLines: 3,
                          icon: null),
                      const SizedBox(height: 6),
                      _TeamModeToggle(
                        on: _teamMode,
                        onChanged: (v) => setState(() => _teamMode = v),
                      ),
                      const SizedBox(height: 12),
                      if (_teamMode)
                        _TeamSection(
                          teams: teams,
                          teamId: _teamId,
                          rows: _teamRows,
                          total: _teamTotal(selTeam),
                          onTeamChanged: (id) => setState(() => _teamId = id),
                          onRowChanged: () => setState(() {}),
                        )
                      else ...[
                        _EquipmentToggle(
                          on: _equipOn,
                          name: _equipName,
                          vehicle: _equipVehicle,
                          onChanged: (v) => setState(() => _equipOn = v),
                        ),
                        const SizedBox(height: 12),
                        _Label(l.confRateType),
                        _RateSegments(
                          value: _rateType,
                          onChanged: (v) => setState(() {
                            _rateType = v;
                            // 공수로 전환 시 유효한 기본값(1공수) 보장.
                            if (v == 'GONGSU' &&
                                validateGongsuQuantity(_qtyValue) == null) {
                              _qty.text = '1';
                            }
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label(_rateType == 'HOURLY'
                                    ? l.confRateHourly
                                    : _rateType == 'PER_CASE'
                                        ? l.confPricePerCase
                                        : _rateType == 'GONGSU'
                                            ? l.confPriceGongsu
                                            : l.confRateDaily),
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
                                    ? l.confQtyHours
                                    : _rateType == 'PER_CASE'
                                        ? l.confQtyCases
                                        : _rateType == 'GONGSU'
                                            ? l.unitGongsu
                                            : l.confQtyDays),
                                _rateType == 'GONGSU'
                                    ? _GongsuStepper(
                                        controller: _qty,
                                        onChanged: () => setState(() {}),
                                      )
                                    : _numInput(_qty, hint: '1'),
                              ],
                            ),
                          ),
                        ]),
                        if (_rateType == 'GONGSU'
                            ? validateGongsuQuantity(_qtyValue) == null
                            : _qtyValue <= 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 2),
                            child: Text(
                                _rateType == 'GONGSU'
                                    ? l.confErrGongsu
                                    : _rateType == 'HOURLY'
                                        ? l.confErrHours
                                        : _rateType == 'PER_CASE'
                                            ? l.confErrCases
                                            : l.confErrDays,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.receivable)),
                          ),
                        const SizedBox(height: 10),
                        _ExtrasSection(
                          extras: _extras,
                          onAdd: () =>
                              setState(() => _extras.add(_ExtraItem('OVERTIME'))),
                          onRemove: (e) => setState(() {
                            _extras.remove(e);
                            e.dispose();
                          }),
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        _CalcPreview(calc: calc, rateType: _rateType),
                      ],
                      const SizedBox(height: 12),
                      _FieldBox(
                        label: l.confDueDate,
                        icon: Icons.event_available_outlined,
                        value: _dueDate == null
                            ? l.confNotSet
                            : fmtShortDate(_dueDate!, lang),
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
                    label: l.confSaveSend,
                    icon: Icons.send_outlined,
                    loading: _saving,
                    onPressed: _valid ? _submit : null,
                  ),
                  const SizedBox(height: 8),
                  Text(l.confSaveHint,
                      style: TextStyle(fontSize: 13, color: c.ink3)),
                ],
              ),
            ),
          ),
        ],
      ),
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
    final l = context.l;
    final s = await showTimePicker(
        context: context, initialTime: _start, helpText: l.confStartTime);
    if (s == null) return;
    if (!mounted) return;
    final e = await showTimePicker(
        context: context, initialTime: _end, helpText: l.confEndTime);
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
            Icon(Icons.content_copy_outlined, size: 20, color: c.accentText),
            const SizedBox(width: 11),
            Text(context.l.confCopyPrevious,
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
                // 날짜/시간 값은 잘림 대신 한 줄 축소(scaleDown) — ru 등 긴 표기 대응.
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
    final l = context.l;
    final conns = connections.valueOrNull ?? const [];
    final hasConns = conns.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(l.confOrdererCompany),
        if (hasConns)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            // 긴 번역(ru/vi)에서도 넘치지 않게 Wrap 으로 줄바꿈 허용.
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _modeChip(context, l.confLinkedBiz, useBusiness, () => onModeChanged(true)),
              _modeChip(context, l.confManualEntry, !useBusiness, () => onModeChanged(false)),
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
                hint: Text(l.confSelectBiz,
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
            Align(
              alignment: Alignment.centerLeft,
              child: _PickPartnerButton(company: company, contact: contact),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: company,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
              decoration: InputDecoration(
                hintText: l.confCompanyHint,
                prefixIcon: Icon(Icons.business_outlined, size: 20, color: c.ink3),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contact,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
              decoration: InputDecoration(
                hintText: l.confContactHint,
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: c.ink3),
              ),
            ),
          ]),
        // 연결된 사업장의 지급 신뢰도 배지 (P3a).
        if (useBusiness && businessId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _ConnectedBizBadge(businessId: businessId!),
          ),
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

/// 선택된 연결 사업장의 지급 신뢰도 배지 (P3a). 없으면 아무것도 그리지 않음.
class _ConnectedBizBadge extends ConsumerStatefulWidget {
  final String businessId;
  const _ConnectedBizBadge({required this.businessId});
  @override
  ConsumerState<_ConnectedBizBadge> createState() => _ConnectedBizBadgeState();
}

class _ConnectedBizBadgeState extends ConsumerState<_ConnectedBizBadge> {
  late Future<PaymentBadge?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(_ConnectedBizBadge old) {
    super.didUpdateWidget(old);
    if (old.businessId != widget.businessId) _future = _load();
  }

  Future<PaymentBadge?> _load() async {
    try {
      return await ref.read(bizRepoProvider).businessBadgeById(widget.businessId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaymentBadge?>(
      future: _future,
      builder: (ctx, snap) {
        final b = snap.data;
        if (b == null) return const SizedBox.shrink();
        return Align(
            alignment: Alignment.centerLeft, child: PaymentBadgeChip(b));
      },
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
    final l = context.l;
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
                Text(l.confEquipSection,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                Text(l.confEquipAutoInclude,
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
                  decoration: InputDecoration(hintText: l.confEquipName, isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: vehicle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                  decoration: InputDecoration(hintText: l.confVehicleNo, isDense: true),
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

    final l = context.l;
    return Row(children: [
      seg('DAILY', l.confRateDaily),
      const SizedBox(width: 6),
      seg('GONGSU', l.unitGongsu),
      const SizedBox(width: 6),
      seg('HOURLY', l.confRateHourly),
      const SizedBox(width: 6),
      seg('PER_CASE', l.confRatePerCase),
    ]);
  }
}

/// 공수(품) 0.5 스텝퍼 — −/값/+ 로 0.5 단위 조절(0.5~5.0), 직접 입력도 허용(0.1 단위).
class _GongsuStepper extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _GongsuStepper({required this.controller, required this.onChanged});

  static const double _min = 0.5;
  static const double _max = 5.0;

  void _step(double delta) {
    final cur = double.tryParse(controller.text.trim()) ?? 1.0;
    var next = ((cur + delta) * 2).round() / 2; // 0.5 격자에 스냅
    if (next < _min) next = _min;
    if (next > _max) next = _max;
    controller.text = formatQty(next);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget btn(IconData icon, VoidCallback onTap, bool enabled) => InkResponse(
          onTap: enabled ? onTap : null,
          radius: 24,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon,
                size: 24, color: enabled ? c.accentText : c.ink3.withValues(alpha: 0.4)),
          ),
        );
    final cur = double.tryParse(controller.text.trim()) ?? 0;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: c.fieldBg,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          btn(Icons.remove_rounded, () => _step(-0.5), cur > _min),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => onChanged(),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()]),
              decoration: const InputDecoration(
                hintText: '1',
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          btn(Icons.add_rounded, () => _step(0.5), cur < _max),
        ],
      ),
    );
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
    final l = context.l;
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
                    items: [
                      DropdownMenuItem(value: 'OVERTIME', child: Text(l.amtOvertime)),
                      DropdownMenuItem(value: 'NIGHT', child: Text(l.amtNight)),
                      DropdownMenuItem(value: 'EARLY', child: Text(l.amtEarly)),
                      DropdownMenuItem(value: 'OTHER', child: Text(l.itemOther)),
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
                  decoration: InputDecoration(hintText: l.confUnitPrice, isDense: true),
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
                  decoration: InputDecoration(hintText: l.confQuantity, isDense: true),
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
            label: Text(l.confAddExtra,
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

  /// 계산 항목 라벨을 공유 번역 키로 매핑(사용자 지정 OTHER 라벨은 그대로 유지).
  String _itemLabel(BuildContext context, AmountLineItem it) {
    final l = context.l;
    switch (it.type) {
      case 'BASE':
        switch (rateType) {
          case 'HOURLY':
            return l.baseHourly;
          case 'PER_CASE':
            return l.basePerCase;
          case 'GONGSU':
            return l.baseGongsu;
          default:
            return l.baseDaily;
        }
      case 'OVERTIME':
        return l.amtOvertime;
      case 'EARLY':
        return l.amtEarly;
      case 'NIGHT':
        return l.amtNight;
      case 'ALLNIGHT':
        return l.amtAllnight;
      case 'OTHER':
        return it.label == (additionalItemLabels['OTHER'] ?? '기타')
            ? l.itemOther
            : it.label;
      default:
        return it.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
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
                Text(_itemLabel(context, it),
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink2)),
                const Spacer(),
                Text(
                    '${formatMoney(it.rate, lang)} × ${it.unit != null && it.unit!.isNotEmpty ? l.qtyGongsu(formatGongsu(it.quantity)) : formatGongsu(it.quantity)}',
                    style: TextStyle(
                        fontSize: 13,
                        color: c.ink3,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                const SizedBox(width: 8),
                Text(formatMoney(it.amount, lang),
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
                    Text(l.paperTotal,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                    const Spacer(),
                    Text(formatMoney(calc.total, lang),
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
}

/// 자동 보존된 초안 복원 배너(폼 이탈 후 재진입 시).
class _RestoreDraftBanner extends StatelessWidget {
  final VoidCallback onRestore;
  final VoidCallback onDiscard;
  const _RestoreDraftBanner({required this.onRestore, required this.onDiscard});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.08),
        border: Border.all(color: c.borderStrong),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 20, color: c.accentText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.confRestoreTitle,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: c.ink)),
          ),
          TextButton(
            onPressed: onDiscard,
            child: Text(l.delete, style: TextStyle(color: c.ink3, fontSize: 14)),
          ),
          TextButton(
            onPressed: onRestore,
            child: Text(l.confRestore,
                style: TextStyle(
                    color: c.accentText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// 팀(반장) 확인서 토글.
class _TeamModeToggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChanged;
  const _TeamModeToggle({required this.on, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: on ? c.accentText : c.border, width: on ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Row(children: [
        Icon(Icons.groups_2_outlined, size: 20, color: c.accentText),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.confTeamMode,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
              Text(l.confTeamModeSub,
                  style: TextStyle(fontSize: 13, color: c.ink3)),
            ],
          ),
        ),
        Switch(value: on, onChanged: onChanged, activeTrackColor: c.primary),
      ]),
    );
  }
}

/// 팀 확인서 본문 — 팀 선택 + 팀원별 공수/단가 + 팀 합계.
class _TeamSection extends StatelessWidget {
  final List<Team> teams;
  final String? teamId;
  final Map<String, _TeamRow> rows;
  final int total;
  final ValueChanged<String?> onTeamChanged;
  final VoidCallback onRowChanged;
  const _TeamSection({
    required this.teams,
    required this.teamId,
    required this.rows,
    required this.total,
    required this.onTeamChanged,
    required this.onRowChanged,
  });

  Team? get _selected {
    if (teamId == null) return null;
    for (final t in teams) {
      if (t.id == teamId) return t;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    if (teams.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: c.surface2,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(l.confTeamNoTeam,
            style: TextStyle(fontSize: 14, color: c.ink2)),
      );
    }
    final team = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(l.confTeamSelect),
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
              value: teamId,
              hint: Text(l.confTeamPickTeam,
                  style: TextStyle(color: c.ink3, fontSize: 16)),
              icon: Icon(Icons.expand_more_rounded, color: c.ink3),
              items: [
                for (final t in teams)
                  DropdownMenuItem(
                    value: t.id,
                    child: Text('${t.name} · ${l.teamMemberCountLabel(t.memberCount)}',
                        style: TextStyle(
                            color: c.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
              onChanged: onTeamChanged,
            ),
          ),
        ),
        if (team != null) ...[
          const SizedBox(height: 12),
          if (team.members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Text(l.teamNoMembers,
                  style: TextStyle(fontSize: 14, color: c.ink3)),
            )
          else
            for (final m in team.members)
              _TeamMemberInput(
                member: m,
                row: rows[m.id],
                onChanged: onRowChanged,
              ),
          const SizedBox(height: 4),
          _TeamTotalBox(total: total),
        ],
      ],
    );
  }
}

class _TeamMemberInput extends StatelessWidget {
  final TeamMember member;
  final _TeamRow? row;
  final VoidCallback onChanged;
  const _TeamMemberInput(
      {required this.member, required this.row, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    if (row == null) return const SizedBox.shrink();
    final g = validateGongsuQuantity(num.tryParse(row!.gongsu.text.trim()) ?? 0);
    final rate = int.tryParse(row!.rate.text.trim()) ?? 0;
    final amount = g == null ? 0 : (rate * g).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
            ),
            Text(formatMoney(amount, lang),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: g == null ? c.ink3 : c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(l.unitGongsu),
                  _GongsuStepper(controller: row!.gongsu, onChanged: onChanged),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(l.teamDefaultRate),
                  TextField(
                    controller: row!.rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                    ],
                    onChanged: (_) => onChanged(),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                    decoration: const InputDecoration(hintText: '0'),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _TeamTotalBox extends StatelessWidget {
  final int total;
  const _TeamTotalBox({required this.total});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.borderStrong),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(l.confTeamTotal,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
          const Spacer(),
          Text(formatMoney(total, lang),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// 확인서 폼 수기 상대 입력 편의 — 거래처 목록에서 하나 골라 회사명/연락처 채움.
class _PickPartnerButton extends ConsumerWidget {
  final TextEditingController company;
  final TextEditingController contact;
  const _PickPartnerButton({required this.company, required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    return OutlinedButton.icon(
      onPressed: () => _pick(context, ref),
      icon: Icon(Icons.contacts_outlined, size: 18, color: c.ink),
      label: Text(l.confPickPartner,
          style:
              TextStyle(color: c.ink, fontSize: 14, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final c = context.c;
    final l = context.l;
    final partners = await ref.read(partnersProvider.future);
    if (!context.mounted) return;
    if (partners.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.partnersEmpty)));
      return;
    }
    final picked = await showModalBottomSheet<Partner>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(l.confPickPartner,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            ),
            for (final p in partners)
              ListTile(
                title: Text(p.name,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.ink)),
                subtitle: (p.phone ?? '').isNotEmpty
                    ? Text(p.phone!, style: TextStyle(color: c.ink3))
                    : null,
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    company.text = picked.name;
    if ((picked.phone ?? '').isNotEmpty) contact.text = picked.phone!;
  }
}
