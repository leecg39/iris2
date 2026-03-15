// @TASK P1-S0-T3 - DdayBadge 위젯 테스트
// @SPEC docs/planning/05-design-system.md#공통-위젯

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/widgets/dday_badge.dart';

void main() {
  group('DdayBadge', () {
    testWidgets('기본 렌더링 - D-5 표시', (tester) async {
      final deadline = DateTime.now().add(const Duration(days: 5));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DdayBadge(deadline: deadline),
          ),
        ),
      );

      expect(find.byType(DdayBadge), findsOneWidget);
      expect(find.text('D-5'), findsOneWidget);
    });

    testWidgets('D-3 이하 - 빨간색(#C62828) 배경', (tester) async {
      final deadline = DateTime.now().add(const Duration(days: 2));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DdayBadge(deadline: deadline),
          ),
        ),
      );

      expect(find.text('D-2'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DdayBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFC62828));
    });

    testWidgets('D-3 경계값 - 빨간색 배경', (tester) async {
      final deadline = DateTime.now().add(const Duration(days: 3));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DdayBadge(deadline: deadline),
          ),
        ),
      );

      expect(find.text('D-3'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DdayBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFC62828));
    });

    testWidgets('D-7 이하 (D-4 ~ D-7) - 노란색(#F9A825) 배경', (tester) async {
      final deadline = DateTime.now().add(const Duration(days: 6));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DdayBadge(deadline: deadline),
          ),
        ),
      );

      expect(find.text('D-6'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DdayBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFF9A825));
    });

    testWidgets('D-7 경계값 - 노란색 배경', (tester) async {
      final deadline = DateTime.now().add(const Duration(days: 7));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DdayBadge(deadline: deadline),
          ),
        ),
      );

      expect(find.text('D-7'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DdayBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFF9A825));
    });

    testWidgets('D-7 초과 - 회색(#757575) 배경', (tester) async {
      final deadline = DateTime.now().add(const Duration(days: 14));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DdayBadge(deadline: deadline),
          ),
        ),
      );

      expect(find.text('D-14'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DdayBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF757575));
    });

    testWidgets('마감된 경우 - "마감" 텍스트 표시', (tester) async {
      final deadline = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DdayBadge(deadline: deadline),
          ),
        ),
      );

      expect(find.text('마감'), findsOneWidget);
    });

    testWidgets('D-0 (오늘 마감) - 빨간색 배경', (tester) async {
      final deadline = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DdayBadge(deadline: deadline),
          ),
        ),
      );

      expect(find.text('D-0'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DdayBadge),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFC62828));
    });
  });
}
