import '../../../../core/network/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Repairs a registration whose /auth/sync call did not complete.
class SyncUserUseCase {
  const SyncUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({required String fullName}) => _repository.syncUser(fullName: fullName);
}
