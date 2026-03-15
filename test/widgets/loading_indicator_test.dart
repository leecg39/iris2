// @TASK P1-S0-T3 - LoadingIndicator 위젯 테스트
// @SPEC docs/planning/05-design-system.md#공통-위젯

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/widgets/loading_indicator.dart';

void main() {
  group('LoadingIndicator', () {
    testWidgets('기본 렌더링 - CircularProgressIndicator 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('message 없을 때 - 메시지 텍스트 미표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      // Text 위젯이 없거나 있어도 빈 텍스트가 아닌 것은 없어야 함
      final texts = tester.widgetList<Text>(find.byType(Text));
      for (final text in texts) {
        expect(text.data?.isEmpty ?? true, isTrue);
      }
    });

    testWidgets('message 있을 때 - 메시지 텍스트 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: '데이터를 불러오는 중...'),
          ),
        ),
      );

      expect(find.text('데이터를 불러오는 중...'), findsOneWidget);
    });

    testWidgets('중앙 배치 - Center 또는 mainAxisAlignment.center 포함', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(),
          ),
        ),
      );

      final hasCenter = find.byType(Center).evaluate().isNotEmpty;
      bool hasColumnCenter = false;
      final columns = tester.widgetList<Column>(find.byType(Column));
      for (final col in columns) {
        if (col.mainAxisAlignment == MainAxisAlignment.center) {
          hasColumnCenter = true;
          break;
        }
      }
      expect(hasCenter || hasColumnCenter, isTrue);
    });

    testWidgets('message와 CircularProgressIndicator 동시 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: '분석 중...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('분석 중...'), findsOneWidget);
    });
  });
}
