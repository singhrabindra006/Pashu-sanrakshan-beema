import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

class ClaimModel extends Equatable {
  const ClaimModel({
    required this.id,
    required this.claimNumber,
    required this.applicationId,
    required this.incidentType,
    required this.incidentDate,
    required this.description,
    required this.claimedAmount,
    required this.status,
    required this.applicationNumber,
    required this.coverageAmount,
    required this.farmerProfileId,
    required this.farmerName,
    required this.animalEarTag,
    required this.animalType,
    required this.schemeName,
    this.approvedAmount,
    this.evidenceUrl,
    this.rejectionReason,
    this.decidedByName,
    this.decidedAt,
    this.createdAt,
    this.policyNumber,
    this.policyStartDate,
    this.policyEndDate,
    this.farmerEmail,
    this.farmerPhone,
    this.animalBreed,
    this.animalPhotoUrl,
  });

  final int id;
  final String claimNumber;
  final int applicationId;
  final IncidentType incidentType;
  final String incidentDate;
  final String description;
  final double claimedAmount;
  final double? approvedAmount;
  final String? evidenceUrl;
  final ClaimStatus status;
  final String? rejectionReason;
  final String? decidedByName;
  final DateTime? decidedAt;
  final DateTime? createdAt;

  final String applicationNumber;
  final String? policyNumber;
  final String? policyStartDate;
  final String? policyEndDate;
  final double coverageAmount;

  final int farmerProfileId;
  final String farmerName;
  final String? farmerEmail;
  final String? farmerPhone;

  final String animalEarTag;
  final AnimalType animalType;
  final String? animalBreed;
  final String? animalPhotoUrl;
  final String schemeName;

  bool get isSubmitted => status == ClaimStatus.submitted;
  bool get isApproved => status == ClaimStatus.approved;
  bool get isRejected => status == ClaimStatus.rejected;
  bool get hasEvidence => evidenceUrl != null && evidenceUrl!.isNotEmpty;
  bool get evidenceIsPdf => (evidenceUrl ?? '').toLowerCase().endsWith('.pdf');

  factory ClaimModel.fromJson(Map<String, dynamic> json) => ClaimModel(
        id: (json['id'] as num).toInt(),
        claimNumber: json['claim_number'] as String? ?? '',
        applicationId: (json['application_id'] as num?)?.toInt() ?? 0,
        incidentType: IncidentType.fromValue(json['incident_type'] as String? ?? 'OTHER'),
        incidentDate: json['incident_date']?.toString() ?? '',
        description: json['description'] as String? ?? '',
        claimedAmount: (json['claimed_amount'] as num?)?.toDouble() ?? 0,
        approvedAmount: (json['approved_amount'] as num?)?.toDouble(),
        evidenceUrl: json['evidence_url'] as String?,
        status: ClaimStatus.fromValue(json['status'] as String? ?? 'SUBMITTED'),
        rejectionReason: json['rejection_reason'] as String?,
        decidedByName: json['decided_by_name'] as String?,
        decidedAt: DateTime.tryParse(json['decided_at']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        applicationNumber: json['application_number'] as String? ?? '',
        policyNumber: json['policy_number'] as String?,
        policyStartDate: json['policy_start_date']?.toString(),
        policyEndDate: json['policy_end_date']?.toString(),
        coverageAmount: (json['coverage_amount'] as num?)?.toDouble() ?? 0,
        farmerProfileId: (json['farmer_profile_id'] as num?)?.toInt() ?? 0,
        farmerName: json['farmer_name'] as String? ?? '',
        farmerEmail: json['farmer_email'] as String?,
        farmerPhone: json['farmer_phone'] as String?,
        animalEarTag: json['animal_ear_tag'] as String? ?? '',
        animalType: AnimalType.fromValue(json['animal_type'] as String? ?? 'COW'),
        animalBreed: json['animal_breed'] as String?,
        animalPhotoUrl: json['animal_photo_url'] as String?,
        schemeName: json['scheme_name'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, claimNumber, status, claimedAmount, approvedAmount, decidedAt];
}
