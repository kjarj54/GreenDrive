class ChargingStation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String chargerType;
  final int power;
  final double rate;
  final bool availability;
  final String schedule;
  final double rating;
  final int reviewCount;
  final List<String> reviews;
  final int totalCharges;
  final DateTime lastUpdated;

  ChargingStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.chargerType,
    required this.power,
    required this.rate,
    required this.availability,
    required this.schedule,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.reviews = const [],
    this.totalCharges = 0,
    DateTime? lastUpdated,
  }) : this.lastUpdated = lastUpdated ?? DateTime.now();  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      id: json['id'] as int,
      name: json['nombre'] as String,
      latitude: (json['latitud'] as num).toDouble(),
      longitude: (json['longitud'] as num).toDouble(),
      address: json['direccion'] as String,
      chargerType: json['tipoCargador'] as String,
      power: json['potencia'] as int,
      rate: (json['tarifa'] as num).toDouble(),
      availability: json['disponibilidad'] as bool,
      schedule: json['horario'] as String,
      rating: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['cantidadResenas'] as int? ?? 0,
      reviews: (json['resenas'] as List<dynamic>?)?.cast<String>() ?? [],
      totalCharges: json['totalCargas'] as int? ?? 0,
      lastUpdated: json['ultimaActualizacion'] != null 
          ? DateTime.parse(json['ultimaActualizacion'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'latitud': latitude,
      'longitud': longitude,
      'direccion': address,
      'tipoCargador': chargerType,
      'potencia': power,
      'tarifa': rate,
      'disponibilidad': availability,
      'horario': schedule,
      'calificacion': rating,
      'cantidadResenas': reviewCount,
      'resenas': reviews,
      'totalCargas': totalCharges,
      'ultimaActualizacion': lastUpdated.toIso8601String(),
    };
  }
}