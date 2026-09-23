import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../shared/data/models/animal_model.dart';
import '../../../../shared/data/models/application_model.dart';
import '../../../../shared/data/models/scheme_model.dart';
import '../../../animals/data/repositories/animal_repository.dart';
import '../../../schemes/data/repositories/scheme_repository.dart';
import '../../data/repositories/application_repository.dart';

enum SubmitStage { loadingOptions, ready, submitting, submitted, failure }

/// Drives the 3-step stepper: pick animal -> pick scheme -> enter coverage.
class ApplicationSubmitState extends Equatable {
  const ApplicationSubmitState({
    this.stage = SubmitStage.loadingOptions,
    this.animals = const [],
    this.schemes = const [],
    this.selectedAnimal,
    this.selectedScheme,
    this.coverageAmount,
    this.created,
    this.message,
  });

  final SubmitStage stage;

  /// Only active animals without a live application can be insured.
  final List<AnimalModel> animals;
  final List<SchemeModel> schemes;
  final AnimalModel? selectedAnimal;
  final SchemeModel? selectedScheme;
  final double? coverageAmount;
  final ApplicationModel? created;
  final String? message;

  bool get isSubmitting => stage == SubmitStage.submitting;
  bool get isLoading => stage == SubmitStage.loadingOptions;
  double? get maxCoverage => selectedScheme?.maxCoverage;

  ApplicationSubmitState copyWith({
    SubmitStage? stage,
    List<AnimalModel>? animals,
    List<SchemeModel>? schemes,
    AnimalModel? selectedAnimal,
    SchemeModel? selectedScheme,
    double? coverageAmount,
    ApplicationModel? created,
    String? message,
  }) =>
      ApplicationSubmitState(
        stage: stage ?? this.stage,
        animals: animals ?? this.animals,
        schemes: schemes ?? this.schemes,
        selectedAnimal: selectedAnimal ?? this.selectedAnimal,
        selectedScheme: selectedScheme ?? this.selectedScheme,
        coverageAmount: coverageAmount ?? this.coverageAmount,
        created: created ?? this.created,
        message: message,
      );

  @override
  List<Object?> get props => [stage, animals, schemes, selectedAnimal, selectedScheme, coverageAmount, created, message];
}

class ApplicationSubmitCubit extends Cubit<ApplicationSubmitState> {
  ApplicationSubmitCubit({
    required ApplicationRepository applications,
    required AnimalRepository animals,
    required SchemeRepository schemes,
  })  : _applications = applications,
        _animals = animals,
        _schemes = schemes,
        super(const ApplicationSubmitState());

  final ApplicationRepository _applications;
  final AnimalRepository _animals;
  final SchemeRepository _schemes;

  /// [preselectedSchemeId] comes from "Apply for this scheme" on the detail page.
  Future<void> loadOptions({int? preselectedSchemeId}) async {
    emit(state.copyWith(stage: SubmitStage.loadingOptions));

    final animalsResult = await _animals.list(isActive: true);
    final schemesResult = await _schemes.list();

    final animalsError = animalsResult.errorOrNull ?? schemesResult.errorOrNull;
    if (animalsError != null) {
      emit(state.copyWith(stage: SubmitStage.failure, message: animalsError.message));
      return;
    }

    // An animal already tied to a pending application or a live policy cannot be
    // insured again, so it is filtered out rather than rejected on submit.
    final animals = (animalsResult.dataOrNull?.items ?? const <AnimalModel>[])
        .where((animal) => animal.isActive && !animal.hasActiveApplication)
        .toList();
    final schemes = (schemesResult.dataOrNull?.items ?? const <SchemeModel>[])
        .where((scheme) => scheme.isAvailable)
        .toList();

    final preselected = schemes.where((scheme) => scheme.id == preselectedSchemeId).toList();

    emit(
      ApplicationSubmitState(
        stage: SubmitStage.ready,
        animals: animals,
        schemes: schemes,
        selectedAnimal: animals.length == 1 ? animals.first : null,
        selectedScheme: preselected.isEmpty ? null : preselected.first,
      ),
    );
  }

  void selectAnimal(AnimalModel? animal) => emit(
        ApplicationSubmitState(
          stage: state.stage,
          animals: state.animals,
          schemes: state.schemes,
          selectedAnimal: animal,
          selectedScheme: state.selectedScheme,
          coverageAmount: state.coverageAmount,
        ),
      );

  void selectScheme(SchemeModel? scheme) => emit(
        ApplicationSubmitState(
          stage: state.stage,
          animals: state.animals,
          schemes: state.schemes,
          selectedAnimal: state.selectedAnimal,
          selectedScheme: scheme,
          // Coverage is cleared: the previous value may exceed the new ceiling.
          coverageAmount: null,
        ),
      );

  void setCoverage(double? amount) => emit(state.copyWith(coverageAmount: amount));

  Future<void> submit() async {
    final animal = state.selectedAnimal;
    final scheme = state.selectedScheme;
    final amount = state.coverageAmount;

    if (animal == null || scheme == null || amount == null) {
      emit(state.copyWith(stage: SubmitStage.failure, message: 'Complete every step before submitting'));
      return;
    }
    if (amount > scheme.maxCoverage) {
      emit(state.copyWith(stage: SubmitStage.failure, message: 'Coverage cannot exceed the scheme maximum'));
      return;
    }

    emit(state.copyWith(stage: SubmitStage.submitting));
    final result = await _applications.submit(
      animalId: animal.id,
      schemeId: scheme.id,
      coverageAmount: amount,
    );

    result.fold(
      (application) => emit(state.copyWith(stage: SubmitStage.submitted, created: application)),
      (error) => emit(state.copyWith(stage: SubmitStage.failure, message: error.message)),
    );
  }
}
