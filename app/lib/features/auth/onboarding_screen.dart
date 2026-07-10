import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../providers/auth.dart';
import '../../widgets/common.dart';

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
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 48, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('반가워요!',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 8),
              Text('확인서에 표시될 이름을 알려주세요.',
                  style: TextStyle(fontSize: 16, color: c.ink2)),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: Text('이름',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: c.ink2)),
              ),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.done,
                style: TextStyle(fontSize: 17, color: c.ink, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(hintText: '예) 김기사'),
                onSubmitted: (_) => _name.text.trim().isNotEmpty ? _save() : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: TextStyle(color: c.receivable, fontSize: 14)),
              ],
              const Spacer(),
              PrimaryButton(
                label: '시작하기',
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
