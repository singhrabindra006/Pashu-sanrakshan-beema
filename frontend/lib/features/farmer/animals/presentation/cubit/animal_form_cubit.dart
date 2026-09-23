import 'package:bloc/bloc.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/cubit/item_state.dart';
import '../../../../shared/data/models/animal_model.dart';
import '../../data/repositories/animal_repository.dart';

/// Add/edit form for a single animal, including the photo replacement.
class AnimalFormCubit extends Cubit<ItemState<AnimalModel>> {
  AnimalFormCubit(this._repository, {AnimalModel? existing})
      : _existing = existing,
        super(ItemState<AnimalModel>(item: existing));

  final AnimalRepository _repository;
  final AnimalModel? _existing;

  bool get isEditing => _existing != null;

  Future<void> submit({
    required String earTag,
    required AnimalType animalType,
    String? breed,
    int ageMonths = 0,
    String? photoPath,
  }) async {
    emit(state.copyWith(status: ItemStatus.submitting));

    final result = isEditing
        ? await _repository.update(
            id: _existing!.id,
            earTag: earTag,
            animalType: animalType,
            breed: breed,
            ageMonths: ageMonths,
            photoPath: photoPath,
          )
        : await _repository.create(
            earTag: earTag,
            animalType: animalType,
            breed: breed,
            ageMonths: ageMonths,
            photoPath: photoPath,
          );

    result.fold(
      (animal) => emit(
        ItemState(
          status: ItemStatus.submitted,
          item: animal,
          message: isEditing ? 'Animal updated' : 'Animal registered',
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
