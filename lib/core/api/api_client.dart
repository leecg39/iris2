import 'package:dio/dio.dart';

/// 백엔드 API 클라이언트
///
/// FastAPI 백엔드와 통신하는 Dio 인스턴스를 제공한다.
/// 기본 baseUrl은 localhost:8000 (개발 환경).
class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? 'http://localhost:8000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ));

  final Dio _dio;

  /// 사업자번호로 기업 정보를 조회한다.
  ///
  /// POST /api/v1/company/lookup
  /// 반환: {business_number, company_name, ceo_name, industry, revenue, employee_count, address}
  Future<Map<String, dynamic>> lookupCompany(String businessNumber) async {
    final response = await _dio.post(
      '/api/v1/company/lookup',
      data: {'business_number': businessNumber},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
