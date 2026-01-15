/// 应用异常基类
///
/// 所有应用层异常都应该继承此类，提供统一的错误处理接口。
abstract class AppException implements Exception {
  /// 错误消息
  final String message;

  /// 错误代码（可选）
  final String? code;

  /// 原始异常（可选）
  final Object? originalError;

  /// 堆栈跟踪（可选）
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message${code != null ? ' ($code)' : ''}';

  /// 获取用户友好的错误消息
  String get userFriendlyMessage => message;
}

/// 数据库异常
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 连接失败
  factory DatabaseException.connectionFailed([Object? error, StackTrace? trace]) {
    return DatabaseException(
      message: '数据库连接失败',
      code: 'DB_CONNECTION_FAILED',
      originalError: error,
      stackTrace: trace,
    );
  }

  /// 查询失败
  factory DatabaseException.queryFailed(String details, [Object? error, StackTrace? trace]) {
    return DatabaseException(
      message: '数据库查询失败: $details',
      code: 'DB_QUERY_FAILED',
      originalError: error,
      stackTrace: trace,
    );
  }

  /// 插入失败
  factory DatabaseException.insertFailed(String table, [Object? error, StackTrace? trace]) {
    return DatabaseException(
      message: '数据插入失败: $table',
      code: 'DB_INSERT_FAILED',
      originalError: error,
      stackTrace: trace,
    );
  }

  /// 更新失败
  factory DatabaseException.updateFailed(String table, [Object? error, StackTrace? trace]) {
    return DatabaseException(
      message: '数据更新失败: $table',
      code: 'DB_UPDATE_FAILED',
      originalError: error,
      stackTrace: trace,
    );
  }

  /// 删除失败
  factory DatabaseException.deleteFailed(String table, [Object? error, StackTrace? trace]) {
    return DatabaseException(
      message: '数据删除失败: $table',
      code: 'DB_DELETE_FAILED',
      originalError: error,
      stackTrace: trace,
    );
  }

  @override
  String get userFriendlyMessage => '数据操作失败，请重试';
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 连接超时
  factory NetworkException.timeout([Object? error, StackTrace? trace]) {
    return NetworkException(
      message: '网络连接超时',
      code: 'NETWORK_TIMEOUT',
      originalError: error,
      stackTrace: trace,
    );
  }

  /// 无网络连接
  factory NetworkException.noConnection([Object? error, StackTrace? trace]) {
    return NetworkException(
      message: '无网络连接',
      code: 'NO_CONNECTION',
      originalError: error,
      stackTrace: trace,
    );
  }

  /// 服务器错误
  factory NetworkException.serverError(int statusCode, [Object? error, StackTrace? trace]) {
    return NetworkException(
      message: '服务器错误: $statusCode',
      code: 'SERVER_ERROR',
      originalError: error,
      stackTrace: trace,
    );
  }

  @override
  String get userFriendlyMessage => '网络请求失败，请检查网络连接';
}

/// 业务逻辑异常
class BusinessException extends AppException {
  const BusinessException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 数据未找到
  factory BusinessException.notFound(String item) {
    return BusinessException(
      message: '$item 不存在',
      code: 'NOT_FOUND',
    );
  }

  /// 数据已存在
  factory BusinessException.alreadyExists(String item) {
    return BusinessException(
      message: '$item 已存在',
      code: 'ALREADY_EXISTS',
    );
  }

  /// 验证失败
  factory BusinessException.validationFailed(String details) {
    return BusinessException(
      message: '数据验证失败: $details',
      code: 'VALIDATION_FAILED',
    );
  }

  /// 操作被拒绝
  factory BusinessException.operationDenied(String reason) {
    return BusinessException(
      message: '操作被拒绝: $reason',
      code: 'OPERATION_DENIED',
    );
  }
}

/// 权限异常
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// 通知权限被拒绝
  factory PermissionException.notificationDenied() {
    return const PermissionException(
      message: '通知权限被拒绝',
      code: 'NOTIFICATION_DENIED',
    );
  }

  /// 存储权限被拒绝
  factory PermissionException.storageDenied() {
    return const PermissionException(
      message: '存储权限被拒绝',
      code: 'STORAGE_DENIED',
    );
  }

  @override
  String get userFriendlyMessage => '请在设置中授予相应权限';
}

/// 解析异常
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  /// iCalendar 解析失败
  factory ParseException.iCalendarFailed(String details, [Object? error, StackTrace? trace]) {
    return ParseException(
      message: 'iCalendar 解析失败: $details',
      code: 'ICALENDAR_PARSE_FAILED',
      originalError: error,
      stackTrace: trace,
    );
  }

  /// JSON 解析失败
  factory ParseException.jsonFailed(String details, [Object? error, StackTrace? trace]) {
    return ParseException(
      message: 'JSON 解析失败: $details',
      code: 'JSON_PARSE_FAILED',
      originalError: error,
      stackTrace: trace,
    );
  }

  @override
  String get userFriendlyMessage => '数据格式错误';
}
