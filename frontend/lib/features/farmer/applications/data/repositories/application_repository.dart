import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/application_model.dart';

class ApplicationRepository {
  const ApplicationRepository(this._client);

  final ApiClient _client;

  Future<Result<Paginated<ApplicationModel>>> list({int page = 1, ApplicationStatus? status}) => _client.get(
        ApiEndpoints.applications,
        query: {
          'page': page,
          'limit': AppConstants.pageSize,
          if (status != null) 'status': status.value,
        },
        decoder: (data) => Paginated.fromJson(data, ApplicationModel.fromJson),
      );

  Future<Result<ApplicationModel>> detail(int id) => _client.get(
        ApiEndpoints.application(id),
        decoder: (data) => ApplicationModel.fromJson(data as Map<String, dynamic>),
      );

  Future<Result<ApplicationModel>> submit({
    required int animalId,
    required int schemeId,
    required double coverageAmount,
  }) =>
      _client.post(
        ApiEndpoints.applications,
        body: {'animal_id': animalId, 'scheme_id': schemeId, 'coverage_amount': coverageAmount},
        decoder: (data) => ApplicationModel.fromJson(data as Map<String, dynamic>),
      );

  /// Approved policies that a claim can be raised against.
  Future<Result<List<ApplicationModel>>> claimable() => _client.get(
        ApiEndpoints.claimableApplications,
        decoder: (data) => (data as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(ApplicationModel.fromJson)
            .toList(),
      );
}
