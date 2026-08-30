import 'dart:async';

import 'package:ff_bloc_example/you_awesome/index.dart';
import 'package:ff_bloc/ff_bloc.dart';
import 'package:flutter/widgets.dart';

@immutable
abstract class YouAwesomeEvent
    implements FFBlocEvent<YouAwesomeState, YouAwesomeBloc> {}

class LoadYouAwesomeEvent extends YouAwesomeEvent {
  LoadYouAwesomeEvent({required this.id});

  final String? id;

  static const String _name = 'LoadYouAwesomeEvent';

  @override
  String toString() => _name;

  @override
  Stream<YouAwesomeState> applyAsync({required YouAwesomeBloc bloc}) async* {
    yield bloc.state.copyWithoutError(isLoading: true);
    final result = await bloc.provider.fetchAsync(id);
    yield bloc.state.copyWithoutError(
      isLoading: false,
      data: YouAwesomeViewModel(items: result),
    );
  }
}

class AddYouAwesomeEvent extends YouAwesomeEvent {
  static const String _name = 'AddYouAwesomeEvent';

  @override
  String toString() => _name;

  @override
  Stream<YouAwesomeState> applyAsync({required YouAwesomeBloc bloc}) async* {
    yield bloc.state.copyWithoutError(isLoading: true);
    final result = await bloc.provider.addMore(bloc.state.data?.items);
    yield bloc.state.copyWithoutError(
      isLoading: false,
      data: YouAwesomeViewModel(items: result),
    );
  }
}

class ErrorYouAwesomeEvent extends YouAwesomeEvent {
  static const String _name = 'ErrorYouAwesomeEvent';

  @override
  String toString() => _name;

  @override
  Stream<YouAwesomeState> applyAsync({required YouAwesomeBloc bloc}) async* {
    throw Exception('Test error');
  }
}

class ClearYouAwesomeEvent extends YouAwesomeEvent {
  static const String _name = 'ClearYouAwesomeEvent';

  @override
  String toString() => _name;

  @override
  Stream<YouAwesomeState> applyAsync({required YouAwesomeBloc bloc}) async* {
    yield bloc.state.copyWithoutError(isLoading: true);
    yield bloc.state.copyWithoutData(
      isLoading: false,
    );
  }
}
