// @TASK P0-T0.1 - Flutter 프로젝트 초기화 기본 스모크 테스트
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iris/main.dart';

void main() {
  testWidgets('IRIS 앱 기본 렌더링 스모크 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: IrisApp(),
      ),
    );

    expect(find.text('IRIS 정부지원사업 자동 매칭'), findsOneWidget);
    expect(find.text('Phase 0 - 초기화 완료'), findsOneWidget);
  });
}
