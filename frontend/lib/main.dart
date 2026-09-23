import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/cubit/connectivity_cubit.dart';
import 'core/network/api_client.dart';
import 'core/storage/prefs_storage.dart';
import 'firebase_options.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Persists ThemeCubit and AuthCubit so a cold start lands on the right screen.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory((await getApplicationDocumentsDirectory()).path),
  );

  await configureDependencies();
  await sl<ApiClient>().discoverHost(sl<PrefsStorage>());
  await sl<ConnectivityCubit>().start();

  runApp(const LimsApp());
}
