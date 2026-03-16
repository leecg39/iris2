// @TASK P2-S2-T1 - 사업자번호 입력 화면 UI 테스트
// @SPEC docs/planning/03-user-flow.md#사업자번호-입력

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris/features/profile/register_screen.dart';

/// 테스트용 라우터 - /register → /profile/edit 네비게이션 포함
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
  return MaterialApp.router(
    routerConfig: _buildTestRouter(),
  );
}

void main() {
  group('RegisterScreen', () {
    testWidgets('사업자번호 입력 필드가 존재한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('business-number-field')), findsOneWidget);
    });

    testWidgets('"사업자번호 입력" 제목이 표시된다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('사업자번호 입력'), findsOneWidget);
    });

    testWidgets('설명 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.text('사업자번호를 입력하면 기업 정보를 자동으로 가져옵니다'),
        findsOneWidget,
      );
    });

    testWidgets('"조회하기" 버튼이 존재한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('lookup-button')), findsOneWidget);
      expect(find.text('조회하기'), findsOneWidget);
    });

    testWidgets('숫자 10자리 미만 입력 시 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 9자리만 입력 (하이픈 제외 순수 숫자)
      await tester.enterText(
        find.byKey(const Key('business-number-field')),
        '123456789',
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('lookup-button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('숫자 10자리 입력 시 버튼이 활성화된다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('business-number-field')),
        '1234567890',
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('lookup-button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('10자리 입력 시 000-00-00000 형식으로 자동 포맷된다',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('business-number-field')),
        '1234567890',
      );
      await tester.pump();

      // 포맷된 텍스트가 화면에 표시되어야 함
      expect(find.text('123-45-67890'), findsOneWidget);
    });

    testWidgets('입력 필드는 숫자 키보드로 설정되어 있다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('business-number-field')),
      );
      expect(textField.keyboardType, TextInputType.number);
    });

    testWidgets('초기 상태에서 로딩 인디케이터가 표시되지 않는다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('초기 상태에서 에러 메시지가 표시되지 않는다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error-message')), findsNothing);
    });

    testWidgets('로딩 중에는 CircularProgressIndicator가 버튼에 표시된다',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // 테스트용: 로딩 상태를 직접 주입
      final screenState = tester.state<RegisterScreenState>(
        find.byType(RegisterScreen),
      );
      screenState.setLoadingForTest();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('에러 상태일 때 에러 메시지가 표시된다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // RegisterScreen에 에러 상태를 외부에서 주입하기 위해
      // 존재하지 않는 사업자번호(mock error trigger) 사용
      // 실제 구현에서 mock이 에러를 반환하도록 설계
      // 여기서는 위젯 상태를 직접 조작하는 방식으로 검증
      final screenState = tester.state<RegisterScreenState>(
        find.byType(RegisterScreen),
      );
      screenState.setErrorForTest('사업자번호를 찾을 수 없습니다');
      await tester.pump();

      expect(find.byKey(const Key('error-message')), findsOneWidget);
      expect(find.text('사업자번호를 찾을 수 없습니다'), findsOneWidget);
    });

    testWidgets('조회 성공 시 /profile/edit로 이동한다', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final screenState = tester.state<RegisterScreenState>(
        find.byType(RegisterScreen),
      );
      screenState.simulateSuccessForTest();
      await tester.pumpAndSettle();

      expect(find.text('profile-edit-screen'), findsOneWidget);
    });
  });
}
