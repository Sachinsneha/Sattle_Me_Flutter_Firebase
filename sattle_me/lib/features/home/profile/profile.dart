import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sattle_me/features/auth/presentation/cubit/session_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sattle_me/features/home/homepage/homepage.dart';
import 'package:sattle_me/features/home/rental_service/pages/favorite_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  bool _isUploading = false;
  int _selectedIndex = 4;
  List<Map<String, String>> favoriteRentals = [];

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FavoritesPage(favoriteRentals: favoriteRentals),
        ),
      );
    } else if (index == 0) {
      // Profile Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _pickAndUploadImage(String userId) async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isUploading = true;
      });

      await _uploadImage(userId);
    }
  }

  Future<void> _uploadImage(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'profile_images/$userId.jpg',
      );

      if (_image == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No image selected!')));
        setState(() => _isUploading = false);
        return;
      }

      final uploadTask = ref.putFile(_image!);
      await uploadTask;

      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'photoUrl': imageUrl,
      });

      context.read<SessionCubit>().updateProfileImage(userId, imageUrl);

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile image uploaded successfully!')),
      );
    } catch (e) {
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: BlocBuilder<SessionCubit, SessionState>(
        builder: (context, state) {
          if (state is SessionAuthenticated) {
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            _image != null
                                ? FileImage(_image!)
                                : (user.photoUrl.isNotEmpty
                                    ? NetworkImage(user.photoUrl)
                                        as ImageProvider
                                    : AssetImage("assets/default_avatar.png")),
                      ),
                      GestureDetector(
                        onTap: () => _pickAndUploadImage(user.uid),
                        child: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          radius: 22,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileDetail("Name", user.fullName),
                          const SizedBox(height: 12),
                          _buildProfileDetail("Email", user.email),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickAndUploadImage(user.uid),
                    icon: Icon(Icons.upload, size: 20),
                    label: Text("Upload Profile Image"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isUploading)
                    Column(
                      children: [
                        CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        Text(
                          "Uploading...",
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    ),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
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
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ''),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(10),
              child: Icon(Icons.add, color: Colors.white),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite), // **Filled Heart**
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),
    );
  }

  Widget _buildProfileDetail(String title, String value) {
    return Row(
      children: [
        Icon(
          title == "Name" ? Icons.person : Icons.email,
          color: Colors.blueAccent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : "Not provided",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
