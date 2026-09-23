import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/farmer_model.dart';

class AdminFarmerRepository {
  const AdminFarmerRepository(this._client);

  final ApiClient _client;

  Future<Result<Paginated<FarmerModel>>> list({
    int page = 1,
    String? search,
    bool? isActive,
  }) => _client.get(
    ApiEndpoints.adminFarmers,
    query: {
      'page': page,
      'limit': AppConstants.pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      'is_active': ?isActive,
    },
    decoder: (data) => Paginated.fromJson(data, FarmerModel.fromJson),
  );

  /// Farmer plus their animals, applications and claims - the three audit tabs.
  Future<Result<FarmerDetailModel>> detail(int userId) => _client.get(
    ApiEndpoints.adminFarmer(userId),
    decoder: (data) => FarmerDetailModel.fromJson(data as Map<String, dynamic>),
  );

  /// Blocks or restores login access (`users.is_active`).
  Future<Result<FarmerModel>> toggleActive(int userId) => _client.patch(
    ApiEndpoints.adminFarmerToggle(userId),
    decoder: (data) => FarmerModel.fromJson(data as Map<String, dynamic>),
  );
}
