import 'package:equatable/equatable.dart';

class ActivityItem extends Equatable {
  const ActivityItem({
    required this.type,
    required this.id,
    required this.reference,
    required this.title,
    required this.subtitle,
    required this.status,
    this.createdAt,
  });

  /// 'APPLICATION' or 'CLAIM' - decides where a tap navigates.
  final String type;
  final int id;
  final String reference;
  final String title;
  final String subtitle;
  final String status;
  final DateTime? createdAt;

  bool get isApplication => type == 'APPLICATION';

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        type: json['type'] as String? ?? 'APPLICATION',
        id: (json['id'] as num?)?.toInt() ?? 0,
        reference: json['reference'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        status: json['status'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  @override
  List<Object?> get props => [type, id, reference, status, createdAt];
}

class AdminDashboardModel extends Equatable {
  const AdminDashboardModel({
    required this.totalFarmers,
    required this.activeFarmers,
    required this.totalAnimals,
    required this.totalSchemes,
    required this.activeSchemes,
    required this.pendingApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    required this.submittedClaims,
    required this.approvedClaims,
    required this.rejectedClaims,
    required this.totalSumInsured,
    required this.totalPayout,
    required this.recentActivity,
  });

  final int totalFarmers;
  final int activeFarmers;
  final int totalAnimals;
  final int totalSchemes;
  final int activeSchemes;
  final int pendingApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final int submittedClaims;
  final int approvedClaims;
  final int rejectedClaims;
  final double totalSumInsured;
  final double totalPayout;
  final List<ActivityItem> recentActivity;

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) => AdminDashboardModel(
        totalFarmers: (json['total_farmers'] as num?)?.toInt() ?? 0,
        activeFarmers: (json['active_farmers'] as num?)?.toInt() ?? 0,
        totalAnimals: (json['total_animals'] as num?)?.toInt() ?? 0,
        totalSchemes: (json['total_schemes'] as num?)?.toInt() ?? 0,
        activeSchemes: (json['active_schemes'] as num?)?.toInt() ?? 0,
        pendingApplications: (json['pending_applications'] as num?)?.toInt() ?? 0,
        approvedApplications: (json['approved_applications'] as num?)?.toInt() ?? 0,
        rejectedApplications: (json['rejected_applications'] as num?)?.toInt() ?? 0,
        submittedClaims: (json['submitted_claims'] as num?)?.toInt() ?? 0,
        approvedClaims: (json['approved_claims'] as num?)?.toInt() ?? 0,
        rejectedClaims: (json['rejected_claims'] as num?)?.toInt() ?? 0,
        totalSumInsured: (json['total_sum_insured'] as num?)?.toDouble() ?? 0,
        totalPayout: (json['total_payout'] as num?)?.toDouble() ?? 0,
        recentActivity: (json['recent_activity'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ActivityItem.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [
        totalFarmers,
        activeFarmers,
        totalAnimals,
        totalSchemes,
        activeSchemes,
        pendingApplications,
        approvedApplications,
        rejectedApplications,
        submittedClaims,
        approvedClaims,
        rejectedClaims,
        totalSumInsured,
        totalPayout,
        recentActivity,
      ];
}
