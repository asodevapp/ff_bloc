// ignore_for_file: null_check_on_nullable_type_parameter

import 'package:flutter/foundation.dart';

import 'package:equatable/equatable.dart';

typedef StateCopyFactory<Self, DataT> = Self Function({
  required int version,
  required bool isLoading,
  required DataT? data,
  required Object? error,
});

/// The derived presentation status of an [FFState] or [FFGenericState].
enum FFStateStatus {
  empty,
  loading,
  data,
  error,
}

/// Convenience checks for [FFStateStatus].
extension StatusCheck on FFStateStatus {
  bool get isEmpty => this == FFStateStatus.empty;
  bool get isLoading => this == FFStateStatus.loading;
  bool get isData => this == FFStateStatus.data;
  bool get isError => this == FFStateStatus.error;
}

/// Immutable state with loading, data, error, and monotonic version fields.
///
/// Status precedence is loading, error, empty, then data. Override [isEmpty]
/// when a non-null domain value, such as an empty list, should be considered
/// empty.
@immutable
abstract class FFState<Self, DataT> extends Equatable {
  const FFState({
    required this.version,
    required this.isLoading,
    required this.data,
    required this.error,
  });

  @nonVirtual
  final int version;
  @nonVirtual
  final bool isLoading;
  @nonVirtual
  final DataT? data;
  @nonVirtual
  final dynamic error;

  /// Derives the current status using loading > error > empty > data priority.
  @nonVirtual
  FFStateStatus get status {
    if (isLoading) {
      return FFStateStatus.loading;
    }
    if (hasError) {
      return FFStateStatus.error;
    }
    if (isEmpty || !hasData) {
      return FFStateStatus.empty;
    }
    if (hasData) {
      return FFStateStatus.data;
    }
    assert(false, 'Unknown state');
    return FFStateStatus.empty;
  }

  @nonVirtual
  bool get hasError => error != null;
  @nonVirtual
  bool get hasData => data != null;
  @nonVirtual
  bool get hasNoData => !hasData;

  bool get isEmpty => data == null;
  bool get isNotEmpty => !isEmpty;

  /// Exhaustively maps the current [status] to a value.
  @nonVirtual
  R when<R>({
    required R Function() onLoading,
    required R Function(Object error) onError,
    required R Function(DataT? data) onEmpty,
    required R Function(DataT data) onData,
  }) {
    switch (status) {
      case FFStateStatus.loading:
        return onLoading();
      case FFStateStatus.error:
        return onError(error!);
      case FFStateStatus.empty:
        return onEmpty(data);
      case FFStateStatus.data:
        return onData(data!);
      default:
        throw StateError('Unexpected FFStateStatus value');
    }
  }

  /// Maps selected statuses and falls back to [onElse] for the rest.
  @nonVirtual
  R whenOrElse<R>({
    required R Function() onElse,
    R Function()? onLoading,
    R Function(Object error)? onError,
    R Function(DataT? data)? onEmpty,
    R Function(DataT data)? onData,
  }) {
    switch (status) {
      case FFStateStatus.loading:
        return onLoading?.call() ?? onElse();
      case FFStateStatus.error:
        return onError?.call(error!) ?? onElse();
      case FFStateStatus.empty:
        return onEmpty?.call(data) ?? onElse();
      case FFStateStatus.data:
        return onData?.call(data!) ?? onElse();
      default:
        throw StateError('Unexpected FFStateStatus value');
    }
  }

  @override
  String toString() {
    return 'State: $version:$status|$isLoading| ${error == null ? ',' : 'error: $error,'}${data == null ? ',' : 'data: $data,'}';
  }

  @protected
  StateCopyFactory<Self, DataT> getCopyFactory();

