import '../network/api_host.dart';

/// Every path the app calls, relative to [ApiEndpoints.baseUrl].
class ApiEndpoints {
  const ApiEndpoints._();

  static String get baseUrl => ApiHost.baseUrl;

  // --- Auth -----------------------------------------------------------------
  static const String authSync = '/auth/sync';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';

  // --- Farmer profile -------------------------------------------------------
  static const String profileMe = '/profile/me';
  static const String profileMePhoto = '/profile/me/photo';
  static const String profileMeDashboard = '/profile/me/dashboard';

  // --- Schemes --------------------------------------------------------------
  static const String schemes = '/schemes';
  static String scheme(int id) => '/schemes/$id';
  static const String adminSchemes = '/admin/schemes';
  static String adminScheme(int id) => '/admin/schemes/$id';
  static String adminSchemeToggle(int id) => '/admin/schemes/$id/toggle';

  // --- Animals --------------------------------------------------------------
  static const String animals = '/animals';
  static String animal(int id) => '/animals/$id';

  // --- Applications ---------------------------------------------------------
  static const String applications = '/applications';
  static const String claimableApplications = '/applications/claimable';
  static String application(int id) => '/applications/$id';
  static const String adminApplications = '/admin/applications';
  static String adminApplication(int id) => '/admin/applications/$id';
  static String adminApplicationDecide(int id) =>
      '/admin/applications/$id/decide';

  // --- Claims ---------------------------------------------------------------
  static const String claims = '/claims';
  static String claim(int id) => '/claims/$id';
  static const String adminClaims = '/admin/claims';
  static String adminClaim(int id) => '/admin/claims/$id';
  static String adminClaimDecide(int id) => '/admin/claims/$id/decide';

  // --- Admin ----------------------------------------------------------------
  static const String adminDashboard = '/admin/dashboard';
  static const String adminFarmers = '/admin/farmers';
  static String adminFarmer(int id) => '/admin/farmers/$id';
  static String adminFarmerToggle(int id) => '/admin/farmers/$id/toggle';
}
