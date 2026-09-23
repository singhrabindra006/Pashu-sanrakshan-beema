import 'package:equatable/equatable.dart';

class SchemeModel extends Equatable {
  const SchemeModel({
    required this.id,
    required this.name,
    required this.maxCoverage,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isAvailable,
    this.description,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? description;
  final double maxCoverage;
  final String startDate;
  final String endDate;
  final bool isActive;

  /// Active AND today is inside the validity window - only then can a farmer apply.
  final bool isAvailable;
  final DateTime? createdAt;

  /// Label for the Active/Inactive chips on the admin list.
  String get statusLabel => isActive ? (isAvailable ? 'ACTIVE' : 'EXPIRED') : 'INACTIVE';

  factory SchemeModel.fromJson(Map<String, dynamic> json) => SchemeModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        maxCoverage: (json['max_coverage'] as num?)?.toDouble() ?? 0,
        startDate: json['start_date']?.toString().substring(0, 10) ?? '',
        endDate: json['end_date']?.toString().substring(0, 10) ?? '',
        isActive: json['is_active'] as bool? ?? false,
        isAvailable: json['is_available'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  @override
  List<Object?> get props => [id, name, description, maxCoverage, startDate, endDate, isActive, isAvailable];
}
