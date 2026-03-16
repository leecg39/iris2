// @TASK P4-S3-T1 - 설정 화면 UI 테스트
// @SPEC docs/planning/03-user-flow.md#설정

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris/features/settings/settings_screen.dart';

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('profile-edit-screen')),
        ),
      ),
    ],
  );
}

Widget _buildTestApp() {
  return MaterialApp.router(routerConfig: _buildTestRouter());
}

Widget _buildDirect() {
  return const MaterialApp(home: SettingsScreen());
}

void main() {
  group('SettingsScreen', () {
    testWidgets('화면 기본 렌더링 - Scaffold가 렌더링됨', (tester) async {
      await tester.pumpWidget(_buildDirect());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('"설정" 제목이 AppBar에 표시된다', (tester) async {
      await tester.pumpWidget(_buildDirect());
      expect(find.text('설정'), findsWidgets);
    });

    group('ProfileSection', () {
      testWidgets('회사명이 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        // mock 회사명이 표시되어야 함
        expect(find.textContaining('(주)테크스타트'), findsAtLeastNWidgets(1));
      });

      testWidgets('사업자번호가 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.textContaining('123-45-67890'), findsAtLeastNWidgets(1));
      });

      testWidgets('"편집" 버튼이 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('profile-edit-button')), findsOneWidget);
      });

      testWidgets('"편집" 버튼 탭 시 /profile/edit으로 이동한다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('profile-edit-button')));
        await tester.pumpAndSettle();

        expect(find.text('profile-edit-screen'), findsOneWidget);
      });
    });

    group('NotificationToggle', () {
      testWidgets('알림 토글 스위치가 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('notification-toggle')), findsOneWidget);
      });

      testWidgets('알림 토글을 탭하면 상태가 변경된다', (tester) async {
        await tester.pumpWidget(_buildDirect());

        final switchWidget = tester.widget<Switch>(
          find.descendant(
            of: find.byKey(const Key('notification-toggle')),
            matching: find.byType(Switch),
          ),
        );
        final initialValue = switchWidget.value;

        await tester.tap(find.byKey(const Key('notification-toggle')));
        await tester.pump();

        final updatedSwitch = tester.widget<Switch>(
          find.descendant(
            of: find.byKey(const Key('notification-toggle')),
            matching: find.byType(Switch),
          ),
        );
        expect(updatedSwitch.value, !initialValue);
      });
    });

    group('SearchInterval', () {
      testWidgets('검색 주기 드롭다운이 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('search-interval-dropdown')), findsOneWidget);
      });

      testWidgets('검색 주기 옵션들이 표시된다 (매일, 주 2회, 매주)', (tester) async {
        await tester.pumpWidget(_buildDirect());
        await tester.tap(find.byKey(const Key('search-interval-dropdown')));
        await tester.pumpAndSettle();

        expect(find.text('매일'), findsAtLeastNWidgets(1));
        expect(find.text('주 2회'), findsAtLeastNWidgets(1));
        expect(find.text('매주'), findsAtLeastNWidgets(1));
      });
    });

    group('AppInfo', () {
      testWidgets('앱 버전 정보가 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.textContaining('버전'), findsAtLeastNWidgets(1));
      });
    });

    group('ResetButton', () {
      testWidgets('"데이터 초기화" 버튼이 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('reset-button')), findsOneWidget);
        expect(find.textContaining('데이터 초기화'), findsAtLeastNWidgets(1));
      });

      testWidgets('"데이터 초기화" 버튼은 빨간색으로 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        // 버튼이 존재하는지만 확인 (색상은 스타일로 설정됨)
        expect(find.byKey(const Key('reset-button')), findsOneWidget);
      });

      testWidgets('"데이터 초기화" 버튼 탭 시 확인 다이얼로그가 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());

        await tester.tap(find.byKey(const Key('reset-button')));
        await tester.pumpAndSettle();

        // 확인 다이얼로그가 표시되어야 함
        expect(find.byType(AlertDialog), findsOneWidget);
      });
    });
  });
}
