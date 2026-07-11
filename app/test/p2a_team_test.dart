import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/l10n/app_localizations.dart';
import 'package:workon/models/models.dart';
import 'package:workon/providers/data.dart';
import 'package:workon/theme/app_theme.dart';
import 'package:workon/features/team/team_screen.dart';
import 'package:workon/features/confirmation/confirmation_form_screen.dart';

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

Team _team() => Team.fromJson({
      'id': 't1',
      'name': '박반장 A팀',
      'memberCount': 2,
      'members': [
        {
          'id': 'm1',
          'name': '홍길동',
          'profileId': 'p1',
          'linked': true,
          'defaultRate': 100000,
        },
        {
          'id': 'm2',
          'name': '김철수',
          'linked': false,
          'defaultRate': 100000,
        },
      ],
    });

void main() {
  group('팀 모델 파싱', () {
    test('Team/TeamMember 필드 매핑', () {
      final t = _team();
      expect(t.name, '박반장 A팀');
      expect(t.memberCount, 2);
      expect(t.members.first.linked, isTrue);
      expect(t.members.first.defaultRate, 100000);
      expect(t.members[1].linked, isFalse);
      expect(t.members[1].profileId, isNull);
    });

    test('Confirmation.isTeam / LedgerEntry.derived', () {
      final teamConf = Confirmation.fromJson({
        'id': 'c1',
        'teamId': 't1',
        'teamEntries': [
          {'name': '홍길동', 'quantity': 1, 'rate': 100000, 'amount': 100000}
        ],
      });
      expect(teamConf.isTeam, isTrue);
      expect(teamConf.teamEntries!.length, 1);

      final plainConf = Confirmation.fromJson({'id': 'c2'});
      expect(plainConf.isTeam, isFalse);

      final derived = LedgerEntry.fromJson(
          {'id': 'l1', 'derived': true, 'sourceConfirmationId': 'c1'});
      expect(derived.derived, isTrue);
      expect(derived.sourceConfirmationId, 'c1');
      final plain = LedgerEntry.fromJson({'id': 'l2'});
      expect(plain.derived, isFalse);
    });
  });

  group('내 팀 화면', () {
    testWidgets('팀이 없으면 빈 상태 + 팀 만들기 버튼', (tester) async {
      await tester.pumpWidget(_app(const TeamScreen(), [
        teamsProvider.overrideWith((ref) async => <Team>[]),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('아직 만든 팀이 없어요'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '팀 만들기'), findsOneWidget);
    });

    testWidgets('팀·팀원·배지를 표시한다', (tester) async {
      await tester.pumpWidget(_app(const TeamScreen(), [
        teamsProvider.overrideWith((ref) async => [_team()]),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('박반장 A팀'), findsOneWidget);
      expect(find.text('팀원 2명'), findsWidgets);
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김철수'), findsOneWidget);
      expect(find.text('가입 연결'), findsOneWidget);
      expect(find.text('수기'), findsOneWidget);
    });
  });

  group('팀 확인서 합계', () {
    testWidgets('팀 선택 시 팀원 단가×공수 합계를 실시간 표시', (tester) async {
      await tester.pumpWidget(_app(const ConfirmationFormScreen(), [
        connectionsProvider.overrideWith((ref) async => <ConnectionItem>[]),
        teamsProvider.overrideWith((ref) async => [_team()]),
      ]));
      await tester.pumpAndSettle();

      // 팀 확인서 토글 ON (첫 번째 Switch = 팀 모드 토글).
      await tester.ensureVisible(find.text('팀 확인서'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // 팀 선택.
      await tester.ensureVisible(find.text('팀을 선택하세요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('팀을 선택하세요'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('박반장 A팀').last);
      await tester.pumpAndSettle();

      // 팀원 2명 각 기본단가 100,000 × 1공수 → 합계 200,000.
      expect(find.text('팀 합계'), findsOneWidget);
      expect(find.textContaining('200,000'), findsWidgets);
    });
  });
}
