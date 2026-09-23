import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Farmer-only sub-object returned inside `/auth/me`.
class FarmerProfileEntity extends Equatable {
  const FarmerProfileEntity({required this.id, this.phone, this.profileImagePath, this.imageUrl});

  final int id;
  final String? phone;
  final String? profileImagePath;
  final String? imageUrl;

  factory FarmerProfileEntity.fromJson(Map<String, dynamic> json) => FarmerProfileEntity(
        id: (json['id'] as num).toInt(),
        phone: json['phone'] as String?,
        profileImagePath: json['profile_image_path'] as String?,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'profile_image_path': profileImagePath,
        'image_url': imageUrl,
      };

  @override
  List<Object?> get props => [id, phone, profileImagePath, imageUrl];
}

/// The signed-in identity. `role` always comes from MySQL - the app never infers
/// it from Firebase custom claims or local state.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.farmerProfile,
    this.createdAt,
  });

  final int id;
  final String firebaseUid;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final FarmerProfileEntity? farmerProfile;
  final DateTime? createdAt;

  bool get isAdmin => role == UserRole.admin;
  bool get isFarmer => role == UserRole.farmer;
  String? get avatarUrl => farmerProfile?.imageUrl;
  String? get phone => farmerProfile?.phone;

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
        id: (json['id'] as num).toInt(),
        firebaseUid: json['firebase_uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        role: UserRole.fromValue(json['role'] as String?),
        isActive: json['is_active'] as bool? ?? true,
        farmerProfile: json['farmer_profile'] == null
            ? null
            : FarmerProfileEntity.fromJson(json['farmer_profile'] as Map<String, dynamic>),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firebase_uid': firebaseUid,
        'email': email,
        'full_name': fullName,
        'role': role.value,
        'is_active': isActive,
        'farmer_profile': farmerProfile?.toJson(),
        'created_at': createdAt?.toIso8601String(),
      };

  UserEntity copyWith({String? fullName, FarmerProfileEntity? farmerProfile}) => UserEntity(
        id: id,
        firebaseUid: firebaseUid,
        email: email,
        fullName: fullName ?? this.fullName,
        role: role,
        isActive: isActive,
        farmerProfile: farmerProfile ?? this.farmerProfile,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, firebaseUid, email, fullName, role, isActive, farmerProfile];
}
