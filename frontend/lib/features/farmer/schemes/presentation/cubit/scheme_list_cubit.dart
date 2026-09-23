import 'package:bloc/bloc.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../data/repositories/scheme_repository.dart';

class SchemeListCubit extends PaginatedListCubit<SchemeModel> {
  SchemeListCubit(this._repository);

  final SchemeRepository _repository;

  @override
  Future<Result<Paginated<SchemeModel>>> fetchPage(int page) => _repository.list(page: page);
}

/// SchemeDetailPage; also used to re-check availability before applying.
class SchemeDetailCubit extends Cubit<ItemState<SchemeModel>> {
  SchemeDetailCubit(this._repository) : super(const ItemState<SchemeModel>());

  final SchemeRepository _repository;

  Future<void> load(int id) async {
    emit(state.copyWith(status: ItemStatus.loading));
    final result = await _repository.detail(id);
    result.fold(
      (scheme) => emit(ItemState(status: ItemStatus.success, item: scheme)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, message: error.message)),
    );
  }
}
