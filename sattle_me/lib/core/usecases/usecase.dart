import 'package:fpdart/fpdart.dart';
import 'package:sattle_me/core/errors/failure.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}
