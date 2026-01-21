class User {
  final String id;
  final String email;
  final UserType type;

  User({required this.id, required this.email, required this.type});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['user_id'] ?? '',
      email: map['email'] ?? '',
      type: _parseUserType(map['user_type']),
    );
  }

  static UserType _parseUserType(String? type) {
    switch (type) {
      case 'ADMINISTRATOR':
        return UserType.admin;
      case 'VOLUNTEER':
        return UserType.volunteer;
      case 'DONOR':
      default:
        return UserType.donor;
    }
  }
}

enum UserType { admin, volunteer, donor }
