import 'package:bloc/bloc.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../shared/data/models/claim_model.dart';
import '../../data/repositories/admin_claim_repository.dart';

class AdminClaimDecisionCubit extends Cubit<ItemState<ClaimModel>> {
  AdminClaimDecisionCubit(this._repository) : super(const ItemState<ClaimModel>());

  final AdminClaimRepository _repository;

  Future<void> load(int id) async {
    emit(state.copyWith(status: ItemStatus.loading));
    final result = await _repository.detail(id);
    result.fold(
      (claim) => emit(ItemState(status: ItemStatus.success, item: claim)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, message: error.message)),
    );
  }

  /// The approved amount may be less than the claimed amount but never more, and
  /// never more than the remaining sum insured (enforced server-side too).
  Future<void> approve(double approvedAmount) async {
    final claim = state.item;
    if (claim == null) return;

    emit(state.copyWith(status: ItemStatus.submitting, item: claim));
    final result = await _repository.approve(id: claim.id, approvedAmount: approvedAmount);
    _apply(result.dataOrNull, result.errorOrNull?.message, claim, 'Claim approved');
  }

  Future<void> reject(String reason) async {
    final claim = state.item;
    if (claim == null) return;

    emit(state.copyWith(status: ItemStatus.submitting, item: claim));
    final result = await _repository.reject(id: claim.id, reason: reason);
    _apply(result.dataOrNull, result.errorOrNull?.message, claim, 'Claim rejected');
  }

  void _apply(ClaimModel? updated, String? error, ClaimModel previous, String successMessage) {
    if (updated != null) {
      emit(ItemState(status: ItemStatus.submitted, item: updated, message: successMessage));
      return;
    }
    emit(ItemState(status: ItemStatus.failure, item: previous, message: error));
  }
}
