import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/scheme_model.dart';

/// Farmer-facing catalogue: only schemes that are active and in date.
class SchemeRepository {
  const SchemeRepository(this._client);

  final ApiClient _client;

  Future<Result<Paginated<SchemeModel>>> list({int page = 1}) => _client.get(
        ApiEndpoints.schemes,
        query: {'page': page, 'limit': AppConstants.pageSize},
        decoder: (data) => Paginated.fromJson(data, SchemeModel.fromJson),
      );

  Future<Result<SchemeModel>> detail(int id) => _client.get(
        ApiEndpoints.scheme(id),
        decoder: (data) => SchemeModel.fromJson(data as Map<String, dynamic>),
      );
}
