// @TASK P1-S0-T1 - IrisApp 위젯 (go_router 연동)
// @TASK P1-S0-T2 - appTheme 적용 (디자인 시스템 토큰)
// @SPEC docs/planning/

import 'package:flutter/material.dart';
import 'package:iris/app/routes.dart';
import 'package:iris/core/theme/app_theme.dart';

/// IRIS 앱의 루트 위젯
///
/// ProviderScope는 main.dart에서 감싸므로 여기서는 ConsumerWidget 사용 가능
/// MaterialApp.router로 go_router 연동
/// theme: appTheme 으로 디자인 시스템 토큰 적용
class IrisApp extends StatelessWidget {
  const IrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IRIS 정부지원사업 매칭',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
