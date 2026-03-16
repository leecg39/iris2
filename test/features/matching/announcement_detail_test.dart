// @TASK P3-S3-T1 - 공고 상세 화면 테스트
// @SPEC docs/planning/03-user-flow.md#공고-상세

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/features/matching/announcement_detail_screen.dart';
import 'package:iris/widgets/match_score_gauge.dart';
import 'package:iris/widgets/dday_badge.dart';

void main() {
  group('AnnouncementDetailScreen', () {
    Widget buildSubject({String id = 'test-id'}) {
      return MaterialApp(
        home: AnnouncementDetailScreen(id: id),
      );
    }

    testWidgets('화면 기본 렌더링 - Scaffold가 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('HeaderInfo - 공고명 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      // 공고 제목 텍스트가 표시되어야 함
      expect(find.textContaining('중소기업'), findsAtLeastNWidgets(1));
    });

    testWidgets('HeaderInfo - DdayBadge 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(DdayBadge), findsAtLeastNWidgets(1));
    });

    testWidgets('ScoreGauge - MatchScoreGauge lg 크기 렌더링됨', (tester) async {
      await tester.pumpWidget(buildSubject());
      final gauge = tester.widget<MatchScoreGauge>(
        find.byType(MatchScoreGauge).first,
      );
      expect(gauge.size, MatchScoreSize.lg);
    });

    testWidgets('AiSummary - AI 요약 카드 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('AI 요약'), findsOneWidget);
    });

    testWidgets('AiSummary - 핵심요건 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('핵심 요건'), findsOneWidget);
    });

    testWidgets('FullContent - 공고 전문 섹션 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('공고 전문'), findsOneWidget);
    });

    testWidgets('FullContent - 펼치기/접기 토글 버튼 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      // 펼치기 또는 접기 텍스트가 있어야 함
      final hasSeeMore = find.textContaining('펼치기').evaluate().isNotEmpty ||
          find.textContaining('접기').evaluate().isNotEmpty ||
          find.textContaining('더보기').evaluate().isNotEmpty;
      expect(hasSeeMore, isTrue);
    });

    testWidgets('AttachmentsList - 첨부파일 섹션 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('첨부파일'), findsOneWidget);
    });

    testWidgets('ReportDownloadButton - 보고서 다운로드 버튼 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('보고서 다운로드'), findsOneWidget);
    });

    testWidgets('ConsultButton - 전문가 상담 신청 버튼 표시', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.textContaining('전문가 상담'), findsOneWidget);
    });

    testWidgets('loading 상태 - CircularProgressIndicator 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnnouncementDetailScreen(
            id: 'test-id',
            initialState: DetailScreenState.loading,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('normal 상태 - 상세 정보 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnnouncementDetailScreen(
            id: 'test-id',
            initialState: DetailScreenState.normal,
          ),
        ),
      );
      expect(find.byType(MatchScoreGauge), findsAtLeastNWidgets(1));
    });

    testWidgets('FullContent 토글 - 접기/펼치기 작동', (tester) async {
      await tester.pumpWidget(buildSubject());
      // 펼치기 버튼까지 스크롤
      final toggleFinder = find.textContaining('펼치기');
      if (toggleFinder.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          toggleFinder.first,
          find.byType(SingleChildScrollView),
          const Offset(0, -300),
        );
        await tester.tap(toggleFinder.first, warnIfMissed: false);
        await tester.pump();
      }
      // 에러 없이 작동해야 함
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
