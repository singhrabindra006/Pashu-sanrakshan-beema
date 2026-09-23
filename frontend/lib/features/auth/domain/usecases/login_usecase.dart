import '../../../../core/network/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);
}
