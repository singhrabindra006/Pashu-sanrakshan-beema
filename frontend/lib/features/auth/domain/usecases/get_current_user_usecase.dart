import '../../../../core/network/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  bool get hasSession => _repository.hasFirebaseSession;

  Future<Result<UserEntity>> call() => _repository.getCurrentUser();
}
