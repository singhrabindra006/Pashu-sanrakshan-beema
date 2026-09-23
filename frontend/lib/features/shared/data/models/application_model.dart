import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// Flattened join of applications + animal + scheme + farmer, which is exactly
/// what every list and detail screen renders.
class ApplicationModel extends Equatable {
  const ApplicationModel({
    required this.id,
    required this.applicationNumber,
    required this.farmerProfileId,
    required this.animalId,
    required this.schemeId,
    required this.coverageAmount,
    required this.status,
    required this.animalEarTag,
    required this.animalType,
    required this.schemeName,
    required this.schemeMaxCoverage,
    required this.farmerName,
    required this.claimCount,
    this.policyNumber,
    this.policyStartDate,
    this.policyEndDate,
    this.rejectionReason,
    this.decidedByName,
    this.decidedAt,
    this.createdAt,
    this.animalBreed,
    this.animalAgeMonths = 0,
    this.animalPhotoUrl,
    this.schemeStartDate,
    this.schemeEndDate,
    this.farmerEmail,
    this.farmerPhone,
  });

  final int id;
  final String applicationNumber;
  final int farmerProfileId;
  final int animalId;
  final int schemeId;
  final double coverageAmount;
  final ApplicationStatus status;
  final String? policyNumber;
  final String? policyStartDate;
  final String? policyEndDate;
  final String? rejectionReason;
  final String? decidedByName;
  final DateTime? decidedAt;
  final DateTime? createdAt;

  final String animalEarTag;
  final AnimalType animalType;
  final String? animalBreed;
  final int animalAgeMonths;
  final String? animalPhotoUrl;

  final String schemeName;
  final double schemeMaxCoverage;
  final String? schemeStartDate;
  final String? schemeEndDate;

  final String farmerName;
  final String? farmerEmail;
  final String? farmerPhone;
  final int claimCount;

  bool get isPending => status == ApplicationStatus.pending;
  bool get isApproved => status == ApplicationStatus.approved;
  bool get isRejected => status == ApplicationStatus.rejected;

  /// Used by the claim form dropdown label.
  String get policyLabel => '${policyNumber ?? applicationNumber} - $animalEarTag';

  factory ApplicationModel.fromJson(Map<String, dynamic> json) => ApplicationModel(
        id: (json['id'] as num).toInt(),
        applicationNumber: json['application_number'] as String? ?? '',
        farmerProfileId: (json['farmer_profile_id'] as num?)?.toInt() ?? 0,
        animalId: (json['animal_id'] as num?)?.toInt() ?? 0,
        schemeId: (json['scheme_id'] as num?)?.toInt() ?? 0,
        coverageAmount: (json['coverage_amount'] as num?)?.toDouble() ?? 0,
        status: ApplicationStatus.fromValue(json['status'] as String? ?? 'PENDING'),
        policyNumber: json['policy_number'] as String?,
        policyStartDate: json['policy_start_date']?.toString(),
        policyEndDate: json['policy_end_date']?.toString(),
        rejectionReason: json['rejection_reason'] as String?,
        decidedByName: json['decided_by_name'] as String?,
        decidedAt: DateTime.tryParse(json['decided_at']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        animalEarTag: json['animal_ear_tag'] as String? ?? '',
        animalType: AnimalType.fromValue(json['animal_type'] as String? ?? 'COW'),
        animalBreed: json['animal_breed'] as String?,
        animalAgeMonths: (json['animal_age_months'] as num?)?.toInt() ?? 0,
        animalPhotoUrl: json['animal_photo_url'] as String?,
        schemeName: json['scheme_name'] as String? ?? '',
        schemeMaxCoverage: (json['scheme_max_coverage'] as num?)?.toDouble() ?? 0,
        schemeStartDate: json['scheme_start_date']?.toString(),
        schemeEndDate: json['scheme_end_date']?.toString(),
        farmerName: json['farmer_name'] as String? ?? '',
        farmerEmail: json['farmer_email'] as String?,
        farmerPhone: json['farmer_phone'] as String?,
        claimCount: (json['claim_count'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [id, applicationNumber, status, coverageAmount, policyNumber, decidedAt];
}
