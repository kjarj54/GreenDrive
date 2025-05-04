class Event {
  final int id;
  final int creatorId;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final String status;
  final DateTime creationDate;
  final int participantCount;
  
  Event({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.status,
    required this.creationDate,
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
      creationDate: DateTime.parse(json['fechaCreacion']),
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
}