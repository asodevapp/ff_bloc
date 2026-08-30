import 'package:ff_bloc/ff_bloc.dart';

import 'package:ff_bloc_example/you_awesome/index.dart';

class YouAwesomeState extends FFState<YouAwesomeState, YouAwesomeViewModel> {
  const YouAwesomeState({
    super.version = 0,
    super.isLoading = false,
    super.data,
    super.error,
  });

  @override
  bool get isEmpty => data?.items.isEmpty ?? true;

  @override
  StateCopyFactory<YouAwesomeState, YouAwesomeViewModel> getCopyFactory() =>
      YouAwesomeState.new;
}
