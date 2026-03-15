// @TASK P1-S0-T1 - 앱 기본 스모크 테스트 (go_router 적용 후)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iris/app/app.dart';

void main() {
  testWidgets('IRIS 앱 기본 렌더링 스모크 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: IrisApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 탭바가 렌더링되고 홈 탭이 표시됨 (탭바 라벨 + 화면 본문에 모두 표시될 수 있음)
    expect(find.text('홈'), findsWidgets);
  });
}
