import 'package:fpdart/fpdart.dart';
import 'package:sattle_me/core/errors/failure.dart';
import 'package:sattle_me/features/auth/data/datasource/firebase_remote_datasource.dart';
import 'package:sattle_me/features/auth/data/datasource/firebase_user_datasource.dart';

import 'package:sattle_me/features/auth/domain/entities/user_entity.dart';
import 'package:sattle_me/features/auth/domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource authDataSource;
  final FirebaseUserDataSource userDataSource;

  AuthRepositoryImpl({
    required this.authDataSource,
    required this.userDataSource,
  });

  @override
  Future<Either<Failure, User>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await authDataSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final uid = authDataSource.firebaseAuthInstance.currentUser?.uid;

      if (uid == null) {
        print(" ERROR: UID is NULL after signup!");
        return left(ServerFailure(message: "Failed to get UID after sign-up"));
      }

      print(" Retrieved UID: $uid");

      await userDataSource.storeUserData(userModel, uid);

      return right(userModel);
    } catch (e) {
      print(" AuthRepository Error: $e");
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await authDataSource.signIn(
        email: email,
        password: password,
      );

      final uid = authDataSource.firebaseAuthInstance.currentUser?.uid;
      if (uid == null) {
        return left(ServerFailure(message: "Failed to get user UID."));
      }

      final userData = await userDataSource.getUserData(uid);
      if (userData != null) {
        return right(userData);
      } else {
        return left(
          ServerFailure(message: "User data not found in Firestore."),
        );
      }
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
