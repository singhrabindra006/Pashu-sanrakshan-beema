import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../data/repositories/admin_application_repository.dart';

/// One instance per Pending/Approved/Rejected tab, with a shared search term.
class AdminApplicationListCubit extends PaginatedListCubit<ApplicationModel> {
  AdminApplicationListCubit(this._repository, {this.status});

  final AdminApplicationRepository _repository;
  final ApplicationStatus? status;

  String? _search;

  @override
  Future<Result<Paginated<ApplicationModel>>> fetchPage(int page) =>
      _repository.list(page: page, status: status, search: _search);

  Future<void> search(String? term) {
    _search = (term == null || term.trim().isEmpty) ? null : term.trim();
    return load();
  }
}
