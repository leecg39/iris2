// @TASK P1-S0-T3 - MatchCard 위젯 테스트
// @SPEC docs/planning/05-design-system.md#공통-위젯

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/widgets/match_card.dart';
import 'package:iris/widgets/match_score_gauge.dart';
import 'package:iris/widgets/dday_badge.dart';

void main() {
  group('MatchCard', () {
    final testDeadline = DateTime.now().add(const Duration(days: 10));

    testWidgets('기본 렌더링 - 모든 요소 표시', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              title: '중소기업 R&D 지원사업',
              score: 85,
              deadline: testDeadline,
              organization: '중소벤처기업부',
            ),
          ),
        ),
      );

      expect(find.byType(MatchCard), findsOneWidget);
      expect(find.text('중소기업 R&D 지원사업'), findsOneWidget);
      expect(find.text('중소벤처기업부'), findsOneWidget);
      expect(find.byType(MatchScoreGauge), findsOneWidget);
      expect(find.byType(DdayBadge), findsOneWidget);
    });

    testWidgets('MatchScoreGauge가 sm 크기로 렌더링됨', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              title: '테스트 공고',
              score: 70,
              deadline: testDeadline,
              organization: '테스트 기관',
            ),
          ),
        ),
      );

      final gauge = tester.widget<MatchScoreGauge>(find.byType(MatchScoreGauge));
      expect(gauge.size, MatchScoreSize.sm);
      expect(gauge.score, 70);
    });

    testWidgets('onTap 콜백 - 카드 탭 시 호출됨', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              title: '테스트 공고',
              score: 70,
              deadline: testDeadline,
              organization: '테스트 기관',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MatchCard));
      expect(tapped, isTrue);
    });

    testWidgets('onTap null - 탭 콜백 없이 렌더링 가능', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              title: '테스트 공고',
              score: 70,
              deadline: testDeadline,
              organization: '테스트 기관',
            ),
          ),
        ),
      );

      // 에러 없이 렌더링되어야 함
      expect(find.byType(MatchCard), findsOneWidget);
    });

    testWidgets('카드가 Card 또는 InkWell/GestureDetector 위젯을 포함함', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              title: '테스트 공고',
              score: 70,
              deadline: testDeadline,
              organization: '테스트 기관',
              onTap: () {},
            ),
          ),
        ),
      );

      // Card 위젯이 있거나, InkWell/GestureDetector가 있어야 함
      final hasCard = find.byType(Card).evaluate().isNotEmpty;
      final hasInkWell = find.byType(InkWell).evaluate().isNotEmpty;
      final hasGestureDetector = find.byType(GestureDetector).evaluate().isNotEmpty;
      expect(hasCard || hasInkWell || hasGestureDetector, isTrue);
    });

    testWidgets('score prop이 MatchScoreGauge에 전달됨', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              title: '테스트 공고',
              score: 92,
              deadline: testDeadline,
              organization: '테스트 기관',
            ),
          ),
        ),
      );

      final gauge = tester.widget<MatchScoreGauge>(find.byType(MatchScoreGauge));
      expect(gauge.score, 92);
    });
  });
}
