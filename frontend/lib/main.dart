import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize dependency injection
  await configureDependencies();
  
  runApp(const CitizenCivicApp());
}

class CitizenCivicApp extends StatelessWidget {
  const CitizenCivicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        localizationsDelegates: const [
          // Add localization delegates here
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ta', 'IN'),
          Locale('hi', 'IN'),
        ],
      ),
    );
  }
}
