/// Values that never change at runtime and are safe to read from anywhere.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Livestock Insurance';
  static const String appShortName = 'LIMS';
  static const String supportPhone = '+91 1800 123 4567';
  static const String supportEmail = 'support@lims.local';

  /// Page size used by every paginated list.
  static const int pageSize = 20;

  /// Upload ceilings mirrored from the backend so the app can fail fast.
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int maxEvidenceBytes = 10 * 1024 * 1024;

  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png'];
  static const List<String> evidenceExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
}

/// `animals.animal_type`
enum AnimalType {
  cow('COW', 'Cow'),
  buffalo('BUFFALO', 'Buffalo'),
  goat('GOAT', 'Goat'),
  sheep('SHEEP', 'Sheep');

  const AnimalType(this.value, this.label);
  final String value;
  final String label;

  static AnimalType fromValue(String value) =>
      AnimalType.values.firstWhere((type) => type.value == value.toUpperCase(), orElse: () => AnimalType.cow);
}

/// `claims.incident_type`
enum IncidentType {
  death('DEATH', 'Death'),
  disease('DISEASE', 'Disease'),
  accident('ACCIDENT', 'Accident'),
  theft('THEFT', 'Theft'),
  naturalDisaster('NATURAL_DISASTER', 'Natural disaster'),
  other('OTHER', 'Other');

  const IncidentType(this.value, this.label);
  final String value;
  final String label;

  static IncidentType fromValue(String value) => IncidentType.values
      .firstWhere((type) => type.value == value.toUpperCase(), orElse: () => IncidentType.other);
}

/// `applications.status`
enum ApplicationStatus {
  pending('PENDING', 'Pending'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected');

  const ApplicationStatus(this.value, this.label);
  final String value;
  final String label;

  static ApplicationStatus fromValue(String value) => ApplicationStatus.values
      .firstWhere((status) => status.value == value.toUpperCase(), orElse: () => ApplicationStatus.pending);
}

/// `claims.status`
enum ClaimStatus {
  submitted('SUBMITTED', 'Submitted'),
  approved('APPROVED', 'Approved'),
  rejected('REJECTED', 'Rejected');

  const ClaimStatus(this.value, this.label);
  final String value;
  final String label;

  static ClaimStatus fromValue(String value) => ClaimStatus.values
      .firstWhere((status) => status.value == value.toUpperCase(), orElse: () => ClaimStatus.submitted);
}

/// `users.role` - the backend is the only authority; this is display/routing only.
enum UserRole {
  farmer('FARMER'),
  admin('ADMIN');

  const UserRole(this.value);
  final String value;

  static UserRole fromValue(String? value) =>
      value?.toUpperCase() == 'ADMIN' ? UserRole.admin : UserRole.farmer;
}
