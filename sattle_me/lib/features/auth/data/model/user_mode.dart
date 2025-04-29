import 'package:sattle_me/features/auth/domain/entities/user_entity.dart';

class UserModel extends User {
  UserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.password,
    required super.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      fullName: json['fullName'],
      email: json['email'],
      password: json['password'],
      photoUrl: json['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'password': password,
      'photoUrl': photoUrl,
    };
  }
}
