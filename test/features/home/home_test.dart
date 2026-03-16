// @TASK P3-S1-T1 - 홈 대시보드 화면 테스트
// @SPEC docs/planning/03-user-flow.md#홈-대시보드

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/home/home_screen.dart';
import 'package:iris/widgets/match_card.dart';
import 'package:iris/widgets/dday_badge.dart';

void main() {
  group('HomeScreen', () {
    Widget buildSubject() {
      return const MaterialApp(
        home: HomeScreen(),
      );
    }

    testWidgets('화면 기본 렌더링 - Scaffold가 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('GreetingHeader - 인사 메시지 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      // "안녕하세요" 텍스트가 존재해야 함
      expect(find.textContaining('안녕하세요'), findsOneWidget);
    });

    testWidgets('MatchSummaryCard - 적합 공고 요약 카드 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      // 적합 공고 건수 텍스트가 존재해야 함
      expect(find.textContaining('적합 공고'), findsAtLeastNWidgets(1));
    });

    testWidgets('DeadlineList - 마감 임박 공고 섹션 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      // 마감 임박 섹션 제목이 존재해야 함
      expect(find.textContaining('마감 임박'), findsOneWidget);
    });

    testWidgets('DeadlineList - DdayBadge 위젯 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      // DdayBadge가 하나 이상 렌더링되어야 함
      expect(find.byType(DdayBadge), findsAtLeastNWidgets(1));
    });

    testWidgets('TopMatches - 상위 매칭 섹션 표시', (tester) async {
      // 충분히 큰 화면에서 렌더링
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.textContaining('상위 매칭'), findsOneWidget);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('TopMatches - MatchCard 위젯 렌더링됨', (tester) async {
      // 충분히 큰 화면에서 렌더링
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(MatchCard), findsAtLeastNWidgets(1));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('Pull-to-refresh - RefreshIndicator 포함', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('loading 상태 - CircularProgressIndicator 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(initialState: HomeScreenState.loading),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('empty 상태 - 빈 상태 메시지 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(initialState: HomeScreenState.empty),
        ),
      );
      expect(find.textContaining('공고가 없습니다'), findsOneWidget);
    });

    testWidgets('normal 상태 - 데이터가 있을 때 기본 렌더링', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(initialState: HomeScreenState.normal),
        ),
      );
      await tester.pump();
      expect(find.byType(MatchCard), findsAtLeastNWidgets(1));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });
  });
}
