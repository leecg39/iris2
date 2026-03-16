// @TASK P3-S3-T1 - 공고 상세 화면
// @SPEC docs/planning/03-user-flow.md#공고-상세
// @TEST test/features/matching/announcement_detail_test.dart

import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/theme/spacing.dart';
import '../../widgets/match_score_gauge.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/loading_indicator.dart';

/// 공고 상세 화면 상태
enum DetailScreenState {
  /// 로딩 중
  loading,

  /// 데이터 있음
  normal,
}

/// 공고 상세 데이터 모델 (mock)
class _AnnouncementDetail {
  const _AnnouncementDetail({
    required this.id,
    required this.title,
    required this.organization,
    required this.field,
    required this.deadline,
    required this.score,
    required this.aiSummary,
    required this.keyRequirements,
    required this.qualifications,
    required this.fullContent,
    required this.attachments,
  });

  final String id;
  final String title;
  final String organization;
  final String field;
  final DateTime deadline;
  final int score;
  final String aiSummary;
  final List<String> keyRequirements;
  final List<String> qualifications;
  final String fullContent;
  final List<_AttachmentFile> attachments;
}

class _AttachmentFile {
  const _AttachmentFile({required this.name, required this.size});
  final String name;
  final String size;
}

/// 샘플 공고 상세 데이터
final _mockDetail = _AnnouncementDetail(
  id: 'test-id',
  title: '2024년 중소기업 기술혁신 R&D 지원사업',
  organization: '중소벤처기업부',
  field: 'ICT / 제조혁신',
  deadline: DateTime.now().add(const Duration(days: 15)),
  score: 92,
  aiSummary:
      'AI 분석 결과, 귀사의 ICT 기반 제조업 역량과 R&D 투자 이력이 본 사업의 지원 요건과 매우 높은 적합성을 보입니다. '
      '특히 3년 이상 사업 운영 및 기술개발 실적이 주요 선정 기준과 일치합니다.',
  keyRequirements: [
    '중소기업기본법 상 중소기업',
    '업력 3년 이상',
    '직전 연도 매출 50억원 이하',
    'R&D 투자 비율 5% 이상',
  ],
  qualifications: [
    '기술혁신형 중소기업(Inno-Biz) 인증 우대',
    'ISO 9001 또는 관련 인증 보유 시 가점',
    '수출 실적 보유 기업 우대',
  ],
  fullContent: '''
■ 사업 개요

2024년도 중소기업 기술혁신 R&D 지원사업은 중소기업의 기술경쟁력 강화를 위해 연구개발비를 지원하는 사업입니다.

■ 지원 내용

- 지원금액: 기업당 최대 3억원 (정부출연금 기준)
- 지원기간: 1년 (협약 후 12개월)
- 지원분야: ICT, 제조, 바이오, 에너지 등 전 산업분야

■ 신청 자격

- 중소기업기본법 상 중소기업
- 업력 3년 이상 운영 중인 기업
- 직전 연도 기준 기업부설연구소 또는 연구개발전담부서 보유 기업

■ 신청 방법

1. IRIS 정부지원사업 포털 접속 (www.iris.go.kr)
2. 온라인 신청서 작성 및 제출
3. 사업계획서, 재무제표, 연구인력 현황 제출

■ 선정 절차

서류검토 → 발표평가 → 현장실사 → 최종 선정 발표

■ 문의처

중소벤처기업부 R&D정책과 (042-481-4444)
''',
  attachments: [
    const _AttachmentFile(name: '2024_기술혁신RD_공고문.pdf', size: '2.3 MB'),
    const _AttachmentFile(name: '사업계획서_양식.hwp', size: '156 KB'),
    const _AttachmentFile(name: '신청요령_안내서.pdf', size: '890 KB'),
  ],
);

