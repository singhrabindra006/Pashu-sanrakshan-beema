import 'package:bloc/bloc.dart';

import '../../../../../core/cubit/item_state.dart';
import '../../../../shared/data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Backs ProfilePage: load, edit phone, replace avatar.
class ProfileCubit extends Cubit<ItemState<ProfileModel>> {
  ProfileCubit(this._repository) : super(const ItemState<ProfileModel>());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ItemStatus.loading));
    final result = await _repository.getMyProfile();
    result.fold(
      (profile) => emit(ItemState(status: ItemStatus.success, item: profile)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, message: error.message)),
    );
  }

  Future<ProfileModel?> updatePhone(String phone) async {
    emit(state.copyWith(status: ItemStatus.submitting));
    final result = await _repository.updatePhone(phone);
    return result.fold(
      (profile) {
        emit(ItemState(status: ItemStatus.success, item: profile, message: 'Phone number updated'));
        return profile;
      },
      (error) {
        emit(state.copyWith(status: ItemStatus.failure, message: error.message, fieldErrors: error.fieldErrors));
        return null;
      },
    );
  }

  Future<ProfileModel?> uploadPhoto(String filePath) async {
    emit(state.copyWith(status: ItemStatus.submitting));
    final result = await _repository.uploadPhoto(filePath);
    return result.fold(
      (profile) {
        emit(ItemState(status: ItemStatus.success, item: profile, message: 'Profile photo updated'));
        return profile;
      },
      (error) {
        emit(state.copyWith(status: ItemStatus.failure, message: error.message));
        return null;
      },
    );
  }
}

/// Stat cards on FarmerHomePage.
class FarmerDashboardCubit extends Cubit<ItemState<FarmerDashboardModel>> {
  FarmerDashboardCubit(this._repository) : super(const ItemState<FarmerDashboardModel>());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ItemStatus.loading));
    final result = await _repository.getDashboard();
    result.fold(
      (data) => emit(ItemState(status: ItemStatus.success, item: data)),
      (error) => emit(state.copyWith(status: ItemStatus.failure, message: error.message)),
    );
  }
}
