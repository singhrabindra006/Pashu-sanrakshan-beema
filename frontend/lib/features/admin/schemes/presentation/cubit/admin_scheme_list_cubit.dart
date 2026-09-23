import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../data/repositories/admin_scheme_repository.dart';

/// One instance per tab: [isActive] true = Active tab, false = Inactive tab.
class AdminSchemeListCubit extends PaginatedListCubit<SchemeModel> {
  AdminSchemeListCubit(this._repository, {this.isActive});

  final AdminSchemeRepository _repository;
  final bool? isActive;

  @override
  Future<Result<Paginated<SchemeModel>>> fetchPage(int page) => _repository.list(page: page, isActive: isActive);

  /// Flips is_active. The row leaves this tab when the tab is filtered.
  Future<String?> toggle(int id) async {
    final result = await _repository.toggle(id);
    return result.fold(
      (scheme) {
        if (isActive == null) {
          replaceItem((item) => item.id == id, scheme);
        } else {
          removeItem((item) => item.id == id);
        }
        return null;
      },
      (error) => error.message,
    );
  }
}
