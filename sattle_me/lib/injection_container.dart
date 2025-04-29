import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:get_it/get_it.dart';
import 'package:sattle_me/features/auth/data/datasource/firebase_remote_datasource.dart';
import 'package:sattle_me/features/auth/data/datasource/firebase_user_datasource.dart';
import 'package:sattle_me/features/auth/data/repository/auth_repository_impl.dart';
import 'package:sattle_me/features/auth/domain/repository/auth_repository.dart';
import 'package:sattle_me/features/auth/domain/usecases/singin_usecase.dart';
import 'package:sattle_me/features/auth/domain/usecases/singup_usecase.dart';
import 'package:sattle_me/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  sl.registerLazySingleton<fb_auth.FirebaseAuth>(
    () => fb_auth.FirebaseAuth.instance,
  );
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Data sources
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(firebaseAuth: sl<fb_auth.FirebaseAuth>()),
  );
  sl.registerLazySingleton<FirebaseUserDataSource>(
    () => FirebaseUserDataSourceImpl(firestore: sl<FirebaseFirestore>()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authDataSource: sl<FirebaseAuthDataSource>(),
      userDataSource: sl<FirebaseUserDataSource>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<SignUp>(() => SignUp(sl<AuthRepository>()));
  sl.registerLazySingleton<SignIn>(() => SignIn(sl<AuthRepository>()));

  // BLoC
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(signInUseCase: sl<SignIn>(), signUpUseCase: sl<SignUp>()),
  );
}
