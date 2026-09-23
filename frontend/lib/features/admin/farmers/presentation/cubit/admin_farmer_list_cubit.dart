import 'package:bloc/bloc.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/farmer_model.dart';
import '../../data/repositories/admin_farmer_repository.dart';

class AdminFarmerListCubit extends PaginatedListCubit<FarmerModel> {
  AdminFarmerListCubit(this._repository);

  final AdminFarmerRepository _repository;

  String? _search;
  bool? _isActive;

  bool? get activeFilter => _isActive;

  @override
  Future<Result<Paginated<FarmerModel>>> fetchPage(int page) =>
      _repository.list(page: page, search: _search, isActive: _isActive);

  Future<void> search(String? term) {
    _search = (term == null || term.trim().isEmpty) ? null : term.trim();
    return load();
  }

  Future<void> setActiveFilter(bool? isActive) {
    _isActive = isActive;
    return load();
  }

  /// Blocks or restores a farmer's access; the row updates in place.
  Future<String?> toggleActive(int userId) async {
    final result = await _repository.toggleActive(userId);
    return result.fold(
      (farmer) {
        if (_isActive == null) {
          replaceItem((item) => item.userId == userId, farmer);
        } else {
          removeItem((item) => item.userId == userId);
        }
        return null;
      },
      (error) => error.message,
    );
  }
}

/// AdminFarmerDetailPage - animals, applications and claims in one payload.
class AdminFarmerDetailCubit extends Cubit<ItemState<FarmerDetailModel>> {
  AdminFarmerDetailCubit(this._repository) : super(const ItemState<FarmerDetailModel>());

  final AdminFarmerRepository _repository;

  Future<void> load(int userId) async {
    emit(state.copyWith(status: ItemStatus.loading));
    final result = await _repository.detail(userId);
    result.fold(
      (detail) => emit(ItemState(status: ItemStatus.success, item: detail)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, message: error.message)),
    );
  }

  Future<String?> toggleActive() async {
    final current = state.item;
    if (current == null) return 'Farmer not loaded';
    final result = await _repository.toggleActive(current.farmer.userId);
    return result.fold(
      (farmer) {
        emit(
          ItemState(
            status: ItemStatus.success,
            item: FarmerDetailModel(
              farmer: farmer,
              animals: current.animals,
              applications: current.applications,
              claims: current.claims,
            ),
            message: farmer.isActive ? 'Farmer activated' : 'Farmer deactivated',
          ),
        );
        return null;
      },
      (error) => error.message,
    );
  }
}
