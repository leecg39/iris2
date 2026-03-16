// @TASK P3-S2-T1 - 매칭 목록 화면 테스트
// @SPEC docs/planning/03-user-flow.md#매칭-목록

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/matching/matching_list_screen.dart';
import 'package:iris/widgets/match_card.dart';
import 'package:iris/widgets/empty_state.dart';

void main() {
  group('MatchingListScreen', () {
    Widget buildSubject() {
      return const MaterialApp(
        home: MatchingListScreen(),
      );
    }

    testWidgets('화면 기본 렌더링 - Scaffold가 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('SearchFilterBar - 검색 TextField 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('SearchFilterBar - 진행중 필터 칩 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('진행중'), findsOneWidget);
    });

    testWidgets('SearchFilterBar - 마감 필터 칩 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('마감'), findsAtLeastNWidgets(1));
    });

    testWidgets('MatchCardList - MatchCard 목록 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(MatchCard), findsAtLeastNWidgets(1));
    });

    testWidgets('정렬 - 적합도순 옵션 존재', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('적합도순'), findsOneWidget);
    });

    testWidgets('loading 상태 - CircularProgressIndicator 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MatchingListScreen(initialState: MatchingListState.loading),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('empty 상태 - EmptyState 위젯 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MatchingListScreen(initialState: MatchingListState.empty),
        ),
      );
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('empty 상태 - 검색 결과 없음 메시지', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MatchingListScreen(initialState: MatchingListState.empty),
        ),
      );
      expect(find.textContaining('검색 결과'), findsOneWidget);
    });

    testWidgets('normal 상태 - MatchCard 목록 렌더링됨', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MatchingListScreen(initialState: MatchingListState.normal),
        ),
      );
      expect(find.byType(MatchCard), findsAtLeastNWidgets(1));
    });

    testWidgets('검색 입력 - TextField에 텍스트 입력 가능', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(find.byType(TextField), 'R&D 지원');
      await tester.pump();
      expect(find.text('R&D 지원'), findsOneWidget);
    });

    testWidgets('필터 칩 탭 - 필터 칩 토글 가능', (tester) async {
      await tester.pumpWidget(buildSubject());
      // 진행중 필터 칩 탭
      await tester.tap(find.textContaining('진행중').first);
      await tester.pump();
      // 에러 없이 렌더링 되어야 함
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
