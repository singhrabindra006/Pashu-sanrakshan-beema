import 'package:bloc/bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../data/repositories/application_repository.dart';

/// One cubit per tab (All / Pending / Approved / Rejected) so switching tabs
/// never discards an already loaded list.
class ApplicationListCubit extends PaginatedListCubit<ApplicationModel> {
  ApplicationListCubit(this._repository, {this.status});

  final ApplicationRepository _repository;
  final ApplicationStatus? status;

  @override
  Future<Result<Paginated<ApplicationModel>>> fetchPage(int page) => _repository.list(page: page, status: status);
}

class ApplicationDetailCubit extends Cubit<ItemState<ApplicationModel>> {
  ApplicationDetailCubit(this._repository) : super(const ItemState<ApplicationModel>());

  final ApplicationRepository _repository;

  Future<void> load(int id) async {
    emit(state.copyWith(status: ItemStatus.loading));
    final result = await _repository.detail(id);
    result.fold(
      (application) => emit(ItemState(status: ItemStatus.success, item: application)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, message: error.message)),
    );
  }
}
