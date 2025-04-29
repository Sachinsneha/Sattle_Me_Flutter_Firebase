import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:sattle_me/features/auth/domain/entities/user_entity.dart';

abstract class SessionState extends Equatable {
  const SessionState();
  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {}

class SessionAuthenticated extends SessionState {
  final User user;
  const SessionAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

class SessionUnauthenticated extends SessionState {}

class SessionCubit extends Cubit<SessionState> {
  final fb_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  SessionCubit({required this.firebaseAuth, required this.firestore})
    : super(SessionInitial()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final fb_auth.User? fbUser = firebaseAuth.currentUser;
    if (fbUser != null) {
      await refreshUserData(fbUser.uid);
    } else {
      emit(SessionUnauthenticated());
    }
  }

  Future<void> refreshUserData(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final user = User(
          uid: uid,
          fullName: data['fullName'] ?? '',
          email: data['email'] ?? '',
          password: '',
          photoUrl: data['photoUrl'] ?? '',
        );
        emit(SessionAuthenticated(user: user));
      } else {
        emit(SessionUnauthenticated());
      }
    } catch (e) {
      print(" Error fetching user data: $e");
      emit(SessionUnauthenticated());
    }
  }

  Future<void> updateProfileImage(String uid, String newPhotoUrl) async {
    try {
      await firestore.collection('users').doc(uid).update({
        'photoUrl': newPhotoUrl,
      });

      await refreshUserData(uid);
    } catch (e) {
      print("Error updating profile image: $e");
    }
  }

  void logIn(User user) {
    emit(SessionAuthenticated(user: user));
  }

  Future<void> logOut() async {
    await firebaseAuth.signOut();
    emit(SessionUnauthenticated());
  }
}
