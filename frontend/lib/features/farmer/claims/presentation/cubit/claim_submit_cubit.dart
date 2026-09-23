import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../../../shared/data/models/claim_model.dart';
import '../../../applications/data/repositories/application_repository.dart';
import '../../data/repositories/claim_repository.dart';

enum ClaimSubmitStage { loadingPolicies, ready, submitting, submitted, failure }

class ClaimSubmitState extends Equatable {
  const ClaimSubmitState({
    this.stage = ClaimSubmitStage.loadingPolicies,
    this.policies = const [],
    this.selectedPolicy,
    this.created,
    this.message,
  });

  final ClaimSubmitStage stage;

  /// Approved applications only - the backend rejects anything else.
  final List<ApplicationModel> policies;
  final ApplicationModel? selectedPolicy;
  final ClaimModel? created;
  final String? message;

  bool get isLoading => stage == ClaimSubmitStage.loadingPolicies;
  bool get isSubmitting => stage == ClaimSubmitStage.submitting;

  ClaimSubmitState copyWith({
    ClaimSubmitStage? stage,
    List<ApplicationModel>? policies,
    ApplicationModel? selectedPolicy,
    ClaimModel? created,
    String? message,
  }) =>
      ClaimSubmitState(
        stage: stage ?? this.stage,
        policies: policies ?? this.policies,
        selectedPolicy: selectedPolicy ?? this.selectedPolicy,
        created: created ?? this.created,
        message: message,
      );

  @override
  List<Object?> get props => [stage, policies, selectedPolicy, created, message];
}

class ClaimSubmitCubit extends Cubit<ClaimSubmitState> {
  ClaimSubmitCubit({required ClaimRepository claims, required ApplicationRepository applications})
      : _claims = claims,
        _applications = applications,
        super(const ClaimSubmitState());

  final ClaimRepository _claims;
  final ApplicationRepository _applications;

  Future<void> loadPolicies({int? preselectedApplicationId}) async {
    emit(state.copyWith(stage: ClaimSubmitStage.loadingPolicies));
    final result = await _applications.claimable();

    result.fold(
      (policies) {
        final matches = policies.where((policy) => policy.id == preselectedApplicationId).toList();
        emit(
          ClaimSubmitState(
            stage: ClaimSubmitStage.ready,
            policies: policies,
            selectedPolicy: matches.isNotEmpty
                ? matches.first
                : (policies.length == 1 ? policies.first : null),
          ),
        );
      },
      (error) => emit(state.copyWith(stage: ClaimSubmitStage.failure, message: error.message)),
    );
  }

  void selectPolicy(ApplicationModel? policy) => emit(
        ClaimSubmitState(
          stage: state.stage,
          policies: state.policies,
          selectedPolicy: policy,
        ),
      );

  Future<void> submit({
    required IncidentType incidentType,
    required DateTime incidentDate,
    required String description,
    required double claimedAmount,
    String? evidencePath,
  }) async {
    final policy = state.selectedPolicy;
    if (policy == null) {
      emit(state.copyWith(stage: ClaimSubmitStage.failure, message: 'Select the policy you are claiming against'));
      return;
    }

    emit(state.copyWith(stage: ClaimSubmitStage.submitting));
    final result = await _claims.submit(
      applicationId: policy.id,
      incidentType: incidentType,
      incidentDate: incidentDate,
      description: description,
      claimedAmount: claimedAmount,
      evidencePath: evidencePath,
    );

    result.fold(
      (claim) => emit(state.copyWith(stage: ClaimSubmitStage.submitted, created: claim)),
      (error) => emit(state.copyWith(stage: ClaimSubmitStage.failure, message: error.message)),
    );
  }
}
