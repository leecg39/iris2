// @TASK P1-S0-T2 - 앱 간격 시스템 정의
// @SPEC docs/planning/05-design-system.md#간격-시스템

/// IRIS 앱 간격 상수
///
/// 기본 단위: 4px 그리드 시스템
/// 05-design-system.md 기반 정의
class AppSpacing {
  AppSpacing._();

  /// 기본 단위: 4px
  static const double unit = 4.0;

  /// XS: 4px - 아이콘-텍스트 간격 등 최소 여백
  static const double xs = 4.0;

  /// SM: 8px - 컴포넌트 내부 소간격
  static const double sm = 8.0;

  /// MD: 16px - 기본 패딩, 카드 내부 간격
  static const double md = 16.0;

  /// LG: 24px - 섹션 간격, 큰 컴포넌트 간격
  static const double lg = 24.0;

  /// XL: 32px - 페이지 상단 여백, 대형 섹션 간격
  static const double xl = 32.0;

  // 용도별 시맨틱 상수
  /// 카드 패딩: 16px
  static const double cardPadding = 16.0;

  /// 섹션 간격: 24px
  static const double sectionGap = 24.0;

  /// 화면 좌우 패딩: 16px
  static const double screenPadding = 16.0;
}
