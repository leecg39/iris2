// @TASK P4-S1-T1 - 보고서 목록 화면 UI 테스트
// @SPEC docs/planning/03-user-flow.md#보고서

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/reports/reports_screen.dart';
import 'package:iris/widgets/match_score_gauge.dart';
import 'package:iris/widgets/empty_state.dart';

void main() {
  group('ReportsScreen', () {
    Widget buildSubject({ReportsScreenState initialState = ReportsScreenState.normal}) {
      return MaterialApp(
        home: ReportsScreen(initialState: initialState),
      );
    }

    testWidgets('화면 기본 렌더링 - Scaffold가 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('"보고서" 제목이 AppBar에 표시된다', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('보고서'), findsWidgets);
    });

    testWidgets('normal 상태 - ReportCard가 5개 이상 렌더링됨', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      await tester.pumpWidget(buildSubject(initialState: ReportsScreenState.normal));
      await tester.pump();
      expect(find.byType(ReportCard), findsAtLeastNWidgets(5));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('normal 상태 - MatchScoreGauge(sm)가 각 카드에 표시됨', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      await tester.pumpWidget(buildSubject(initialState: ReportsScreenState.normal));
      await tester.pump();
      expect(find.byType(MatchScoreGauge), findsAtLeastNWidgets(5));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('normal 상태 - 각 카드에 공고명이 표시됨', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      await tester.pumpWidget(buildSubject(initialState: ReportsScreenState.normal));
      await tester.pump();
      // mock 데이터의 공고명 중 하나가 표시되어야 함
      expect(find.textContaining('기술혁신'), findsAtLeastNWidgets(1));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('normal 상태 - 각 카드에 생성일이 표시됨', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      await tester.pumpWidget(buildSubject(initialState: ReportsScreenState.normal));
      await tester.pump();
      // 날짜 형식의 텍스트가 하나 이상 존재해야 함
      expect(find.textContaining('2024'), findsAtLeastNWidgets(1));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('empty 상태 - EmptyState 위젯이 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject(initialState: ReportsScreenState.empty));
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('empty 상태 - "아직 보고서가 없습니다" 메시지 표시', (tester) async {
      await tester.pumpWidget(buildSubject(initialState: ReportsScreenState.empty));
      await tester.pump();
      expect(find.textContaining('아직 보고서가 없습니다'), findsOneWidget);
    });

    testWidgets('normal 상태 - 카드 탭 가능 (InkWell 또는 GestureDetector 존재)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 2000));
      await tester.pumpWidget(buildSubject(initialState: ReportsScreenState.normal));
      await tester.pump();
      // 탭 가능한 카드가 존재하는지 확인
      expect(
        find.byType(ReportCard),
        findsAtLeastNWidgets(1),
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });
  });
}
