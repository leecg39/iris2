// @TASK P1-S0-T1 - 하단 탭바 위젯
// @SPEC docs/planning/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// IRIS 앱의 하단 네비게이션 탭바
///
/// 4개 탭: 홈 / 매칭 / 보고서 / 설정
/// Primary 색상: #1565C0
/// Material 3 스타일
class IrisBottomTabBar extends StatelessWidget {
  const IrisBottomTabBar({
    super.key,
    required this.child,
  });

  final Widget child;

  static const _tabs = [
    _TabItem(label: '홈', icon: Icons.home, route: '/'),
    _TabItem(label: '매칭', icon: Icons.search, route: '/matching'),
    _TabItem(label: '보고서', icon: Icons.description, route: '/reports'),
    _TabItem(label: '설정', icon: Icons.settings, route: '/settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/matching')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          context.go(_tabs[index].route);
        },
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
