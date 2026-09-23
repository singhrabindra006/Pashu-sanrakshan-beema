import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/applications/presentation/pages/admin_application_detail_page.dart';
import '../../features/admin/applications/presentation/pages/admin_application_list_page.dart';
import '../../features/admin/claims/presentation/pages/admin_claim_detail_page.dart';
import '../../features/admin/claims/presentation/pages/admin_claim_list_page.dart';
import '../../features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/farmers/presentation/pages/admin_farmer_detail_page.dart';
import '../../features/admin/farmers/presentation/pages/admin_farmer_list_page.dart';
import '../../features/admin/schemes/presentation/pages/admin_scheme_form_page.dart';
import '../../features/admin/schemes/presentation/pages/admin_scheme_list_page.dart';
import '../../features/admin/widgets/admin_scaffold.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/farmer/animals/presentation/pages/animal_form_page.dart';
import '../../features/farmer/animals/presentation/pages/animal_list_page.dart';
import '../../features/farmer/applications/presentation/pages/application_detail_page.dart';
import '../../features/farmer/applications/presentation/pages/application_list_page.dart';
import '../../features/farmer/applications/presentation/pages/application_submit_page.dart';
import '../../features/farmer/claims/presentation/pages/claim_detail_page.dart';
import '../../features/farmer/claims/presentation/pages/claim_list_page.dart';
import '../../features/farmer/claims/presentation/pages/claim_submit_page.dart';
import '../../features/farmer/home/presentation/pages/farmer_home_page.dart';
import '../../features/farmer/profile/presentation/pages/profile_page.dart';
import '../../features/farmer/schemes/presentation/pages/scheme_detail_page.dart';
import '../../features/farmer/schemes/presentation/pages/scheme_list_page.dart';
import '../../features/farmer/widgets/farmer_scaffold.dart';
import '../../features/shared/data/models/animal_model.dart';
import '../../features/shared/data/models/scheme_model.dart';
import '../../features/shared/file_viewer/presentation/pages/file_viewer_page.dart';
import 'route_names.dart';

/// Rebuilds the router whenever the auth state changes, which is what drives the
/// redirect below.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  const AppRouter._();

  static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter build(AuthCubit authCubit) {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: Routes.splash,
      debugLogDiagnostics: false,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) => _redirect(authCubit.state, state.matchedLocation),
      routes: [
        GoRoute(path: Routes.splash, builder: (_, __) => const SplashPage()),
        GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
        GoRoute(path: Routes.register, builder: (_, __) => const RegisterPage()),
        GoRoute(path: Routes.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),

        // --- Farmer shell (bottom navigation) ---------------------------------
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => FarmerScaffold(shell: shell),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.farmerHome, builder: (_, __) => const FarmerHomePage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.farmerAnimals, builder: (_, __) => const AnimalListPage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.farmerSchemes, builder: (_, __) => const SchemeListPage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.farmerApplications, builder: (_, __) => const ApplicationListPage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.farmerClaims, builder: (_, __) => const ClaimListPage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.farmerProfile, builder: (_, __) => const ProfilePage())],
            ),
          ],
        ),

        // --- Farmer sub-screens (full screen, over the shell) -----------------
        GoRoute(
          path: Routes.animalForm,
          builder: (_, state) => AnimalFormPage(animal: state.extra as AnimalModel?),
        ),
        GoRoute(
          path: Routes.schemeDetailPattern,
          builder: (_, state) => SchemeDetailPage(
            schemeId: int.parse(state.pathParameters['id']!),
            scheme: state.extra as SchemeModel?,
          ),
        ),
        GoRoute(
          path: Routes.applicationSubmit,
          builder: (_, state) => ApplicationSubmitPage(preselectedSchemeId: state.extra as int?),
        ),
        GoRoute(
          path: Routes.applicationDetailPattern,
          builder: (_, state) => ApplicationDetailPage(applicationId: int.parse(state.pathParameters['id']!)),
        ),
        // Declared before the ":id" route so "submit" is not parsed as an id.
        GoRoute(
          path: Routes.claimSubmit,
          builder: (_, state) => ClaimSubmitPage(preselectedApplicationId: state.extra as int?),
        ),
        GoRoute(
          path: Routes.claimDetailPattern,
          builder: (_, state) => ClaimDetailPage(claimId: int.parse(state.pathParameters['id']!)),
        ),

        // --- Admin shell ------------------------------------------------------
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => AdminScaffold(shell: shell),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.adminDashboard, builder: (_, __) => const AdminDashboardPage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.adminSchemes, builder: (_, __) => const AdminSchemeListPage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.adminApplications, builder: (_, __) => const AdminApplicationListPage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.adminClaims, builder: (_, __) => const AdminClaimListPage())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: Routes.adminFarmers, builder: (_, __) => const AdminFarmerListPage())],
            ),
          ],
        ),

        // --- Admin sub-screens ------------------------------------------------
        GoRoute(
          path: Routes.adminSchemeForm,
          builder: (_, state) => AdminSchemeFormPage(scheme: state.extra as SchemeModel?),
        ),
        GoRoute(
          path: Routes.adminApplicationDetailPattern,
          builder: (_, state) => AdminApplicationDetailPage(applicationId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: Routes.adminClaimDetailPattern,
          builder: (_, state) => AdminClaimDetailPage(claimId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: Routes.adminFarmerDetailPattern,
          builder: (_, state) => AdminFarmerDetailPage(userId: int.parse(state.pathParameters['id']!)),
        ),

        // --- Shared -----------------------------------------------------------
        GoRoute(
          path: Routes.fileViewer,
          builder: (_, state) => FileViewerPage(args: state.extra as FileViewerArgs),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(child: Text('No route for ${state.uri}')),
      ),
    );
  }

  /// The only place that decides which shell a user may see. Role comes from the
  /// backend-verified [AuthState], never from local input.
  static String? _redirect(AuthState auth, String location) {
    if (auth.isResolving) {
      return location == Routes.splash ? null : Routes.splash;
    }

    final user = auth.user;
    if (user == null) {
      if (Routes.publicPaths.contains(location)) return null;
      return Routes.login;
    }

    final home = user.isAdmin ? Routes.adminDashboard : Routes.farmerHome;

    // Signed in but sitting on splash or a public page.
    if (location == Routes.splash || Routes.publicPaths.contains(location)) return home;

    // Cross-role access attempt.
    if (user.isAdmin && location.startsWith('/farmer')) return home;
    if (!user.isAdmin && location.startsWith('/admin')) return home;

    return null;
  }
}
