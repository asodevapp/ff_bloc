import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ff_bloc_example/you_awesome/index.dart';

class YouAwesomePage extends StatelessWidget {
  const YouAwesomePage({super.key});

  static const String routeName = '/youAwesome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('YouAwesome'),
        actions: [
          IconButton(
            icon: const Icon(Icons.error),
            tooltip: 'Show error',
            onPressed: () {
              context.read<YouAwesomeBloc>().add(ErrorYouAwesomeEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add item',
            onPressed: () {
              context.read<YouAwesomeBloc>().add(AddYouAwesomeEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear items',
            onPressed: () {
              context.read<YouAwesomeBloc>().add(ClearYouAwesomeEvent());
            },
          ),
        ],
      ),
      body: const YouAwesomeScreen(),
    );
  }
}
