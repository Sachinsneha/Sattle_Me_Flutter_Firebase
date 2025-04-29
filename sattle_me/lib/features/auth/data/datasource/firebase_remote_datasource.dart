import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:sattle_me/features/auth/data/model/user_mode.dart';

abstract class FirebaseAuthDataSource {
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<UserModel> signIn({required String email, required String password});

  fb_auth.FirebaseAuth get firebaseAuthInstance;
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final fb_auth.FirebaseAuth firebaseAuth;

  FirebaseAuthDataSourceImpl({required this.firebaseAuth});

  @override
  fb_auth.FirebaseAuth get firebaseAuthInstance => firebaseAuth;

  @override
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final fb_auth.UserCredential credential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final fb_auth.User? user = credential.user;

      if (user != null) {
        await user.updateDisplayName(fullName);
      }

      print("✅ User created successfully: ${user?.uid}");

      return UserModel(
        uid: user?.uid ?? '',
        fullName: fullName,
        email: email,
        password: password,
        photoUrl: user?.photoURL ?? '',
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.message}");
      throw Exception(e.message);
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final fb_auth.UserCredential credential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final fb_auth.User? user = credential.user;
      final fullName = user?.displayName ?? '';

      print("User signed in successfully: ${user?.uid}");

      return UserModel(
        uid: user?.uid ?? '',
        fullName: fullName,
        email: email,
        password: password,
        photoUrl: user?.photoURL ?? '',
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      throw Exception(e.message);
    }
  }
}
