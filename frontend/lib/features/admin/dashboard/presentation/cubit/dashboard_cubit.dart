import 'package:bloc/bloc.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../shared/data/models/admin_dashboard_model.dart';
import '../../data/repositories/admin_dashboard_repository.dart';

class DashboardCubit extends Cubit<ItemState<AdminDashboardModel>> {
  DashboardCubit(this._repository) : super(const ItemState<AdminDashboardModel>());

  final AdminDashboardRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ItemStatus.loading, item: state.item));
    final result = await _repository.load();
    result.fold(
      (data) => emit(ItemState(status: ItemStatus.success, item: data)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, item: state.item, message: error.message)),
    );
  }
}
