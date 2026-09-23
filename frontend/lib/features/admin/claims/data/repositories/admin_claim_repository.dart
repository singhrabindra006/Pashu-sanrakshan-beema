import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/claim_model.dart';

class AdminClaimRepository {
  const AdminClaimRepository(this._client);

  final ApiClient _client;

  Future<Result<Paginated<ClaimModel>>> list({int page = 1, ClaimStatus? status, String? search}) => _client.get(
        ApiEndpoints.adminClaims,
        query: {
          'page': page,
          'limit': AppConstants.pageSize,
          if (status != null) 'status': status.value,
          if (search != null && search.isNotEmpty) 'search': search,
        },
        decoder: (data) => Paginated.fromJson(data, ClaimModel.fromJson),
      );

  Future<Result<ClaimModel>> detail(int id) => _client.get(
        ApiEndpoints.adminClaim(id),
        decoder: (data) => ClaimModel.fromJson(data as Map<String, dynamic>),
      );

  Future<Result<ClaimModel>> approve({required int id, required double approvedAmount}) => _client.patch(
        ApiEndpoints.adminClaimDecide(id),
        body: {'action': 'APPROVE', 'approved_amount': approvedAmount},
        decoder: (data) => ClaimModel.fromJson(data as Map<String, dynamic>),
      );

  Future<Result<ClaimModel>> reject({required int id, required String reason}) => _client.patch(
        ApiEndpoints.adminClaimDecide(id),
        body: {'action': 'REJECT', 'reason': reason},
        decoder: (data) => ClaimModel.fromJson(data as Map<String, dynamic>),
      );
}
