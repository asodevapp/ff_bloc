import 'package:ff_bloc_example/you_awesome/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ff_bloc example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider(
        create: (_) => YouAwesomeBloc(
          provider: YouAwesomeProvider(),
        ),
        child: const YouAwesomePage(),
      ),
    );
  }
}
