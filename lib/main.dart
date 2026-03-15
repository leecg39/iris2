// @TASK P1-S0-T1 - 앱 진입점 (IrisApp 사용)
// @SPEC docs/planning/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iris/app/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: IrisApp(),
    ),
  );
}
