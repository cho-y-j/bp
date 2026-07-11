import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../core/env.dart';
import '../../core/kakao_auth.dart';
import '../../providers/auth.dart';
import '../../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  bool _kakaoLoading = false;
  String? _error;

  Future<void> _kakaoLogin() async {
    setState(() {
      _kakaoLoading = true;
      _error = null;
    });
    try {
      final token = await KakaoAuth.obtainAccessToken();
      await ref.read(authControllerProvider.notifier).kakaoLogin(token);
      // 라우터 redirect 가 온보딩/홈으로 이동
    } on ApiException catch (e) {
      setState(() => _error = e.code == 'NOT_IMPLEMENTED'
          ? '카카오 로그인 준비 중이에요. 전화번호로 시작해 주세요.'
          : e.message);
    } catch (_) {
      // 사용자가 카카오 로그인을 취소한 경우 등 — 조용히 무시.
    } finally {
      if (mounted) setState(() => _kakaoLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devCode = await ref
          .read(authControllerProvider.notifier)
          .requestCode(_phone.text.trim());
      setState(() {
        _codeSent = true;
        // dev 편의: 서버가 준 devCode 자동 채움
        if (devCode != null && devCode.isNotEmpty) _code.text = devCode;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verify(_phone.text.trim(), _code.text.trim());
      // 라우터 redirect 가 온보딩/홈으로 이동
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: c.primary, borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.bolt_rounded, color: c.primaryInk, size: 26),
                ),
                const SizedBox(width: 12),
                Text('작업온',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800, color: c.ink)),
              ]),
              const SizedBox(height: 28),
              Text('전화번호로 시작하기',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 8),
              Text('일한 것을 30초에 기록하고 확인서·장부·정산을 자동으로 관리하세요.',
                  style: TextStyle(fontSize: 15, color: c.ink2, height: 1.4)),
              const SizedBox(height: 28),
              _Label('전화번호'),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                enabled: !_codeSent,
                style: TextStyle(fontSize: 17, color: c.ink, fontWeight: FontWeight.w600),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                decoration: const InputDecoration(hintText: '01012345678'),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                _Label('인증번호'),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      fontSize: 17,
                      color: c.ink,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()]),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                  decoration: const InputDecoration(hintText: '6자리 인증번호'),
                ),
                const SizedBox(height: 6),
                Text('개발 환경: 인증번호가 자동으로 채워집니다.',
                    style: TextStyle(fontSize: 13, color: c.ink3)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: TextStyle(color: c.receivable, fontSize: 14)),
              ],
              const SizedBox(height: 26),
              if (!_codeSent)
                PrimaryButton(
                  label: '인증번호 받기',
                  icon: Icons.sms_outlined,
                  loading: _loading,
                  onPressed: _phone.text.trim().length >= 10 ? _requestCode : null,
                )
              else
                Column(
                  children: [
                    PrimaryButton(
                      label: '인증하고 시작하기',
                      icon: Icons.arrow_forward_rounded,
                      loading: _loading,
                      onPressed: _code.text.trim().length >= 4 ? _verify : null,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _codeSent = false;
                                _code.clear();
                              }),
                      child: Text('전화번호 다시 입력',
                          style: TextStyle(color: c.accentText, fontSize: 15)),
                    ),
                  ],
                ),
              // 카카오 로그인 — KAKAO_APP_KEY 주입 시에만 노출(없으면 전화 인증만).
              if (Env.kakaoEnabled && !_codeSent) ...[
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: c.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('또는',
                        style: TextStyle(fontSize: 13, color: c.ink3)),
                  ),
                  Expanded(child: Divider(color: c.border)),
                ]),
                const SizedBox(height: 20),
                _KakaoButton(loading: _kakaoLoading, onPressed: _kakaoLogin),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 카카오 로그인 버튼(카카오 브랜드 색). 조건부 노출.
class _KakaoButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _KakaoButton({required this.loading, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    const kakaoYellow = Color(0xFFFEE500);
    const kakaoBrown = Color(0xFF191600);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: kakaoYellow,
          foregroundColor: kakaoBrown,
          disabledBackgroundColor: kakaoYellow.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: kakaoBrown))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('카카오로 시작하기'),
                ],
              ),
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
                fontSize: 13, fontWeight: FontWeight.w700, color: context.c.ink2)),
      );
}
