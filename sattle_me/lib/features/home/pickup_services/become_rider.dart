import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BecomeRiderPage extends StatefulWidget {
  const BecomeRiderPage({Key? key}) : super(key: key);

  @override
  _BecomeRiderPageState createState() => _BecomeRiderPageState();
}

class _BecomeRiderPageState extends State<BecomeRiderPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  final List<String> _days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  final Set<String> _selectedDays = {};

  bool _isLoading = false;
  String? _riderDocId;
  String? _imageUrl;
  String? _applicationStatus; // "pending" or "approved"

  @override
  void initState() {
    super.initState();
    _loadRiderData();
  }

  Future<void> _loadRiderData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var snapshot =
        await FirebaseFirestore.instance
            .collection("riderApplications")
            .where("userId", isEqualTo: user.uid)
            .get();

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first;
      setState(() {
        _riderDocId = data.id;
        _applicationStatus = data["status"];
        _fullNameController.text = data["fullName"];
        _emailController.text = data["email"];
        _contactController.text = data["contact"];
        _numberPlateController.text = data["numberPlate"] ?? "";
        _vehicleTypeController.text = data["vehicleType"] ?? "";
        _colorController.text = data["color"] ?? "";
        _selectedDays.addAll(List<String>.from(data["availability"] ?? []));
        _imageUrl = data["photoUrl"];
      });
    } else {
      // Pre-fill with current user's data if no application exists.
      _fullNameController.text = user.displayName ?? "";
      _emailController.text = user.email ?? "";
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error picking image")));
    }
  }

  Future<void> _submitApplication() async {
    bool isApproved = _riderDocId != null && _applicationStatus == "approved";

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one availability day"),
        ),
      );
      return;
    }

    if (!isApproved && !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!isApproved &&
        (_fullNameController.text != (user.displayName ?? "") ||
            _emailController.text != (user.email ?? ""))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Full Name and Email must match your login credentials",
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (isApproved) {
      await FirebaseFirestore.instance
          .collection("riderApplications")
          .doc(_riderDocId)
          .update({
            "availability": _selectedDays.toList(),
            "timestamp": FieldValue.serverTimestamp(),
          });
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Availability updated")));
      return;
    }

    String imageUrl = _imageUrl ?? "";
    if (_selectedImage != null) {
      File file = File(_selectedImage!.path);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child("riderApplications")
          .child(user.uid)
          .child(fileName);
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    Map<String, dynamic> riderData = {
      "fullName": _fullNameController.text,
      "email": _emailController.text,
      "contact": _contactController.text,
      "numberPlate": _numberPlateController.text,
      "vehicleType": _vehicleTypeController.text,
      "color": _colorController.text,
      "photoUrl": imageUrl,
      "availability": _selectedDays.toList(),
      "userId": user.uid,
      "timestamp": FieldValue.serverTimestamp(),
      "status": "pending",
    };

    if (_riderDocId == null) {
      var docRef = await FirebaseFirestore.instance
          .collection("riderApplications")
          .add(riderData);
      setState(() => _riderDocId = docRef.id);
    } else {
      await FirebaseFirestore.instance
          .collection("riderApplications")
          .doc(_riderDocId)
          .update(riderData);
    }

    setState(() {
      _isLoading = false;
      _imageUrl = imageUrl;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Application Updated")));
  }

  Future<void> _deleteApplication() async {
    if (_riderDocId == null) return;
    await FirebaseFirestore.instance
        .collection("riderApplications")
        .doc(_riderDocId)
        .delete();
    setState(() {
      _riderDocId = null;
      _applicationStatus = null;
      _fullNameController.clear();
      _emailController.clear();
      _contactController.clear();
      _numberPlateController.clear();
      _vehicleTypeController.clear();
      _colorController.clear();
      _selectedDays.clear();
      _selectedImage = null;
      _imageUrl = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Application Deleted")));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isApproved = _riderDocId != null && _applicationStatus == "approved";
    String buttonText;
    if (_riderDocId == null) {
      buttonText = "Submit Application";
    } else if (isApproved) {
      buttonText = "Update Availability";
    } else {
      buttonText = "Update Application";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Become a Rider"),
        backgroundColor: const Color(0xFFFAAE2B),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.orange.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 8,
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _fullNameController,
                              decoration: _inputDecoration("Full Name"),
                              readOnly: true,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? "Full name is required"
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration("Email"),
                              readOnly: true,
                              validator:
                                  (value) =>
                                      value!.contains("@")
                                          ? null
                                          : "Enter a valid email",
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contactController,
                              decoration: _inputDecoration("Contact"),
                              readOnly: isApproved,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? "Enter your contact info"
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _numberPlateController,
                              decoration: _inputDecoration("Number Plate"),
                              readOnly: isApproved,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? "Enter your vehicle's number plate"
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _vehicleTypeController,
                              decoration: _inputDecoration("Vehicle Type"),
                              readOnly: isApproved,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? "Enter your vehicle type"
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _colorController,
                              decoration: _inputDecoration("Vehicle Color"),
                              readOnly: isApproved,
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? "Enter your vehicle color"
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Availability",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children:
                                  _days.map((day) {
                                    final isSelected = _selectedDays.contains(
                                      day,
                                    );
                                    return ChoiceChip(
                                      label: Text(day),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          selected
                                              ? _selectedDays.add(day)
                                              : _selectedDays.remove(day);
                                        });
                                      },
                                      selectedColor: const Color.fromARGB(
                                        255,
                                        2,
                                        156,
                                        30,
                                      ),
                                      backgroundColor: Colors.grey.shade200,
                                    );
                                  }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _imageUrl != null
                                    ? CircleAvatar(
                                      radius: 30,
                                      backgroundImage: NetworkImage(_imageUrl!),
                                    )
                                    : const CircleAvatar(
                                      radius: 30,
                                      child: Icon(Icons.directions_car),
                                    ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: isApproved ? null : _pickImage,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text(
                                    "Upload Vehicle Photo",
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 128, 121, 121),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFAAE2B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _submitApplication,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFAAE2B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                buttonText,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_riderDocId != null)
                              ElevatedButton(
                                onPressed: _deleteApplication,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFAAE2B),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Delete Application",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}
