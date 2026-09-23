import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../shared/data/models/claim_model.dart';

class ClaimRepository {
  const ClaimRepository(this._client);

  final ApiClient _client;

  Future<Result<Paginated<ClaimModel>>> list({int page = 1, ClaimStatus? status}) => _client.get(
        ApiEndpoints.claims,
        query: {
          'page': page,
          'limit': AppConstants.pageSize,
          if (status != null) 'status': status.value,
        },
        decoder: (data) => Paginated.fromJson(data, ClaimModel.fromJson),
      );

  Future<Result<ClaimModel>> detail(int id) => _client.get(
        ApiEndpoints.claim(id),
        decoder: (data) => ClaimModel.fromJson(data as Map<String, dynamic>),
      );

  Future<Result<ClaimModel>> submit({
    required int applicationId,
    required IncidentType incidentType,
    required DateTime incidentDate,
    required String description,
    required double claimedAmount,
    String? evidencePath,
  }) =>
      _client.multipart(
        ApiEndpoints.claims,
        fields: {
          'application_id': applicationId,
          'incident_type': incidentType.value,
          'incident_date': DateFormatter.api(incidentDate),
          'description': description,
          'claimed_amount': claimedAmount,
        },
        filePath: evidencePath,
        fileField: 'evidence',
        decoder: (data) => ClaimModel.fromJson(data as Map<String, dynamic>),
      );
}
