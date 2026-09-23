import 'package:equatable/equatable.dart';

enum ItemStatus { initial, loading, success, failure, submitting, submitted }

/// Shared shape for detail screens and single-record forms.
class ItemState<T> extends Equatable {
  const ItemState({this.status = ItemStatus.initial, this.item, this.message, this.fieldErrors});

  final ItemStatus status;
  final T? item;
  final String? message;

  /// Backend 422 messages, keyed by field name.
  final Map<String, String>? fieldErrors;

  bool get isLoading => status == ItemStatus.loading;
  bool get isSubmitting => status == ItemStatus.submitting;
  bool get isFailure => status == ItemStatus.failure;
  bool get isSubmitted => status == ItemStatus.submitted;
  bool get hasItem => item != null;

  ItemState<T> copyWith({
    ItemStatus? status,
    T? item,
    String? message,
    Map<String, String>? fieldErrors,
  }) =>
      ItemState<T>(
        status: status ?? this.status,
        item: item ?? this.item,
        message: message,
        fieldErrors: fieldErrors,
      );

  @override
  List<Object?> get props => [status, item, message, fieldErrors];
}
