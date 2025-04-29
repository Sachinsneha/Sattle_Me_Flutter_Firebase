import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RiderDetailPage extends StatelessWidget {
  final DocumentSnapshot doc;

  const RiderDetailPage({Key? key, required this.doc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final String riderName = data["fullName"] ?? "Unknown Rider";
    final String photoUrl = data["photoUrl"] ?? "";
    final List<dynamic> availability = data["availability"] ?? [];
    final String vehicleType = data["vehicleType"] ?? "N/A";
    final String vehicleColor = data["color"] ?? "N/A";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(250, 174, 43, 1),
        title: Text(riderName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child:
                      photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    riderName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Vehicle Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Chip(
                  label: Text("Vehicle: $vehicleType"),
                  backgroundColor: Colors.grey[200],
                ),
                Chip(
                  label: Text("Color: $vehicleColor"),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Availability Info
            const Text(
              "Availability",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((day) {
                    final bool isAvailable = availability.contains(day);
                    return Chip(
                      label: Text(day),
                      backgroundColor: isAvailable ? Colors.green : Colors.red,
                      labelStyle: const TextStyle(color: Colors.white),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
            // Additional details can be added here
            const Text(
              "Additional details about the rider can be shown here.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
