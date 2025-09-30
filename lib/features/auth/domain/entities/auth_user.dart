class AuthUser {
  const AuthUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  AuthUser copyWith({String? id, String? email, String? displayName}) =>
      AuthUser(id: id ?? this.id, email: email ?? this.email, displayName: displayName ?? this.displayName);

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'email': email, 'displayName': displayName};

  // ignore: public_member_api_docs
  static AuthUser fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AuthUser && other.id == id && other.email == email && other.displayName == displayName);

  @override
  int get hashCode => Object.hash(id, email, displayName);
}
