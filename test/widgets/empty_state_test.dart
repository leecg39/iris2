// @TASK P1-S0-T3 - EmptyState 위젯 테스트
// @SPEC docs/planning/05-design-system.md#공통-위젯

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('기본 렌더링 - 아이콘과 메시지 표시', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search_off,
              message: '검색 결과가 없습니다',
            ),
          ),
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('검색 결과가 없습니다'), findsOneWidget);
    });

    testWidgets('아이콘 크기가 48px', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              message: '데이터가 없습니다',
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 48.0);
    });

    testWidgets('중앙 배치 - Center 위젯 또는 Column mainAxisAlignment.center 포함', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              message: '데이터가 없습니다',
            ),
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

    testWidgets('다른 아이콘과 메시지로도 정상 렌더링', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.notifications_none,
              message: '알림이 없습니다',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.text('알림이 없습니다'), findsOneWidget);
    });

    testWidgets('메시지 텍스트가 Text 위젯으로 렌더링됨', (tester) async {
      const testMessage = '매칭 결과가 없습니다';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search_off,
              message: testMessage,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text(testMessage));
      expect(textWidget.data, testMessage);
    });
  });
}
