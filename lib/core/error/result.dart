import 'package:app_management/core/error/failures.dart';

sealed class Result<T> {
  const Result();

  R when<R>({required R Function(T data) success, required R Function(Failure failure) failure}) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    }
    return failure((this as FailureResult<T>).failure);
  }
}

class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}
