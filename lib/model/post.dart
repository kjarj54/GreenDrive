class Post {
  final int id;
  final int userId;
  final String username;
  final String title;
  final String content;
  final DateTime date;
  final int commentCount;
  final String category;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.title,
    required this.content,
    required this.date,
    this.commentCount = 0,
    this.category = 'General',
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['usuarioId'],
      username: json['nombreUsuario'] ?? 'Unknown User',
      title: json['tema'],
      content: json['contenido'],
      date: DateTime.parse(json['fecha']),
      commentCount: json['cantidadComentarios'] ?? 0,
      category: json['categoria'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': userId,
      'tema': title,
      'contenido': content,
      'categoria': category,
    };
  }
}
