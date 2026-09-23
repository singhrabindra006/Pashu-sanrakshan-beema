import 'package:bloc/bloc.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../data/repositories/admin_application_repository.dart';

/// AdminApplicationDetailPage: loads the application and records the decision.
class AdminApplicationDecisionCubit extends Cubit<ItemState<ApplicationModel>> {
  AdminApplicationDecisionCubit(this._repository) : super(const ItemState<ApplicationModel>());

  final AdminApplicationRepository _repository;

  Future<void> load(int id) async {
    emit(state.copyWith(status: ItemStatus.loading));
    final result = await _repository.detail(id);
    result.fold(
      (application) => emit(ItemState(status: ItemStatus.success, item: application)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, message: error.message)),
    );
  }

  /// Policy number and dates are optional: the backend generates a POL-YYYY-NNNNN
  /// number and a 12-month window when they are omitted.
  Future<void> approve({String? policyNumber, DateTime? startDate, DateTime? endDate}) async {
    final application = state.item;
    if (application == null) return;

    emit(state.copyWith(status: ItemStatus.submitting, item: application));
    final result = await _repository.approve(
      id: application.id,
      policyNumber: policyNumber,
      startDate: startDate,
      endDate: endDate,
    );
    _apply(result.dataOrNull, result.errorOrNull?.message, application, 'Application approved');
  }

  Future<void> reject(String reason) async {
    final application = state.item;
    if (application == null) return;

    emit(state.copyWith(status: ItemStatus.submitting, item: application));
    final result = await _repository.reject(id: application.id, reason: reason);
    _apply(result.dataOrNull, result.errorOrNull?.message, application, 'Application rejected');
  }

  void _apply(ApplicationModel? updated, String? error, ApplicationModel previous, String successMessage) {
    if (updated != null) {
      emit(ItemState(status: ItemStatus.submitted, item: updated, message: successMessage));
      return;
    }
    emit(ItemState(status: ItemStatus.failure, item: previous, message: error));
  }
}
