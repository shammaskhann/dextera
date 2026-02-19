class LocalConversation {
  final String id;
  final String title;
  final int? userId;

  LocalConversation({
    required this.id,
    required this.title,
    required this.userId,
  });

  factory LocalConversation.fromJson(Map<String, dynamic> json) {
    return LocalConversation(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse((json['userId'] ?? '').toString()),
    );
  }
}
