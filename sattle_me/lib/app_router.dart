import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sattle_me/features/auth/presentation/screens/login_screen.dart';
import 'package:sattle_me/features/home/homepage/homepage.dart';
import 'features/auth/presentation/cubit/session_cubit.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        if (state is SessionAuthenticated) {
          return HomePage();
        } else if (state is SessionUnauthenticated) {
          return LoginPage();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
