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
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
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
    );
  }
}