import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';

/// "내 팀" — 반장이 팀원 명단·단가를 관리하는 화면.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final teams = ref.watch(teamsProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.teamListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTeam(context, ref),
        backgroundColor: c.primary,
        foregroundColor: c.primaryInk,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.teamCreate,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: teams.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorRetry(
                  boxed: false, onRetry: () => ref.invalidate(teamsProvider)),
            ),
          ),
          data: (list) => list.isEmpty
              ? _Empty(onCreate: () => _createTeam(context, ref))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    for (final team in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TeamCard(team: team),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;
  const _Empty({required this.onCreate});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 40, 18, 24),
      children: [
        PaperCard(
          stamp: l.teamListTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.teamEmptyTitle,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
              const SizedBox(height: 4),
              Text(l.teamEmptySub,
                  style: TextStyle(fontSize: 14, color: c.ink2, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l.teamCreate,
          icon: Icons.add_rounded,
          onPressed: onCreate,
        ),
      ],
    );
  }
}

class _TeamCard extends ConsumerWidget {
  final Team team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.groups_2_outlined, color: c.accentText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: c.ink)),
                    const SizedBox(height: 2),
                    Text(l.teamMemberCountLabel(team.memberCount),
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: c.ink3),
                onPressed: () => _renameTeam(context, ref, team),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 20, color: c.ink3),
                onPressed: () => _deleteTeam(context, ref, team),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(l.teamMembersTitle,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.ink2)),
          ),
          const SizedBox(height: 8),
          if (team.members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Text(l.teamNoMembers,
                  style: TextStyle(fontSize: 14, color: c.ink3)),
            )
          else
            for (final m in team.members)
              _MemberRow(team: team, member: m),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addMember(context, ref, team),
              icon: Icon(Icons.person_add_alt_1_outlined,
                  size: 18, color: c.accentText),
              label: Text(l.teamAddMember,
                  style: TextStyle(
                      color: c.accentText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  final Team team;
  final TeamMember member;
  const _MemberRow({required this.team, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.ink)),
                    ),
                    const SizedBox(width: 8),
                    _Badge(linked: member.linked),
                  ],
                ),
                if (member.defaultRate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                        '${l.teamDefaultRate} ${formatMoney(member.defaultRate!, context.lang)}',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: c.ink2,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                  ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, size: 18, color: c.ink3),
            onPressed: () => _editMember(context, ref, team, member),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove_circle_outline_rounded,
                size: 18, color: c.ink3),
            onPressed: () => _deleteMember(context, ref, team, member),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final bool linked;
  const _Badge({required this.linked});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final bg = linked
        ? c.deposited.withValues(alpha: 0.12)
        : c.ink2.withValues(alpha: 0.12);
    final fg = linked ? c.depositedBadge : c.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(linked ? Icons.link : Icons.edit_note_rounded,
              size: 12, color: fg),
          const SizedBox(width: 3),
          Text(linked ? l.teamMemberLinked : l.teamMemberManual,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

// ── 액션 ────────────────────────────────────────────────────

Future<void> _createTeam(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final name = await _promptName(context, initial: '');
  if (name == null || name.trim().isEmpty) return;
  try {
    await ref.read(repoProvider).createTeam(name.trim());
    ref.invalidate(teamsProvider);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<void> _renameTeam(
    BuildContext context, WidgetRef ref, Team team) async {
  final messenger = ScaffoldMessenger.of(context);
  final name = await _promptName(context, initial: team.name);
  if (name == null || name.trim().isEmpty || name.trim() == team.name) return;
  try {
    await ref.read(repoProvider).updateTeam(team.id, name.trim());
    ref.invalidate(teamsProvider);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<String?> _promptName(BuildContext context, {required String initial}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _NamePromptDialog(initial: initial),
  );
}

/// 팀 이름 입력 다이얼로그 — 컨트롤러를 스스로 소유·해제한다.
class _NamePromptDialog extends StatefulWidget {
  final String initial;
  const _NamePromptDialog({required this.initial});
  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  late final TextEditingController _ctl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return AlertDialog(
      backgroundColor: c.surface,
      title: Text(l.teamNameLabel,
          style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
      content: TextField(
        controller: _ctl,
        autofocus: true,
        style:
            TextStyle(fontSize: 16, color: c.ink, fontWeight: FontWeight.w600),
        decoration: InputDecoration(hintText: l.teamNameHint),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(
            onPressed: () => Navigator.pop(context, _ctl.text),
            child: Text(l.save)),
      ],
    );
  }
}

Future<void> _deleteTeam(BuildContext context, WidgetRef ref, Team team) async {
  final l = context.l;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await _confirm(context, l.teamDeleteConfirm);
  if (ok != true) return;
  try {
    await ref.read(repoProvider).deleteTeam(team.id);
    ref.invalidate(teamsProvider);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<void> _deleteMember(
    BuildContext context, WidgetRef ref, Team team, TeamMember member) async {
  final l = context.l;
  final messenger = ScaffoldMessenger.of(context);
  final ok = await _confirm(context, l.teamDeleteMemberConfirm);
  if (ok != true) return;
  try {
    await ref.read(repoProvider).deleteTeamMember(team.id, member.id);
    ref.invalidate(teamsProvider);
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

Future<bool?> _confirm(BuildContext context, String message) {
  final c = context.c;
  final l = context.l;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      content: Text(message, style: TextStyle(color: c.ink, fontSize: 15)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete,
                style: TextStyle(color: c.receivable))),
      ],
    ),
  );
}

/// 팀원 편집(이름·전화·기본단가). 가입 연결 팀원의 이름은 스냅샷이므로 편집 허용.
Future<void> _editMember(
    BuildContext context, WidgetRef ref, Team team, TeamMember member) async {
  final nameCtl = TextEditingController(text: member.name);
  final phoneCtl = TextEditingController(text: member.phone ?? '');
  final rateCtl =
      TextEditingController(text: member.defaultRate?.toString() ?? '');
  final c = context.c;
  final l = context.l;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
            left: 18,
            right: 18,
            top: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.edit,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 14),
            _sheetField(ctx, nameCtl, l.teamMemberNameHint),
            const SizedBox(height: 10),
            _sheetField(ctx, phoneCtl, l.teamMemberPhoneHint,
                keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _sheetField(ctx, rateCtl, l.teamDefaultRateHint,
                keyboard: TextInputType.number),
            const SizedBox(height: 18),
            PrimaryButton(
                label: l.save, onPressed: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await ref.read(repoProvider).updateTeamMember(
              team.id,
              member.id,
              name: nameCtl.text.trim().isEmpty ? null : nameCtl.text.trim(),
              phone: phoneCtl.text.trim(),
              defaultRate: int.tryParse(rateCtl.text.trim()),
            );
        ref.invalidate(teamsProvider);
      } on ApiException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  } finally {
    nameCtl.dispose();
    phoneCtl.dispose();
    rateCtl.dispose();
  }
}

/// 팀원 추가 시트 — 전화 검색 연결 / 직접 입력 두 모드.
Future<void> _addMember(BuildContext context, WidgetRef ref, Team team) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _AddMemberSheet(team: team),
  );
}

Widget _sheetField(BuildContext context, TextEditingController ctl, String hint,
    {TextInputType? keyboard}) {
  final c = context.c;
  return TextField(
    controller: ctl,
    keyboardType: keyboard,
    inputFormatters: keyboard == TextInputType.number
        ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))]
        : null,
    style: TextStyle(fontSize: 16, color: c.ink, fontWeight: FontWeight.w600),
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

