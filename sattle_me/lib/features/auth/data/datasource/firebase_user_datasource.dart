import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sattle_me/features/auth/data/model/user_mode.dart';

abstract class FirebaseUserDataSource {
  Future<void> storeUserData(UserModel userModel, String uid);
  Future<UserModel?> getUserData(String uid);
}

class FirebaseUserDataSourceImpl implements FirebaseUserDataSource {
  final FirebaseFirestore firestore;

  FirebaseUserDataSourceImpl({required this.firestore});

  @override
  Future<void> storeUserData(UserModel userModel, String uid) async {
    try {
      print("Storing user data in Firestore...");
      print("User UID: $uid");
      print("User Data: ${userModel.toJson()}");

      await firestore.collection('users').doc(uid).set(userModel.toJson());

      print("User data successfully stored in Firestore!");
    } catch (e) {
      print("Firestore error: $e");
      throw Exception('Failed to store user data: $e');
    }
  }

  @override
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final userData = doc.data()!;

        return UserModel(
          uid: userData['uid'] ?? uid,
          fullName: userData['fullName'] ?? '',
          email: userData['email'] ?? '',
          password: userData['password'] ?? '',
          photoUrl: userData['photoUrl'] ?? '',
        );
      }
      return null;
    } catch (e) {
      print(" Firestore read error: $e");
      return null;
    }
  }
}
