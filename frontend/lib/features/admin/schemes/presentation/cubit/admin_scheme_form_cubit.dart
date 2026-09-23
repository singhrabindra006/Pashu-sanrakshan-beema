import 'package:bloc/bloc.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../data/repositories/admin_scheme_repository.dart';

class AdminSchemeFormCubit extends Cubit<ItemState<SchemeModel>> {
  AdminSchemeFormCubit(this._repository, {SchemeModel? existing})
      : _existing = existing,
        super(ItemState<SchemeModel>(item: existing));

  final AdminSchemeRepository _repository;
  final SchemeModel? _existing;

  bool get isEditing => _existing != null;

  Future<void> submit({
    required String name,
    String? description,
    required double maxCoverage,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(state.copyWith(status: ItemStatus.submitting, item: _existing));

    final result = isEditing
        ? await _repository.update(
            id: _existing!.id,
            name: name,
            description: description,
            maxCoverage: maxCoverage,
            startDate: startDate,
            endDate: endDate,
          )
        : await _repository.create(
            name: name,
            description: description,
            maxCoverage: maxCoverage,
            startDate: startDate,
            endDate: endDate,
          );

    result.fold(
      (scheme) => emit(
        ItemState(
          status: ItemStatus.submitted,
          item: scheme,
          message: isEditing ? 'Scheme updated' : 'Scheme created',
        ),
      ),
      (error) => emit(
        ItemState(
          status: ItemStatus.failure,
          item: _existing,
          message: error.message,
          fieldErrors: error.fieldErrors,
        ),
      ),
    );
  }
}
