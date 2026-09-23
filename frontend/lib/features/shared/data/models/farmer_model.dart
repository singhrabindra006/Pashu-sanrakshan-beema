import 'package:equatable/equatable.dart';

import 'animal_model.dart';
import 'application_model.dart';
import 'claim_model.dart';

/// Row on AdminFarmerListPage.
class FarmerModel extends Equatable {
  const FarmerModel({
    required this.userId,
    required this.farmerProfileId,
    required this.fullName,
    required this.email,
    required this.isActive,
    required this.animalCount,
    required this.applicationCount,
    required this.claimCount,
    this.phone,
    this.imageUrl,
    this.createdAt,
  });

  final int userId;
  final int farmerProfileId;
  final String fullName;
  final String email;
  final String? phone;
  final String? imageUrl;
  final bool isActive;
  final int animalCount;
  final int applicationCount;
  final int claimCount;
  final DateTime? createdAt;

  factory FarmerModel.fromJson(Map<String, dynamic> json) => FarmerModel(
        userId: (json['user_id'] as num).toInt(),
        farmerProfileId: (json['farmer_profile_id'] as num?)?.toInt() ?? 0,
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        imageUrl: json['image_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        animalCount: (json['animal_count'] as num?)?.toInt() ?? 0,
        applicationCount: (json['application_count'] as num?)?.toInt() ?? 0,
        claimCount: (json['claim_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  @override
  List<Object?> get props => [userId, fullName, email, phone, isActive, animalCount, applicationCount, claimCount];
}

/// Payload behind AdminFarmerDetailPage's three tabs.
class FarmerDetailModel extends Equatable {
  const FarmerDetailModel({
    required this.farmer,
    required this.animals,
    required this.applications,
    required this.claims,
  });

  final FarmerModel farmer;
  final List<AnimalModel> animals;
  final List<ApplicationModel> applications;
  final List<ClaimModel> claims;

  factory FarmerDetailModel.fromJson(Map<String, dynamic> json) => FarmerDetailModel(
        farmer: FarmerModel.fromJson(json['farmer'] as Map<String, dynamic>),
        animals: (json['animals'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AnimalModel.fromJson)
            .toList(),
        applications: (json['applications'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ApplicationModel.fromJson)
            .toList(),
        claims: (json['claims'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ClaimModel.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [farmer, animals, applications, claims];
}
