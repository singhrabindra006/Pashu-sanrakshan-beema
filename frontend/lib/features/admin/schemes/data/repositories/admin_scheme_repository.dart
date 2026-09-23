import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../shared/data/models/scheme_model.dart';

/// Admin catalogue: includes inactive and expired schemes.
class AdminSchemeRepository {
  const AdminSchemeRepository(this._client);

  final ApiClient _client;

  Future<Result<Paginated<SchemeModel>>> list({int page = 1, bool? isActive}) =>
      _client.get(
        ApiEndpoints.adminSchemes,
        query: {
          'page': page,
          'limit': AppConstants.pageSize,
          'is_active': ?isActive,
        },
        decoder: (data) => Paginated.fromJson(data, SchemeModel.fromJson),
      );

  Future<Result<SchemeModel>> detail(int id) => _client.get(
    ApiEndpoints.scheme(id),
    decoder: (data) => SchemeModel.fromJson(data as Map<String, dynamic>),
  );

  Future<Result<SchemeModel>> create({
    required String name,
    String? description,
    required double maxCoverage,
    required DateTime startDate,
    required DateTime endDate,
  }) => _client.post(
    ApiEndpoints.adminSchemes,
    body: _body(name, description, maxCoverage, startDate, endDate),
    decoder: (data) => SchemeModel.fromJson(data as Map<String, dynamic>),
  );

  Future<Result<SchemeModel>> update({
    required int id,
    required String name,
    String? description,
    required double maxCoverage,
    required DateTime startDate,
    required DateTime endDate,
  }) => _client.put(
    ApiEndpoints.adminScheme(id),
    body: _body(name, description, maxCoverage, startDate, endDate),
    decoder: (data) => SchemeModel.fromJson(data as Map<String, dynamic>),
  );

  Future<Result<SchemeModel>> toggle(int id) => _client.patch(
    ApiEndpoints.adminSchemeToggle(id),
    decoder: (data) => SchemeModel.fromJson(data as Map<String, dynamic>),
  );

  Map<String, dynamic> _body(
    String name,
    String? description,
    double maxCoverage,
    DateTime startDate,
    DateTime endDate,
  ) => {
    'name': name,
    'description': description,
    'max_coverage': maxCoverage,
    'start_date': DateFormatter.api(startDate),
    'end_date': DateFormatter.api(endDate),
  };
}
