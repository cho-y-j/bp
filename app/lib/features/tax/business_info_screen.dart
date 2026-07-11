import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../providers/auth.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';

/// 세금계산서 공급자(내 사업자) 정보 입력 — bizNumber/bizName/bizAddress (PATCH /me).
class BusinessInfoScreen extends ConsumerStatefulWidget {
  const BusinessInfoScreen({super.key});
  @override
  ConsumerState<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends ConsumerState<BusinessInfoScreen> {
  final _bizNumber = TextEditingController();
  final _bizName = TextEditingController();
  final _bizAddress = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(authControllerProvider).profile;
    _bizNumber.text = p?.bizNumber ?? '';
    _bizName.text = p?.bizName ?? '';
    _bizAddress.text = p?.bizAddress ?? '';
    for (final ctl in [_bizNumber, _bizName, _bizAddress]) {
      ctl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _bizNumber.dispose();
    _bizName.dispose();
    _bizAddress.dispose();
    super.dispose();
  }

  bool get _valid => _bizNumber.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    try {
      await ref.read(authControllerProvider.notifier).saveBusinessInfo(
            bizNumber: _bizNumber.text,
            bizName: _bizName.text,
            bizAddress: _bizAddress.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
          SnackBar(content: Text(l.bizinfoSavedSnack)));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(
            SnackBar(content: Text(l.bizinfoSaveFailed(e.message))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.bizinfoTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              children: [
                Text(l.bizinfoDesc,
                    style: TextStyle(fontSize: 14, color: c.ink2, height: 1.4)),
                const SizedBox(height: 20),
                _Label(l.bizinfoBizNumberLabel),
                _field(_bizNumber,
                    hint: '000-00-00000', keyboard: TextInputType.text),
                const SizedBox(height: 16),
                _Label(l.bizinfoBizNameLabel),
                _field(_bizName, hint: l.bizinfoBizNameHint),
                const SizedBox(height: 16),
                _Label(l.bizinfoAddressLabel),
                _field(_bizAddress, hint: l.bizinfoAddressHint, maxLines: 2),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: l.save,
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _valid ? _save : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctl,
      {required String hint,
      int maxLines = 1,
      TextInputType keyboard = TextInputType.text}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
      decoration: InputDecoration(hintText: hint),
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
                fontSize: 13, fontWeight: FontWeight.w700, color: context.c.ink2)),
      );
}
