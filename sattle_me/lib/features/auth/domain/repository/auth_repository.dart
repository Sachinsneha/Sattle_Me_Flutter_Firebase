import 'package:fpdart/fpdart.dart';
import 'package:sattle_me/core/errors/failure.dart';

import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });
}