/// 공고 상세 화면
///
/// - HeaderInfo: 공고명, 기관명, 분야, 마감일
/// - ScoreGauge: 적합도 원형 게이지 (lg)
/// - AiSummary: AI 요약 카드
/// - FullContent: 공고 전문 (접힘/펼침)
/// - AttachmentsList: 첨부파일 목록
/// - ReportDownloadButton: 보고서 다운로드 CTA
/// - ConsultButton: 전문가 상담 신청 CTA
class AnnouncementDetailScreen extends StatefulWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.id,
    this.initialState = DetailScreenState.normal,
  });

  final String id;
  final DetailScreenState initialState;

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late DetailScreenState _state;
  bool _isContentExpanded = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  void _navigateToConsult() {
    // /consult/:id 이동 (go_router 사용)
    // context.push('/consult/${widget.id}');
    // 현재는 mock으로 스낵바 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전문가 상담 신청 화면으로 이동합니다.')),
    );
  }

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('보고서를 다운로드합니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          '공고 상세',
          style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: _state == DetailScreenState.loading
          ? const Center(child: LoadingIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final detail = _mockDetail;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            bottom: 100, // CTA 버튼 높이만큼 여백
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HeaderInfo 섹션
              _HeaderInfo(detail: detail),
              const SizedBox(height: AppSpacing.md),

              // ScoreGauge 섹션
              _ScoreGaugeSection(score: detail.score),
              const SizedBox(height: AppSpacing.md),

              // AiSummary 섹션
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: _AiSummaryCard(
                  summary: detail.aiSummary,
                  keyRequirements: detail.keyRequirements,
                  qualifications: detail.qualifications,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // FullContent 섹션
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: _FullContentSection(
                  content: detail.fullContent,
                  isExpanded: _isContentExpanded,
                  onToggle: () {
                    setState(() => _isContentExpanded = !_isContentExpanded);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // AttachmentsList 섹션
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: _AttachmentsList(attachments: detail.attachments),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),

        // 하단 고정 CTA 버튼
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _CtaButtons(
            onDownload: _downloadReport,
            onConsult: _navigateToConsult,
          ),
        ),
      ],
    );
  }
}

/// 헤더 정보: 공고명, 기관명, 분야, 마감일
class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.detail});

  final _AnnouncementDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title,
            style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.business_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                detail.organization,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.category_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                detail.field,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '마감일: ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${detail.deadline.year}.${detail.deadline.month.toString().padLeft(2, '0')}.${detail.deadline.day.toString().padLeft(2, '0')}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DdayBadge(deadline: detail.deadline),
            ],
          ),
        ],
      ),
    );
  }
}

/// 적합도 게이지 섹션
class _ScoreGaugeSection extends StatelessWidget {
  const _ScoreGaugeSection({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          MatchScoreGauge(score: score, size: MatchScoreSize.lg),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 적합도 점수',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  score >= 80
                      ? '매우 적합'
                      : score >= 50
                          ? '적합'
                          : '보통',
                  style: AppTypography.h2.copyWith(
                    color: score >= 80
                        ? AppColors.success
                        : score >= 50
                            ? AppColors.accent
                            : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '귀사 프로필과 공고 조건을 AI가 분석한 결과입니다.',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// AI 요약 카드
class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard({
    required this.summary,
    required this.keyRequirements,
    required this.qualifications,
  });

  final String summary;
  final List<String> keyRequirements;
  final List<String> qualifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'AI 요약',
                  style: AppTypography.h2.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 요약 텍스트
                Text(
                  summary,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 핵심 요건
                Text(
                  '핵심 요건',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...keyRequirements.map(
                  (req) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            req,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 자격 조건 (우대)
                Text(
                  '우대 조건',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...qualifications.map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Icon(
                            Icons.star_outline,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            q,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 공고 전문 섹션 (접힘/펼침)
class _FullContentSection extends StatelessWidget {
  const _FullContentSection({
    required this.content,
    required this.isExpanded,
    required this.onToggle,
  });

  final String content;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '공고 전문',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // 본문 (접힘/펼침)
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.cardPadding,
                right: AppSpacing.cardPadding,
              ),
              child: Text(
                content,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.cardPadding,
                right: AppSpacing.cardPadding,
              ),
              child: Text(
                content,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          // 토글 버튼
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded ? '접기' : '펼치기',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 첨부파일 목록
class _AttachmentsList extends StatelessWidget {
  const _AttachmentsList({required this.attachments});

  final List<_AttachmentFile> attachments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Text(
              '첨부파일',
              style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
            ),
          ),
          ...attachments.map(
            (file) => _AttachmentItem(file: file),
          ),
        ],
      ),
    );
  }
}

/// 개별 첨부파일 아이템
class _AttachmentItem extends StatelessWidget {
  const _AttachmentItem({required this.file});

  final _AttachmentFile file;

  IconData get _fileIcon {
    final ext = file.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'hwp':
        return Icons.article_outlined;
      case 'xlsx':
      case 'xls':
        return Icons.table_chart_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              _fileIcon,
              size: 24,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    file.size,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.download_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 하단 CTA 버튼 그룹
class _CtaButtons extends StatelessWidget {
  const _CtaButtons({
    required this.onDownload,
    required this.onConsult,
  });

  final VoidCallback onDownload;
  final VoidCallback onConsult;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 보고서 다운로드 버튼 (아웃라인)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('보고서 다운로드'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // 전문가 상담 신청 버튼 (채워진)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onConsult,
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('전문가 상담 신청'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
