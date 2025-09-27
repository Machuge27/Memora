class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profilePicture;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }
}