class _AddMemberSheet extends ConsumerStatefulWidget {
  final Team team;
  const _AddMemberSheet({required this.team});
  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  bool _phoneMode = true;
  final _searchPhone = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _rate = TextEditingController();
  bool _searching = false;
  bool _saving = false;
  List<WorkerSearchItem>? _results;

  @override
  void dispose() {
    _searchPhone.dispose();
    _name.dispose();
    _phone.dispose();
    _rate.dispose();
    super.dispose();
  }

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

  Future<void> _addByProfile(WorkerSearchItem w) async {
    setState(() => _saving = true);
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(repoProvider).addTeamMemberByProfile(
            widget.team.id,
            w.profileId,
            defaultRate: int.tryParse(_rate.text.trim()),
          );
      ref.invalidate(teamsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.teamMemberAdded)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(_errMsg(context, e))));
    }
  }

  Future<void> _addManual() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(repoProvider).addTeamMemberManual(
            widget.team.id,
            name: name,
            phone: _phone.text.trim(),
            defaultRate: int.tryParse(_rate.text.trim()),
          );
      ref.invalidate(teamsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l.teamMemberAdded)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(_errMsg(context, e))));
    }
  }

  String _errMsg(BuildContext context, ApiException e) {
    final l = context.l;
    switch (e.code) {
      case 'TEAM_MEMBER_EXISTS':
        return l.teamMemberExists;
      case 'CONSENT_REQUIRED':
        return l.teamConsentRequired;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          left: 18,
          right: 18,
          top: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.teamAddMember,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
          const SizedBox(height: 14),
          Row(children: [
            _modeChip(l.teamAddByPhone, _phoneMode,
                () => setState(() => _phoneMode = true)),
            const SizedBox(width: 8),
            _modeChip(l.teamAddManual, !_phoneMode,
                () => setState(() => _phoneMode = false)),
          ]),
          const SizedBox(height: 14),
          if (_phoneMode) ..._phoneModeBody(context) else ..._manualModeBody(context),
        ],
      ),
    );
  }

  List<Widget> _phoneModeBody(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return [
      Row(children: [
        Expanded(
            child: _sheetField(context, _searchPhone, l.teamSearchPhoneHint,
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
      Text(l.teamSearchHint, style: TextStyle(fontSize: 12.5, color: c.ink3)),
      const SizedBox(height: 12),
      if (_results != null && _results!.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(l.teamSearchNoResult,
              style: TextStyle(fontSize: 14, color: c.ink3)),
        ),
      if (_results != null && _results!.isNotEmpty) ...[
        _sheetField(context, _rate, l.teamDefaultRateHint,
            keyboard: TextInputType.number),
        const SizedBox(height: 10),
        for (final w in _results!)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: c.fieldBg,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saving ? null : () => _addByProfile(w),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.person_outline_rounded, color: c.accentText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(w.maskedName,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.ink)),
                    ),
                    Icon(Icons.add_circle_outline_rounded, color: c.accentText),
                  ]),
                ),
              ),
            ),
          ),
      ],
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _manualModeBody(BuildContext context) {
    final l = context.l;
    return [
      _sheetField(context, _name, l.teamMemberNameHint),
      const SizedBox(height: 10),
      _sheetField(context, _phone, l.teamMemberPhoneHint,
          keyboard: TextInputType.phone),
      const SizedBox(height: 10),
      _sheetField(context, _rate, l.teamDefaultRateHint,
          keyboard: TextInputType.number),
      const SizedBox(height: 18),
      PrimaryButton(
        label: l.teamAddMember,
        loading: _saving,
        onPressed: _addManual,
      ),
      const SizedBox(height: 10),
    ];
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
}
