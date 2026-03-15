// @TASK P1-S0-T1 - go_router 기반 라우팅 설정
// @SPEC docs/planning/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iris/features/home/home_screen.dart';
import 'package:iris/features/matching/matching_screen.dart';
import 'package:iris/features/reports/reports_screen.dart';
import 'package:iris/features/settings/settings_screen.dart';
import 'package:iris/widgets/bottom_tab_bar.dart';

/// IRIS 앱의 go_router 라우터 인스턴스
///
/// 4탭: 홈(/), 매칭(/matching), 보고서(/reports), 설정(/settings)
/// ShellRoute로 탭바 래핑
/// 하위 라우트:
///   - /onboarding
///   - /register
///   - /profile/edit
///   - /matching/:id
///   - /consult/:announcementId
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return IrisBottomTabBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/matching',
          builder: (context, state) => const MatchingScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return _MatchingDetailPlaceholder(id: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    // ShellRoute 외부 라우트 (탭바 없음)
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const _OnboardingPlaceholder(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const _RegisterPlaceholder(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const _ProfileEditPlaceholder(),
    ),
    GoRoute(
      path: '/consult/:announcementId',
      builder: (context, state) {
        final announcementId = state.pathParameters['announcementId'] ?? '';
        return _ConsultPlaceholder(announcementId: announcementId);
      },
    ),
  ],
);

// 하위 라우트 Placeholder 화면들

class _MatchingDetailPlaceholder extends StatelessWidget {
  const _MatchingDetailPlaceholder({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('매칭 상세 - $id')),
      body: const Center(child: Text('매칭 상세 (준비 중)')),
    );
  }
}

class _OnboardingPlaceholder extends StatelessWidget {
  const _OnboardingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('온보딩 (준비 중)')),
    );
  }
}

class _RegisterPlaceholder extends StatelessWidget {
  const _RegisterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('등록 (준비 중)')),
    );
  }
}

class _ProfileEditPlaceholder extends StatelessWidget {
  const _ProfileEditPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('프로필 편집 (준비 중)')),
    );
  }
}

class _ConsultPlaceholder extends StatelessWidget {
  const _ConsultPlaceholder({required this.announcementId});
  final String announcementId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('전문가 상담 - $announcementId')),
      body: const Center(child: Text('전문가 상담 (준비 중)')),
    );
  }
}
