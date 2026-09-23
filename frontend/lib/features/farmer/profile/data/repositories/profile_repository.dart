import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/profile_model.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final ApiClient _client;

  Future<Result<ProfileModel>> getMyProfile() => _client.get(
        ApiEndpoints.profileMe,
        decoder: (data) => ProfileModel.fromJson(data as Map<String, dynamic>),
      );

  /// Phone is the only editable field.
  Future<Result<ProfileModel>> updatePhone(String phone) => _client.patch(
        ApiEndpoints.profileMe,
        body: {'phone': phone},
        decoder: (data) => ProfileModel.fromJson(data as Map<String, dynamic>),
      );

  Future<Result<ProfileModel>> uploadPhoto(String filePath) => _client.multipart(
        ApiEndpoints.profileMePhoto,
        fields: const {},
        filePath: filePath,
        fileField: 'photo',
        decoder: (data) => ProfileModel.fromJson(data as Map<String, dynamic>),
      );

  Future<Result<FarmerDashboardModel>> getDashboard() => _client.get(
        ApiEndpoints.profileMeDashboard,
        decoder: (data) => FarmerDashboardModel.fromJson(data as Map<String, dynamic>),
      );
}
