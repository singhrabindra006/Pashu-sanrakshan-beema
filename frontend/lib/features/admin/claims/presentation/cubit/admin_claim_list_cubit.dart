import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/cubit/paginated_list_cubit.dart';
import '../../../../../core/network/paginated.dart';
import '../../../../../core/network/result.dart';
import '../../../../shared/data/models/claim_model.dart';
import '../../data/repositories/admin_claim_repository.dart';

class AdminClaimListCubit extends PaginatedListCubit<ClaimModel> {
  AdminClaimListCubit(this._repository, {this.status});

  final AdminClaimRepository _repository;
  final ClaimStatus? status;

  String? _search;

  @override
  Future<Result<Paginated<ClaimModel>>> fetchPage(int page) =>
      _repository.list(page: page, status: status, search: _search);

  Future<void> search(String? term) {
    _search = (term == null || term.trim().isEmpty) ? null : term.trim();
    return load();
  }
}
