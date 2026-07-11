import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../providers/auth.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .saveProfile(name: _name.text.trim());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 48, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.onbWelcome,
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 8),
              Text(l.onbNamePrompt,
                  style: TextStyle(fontSize: 16, color: c.ink2)),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: Text(l.onbNameLabel,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: c.ink2)),
              ),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.done,
                style: TextStyle(fontSize: 17, color: c.ink, fontWeight: FontWeight.w600),
                decoration: InputDecoration(hintText: l.onbNameHint),
                onSubmitted: (_) => _name.text.trim().isNotEmpty ? _save() : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: TextStyle(color: c.receivable, fontSize: 14)),
              ],
              const Spacer(),
              PrimaryButton(
                label: l.onbStart,
                icon: Icons.check_rounded,
                loading: _loading,
                onPressed: _name.text.trim().isNotEmpty ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
