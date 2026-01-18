import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/complaints/presentation/bloc/complaints_bloc.dart';
import '../../features/complaints/data/repositories/complaints_repository.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/community/presentation/bloc/community_bloc.dart';
import '../../features/community/data/repositories/community_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  
  // Dio HTTP client
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  
  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = getIt<FlutterSecureStorage>();
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle token expiration
          getIt<AuthBloc>().add(AuthLogoutRequested());
        }
        return handler.next(error);
      },
    ),
  );
  
  getIt.registerSingleton<Dio>(dio);
  
  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<Dio>()),
  );
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );
  
  getIt.registerLazySingleton<ComplaintsRepository>(
    () => ComplaintsRepository(dio: getIt<Dio>()),
  );
  
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepository(dio: getIt<Dio>()),
  );
  
  getIt.registerLazySingleton<CommunityRepository>(
    () => CommunityRepository(dio: getIt<Dio>()),
  );
  
  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(repository: getIt<AuthRepository>()),
  );
  
  getIt.registerFactory<ComplaintsBloc>(
    () => ComplaintsBloc(repository: getIt<ComplaintsRepository>()),
  );
  
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(repository: getIt<ChatRepository>()),
  );
  
  getIt.registerFactory<CommunityBloc>(
    () => CommunityBloc(repository: getIt<CommunityRepository>()),
  );
}
