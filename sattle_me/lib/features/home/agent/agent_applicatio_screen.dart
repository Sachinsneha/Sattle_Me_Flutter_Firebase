import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BecomeAgentPage extends StatefulWidget {
  const BecomeAgentPage({Key? key}) : super(key: key);

  @override
  _BecomeAgentPageState createState() => _BecomeAgentPageState();
}

class _BecomeAgentPageState extends State<BecomeAgentPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _specialityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error picking image")));
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not authenticated")));
        return;
      }

      String imageUrl = "";
      if (_selectedImage != null) {
        File file = File(_selectedImage!.path);
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}';
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child("agentApplications")
            .child(user.uid)
            .child(fileName);
        UploadTask uploadTask = storageRef.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      Map<String, dynamic> agentData = {
        "fullName": _fullNameController.text,
        "speciality": _specialityController.text,
        "rate": _rateController.text,
        "contact": _contactController.text,
        "bio": _bioController.text,
        "photoUrl": imageUrl,
        "userId": user.uid,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "pending",
      };

      await FirebaseFirestore.instance
          .collection("agentApplications")
          .add(agentData);

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Application Submitted"),
            content: const Text("We will contact you soon through email."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _specialityController.dispose();
    _rateController.dispose();
    _contactController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text(
          "Become an Agent",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                _selectedImage != null
                                    ? FileImage(File(_selectedImage!.path))
                                    : null,
                            child:
                                _selectedImage == null
                                    ? const Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: Colors.white,
                                    )
                                    : null,
                            backgroundColor: Colors.grey[400],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildTextField(_fullNameController, "Full Name"),
                      const SizedBox(height: 16),
                      buildTextField(_specialityController, "Speciality"),
                      const SizedBox(height: 16),
                      buildTextField(
                        _rateController,
                        "Agent Rate",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      buildTextField(_contactController, "Contact Information"),
                      const SizedBox(height: 16),
                      buildTextField(_bioController, "Short Bio", maxLines: 3),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitApplication,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blueAccent,
                            shadowColor: Colors.blueAccent.withOpacity(0.5),
                            elevation: 5,
                          ),
                          child: const Text(
                            "Submit Application",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter $label";
        }
        return null;
      },
    );
  }
}
