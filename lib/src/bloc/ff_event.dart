import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Contract for an event that emits a stream of states for its owning [Bloc].
abstract class FFBlocEvent<State, B extends Bloc> {
  FFBlocEvent._();

  /// Runs the event and emits zero or more states.
  ///
  /// Uncaught errors are forwarded to the bloc observer and converted through
  /// `FFBloc.onErrorState` or `FFGenericBloc.onErrorState`.
  Stream<State> applyAsync({required B bloc});
}
