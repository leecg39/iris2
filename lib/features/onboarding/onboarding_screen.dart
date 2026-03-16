// @TASK P2-S1-T1 - 온보딩 화면 UI 구현
// @SPEC docs/planning/03-user-flow.md#온보딩
// @TEST test/features/onboarding/onboarding_test.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iris/core/theme/colors.dart';
import 'package:iris/core/theme/spacing.dart';
import 'package:iris/core/theme/typography.dart';

/// 온보딩 페이지 데이터 모델
class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// 온보딩 3페이지 데이터
const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    icon: Icons.search_rounded,
    title: 'IRIS 앱 소개',
    description: 'IRIS 사업자번호만 입력하면\n내 기업에 맞는 정부지원사업을\n자동으로 찾아드립니다.',
  ),
  _OnboardingPage(
    icon: Icons.psychology_rounded,
    title: 'AI 기반\n적합도 분석',
    description: 'GPT AI가 공고를 분석하여\n우리 기업과의 적합도를\n정확하게 평가합니다.',
  ),
  _OnboardingPage(
    icon: Icons.handshake_rounded,
    title: '전문가 연결',
    description: '매칭된 사업에 대해\n전문 컨설턴트와 상담을\n바로 연결해 드립니다.',
  ),
];

/// IRIS 온보딩 화면
///
/// - 3페이지 PageView 슬라이드
/// - 하단 페이지 인디케이터
/// - 상단 우측 "건너뛰기" 버튼
/// - 마지막 페이지 "시작하기" ElevatedButton
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _navigateToRegister() {
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 영역: 건너뛰기 버튼
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: TextButton(
                  onPressed: _navigateToRegister,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text(
                    '건너뛰기',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // PageView 영역
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageContent(page: _pages[index]);
                },
              ),
            ),

            // 하단 영역: 인디케이터 + 시작하기 버튼
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.xl,
                top: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // 페이지 인디케이터
                  _PageIndicator(
                    pageCount: _pages.length,
                    currentIndex: _currentPage,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 시작하기 버튼 (마지막 페이지에서만 표시)
                  if (isLastPage)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _navigateToRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '시작하기',
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    // 비어있는 공간 유지 (레이아웃 안정성)
                    const SizedBox(height: 52),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 온보딩 개별 페이지 콘텐츠
class _OnboardingPageContent extends StatelessWidget {
  const _OnboardingPageContent({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 제목
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 설명
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 페이지 인디케이터 (점 3개)
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.pageCount,
    required this.currentIndex,
  });

  final int pageCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('page-indicator'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          key: Key('indicator-dot-$index'),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
