import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../network/paginated.dart';
import '../network/result.dart';

enum ListStatus { initial, loading, refreshing, loadingMore, success, failure }

/// Shared shape for every paginated list screen: first load, pull-to-refresh,
/// infinite scroll and an error that keeps the already-loaded rows on screen.
class ListState<T> extends Equatable {
  const ListState({
    this.status = ListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.message,
  });

  final ListStatus status;
  final List<T> items;
  final int page;
  final int totalPages;
  final int total;
  final String? message;

  bool get isFirstLoad => status == ListStatus.loading && items.isEmpty;
  bool get isEmpty => status == ListStatus.success && items.isEmpty;
  bool get hasMore => page < totalPages;
  bool get isLoadingMore => status == ListStatus.loadingMore;
  bool get isBusy => status == ListStatus.loading || status == ListStatus.refreshing;

  ListState<T> copyWith({
    ListStatus? status,
    List<T>? items,
    int? page,
    int? totalPages,
    int? total,
    String? message,
  }) =>
      ListState<T>(
        status: status ?? this.status,
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        message: message,
      );

  @override
  List<Object?> get props => [status, items, page, totalPages, total, message];
}

/// Subclasses only implement [fetchPage]; paging and error handling live here.
abstract class PaginatedListCubit<T> extends Cubit<ListState<T>> {
  PaginatedListCubit() : super(ListState<T>());

  Future<Result<Paginated<T>>> fetchPage(int page);

  Future<void> load({bool refresh = false}) async {
    if (state.isBusy) return;
    emit(state.copyWith(status: refresh ? ListStatus.refreshing : ListStatus.loading));

    final result = await fetchPage(1);
    result.fold(
      (data) => emit(
        ListState<T>(
          status: ListStatus.success,
          items: data.items,
          page: data.page,
          totalPages: data.totalPages,
          total: data.total,
        ),
      ),
      (error) => emit(state.copyWith(status: ListStatus.failure, message: error.message)),
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.status == ListStatus.loadingMore || state.isBusy) return;
    emit(state.copyWith(status: ListStatus.loadingMore));

    final result = await fetchPage(state.page + 1);
    result.fold(
      (data) => emit(
        ListState<T>(
          status: ListStatus.success,
          items: [...state.items, ...data.items],
          page: data.page,
          totalPages: data.totalPages,
          total: data.total,
        ),
      ),
      (error) => emit(state.copyWith(status: ListStatus.failure, message: error.message)),
    );
  }

  /// Replaces a single row after an inline action (toggle, deactivate) without
  /// re-fetching the whole page.
  void replaceItem(bool Function(T item) matcher, T replacement) {
    final index = state.items.indexWhere(matcher);
    if (index < 0) return;
    final items = [...state.items];
    items[index] = replacement;
    emit(state.copyWith(status: ListStatus.success, items: items));
  }

  void removeItem(bool Function(T item) matcher) {
    final items = state.items.where((item) => !matcher(item)).toList();
    emit(state.copyWith(status: ListStatus.success, items: items, total: items.length));
  }
}
