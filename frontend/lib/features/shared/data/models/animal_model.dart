import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class AnimalModel extends Equatable {
  const AnimalModel({
    required this.id,
    required this.farmerProfileId,
    required this.earTag,
    required this.animalType,
    required this.ageMonths,
    required this.isActive,
    required this.hasActiveApplication,
    this.breed,
    this.photoUrl,
    this.ownerName,
    this.ownerPhone,
    this.createdAt,
  });

  final int id;
  final int farmerProfileId;
  final String earTag;
  final AnimalType animalType;
  final String? breed;
  final int ageMonths;
  final String? photoUrl;
  final bool isActive;

  /// Blocks deactivation and a second application on the same animal.
  final bool hasActiveApplication;
  final String? ownerName;
  final String? ownerPhone;
  final DateTime? createdAt;

  String get title => '$earTag - ${animalType.label}';

  factory AnimalModel.fromJson(Map<String, dynamic> json) => AnimalModel(
        id: (json['id'] as num).toInt(),
        farmerProfileId: (json['farmer_profile_id'] as num?)?.toInt() ?? 0,
        earTag: json['ear_tag'] as String? ?? '',
        animalType: AnimalType.fromValue(json['animal_type'] as String? ?? 'COW'),
        breed: json['breed'] as String?,
        ageMonths: (json['age_months'] as num?)?.toInt() ?? 0,
        photoUrl: json['photo_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        hasActiveApplication: json['has_active_application'] as bool? ?? false,
        ownerName: json['owner_name'] as String?,
        ownerPhone: json['owner_phone'] as String?,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  @override
  List<Object?> get props => [id, earTag, animalType, breed, ageMonths, photoUrl, isActive, hasActiveApplication];
}
