class Event {
  final int id;
  final int creatorId;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final String status;
  final int participantCount;

  Event({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.status,
    this.participantCount = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      creatorId: json['usuarioCreadorId'],
      title: json['titulo'],
      description: json['descripcion'] ?? '',
      eventDate: DateTime.parse(json['fechaEvento']),
      location: json['ubicacion'] ?? '',
      status: json['estado'] ?? 'Activo',
      participantCount: json['cantidadParticipantes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuarioCreadorId': creatorId,
      'titulo': title,
      'descripcion': description,
      'fechaEvento': eventDate.toIso8601String(),
      'ubicacion': location,
      'estado': status,
    };
  }

  Event copyWith({
    int? id,
    int? creatorId,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
    String? status,
    DateTime? creationDate,
    int? participantCount,
  }) {
    return Event(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      status: status ?? this.status,
      participantCount: participantCount ?? this.participantCount,
    );
  }
}
