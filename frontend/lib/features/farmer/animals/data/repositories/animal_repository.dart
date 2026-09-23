import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/animal_model.dart';

class AnimalRepository {
  const AnimalRepository(this._client);

  final ApiClient _client;

  Future<Result<Paginated<AnimalModel>>> list({
    int page = 1,
    bool? isActive,
    String? search,
  }) => _client.get(
    ApiEndpoints.animals,
    query: {
      'page': page,
      'limit': AppConstants.pageSize,
      'is_active': ?isActive,
      if (search != null && search.isNotEmpty) 'search': search,
    },
    decoder: (data) => Paginated.fromJson(data, AnimalModel.fromJson),
  );

  Future<Result<AnimalModel>> detail(int id) => _client.get(
    ApiEndpoints.animal(id),
    decoder: (data) => AnimalModel.fromJson(data as Map<String, dynamic>),
  );

  Future<Result<AnimalModel>> create({
    required String earTag,
    required AnimalType animalType,
    String? breed,
    int ageMonths = 0,
    String? photoPath,
  }) => _client.multipart(
    ApiEndpoints.animals,
    fields: {
      'ear_tag': earTag,
      'animal_type': animalType.value,
      if (breed != null && breed.isNotEmpty) 'breed': breed,
      'age_months': ageMonths,
    },
    filePath: photoPath,
    fileField: 'photo',
    decoder: (data) => AnimalModel.fromJson(data as Map<String, dynamic>),
  );

  /// A new [photoPath] replaces the stored photo; omitting it keeps the old one.
  Future<Result<AnimalModel>> update({
    required int id,
    required String earTag,
    required AnimalType animalType,
    String? breed,
    int ageMonths = 0,
    String? photoPath,
  }) => _client.multipart(
    ApiEndpoints.animal(id),
    method: 'PUT',
    fields: {
      'ear_tag': earTag,
      'animal_type': animalType.value,
      if (breed != null && breed.isNotEmpty) 'breed': breed,
      'age_months': ageMonths,
    },
    filePath: photoPath,
    fileField: 'photo',
    decoder: (data) => AnimalModel.fromJson(data as Map<String, dynamic>),
  );

  /// Soft delete - history keeps referencing the animal.
  Future<Result<AnimalModel>> deactivate(int id) => _client.delete(
    ApiEndpoints.animal(id),
    decoder: (data) => AnimalModel.fromJson(data as Map<String, dynamic>),
  );
}
