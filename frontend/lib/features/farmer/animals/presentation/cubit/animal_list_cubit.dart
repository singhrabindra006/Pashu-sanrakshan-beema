import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/animal_model.dart';
import '../../data/repositories/animal_repository.dart';

class AnimalListCubit extends PaginatedListCubit<AnimalModel> {
  AnimalListCubit(this._repository);

  final AnimalRepository _repository;

  bool? _isActive;
  String? _search;

  bool? get activeFilter => _isActive;

  @override
  Future<Result<Paginated<AnimalModel>>> fetchPage(int page) =>
      _repository.list(page: page, isActive: _isActive, search: _search);

  /// null = show every animal, true/false = the Active/Inactive filter.
  Future<void> setActiveFilter(bool? isActive) {
    _isActive = isActive;
    return load();
  }

  Future<void> search(String? term) {
    _search = (term == null || term.trim().isEmpty) ? null : term.trim();
    return load();
  }

  /// Soft delete; returns the error message when the backend refuses.
  Future<String?> deactivate(int id) async {
    final result = await _repository.deactivate(id);
    return result.fold(
      (animal) {
        if (_isActive == true) {
          removeItem((item) => item.id == id);
        } else {
          replaceItem((item) => item.id == id, animal);
        }
        return null;
      },
      (error) => error.message,
    );
  }
}
