// @TASK P2-S3-T1 - 기업 프로필 설정 화면 UI 테스트
// @SPEC docs/planning/03-user-flow.md#프로필-설정

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iris/features/profile/profile_edit_screen.dart';

/// 테스트용 기업 정보 mock 데이터
const _mockCompanyData = ProfileCompanyData(
  companyName: '테스트 주식회사',
  ceoName: '홍길동',
  industry: 'IT서비스',
  revenue: 5000000000, // 50억
  employeeCount: 42,
  address: '서울시 강남구 테헤란로 123',
);

/// 테스트용 라우터
GoRouter _buildTestRouter({ProfileCompanyData? companyData}) {
  return GoRouter(
    initialLocation: '/profile/edit',
    routes: [
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => ProfileEditScreen(
          companyData: companyData ?? _mockCompanyData,
        ),
      ),
    ],
  );
}

Widget _buildTestApp({ProfileCompanyData? companyData}) {
  return MaterialApp.router(
    routerConfig: _buildTestRouter(companyData: companyData),
  );
}

void main() {
  group('ProfileEditScreen', () {
    group('화면 렌더링', () {
      testWidgets('"프로필 설정" 제목이 AppBar에 표시된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('프로필 설정'), findsOneWidget);
      });
    });

    group('자동 채움 섹션 (읽기 전용)', () {
      testWidgets('회사명이 표시된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('테스트 주식회사'), findsOneWidget);
      });

      testWidgets('대표자명이 표시된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('홍길동'), findsOneWidget);
      });

      testWidgets('업종이 표시된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('IT서비스'), findsOneWidget);
      });

      testWidgets('매출액이 억원 단위로 포맷되어 표시된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // 5000000000원 → "50억원"
        expect(find.text('50억원'), findsOneWidget);
      });

      testWidgets('직원수가 명 단위로 표시된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('42명'), findsOneWidget);
      });

      testWidgets('주소가 표시된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('서울시 강남구 테헤란로 123'), findsOneWidget);
      });
    });

    group('연구분야 멀티셀렉트', () {
      testWidgets('연구분야 Chip들이 표시된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // 미리 정의된 옵션 6개가 Chip으로 표시
        expect(find.text('ICT'), findsOneWidget);
        expect(find.text('BT'), findsOneWidget);
        expect(find.text('NT'), findsOneWidget);
        expect(find.text('ET'), findsOneWidget);
        expect(find.text('ST'), findsOneWidget);
        expect(find.text('기타'), findsOneWidget);
      });

      testWidgets('Chip을 탭하면 선택 상태가 토글된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // ICT Chip 탭
        await tester.tap(find.text('ICT'));
        await tester.pump();

        // 선택된 Chip이 존재하는지 확인 (FilterChip selected 상태)
        final chip = tester.widget<FilterChip>(
          find.ancestor(
            of: find.text('ICT'),
            matching: find.byType(FilterChip),
          ),
        );
        expect(chip.selected, isTrue);
      });

      testWidgets('선택된 Chip을 다시 탭하면 선택 해제된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        // ICT 선택
        await tester.tap(find.text('ICT'));
        await tester.pump();

        // ICT 다시 탭하여 선택 해제
        await tester.tap(find.text('ICT'));
        await tester.pump();

        final chip = tester.widget<FilterChip>(
          find.ancestor(
            of: find.text('ICT'),
            matching: find.byType(FilterChip),
          ),
        );
        expect(chip.selected, isFalse);
      });
    });

    group('기술키워드 TagInput', () {
      testWidgets('TagInput 위젯이 존재한다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('technology-keywords-input')), findsOneWidget);
      });
    });

    group('저장 버튼', () {
      testWidgets('"저장" 버튼이 존재한다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('save-button')), findsOneWidget);
        expect(find.text('저장'), findsOneWidget);
      });

      testWidgets('저장 버튼은 ElevatedButton이다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(
          find.ancestor(
            of: find.text('저장'),
            matching: find.byType(ElevatedButton),
          ),
          findsOneWidget,
        );
      });
    });

    group('로딩 상태', () {
      testWidgets('초기 상태에서 로딩 인디케이터가 표시되지 않는다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('로딩 상태일 때 CircularProgressIndicator가 표시된다',
          (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        final screenState = tester.state<ProfileEditScreenState>(
          find.byType(ProfileEditScreen),
        );
        screenState.setLoadingForTest();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('로딩 상태일 때 저장 버튼이 비활성화된다', (tester) async {
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        final screenState = tester.state<ProfileEditScreenState>(
          find.byType(ProfileEditScreen),
        );
        screenState.setLoadingForTest();
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('save-button')),
        );
        expect(button.onPressed, isNull);
      });
    });
  });
}
