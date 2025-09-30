class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.updatedAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime updatedAt;
  final DateTime? createdAt;

  Todo copyWith({String? id, String? title, bool? isCompleted, DateTime? updatedAt, DateTime? createdAt}) => Todo(
        id: id ?? this.id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'updatedAt': updatedAt.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  static Todo fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      );
}
