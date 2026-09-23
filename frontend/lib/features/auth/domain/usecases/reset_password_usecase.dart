import '../../../../core/network/result.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String email) => _repository.sendPasswordResetEmail(email);
}
