class Vehicle {
  final int id;
  final String marca;
  final String modelo;
  final double autonomia;

  Vehicle({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.autonomia,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      marca: json['marca'],
      modelo: json['modelo'],
      autonomia: (json['autonomia'] as num).toDouble(),
    );
  }
}
