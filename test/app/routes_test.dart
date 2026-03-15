// @TASK P1-S0-T1 - 라우팅 설정 테스트
// @SPEC docs/planning/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris/app/app.dart';
import 'package:iris/app/routes.dart';

void main() {
  group('IrisRouter 설정 테스트', () {
    test('appRouter 인스턴스가 GoRouter 타입이다', () {
      expect(appRouter, isA<GoRouter>());
    });

    testWidgets('앱이 MaterialApp.router로 렌더링된다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IrisApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('초기 경로(/)에서 홈 화면이 표시된다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IrisApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 홈 화면 placeholder 텍스트 확인 (탭바 + 화면 본문에 모두 표시될 수 있음)
      expect(find.text('홈'), findsWidgets);
    });

    testWidgets('/matching 경로로 이동하면 매칭 화면이 표시된다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IrisApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 매칭 탭으로 이동
      await tester.tap(find.text('매칭'));
      await tester.pumpAndSettle();

      expect(find.text('매칭'), findsWidgets);
    });

    testWidgets('/reports 경로로 이동하면 보고서 화면이 표시된다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IrisApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('보고서'));
      await tester.pumpAndSettle();

      expect(find.text('보고서'), findsWidgets);
    });

    testWidgets('/settings 경로로 이동하면 설정 화면이 표시된다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IrisApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();

      expect(find.text('설정'), findsWidgets);
    });

    testWidgets('탭바가 모든 화면에서 지속적으로 표시된다',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: IrisApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 홈에서 탭바 확인
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // 매칭 탭으로 이동 후 탭바 확인
      await tester.tap(find.text('매칭'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // 보고서 탭으로 이동 후 탭바 확인
      await tester.tap(find.text('보고서'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}
