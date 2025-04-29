import 'package:fpdart/fpdart.dart';
import 'package:sattle_me/core/errors/failure.dart';
import 'package:sattle_me/core/usecases/usecase.dart';
import 'package:sattle_me/features/auth/domain/entities/user_entity.dart';
import 'package:sattle_me/features/auth/domain/repository/auth_repository.dart';

class SignUpParams {
  final String fullName;
  final String email;
  final String password;

  SignUpParams({
    required this.fullName,
    required this.email,
    required this.password,
  });
}

class SignUp implements UseCase<User, SignUpParams> {
  final AuthRepository repository;
  SignUp(this.repository);

  @override
  Future<Either<Failure, User>> call(SignUpParams params) async {
    return repository.signUp(
      fullName: params.fullName,
      email: params.email,
      password: params.password,
    );
  }
}
