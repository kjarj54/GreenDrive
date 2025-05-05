class Comment {
  final int id;
  final int postId;
  final int userId;
  final String username;
  final String content;
  final DateTime date;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    required this.date,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['publicacionId'],
      userId: json['usuarioId'],
      username: json['nombreUsuario'] ?? 'Usuario',
      content: json['contenido'],
      date: DateTime.parse(json['fecha']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'publicacionId': postId, 'usuarioId': userId, 'contenido': content};
  }
}
