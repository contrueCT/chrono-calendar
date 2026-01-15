import 'app_exception.dart';

/// 操作结果类型
///
/// 用于封装可能成功或失败的操作结果，避免使用异常控制流程。
///
/// 使用示例：
/// ```dart
/// Future<Result<User>> getUser(String id) async {
///   try {
///     final user = await repository.findById(id);
///     if (user == null) {
///       return Result.failure(BusinessException.notFound('用户'));
///     }
///     return Result.success(user);
///   } catch (e, s) {
///     return Result.failure(DatabaseException.queryFailed('获取用户', e, s));
///   }
/// }
///
/// // 调用
/// final result = await getUser('123');
/// result.when(
///   success: (user) => print('用户: ${user.name}'),
///   failure: (error) => showError(error.userFriendlyMessage),
/// );
/// ```
sealed class Result<T> {
  const Result._();

  /// 创建成功结果
  factory Result.success(T value) = Success<T>;

  /// 创建失败结果
  factory Result.failure(AppException error) = Failure<T>;

  /// 是否成功
  bool get isSuccess => this is Success<T>;

  /// 是否失败
  bool get isFailure => this is Failure<T>;

  /// 获取成功值（如果是失败则返回 null）
  T? get valueOrNull => switch (this) {
        Success<T> s => s.value,
        Failure<T> _ => null,
      };

  /// 获取错误（如果是成功则返回 null）
  AppException? get errorOrNull => switch (this) {
        Success<T> _ => null,
        Failure<T> f => f.error,
      };

  /// 获取成功值或抛出错误
  T get valueOrThrow => switch (this) {
        Success<T> s => s.value,
        Failure<T> f => throw f.error,
      };

  /// 模式匹配处理结果
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException error) failure,
  }) {
    return switch (this) {
      Success<T> s => success(s.value),
      Failure<T> f => failure(f.error),
    };
  }

  /// 转换成功值
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T> s => Result.success(transform(s.value)),
      Failure<T> f => Result.failure(f.error),
    };
  }

  /// 异步转换成功值
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async {
    return switch (this) {
      Success<T> s => Result.success(await transform(s.value)),
      Failure<T> f => Result.failure(f.error),
    };
  }

  /// 链式转换
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success<T> s => transform(s.value),
      Failure<T> f => Result.failure(f.error),
    };
  }

  /// 获取成功值或默认值
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T> s => s.value,
      Failure<T> _ => defaultValue,
    };
  }

  /// 获取成功值或通过函数计算默认值
  T getOrElseCompute(T Function() compute) {
    return switch (this) {
      Success<T> s => s.value,
      Failure<T> _ => compute(),
    };
  }
}

/// 成功结果
final class Success<T> extends Result<T> {
  /// 成功的值
  final T value;

  const Success(this.value) : super._();

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// 失败结果
final class Failure<T> extends Result<T> {
  /// 错误信息
  final AppException error;

  const Failure(this.error) : super._();

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Result 扩展方法
extension ResultExtension<T> on Future<Result<T>> {
  /// 异步模式匹配
  Future<R> when<R>({
    required R Function(T value) success,
    required R Function(AppException error) failure,
  }) async {
    final result = await this;
    return result.when(success: success, failure: failure);
  }
}
