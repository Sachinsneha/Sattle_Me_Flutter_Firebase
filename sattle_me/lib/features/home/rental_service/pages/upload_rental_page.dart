import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadRentalPage extends StatefulWidget {
  const UploadRentalPage({Key? key}) : super(key: key);

  @override
  _UploadRentalPageState createState() => _UploadRentalPageState();
}

class _UploadRentalPageState extends State<UploadRentalPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile>? _imageFiles = [];

  bool _isLoading = false;

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles = pickedFiles;
        });
      }
    } catch (e) {
      print("Error picking images: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error picking images")));
    }
  }

  Future<void> _postRental() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFiles == null || _imageFiles!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one image")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current authenticated user.
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not authenticated")));
        return;
      }

      // Upload images to Firebase Storage.
      List<String> imageUrls = [];
      for (XFile imageFile in _imageFiles!) {
        File file = File(imageFile.path);
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child("rentalListings")
            .child(user.uid)
            .child(fileName);
        UploadTask uploadTask = storageRef.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Prepare the listing data.
      Map<String, dynamic> listingData = {
        "name": _nameController.text,
        "address": _addressController.text,
        "price": _priceController.text,
        "description": _descriptionController.text,
        "imageUrls": imageUrls,
        "userId": user.uid,
        "userEmail": user.email ?? "no-email",
        // Save user info from FirebaseAuth.
        "userFullName": user.displayName ?? "Unknown",
        "userPhotoUrl": user.photoURL ?? "",
        "timestamp": FieldValue.serverTimestamp(),
      };

      // Save the listing document.
      await FirebaseFirestore.instance
          .collection("rentalListings")
          .add(listingData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Listing Posted!")));

      // Clear the form.
      _nameController.clear();
      _addressController.clear();
      _priceController.clear();
      _descriptionController.clear();
      setState(() {
        _imageFiles = [];
      });
    } catch (e) {
      print("Error posting listing: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error posting listing: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show an edit dialog for a listing document.
  void _showEditDialog(DocumentSnapshot doc) {
    final TextEditingController editNameController = TextEditingController(
      text: doc["name"],
    );
    final TextEditingController editAddressController = TextEditingController(
      text: doc["address"],
    );
    final TextEditingController editPriceController = TextEditingController(
      text: doc["price"],
    );
    final TextEditingController editDescriptionController =
        TextEditingController(text: doc["description"]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Listing"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: editNameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: editAddressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                TextField(
                  controller: editPriceController,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: editDescriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () async {
                try {
                  await doc.reference.update({
                    "name": editNameController.text,
                    "address": editAddressController.text,
                    "price": editPriceController.text,
                    "description": editDescriptionController.text,
                    "timestamp": FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Listing Updated")),
                  );
                } catch (e) {
                  print("Error updating listing: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating listing: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Delete a listing.
  Future<void> _deleteListing(DocumentSnapshot doc) async {
    try {
      await doc.reference.delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Listing Deleted")));
    } catch (e) {
      print("Error deleting listing: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting listing: $e")));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Rental")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Posting Form.
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Upload Images",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                _imageFiles != null && _imageFiles!.isNotEmpty
                                    ? ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _imageFiles!.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.all(8),
                                          child: Image.file(
                                            File(_imageFiles![index].path),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    )
                                    : const Center(
                                      child: Text("No images selected"),
                                    ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Select Images"),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Name",
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please enter a name"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: "Address",
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please enter an address"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: "Price",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please enter a price"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: "Description",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Please enter a description"
                                        : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _postRental,
                            child: const Text("Post"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // "My Listings" section.
                    if (user != null) ...[
                      const Text(
                        "My Listings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection("rentalListings")
                                .where("userId", isEqualTo: user.uid)
                                .orderBy("timestamp", descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text("Error: ${snapshot.error}"),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final docs = snapshot.data?.docs;
                          if (docs == null || docs.isEmpty) {
                            return const Text("No listings posted yet.");
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              String title = data["name"] ?? "No title";
                              String address = data["address"] ?? "No address";
                              String price = data["price"] ?? "";
                              String description = data["description"] ?? "";
                              List<dynamic> imageUrls = data["imageUrls"] ?? [];
                              String imageUrl =
                                  imageUrls.isNotEmpty ? imageUrls[0] : "";
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading:
                                      imageUrl.isNotEmpty
                                          ? Image.network(
                                            imageUrl,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          )
                                          : Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey,
                                            child: const Center(
                                              child: Text("No Image"),
                                            ),
                                          ),
                                  title: Text(title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(address),
                                      Text(price),
                                      Text(
                                        description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  trailing: Wrap(
                                    spacing: 12,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _showEditDialog(doc),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deleteListing(doc),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
      ),
    );
  }
}
