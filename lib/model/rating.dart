class StationRating {
  final int id;
  final int userId;
  final int stationId;
  final int rating;
  final String? comment;
  final DateTime date;
  final String? username;

  StationRating({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.rating,
    this.comment,
    required this.date,
    this.username,
  });
  factory StationRating.fromJson(Map<String, dynamic> json) {
    return StationRating(
      id: json['id'],
      userId: json['usuarioId'],
      stationId: json['estacionId'],
      rating: json['calificacion'],
      comment: json['comentario'],
      date: DateTime.parse(json['fecha']),
      username: json['nombreUsuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': userId,
      'estacionId': stationId,
      'calificacion': rating,
      'comentario': comment,
      'fecha': date.toIso8601String(),
    };
  }
}
