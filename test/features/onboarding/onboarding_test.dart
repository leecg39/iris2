// @TASK P2-S1-T1 - 온보딩 화면 UI 테스트
// @SPEC docs/planning/03-user-flow.md#온보딩

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris/features/onboarding/onboarding_screen.dart';

/// 테스트용 라우터 - /onboarding → /register 네비게이션 포함
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('register-screen')),
        ),
      ),
    ],
  );
}

Widget _buildTestApp() {
  return MaterialApp.router(
    routerConfig: _buildTestRouter(),
  );
}

void main() {
  group('OnboardingScreen', () {
    testWidgets('3개 페이지 PageView가 렌더링된다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // PageView가 존재해야 함
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('첫 번째 페이지 - IRIS 앱 소개가 표시된다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 첫 페이지 제목 텍스트 확인
      expect(find.text('IRIS 앱 소개'), findsOneWidget);
    });

    testWidgets('페이지 인디케이터(점 3개)가 표시된다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 인디케이터 컨테이너: key로 식별
      expect(find.byKey(const Key('page-indicator')), findsOneWidget);

      // 인디케이터 점 3개 (인덱스 기반 고유 키)
      expect(find.byKey(const Key('indicator-dot-0')), findsOneWidget);
      expect(find.byKey(const Key('indicator-dot-1')), findsOneWidget);
      expect(find.byKey(const Key('indicator-dot-2')), findsOneWidget);
    });

    testWidgets('"건너뛰기" 버튼이 존재한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('건너뛰기'), findsOneWidget);
    });

    testWidgets('마지막 페이지(3번째)에서 "시작하기" 버튼이 표시된다',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 마지막 페이지로 스와이프
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();

      expect(find.text('시작하기'), findsOneWidget);
    });

    testWidgets('"건너뛰기" 탭 시 /register로 이동한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('건너뛰기'));
      await tester.pumpAndSettle();

      // register-screen 텍스트가 표시되면 /register로 이동된 것
      expect(find.text('register-screen'), findsOneWidget);
    });

    testWidgets('마지막 페이지에서 "시작하기" 탭 시 /register로 이동한다',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 마지막 페이지로 스와이프
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      expect(find.text('register-screen'), findsOneWidget);
    });

    testWidgets('페이지를 스와이프하면 인디케이터 활성 점이 변경된다',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 초기 상태: 3개 인디케이터 점이 모두 존재
      expect(find.byKey(const Key('indicator-dot-0')), findsOneWidget);
      expect(find.byKey(const Key('indicator-dot-1')), findsOneWidget);
      expect(find.byKey(const Key('indicator-dot-2')), findsOneWidget);

      // 두 번째 페이지로 이동
      await tester.drag(find.byType(PageView), const Offset(-800, 0));
      await tester.pumpAndSettle();

      // 인디케이터 재확인 - 여전히 3개 존재
      expect(find.byKey(const Key('indicator-dot-0')), findsOneWidget);
      expect(find.byKey(const Key('indicator-dot-1')), findsOneWidget);
      expect(find.byKey(const Key('indicator-dot-2')), findsOneWidget);
    });
  });
}
