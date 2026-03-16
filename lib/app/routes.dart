// @TASK P1-S0-T1 - go_router 기반 라우팅 설정
// @SPEC docs/planning/

import 'package:go_router/go_router.dart';
import 'package:iris/features/home/home_screen.dart';
import 'package:iris/features/matching/matching_list_screen.dart';
import 'package:iris/features/matching/announcement_detail_screen.dart';
import 'package:iris/features/onboarding/onboarding_screen.dart';
import 'package:iris/features/profile/profile_edit_screen.dart';
import 'package:iris/features/profile/register_screen.dart';
import 'package:iris/features/consultation/consult_form_screen.dart';
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
          builder: (context, state) => const MatchingListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return AnnouncementDetailScreen(id: id);
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
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const ProfileEditScreen(
        companyData: ProfileCompanyData(
          companyName: '',
          ceoName: '',
          industry: '',
          revenue: 0,
          employeeCount: 0,
          address: '',
        ),
      ),
    ),
    GoRoute(
      path: '/consult/:announcementId',
      builder: (context, state) {
        final announcementId = state.pathParameters['announcementId'] ?? '';
        return ConsultFormScreen(announcementId: announcementId);
      },
    ),
  ],
);
