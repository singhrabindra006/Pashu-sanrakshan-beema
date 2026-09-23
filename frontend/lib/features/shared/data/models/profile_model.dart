import 'package:equatable/equatable.dart';

class ProfileModel extends Equatable {
  const ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.imageUrl,
    this.createdAt,
  });

  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? imageUrl;
  final DateTime? createdAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: (json['id'] as num).toInt(),
        userId: (json['user_id'] as num?)?.toInt() ?? 0,
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        imageUrl: json['image_url'] as String?,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  @override
  List<Object?> get props => [id, userId, fullName, email, phone, imageUrl];
}

/// Stat cards on FarmerHomePage.
class FarmerDashboardModel extends Equatable {
  const FarmerDashboardModel({
    required this.totalAnimals,
    required this.activeAnimals,
    required this.pendingApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    required this.activePolicies,
    required this.submittedClaims,
    required this.approvedClaims,
    required this.rejectedClaims,
    required this.totalSumInsured,
    required this.totalPayout,
  });

  final int totalAnimals;
  final int activeAnimals;
  final int pendingApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final int activePolicies;
  final int submittedClaims;
  final int approvedClaims;
  final int rejectedClaims;
  final double totalSumInsured;
  final double totalPayout;

  factory FarmerDashboardModel.fromJson(Map<String, dynamic> json) => FarmerDashboardModel(
        totalAnimals: (json['total_animals'] as num?)?.toInt() ?? 0,
        activeAnimals: (json['active_animals'] as num?)?.toInt() ?? 0,
        pendingApplications: (json['pending_applications'] as num?)?.toInt() ?? 0,
        approvedApplications: (json['approved_applications'] as num?)?.toInt() ?? 0,
        rejectedApplications: (json['rejected_applications'] as num?)?.toInt() ?? 0,
        activePolicies: (json['active_policies'] as num?)?.toInt() ?? 0,
        submittedClaims: (json['submitted_claims'] as num?)?.toInt() ?? 0,
        approvedClaims: (json['approved_claims'] as num?)?.toInt() ?? 0,
        rejectedClaims: (json['rejected_claims'] as num?)?.toInt() ?? 0,
        totalSumInsured: (json['total_sum_insured'] as num?)?.toDouble() ?? 0,
        totalPayout: (json['total_payout'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [
        totalAnimals,
        activeAnimals,
        pendingApplications,
        approvedApplications,
        rejectedApplications,
        activePolicies,
        submittedClaims,
        approvedClaims,
        rejectedClaims,
        totalSumInsured,
        totalPayout,
      ];
}