  /// Copies this state, retaining omitted values and incrementing [version].
  ///
  /// Passing `null` retains the old nullable value. Use [copyWithoutError],
  /// [copyWithoutData], or [copyClear] when a value must be cleared.
  Self copy({
    bool? isLoading,
    DataT? data,
    Object? error,
  }) {
    return getCopyFactory()(
      version: version + 1,
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Copies this state, clears [error], and increments [version].
  Self copyWithoutError({
    bool? isLoading,
    DataT? data,
  }) {
    return getCopyFactory()(
      version: version + 1,
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: null,
    );
  }

  /// Copies this state, clears [data], and increments [version].
  Self copyWithoutData({
    bool? isLoading,
    Object? error,
  }) {
    return getCopyFactory()(
      version: version + 1,
      isLoading: isLoading ?? this.isLoading,
      data: null,
      error: error ?? this.error,
    );
  }

  /// Clears [data] and [error], sets loading explicitly, and increments version.
  Self copyClear({
    bool isLoading = false,
  }) {
    return getCopyFactory()(
      version: version + 1,
      isLoading: isLoading,
      data: null,
      error: null,
    );
  }

  @override
  List<Object?> get props => [version, isLoading, data, error];
}

/// A state base for custom implementations of the copy operations.
///
/// Prefer [FFState] when its built-in copy semantics are sufficient.
@immutable
abstract class FFGenericState<DataT> extends Equatable {
  const FFGenericState({
    required this.version,
    required this.isLoading,
    required this.data,
    required this.error,
  });

  @nonVirtual
  final int version;
  @nonVirtual
  final bool isLoading;
  @nonVirtual
  final DataT? data;
  @nonVirtual
  final Object? error;

  @nonVirtual
  FFStateStatus get status {
    if (isLoading) {
      return FFStateStatus.loading;
    }
    if (hasError) {
      return FFStateStatus.error;
    }
    if (isEmpty || !hasData) {
      return FFStateStatus.empty;
    }
    if (hasData) {
      return FFStateStatus.data;
    }
    assert(false, 'Unknown state');
    return FFStateStatus.empty;
  }

  @nonVirtual
  bool get hasError => error != null;
  @nonVirtual
  bool get hasData => data != null;
  @nonVirtual
  bool get hasNoData => !hasData;

  bool get isEmpty => data == null;
  bool get isNotEmpty => !isEmpty;

  @nonVirtual
  R when<R>({
    required R Function() onLoading,
    required R Function(Object error) onError,
    required R Function(DataT? data) onEmpty,
    required R Function(DataT data) onData,
  }) {
    switch (status) {
      case FFStateStatus.loading:
        return onLoading();
      case FFStateStatus.error:
        return onError(error!);
      case FFStateStatus.empty:
        return onEmpty(data);
      case FFStateStatus.data:
        return onData(data!);
      default:
        throw StateError('Unexpected FFStateStatus value');
    }
  }

  @nonVirtual
  R whenOrElse<R>({
    required R Function() onElse,
    R Function()? onLoading,
    R Function(Object error)? onError,
    R Function(DataT? data)? onEmpty,
    R Function(DataT data)? onData,
  }) {
    switch (status) {
      case FFStateStatus.loading:
        return onLoading?.call() ?? onElse();
      case FFStateStatus.error:
        return onError?.call(error!) ?? onElse();
      case FFStateStatus.empty:
        return onEmpty?.call(data) ?? onElse();
      case FFStateStatus.data:
        return onData?.call(data!) ?? onElse();
      default:
        throw StateError('Unexpected FFStateStatus value');
    }
  }

  @override
  String toString() {
    return 'State: version: $version, status: $status, isLoading: $isLoading, error: $error, data: $data';
  }

  @protected
  StateCopyFactory<FFGenericState, DataT> getCopyFactory();

  @protected
  FFGenericState copy({
    bool? isLoading,
    DataT? data,
    Object? error,
  });

  @protected
  FFGenericState copyWithoutError({
    bool? isLoading,
    DataT? data,
  });

  @protected
  FFGenericState copyWithoutData({
    bool? isLoading,
    Object? error,
  });

  @protected
  FFGenericState copyClear({
    bool isLoading = false,
  });

  @override
  List<Object?> get props => [version, isLoading, data, error];
}
