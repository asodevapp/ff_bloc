# ff_bloc example

A small runnable feature that demonstrates the complete `ff_bloc` flow:

- initial loading through an `FFBlocEvent`;
- data, empty, and error rendering through `FFState.when`;
- incremental updates;
- subscription-safe bloc ownership through `BlocProvider`.

Run it from this directory:

```shell
flutter run
```

Run the interaction test with:

```shell
flutter test
```

Start with [`lib/you_awesome/you_awesome_bloc.dart`](lib/you_awesome/you_awesome_bloc.dart)
and [`lib/you_awesome/you_awesome_event.dart`](lib/you_awesome/you_awesome_event.dart).
