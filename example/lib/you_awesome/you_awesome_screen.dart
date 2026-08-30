import 'package:ff_bloc_example/you_awesome/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class YouAwesomeScreen extends StatefulWidget {
  const YouAwesomeScreen({super.key});

  @override
  State<YouAwesomeScreen> createState() {
    return YouAwesomeScreenState();
  }
}

class YouAwesomeScreenState extends State<YouAwesomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!context.read<YouAwesomeBloc>().state.hasData) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<YouAwesomeBloc, YouAwesomeState>(
      builder: (
        BuildContext context,
        YouAwesomeState currentState,
      ) {
        return currentState.when(
          onLoading: () => const Center(child: CircularProgressIndicator()),
          onEmpty: (data) => const _Empty(),
          onData: (data) => _BodyList(data: data),
          onError: (e) => Center(
            child: Column(
              children: [
                Text(e.toString()),
                TextButton(
                  onPressed: _load,
                  child: const Text('Reload'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _load() {
    context.read<YouAwesomeBloc>().add(LoadYouAwesomeEvent(id: '1'));
  }
}

class _BodyList extends StatelessWidget {
  const _BodyList({required this.data});

  final YouAwesomeViewModel data;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: Divider()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final item = data.items[index];
              if (index == 0) {
                return Text('Header $index, id = ${item.name}');
              }
              return Text('Index = $index, id = ${item.name}');
            },
            childCount: data.items.length,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        Text('Empty'),
      ],
    );
  }
}
