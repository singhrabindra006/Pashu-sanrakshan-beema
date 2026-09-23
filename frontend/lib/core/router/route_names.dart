/// Every route path and name in one place so navigation calls stay typo-proof.
class Routes {
  const Routes._();

  // --- Auth -----------------------------------------------------------------
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  /// Screens reachable without a session.
  static const Set<String> publicPaths = {login, register, forgotPassword};

  // --- Farmer shell ---------------------------------------------------------
  static const String farmerHome = '/farmer';
  static const String farmerAnimals = '/farmer/animals';
  static const String farmerSchemes = '/farmer/schemes';
  static const String farmerApplications = '/farmer/applications';
  static const String farmerClaims = '/farmer/claims';
  static const String farmerProfile = '/farmer/profile';

  // --- Farmer sub-screens (pushed over the shell) ---------------------------
  static const String animalForm = '/farmer/animal/form';
  static String schemeDetail(int id) => '/farmer/scheme/$id';
  static const String schemeDetailPattern = '/farmer/scheme/:id';
  static const String applicationSubmit = '/farmer/apply';
  static String applicationDetail(int id) => '/farmer/app/$id';
  static const String applicationDetailPattern = '/farmer/app/:id';
  static const String claimSubmit = '/farmer/claim/submit';
  static String claimDetail(int id) => '/farmer/claim/$id';
  static const String claimDetailPattern = '/farmer/claim/:id';

  // --- Admin shell ----------------------------------------------------------
  static const String adminDashboard = '/admin';
  static const String adminSchemes = '/admin/schemes';
  static const String adminApplications = '/admin/applications';
  static const String adminClaims = '/admin/claims';
  static const String adminFarmers = '/admin/farmers';

  // --- Admin sub-screens ----------------------------------------------------
  static const String adminSchemeForm = '/admin/scheme/form';
  static String adminApplicationDetail(int id) => '/admin/app/$id';
  static const String adminApplicationDetailPattern = '/admin/app/:id';
  static String adminClaimDetail(int id) => '/admin/claim/$id';
  static const String adminClaimDetailPattern = '/admin/claim/:id';
  static String adminFarmerDetail(int id) => '/admin/farmer/$id';
  static const String adminFarmerDetailPattern = '/admin/farmer/:id';

  // --- Shared ---------------------------------------------------------------
  static const String fileViewer = '/viewer';
}
