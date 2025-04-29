import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RideRequestFormScreen extends StatefulWidget {
  final String? rideRequestDocId;
  const RideRequestFormScreen({Key? key, this.rideRequestDocId})
    : super(key: key);

  @override
  _RideRequestFormScreenState createState() => _RideRequestFormScreenState();
}

class _RideRequestFormScreenState extends State<RideRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;
  DocumentSnapshot? _rideRequestDoc;

  @override
  void initState() {
    super.initState();
    if (widget.rideRequestDocId != null) {
      _loadRideRequest();
    }
  }

  Future<void> _loadRideRequest() async {
    final doc =
        await FirebaseFirestore.instance
            .collection("rideRequests")
            .doc(widget.rideRequestDocId)
            .get();
    if (doc.exists) {
      setState(() {
        _rideRequestDoc = doc;
        _pickupController.text = doc.get("pickupLocation");
        _dropController.text = doc.get("dropLocation");
        Timestamp ts = doc.get("rideDate");
        _selectedDate = ts.toDate();
        Timestamp tsTime = doc.get("rideTime");
        final dtTime = tsTime.toDate();
        _selectedTime = TimeOfDay(hour: dtTime.hour, minute: dtTime.minute);
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay initialTime = _selectedTime ?? TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String rideDay = DateFormat.EEEE().format(_selectedDate!);
    String rideMonth = DateFormat.MMMM().format(_selectedDate!);

    DateTime rideDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    Map<String, dynamic> data = {
      "userId": user.uid,
      "name": user.displayName ?? "",
      "email": user.email ?? "",
      "photoUrl": user.photoURL ?? "",
      "pickupLocation": _pickupController.text.trim(),
      "dropLocation": _dropController.text.trim(),
      "rideDate": Timestamp.fromDate(_selectedDate!),
      "rideTime": Timestamp.fromDate(rideDateTime),
      "rideDay": rideDay,
      "rideMonth": rideMonth,
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (_rideRequestDoc == null) {
      await FirebaseFirestore.instance.collection("rideRequests").add(data);
    } else {
      await FirebaseFirestore.instance
          .collection("rideRequests")
          .doc(_rideRequestDoc!.id)
          .update({
            "pickupLocation": _pickupController.text.trim(),
            "dropLocation": _dropController.text.trim(),
            "rideDate": Timestamp.fromDate(_selectedDate!),
            "rideTime": Timestamp.fromDate(rideDateTime),
            "rideDay": rideDay,
            "rideMonth": rideMonth,
          });
    }
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Ride request submitted")));
    Navigator.pop(context);
  }

  // Fetch the user's document from Firestore to get the correct "photoUrl"
  Future<Map<String, dynamic>?> _getUserData() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
    return doc.data();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Ride"),
        backgroundColor: const Color(0xFFFAAE2B),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _getUserData(),
                      builder: (context, snapshot) {
                        String photoUrl = "";
                        if (snapshot.hasData && snapshot.data != null) {
                          photoUrl = snapshot.data!["photoUrl"] ?? "";
                        }
                        if (photoUrl.isEmpty && user?.photoURL != null) {
                          photoUrl = user!.photoURL!;
                        }
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      photoUrl.isNotEmpty
                                          ? NetworkImage(photoUrl)
                                          : const AssetImage(
                                                'assets/images/avatar.png',
                                              )
                                              as ImageProvider,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.displayName ?? "No Name",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? "",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Ride request form.
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _pickupController,
                            decoration: InputDecoration(
                              labelText: "Pickup Location",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Enter pickup location"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          // Drop Location Field.
                          TextFormField(
                            controller: _dropController,
                            decoration: InputDecoration(
                              labelText: "Drop Location",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? "Enter drop location"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          // Date Picker Row.
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedDate != null
                                        ? "Date: ${DateFormat.yMd().format(_selectedDate!)}"
                                        : "Select Date",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _pickDate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFAAE2B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                                child: const Text("Pick Date"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Time Picker Row.
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _selectedTime != null
                                        ? "Time: ${_selectedTime!.format(context)}"
                                        : "Select Time",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _pickTime,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFAAE2B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                                child: const Text("Pick Time"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_selectedDate != null)
                            Text(
                              "Day: ${DateFormat.EEEE().format(_selectedDate!)}   Month: ${DateFormat.MMMM().format(_selectedDate!)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              onPressed: _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFAAE2B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _rideRequestDoc == null
                                    ? "Submit Request"
                                    : "Update Request",
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
