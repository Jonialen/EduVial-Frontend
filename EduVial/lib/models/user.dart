// lib/models/user.dart
class User {
         // ID único (asigna el backend)
  final String name;
  final String email;
  final String password;
  final String role;       // Ej: "principiante", "user"

  User({

    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  // Método para convertir el objeto a JSON (para enviar al backend)
  Map<String, dynamic> toJson() {
    return {
      // Incluido si el backend lo requiere en updates
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }

  // Método opcional: para crear un User desde JSON (recibido del backend)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(

      name: json['name'],
      email: json['email'],
      password: json['password'] ?? '',
      role: json['role'],
    );
  }
}