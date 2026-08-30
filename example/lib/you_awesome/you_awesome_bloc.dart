import 'dart:async';

import 'package:ff_bloc/ff_bloc.dart';

import 'package:ff_bloc_example/you_awesome/index.dart';

class YouAwesomeBloc extends FFBloc<YouAwesomeEvent, YouAwesomeState> {
  YouAwesomeBloc({
    required this.provider,
    super.initialState = const YouAwesomeState(),
  });

  final YouAwesomeProvider provider;

  @override
  Iterable<StreamSubscription>? initSubscriptions() {
    return const <StreamSubscription>[];
  }

  @override
  YouAwesomeState onErrorState(Object error) =>
      state.copy(error: error, isLoading: false);
}
