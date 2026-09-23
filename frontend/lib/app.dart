import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/cubit/connectivity_cubit.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/cubit/theme_cubit.dart';
import 'core/theme/cubit/theme_state.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'injection_container.dart';

class LimsApp extends StatefulWidget {
  const LimsApp({super.key});

  @override
  State<LimsApp> createState() => _LimsAppState();
}

class _LimsAppState extends State<LimsApp> {
  late final AuthCubit _authCubit = sl<AuthCubit>();
  late final GoRouter _router = AppRouter.build(_authCubit);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<ConnectivityCubit>.value(value: sl<ConnectivityCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) => MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeState.mode,
          routerConfig: _router,
          builder: (context, child) => _OfflineBanner(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Thin persistent strip so the user knows why requests are failing.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        if (status != ConnectivityStatus.offline) return child;
        return Column(
          children: [
            Expanded(child: child),
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 16, color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Text(
                        'You are offline',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
