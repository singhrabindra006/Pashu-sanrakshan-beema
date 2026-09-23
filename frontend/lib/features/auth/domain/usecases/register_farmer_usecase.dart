import '../../../../core/network/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterFarmerUseCase {
  const RegisterFarmerUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String fullName,
    required String email,
    required String password,
  }) =>
      _repository.registerFarmer(fullName: fullName, email: email, password: password);
}
