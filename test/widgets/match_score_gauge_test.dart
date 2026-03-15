// @TASK P1-S0-T3 - MatchScoreGauge 위젯 테스트
// @SPEC docs/planning/05-design-system.md#공통-위젯

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/widgets/match_score_gauge.dart';

void main() {
  group('MatchScoreGauge', () {
    testWidgets('기본 렌더링 - md 크기, 점수 75', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 75),
          ),
        ),
      );

      expect(find.byType(MatchScoreGauge), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('sm 크기 - 40px SizedBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 50, size: MatchScoreSize.sm),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(MatchScoreGauge),
          matching: find.byType(SizedBox).first,
        ),
      );
      expect(sizedBox.width, 40.0);
      expect(sizedBox.height, 40.0);
    });

    testWidgets('md 크기 - 64px SizedBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 50, size: MatchScoreSize.md),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(MatchScoreGauge),
          matching: find.byType(SizedBox).first,
        ),
      );
      expect(sizedBox.width, 64.0);
      expect(sizedBox.height, 64.0);
    });

    testWidgets('lg 크기 - 120px SizedBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 50, size: MatchScoreSize.lg),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(MatchScoreGauge),
          matching: find.byType(SizedBox).first,
        ),
      );
      expect(sizedBox.width, 120.0);
      expect(sizedBox.height, 120.0);
    });

    testWidgets('80점 이상 - 초록색(#2E7D32) CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 85),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        (indicator.valueColor as AlwaysStoppedAnimation<Color>).value,
        const Color(0xFF2E7D32),
      );
    });

    testWidgets('50~79점 - 오렌지색(#FF6D00) CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 65),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        (indicator.valueColor as AlwaysStoppedAnimation<Color>).value,
        const Color(0xFFFF6D00),
      );
    });

    testWidgets('50점 미만 - 회색(#757575) CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 30),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        (indicator.valueColor as AlwaysStoppedAnimation<Color>).value,
        const Color(0xFF757575),
      );
    });

    testWidgets('경계값 80점 - 초록색', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 80),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        (indicator.valueColor as AlwaysStoppedAnimation<Color>).value,
        const Color(0xFF2E7D32),
      );
    });

    testWidgets('경계값 50점 - 오렌지색', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 50),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(
        (indicator.valueColor as AlwaysStoppedAnimation<Color>).value,
        const Color(0xFFFF6D00),
      );
    });

    testWidgets('progress 값이 score/100 비율로 설정됨', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchScoreGauge(score: 75),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, closeTo(0.75, 0.001));
    });
  });
}
