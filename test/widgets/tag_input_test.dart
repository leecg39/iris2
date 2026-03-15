// @TASK P1-S0-T3 - TagInput 위젯 테스트
// @SPEC docs/planning/05-design-system.md#공통-위젯

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/widgets/tag_input.dart';

void main() {
  group('TagInput', () {
    testWidgets('기본 렌더링 - 태그 없는 초기 상태', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInput(
              tags: const [],
              onTagsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TagInput), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('기존 태그 Chip 형태로 표시', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInput(
              tags: const ['Flutter', 'Dart', 'AI'],
              onTagsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      // Chip 위젯 3개 확인
      expect(find.byType(Chip), findsNWidgets(3));
    });

    testWidgets('태그 삭제 버튼(X) - 삭제 시 onTagsChanged 호출', (tester) async {
      List<String> currentTags = ['Flutter', 'Dart'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TagInput(
                tags: currentTags,
                onTagsChanged: (newTags) {
                  setState(() => currentTags = newTags);
                },
              ),
            ),
          ),
        ),
      );

      // Flutter 태그의 삭제 아이콘 탭
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(currentTags.contains('Flutter'), isFalse);
      expect(currentTags.contains('Dart'), isTrue);
    });

    testWidgets('TextField에 텍스트 입력 후 Enter - 새 태그 추가', (tester) async {
      List<String> currentTags = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TagInput(
                tags: currentTags,
                onTagsChanged: (newTags) {
                  setState(() => currentTags = newTags);
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'NewTag');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(currentTags.contains('NewTag'), isTrue);
    });

    testWidgets('placeholder - TextField에 hint 텍스트 표시', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInput(
              tags: const [],
              onTagsChanged: (_) {},
              placeholder: '태그를 입력하세요',
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, '태그를 입력하세요');
    });

    testWidgets('placeholder null - 기본 힌트 또는 빈 힌트', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TagInput(
              tags: const [],
              onTagsChanged: (_) {},
            ),
          ),
        ),
      );

      // 에러 없이 렌더링되어야 함
      expect(find.byType(TagInput), findsOneWidget);
    });

    testWidgets('빈 텍스트 입력 시 태그 추가 안 됨', (tester) async {
      List<String> currentTags = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TagInput(
                tags: currentTags,
                onTagsChanged: (newTags) {
                  setState(() => currentTags = newTags);
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(currentTags.isEmpty, isTrue);
    });

    testWidgets('태그 추가 후 TextField 초기화됨', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TagInput(
                tags: const [],
                onTagsChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'TestTag');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text ?? '', isEmpty);
    });
  });
}
