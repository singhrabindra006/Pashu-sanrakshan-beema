import 'api_exceptions.dart';

/// Repositories return this instead of throwing, so cubits handle both paths
/// explicitly and never leak an unhandled exception into the widget tree.
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(AppException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  AppException? get errorOrNull => this is Failure<T> ? (this as Failure<T>).error : null;

  R fold<R>(R Function(T data) onSuccess, R Function(AppException error) onFailure) => switch (this) {
        Success<T>(data: final data) => onSuccess(data),
        Failure<T>(error: final error) => onFailure(error),
      };

  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success<T>(data: final data) => Success<R>(transform(data)),
        Failure<T>(error: final error) => Failure<R>(error),
      };
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppException error;
}
