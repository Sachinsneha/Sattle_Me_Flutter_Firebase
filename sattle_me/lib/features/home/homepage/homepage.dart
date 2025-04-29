import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sattle_me/features/auth/presentation/cubit/session_cubit.dart';
import 'package:sattle_me/features/auth/presentation/screens/login_screen.dart';
import 'package:sattle_me/features/home/agent/agent_listing_page.dart';
import 'package:sattle_me/features/home/homepage/widgets/horizontal_list.dart';
import 'package:sattle_me/features/home/homepage/widgets/section_header.dart';
import 'package:sattle_me/features/home/homepage/widgets/service_tiles.dart';
import 'package:sattle_me/features/home/pickup_services/pickup_service.dart';
import 'package:sattle_me/features/home/profile/profile.dart';
import 'package:sattle_me/features/home/rental_service/pages/conversion_list_screen.dart';
import 'package:sattle_me/features/home/rental_service/pages/favorite_page.dart';
import 'package:sattle_me/features/home/rental_service/pages/rental_list_page.dart';
import 'package:sattle_me/features/home/rental_service/pages/upload_rental_page.dart';
import 'package:sattle_me/features/home/todo/todo_screen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Map<String, String>> favoriteRentals = [];

  void _onItemTapped(int index) {
    Widget? page;
    if (index == 3) {
      page = FavoritesPage(favoriteRentals: favoriteRentals);
    } else if (index == 4) {
      page = ProfilePage();
    } else if (index == 2) {
      page = UploadRentalPage();
    } else if (index == 1) {
      page = ConversationListScreen();
    } else {
      setState(() {
        _selectedIndex = index;
      });
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionState>(
      builder: (context, state) {
        if (state is SessionAuthenticated) {
          final userId = state.user.uid;
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              elevation: 1,
              backgroundColor: Colors.white,
              title: const Text(
                "Home",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  onPressed: () {
                    context.read<SessionCubit>().logOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginPage()),
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Rental Service Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionHeader(title: "Rental Service"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => RentalListPage(
                                    favoriteRentals: favoriteRentals,
                                  ),
                            ),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HorizontalList(),
                  const SizedBox(height: 20),
                  // Pick Up Service
                  const SectionHeader(title: "Pick Up Service"),
                  serv(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PickUpServicePage()),
                      );
                    },
                    icon: Icons.local_taxi,
                    title: "Book a Ride",
                    subtitle: "Quick and safe pickup",
                  ),
                  const SizedBox(height: 16),
                  // To Do
                  const SectionHeader(title: "To Do"),
                  serv(
                    icon: Icons.check_circle,
                    title: "Task Manager",
                    subtitle: "Manage your daily tasks",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ToDoScreen(userId: userId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Book an Agent
                  const SectionHeader(title: "Book an Agent"),
                  serv(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AgentListPage()),
                      );
                    },
                    icon: Icons.support_agent,
                    title: "Find an Agent",
                    subtitle: "Professional support anytime",
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 24),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat, size: 24),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add, size: 24),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border, size: 24),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline, size: 24),
                  label: '',
                ),
              ],
            ),
          );
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
