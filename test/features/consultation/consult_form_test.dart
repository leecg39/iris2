// @TASK P4-S2-T1 - 전문가 상담 폼 화면 UI 테스트
// @SPEC docs/planning/03-user-flow.md#전문가-상담

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/consultation/consult_form_screen.dart';

Widget _buildDirect() {
  return const MaterialApp(
    home: ConsultFormScreen(announcementId: 'announce-001'),
  );
}

void main() {
  group('ConsultFormScreen', () {
    testWidgets('화면 기본 렌더링 - Scaffold가 렌더링됨', (tester) async {
      await tester.pumpWidget(_buildDirect());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('"전문가 상담 신청" 제목이 AppBar에 표시된다', (tester) async {
      await tester.pumpWidget(_buildDirect());
      expect(find.textContaining('전문가 상담'), findsAtLeastNWidgets(1));
    });

    group('AutoFilledInfo 자동채움 섹션', () {
      testWidgets('회사명이 읽기전용으로 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.textContaining('회사명'), findsAtLeastNWidgets(1));
      });

      testWidgets('사업자번호가 읽기전용으로 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.textContaining('사업자번호'), findsAtLeastNWidgets(1));
      });

      testWidgets('공고명이 읽기전용으로 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.textContaining('공고명'), findsAtLeastNWidgets(1));
      });

      testWidgets('적합도가 읽기전용으로 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.textContaining('적합도'), findsAtLeastNWidgets(1));
      });
    });

    group('ConsultForm 입력 폼', () {
      testWidgets('이름 입력 필드가 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('consult-name-field')), findsOneWidget);
      });

      testWidgets('이메일 입력 필드가 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('consult-email-field')), findsOneWidget);
      });

      testWidgets('연락처 입력 필드가 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('consult-phone-field')), findsOneWidget);
      });

      testWidgets('문의내용 입력 필드가 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('consult-message-field')), findsOneWidget);
      });
    });

    group('SubmitButton', () {
      testWidgets('"상담 신청" 버튼이 존재한다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(find.byKey(const Key('consult-submit-button')), findsOneWidget);
        expect(find.text('상담 신청'), findsOneWidget);
      });

      testWidgets('"상담 신청" 버튼은 ElevatedButton이다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        expect(
          find.ancestor(
            of: find.text('상담 신청'),
            matching: find.byType(ElevatedButton),
          ),
          findsOneWidget,
        );
      });

      testWidgets('이름이 비어 있을 때 버튼이 비활성화된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('consult-submit-button')),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('이름을 입력하면 버튼이 활성화된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        await tester.pump();

        await tester.enterText(
          find.byKey(const Key('consult-name-field')),
          '홍길동',
        );
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('consult-submit-button')),
        );
        expect(button.onPressed, isNotNull);
      });
    });

    group('submitting 상태', () {
      testWidgets('submitting 상태에서 CircularProgressIndicator가 표시된다',
          (tester) async {
        await tester.pumpWidget(_buildDirect());
        await tester.pump();

        final screenState = tester.state<ConsultFormScreenState>(
          find.byType(ConsultFormScreen),
        );
        screenState.setSubmittingForTest();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('submitting 상태에서 버튼이 비활성화된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        await tester.pump();

        final screenState = tester.state<ConsultFormScreenState>(
          find.byType(ConsultFormScreen),
        );
        screenState.setSubmittingForTest();
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('consult-submit-button')),
        );
        expect(button.onPressed, isNull);
      });
    });

    group('success 상태', () {
      testWidgets('success 상태에서 SuccessDialog가 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        await tester.pump();

        final screenState = tester.state<ConsultFormScreenState>(
          find.byType(ConsultFormScreen),
        );
        // showSuccessDialogForTest를 unawaited로 실행하여 다이얼로그를 pump 후 확인
        screenState.showSuccessDialogForTest(
          tester.element(find.byType(ConsultFormScreen)),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('신청이 접수되었습니다'), findsOneWidget);
        expect(find.textContaining('확인 이메일을 보내드렸습니다'), findsOneWidget);
      });
    });

    group('error 상태', () {
      testWidgets('error 상태에서 에러 메시지가 표시된다', (tester) async {
        await tester.pumpWidget(_buildDirect());
        await tester.pump();

        final screenState = tester.state<ConsultFormScreenState>(
          find.byType(ConsultFormScreen),
        );
        screenState.setErrorForTest('서버 오류가 발생했습니다');
        await tester.pump();

        expect(find.textContaining('서버 오류가 발생했습니다'), findsOneWidget);
      });
    });
  });
}
