class User {
  final int id;
  final String email;
  final String name;
  final String? token;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['correo'] as String,
      name: json['nombre'] as String,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correo': email,
      'nombre': name,
      'token': token,
    };
  }
}