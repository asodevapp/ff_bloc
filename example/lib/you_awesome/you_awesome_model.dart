import 'package:equatable/equatable.dart';

class YouAwesomeModel extends Equatable {
  const YouAwesomeModel({
    required this.name,
  });

  final String name;

  @override
  List<Object> get props => [name];

  Map<dynamic, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  static YouAwesomeModel? fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return null;
    }

    return YouAwesomeModel(
      name: map['name']!.toString(),
    );
  }
}

class YouAwesomeViewModel extends Equatable {
  const YouAwesomeViewModel({
    required this.items,
  });

  final List<YouAwesomeModel> items;

  @override
  List<Object?> get props => [items];

  YouAwesomeViewModel copyWith({
    List<YouAwesomeModel>? items,
  }) {
    return YouAwesomeViewModel(
      items: items ?? this.items,
    );
  }
}
