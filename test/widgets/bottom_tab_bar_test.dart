// @TASK P1-S0-T1 - 하단 탭바 위젯 테스트
// @SPEC docs/planning/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris/widgets/bottom_tab_bar.dart';

// 테스트용 간단 라우터
GoRouter _buildTestRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return IrisBottomTabBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('홈 화면'))),
          ),
          GoRoute(
            path: '/matching',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('매칭 화면'))),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('보고서 화면'))),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('설정 화면'))),
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('IrisBottomTabBar 위젯 테스트', () {
    testWidgets('4개 탭이 렌더링된다', (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 4개 탭 라벨 존재 확인
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('매칭'), findsOneWidget);
      expect(find.text('보고서'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('홈 아이콘이 렌더링된다', (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsWidgets);
    });

    testWidgets('매칭 아이콘이 렌더링된다', (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('보고서 아이콘이 렌더링된다', (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.description), findsWidgets);
    });

    testWidgets('설정 아이콘이 렌더링된다', (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsWidgets);
    });

    testWidgets('초기 화면은 홈 화면이다', (WidgetTester tester) async {
      final router = _buildTestRouter(initialLocation: '/');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('홈 화면'), findsOneWidget);
    });

    testWidgets('매칭 탭 탭하면 매칭 화면으로 이동한다',
        (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('매칭'));
      await tester.pumpAndSettle();

      expect(find.text('매칭 화면'), findsOneWidget);
    });

    testWidgets('보고서 탭 탭하면 보고서 화면으로 이동한다',
        (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('보고서'));
      await tester.pumpAndSettle();

      expect(find.text('보고서 화면'), findsOneWidget);
    });

    testWidgets('설정 탭 탭하면 설정 화면으로 이동한다',
        (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('설정'));
      await tester.pumpAndSettle();

      expect(find.text('설정 화면'), findsOneWidget);
    });

    testWidgets('BottomNavigationBar 위젯이 존재한다',
        (WidgetTester tester) async {
      final router = _buildTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}
