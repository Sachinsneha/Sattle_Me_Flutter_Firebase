import 'package:fpdart/fpdart.dart';
import 'package:sattle_me/core/errors/failure.dart';
import 'package:sattle_me/core/usecases/usecase.dart';
import 'package:sattle_me/features/auth/domain/entities/user_entity.dart';
import 'package:sattle_me/features/auth/domain/repository/auth_repository.dart';

class SignInParams {
  final String email;
  final String password;
  SignInParams({required this.email, required this.password});
}

class SignIn implements UseCase<User, SignInParams> {
  final AuthRepository repository;
  SignIn(this.repository);

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    return repository.signIn(email: params.email, password: params.password);
  }
}
