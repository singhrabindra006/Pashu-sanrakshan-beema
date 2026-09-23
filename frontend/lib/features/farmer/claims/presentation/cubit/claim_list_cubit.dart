import 'package:bloc/bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/cubit/item_state.dart';
import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/claim_model.dart';
import '../../data/repositories/claim_repository.dart';

class ClaimListCubit extends PaginatedListCubit<ClaimModel> {
  ClaimListCubit(this._repository, {this.status});

  final ClaimRepository _repository;
  final ClaimStatus? status;

  @override
  Future<Result<Paginated<ClaimModel>>> fetchPage(int page) => _repository.list(page: page, status: status);
}

class ClaimDetailCubit extends Cubit<ItemState<ClaimModel>> {
  ClaimDetailCubit(this._repository) : super(const ItemState<ClaimModel>());

  final ClaimRepository _repository;

  Future<void> load(int id) async {
    emit(state.copyWith(status: ItemStatus.loading));
    final result = await _repository.detail(id);
    result.fold(
      (claim) => emit(ItemState(status: ItemStatus.success, item: claim)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, message: error.message)),
    );
  }
}
