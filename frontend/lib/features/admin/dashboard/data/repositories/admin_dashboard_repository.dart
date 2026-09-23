import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/admin_dashboard_model.dart';

class AdminDashboardRepository {
  const AdminDashboardRepository(this._client);

  final ApiClient _client;

  Future<Result<AdminDashboardModel>> load() => _client.get(
        ApiEndpoints.adminDashboard,
        decoder: (data) => AdminDashboardModel.fromJson(data as Map<String, dynamic>),
      );
}
