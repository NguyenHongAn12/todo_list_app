class Task {
  String title;
  String description;
  DateTime createdAt;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.createdAt,
    this.isCompleted = false,
  });
}
