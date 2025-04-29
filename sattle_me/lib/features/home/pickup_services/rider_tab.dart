import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sattle_me/features/home/rental_service/pages/message_screen.dart';

class RiderTab extends StatefulWidget {
  const RiderTab({Key? key}) : super(key: key);

  @override
  _RiderTabState createState() => _RiderTabState();
}

class _RiderTabState extends State<RiderTab> {
  // Dropdown filter values.
  String selectedAvailability = 'All';
  String selectedColor = 'All';

  // Options for the dropdown menus.
  final List<String> availabilityOptions = [
    'All',
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  final List<String> colorOptions = [
    'All',
    'Red',
    'Blue',
    'Green',
    'Black',
    'White',
    'N/A',
  ];

  @override
  Widget build(BuildContext context) {
    // Use the actual logged-in user's id.
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Column(
        children: [
          // Filters section.
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Availability Dropdown.
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedAvailability,
                      decoration: InputDecoration(
                        labelText: "Availability",
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          availabilityOptions.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAvailability = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Vehicle Color Dropdown.
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedColor,
                      decoration: InputDecoration(
                        labelText: "Vehicle Color",
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          colorOptions.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(
                                option,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedColor = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // List of approved riders.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection("riderApplications")
                      .where("status", isEqualTo: "approved")
                      .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final riders = snapshot.data!.docs;

                // Filter riders based on dropdown values.
                final filteredRiders =
                    riders.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      bool matchesAvailability = true;
                      bool matchesColor = true;

                      if (selectedAvailability != 'All') {
                        final avail =
                            data['availability'] as List<dynamic>? ?? [];
                        matchesAvailability = avail.contains(
                          selectedAvailability,
                        );
                      }
                      if (selectedColor != 'All') {
                        final vehicleColor =
                            data.containsKey('color')
                                ? data['color'].toString()
                                : 'N/A';
                        matchesColor =
                            vehicleColor.toLowerCase() ==
                            selectedColor.toLowerCase();
                      }
                      return matchesAvailability && matchesColor;
                    }).toList();

                if (filteredRiders.isEmpty) {
                  return const Center(
                    child: Text(
                      "No approved riders match the filters.",
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredRiders.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredRiders[index].data() as Map<String, dynamic>;
                    final riderName = data["fullName"] ?? "Unknown";
                    final vehiclePhoto = data["photoUrl"] ?? "";
                    final availability =
                        data["availability"] as List<dynamic>? ?? [];
                    final vehicleType =
                        data.containsKey("vehicleType")
                            ? data["vehicleType"]
                            : "N/A";
                    final vehicleColor =
                        data.containsKey("color") ? data["color"] : "N/A";

                    // Use consistent field names for the rider's id.
                    final riderId =
                        data["uid"] ?? data["userId"] ?? "riderUnknown";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              vehiclePhoto.isNotEmpty
                                  ? NetworkImage(vehiclePhoto)
                                  : null,
                          child:
                              vehiclePhoto.isEmpty
                                  ? const Icon(Icons.person, size: 25)
                                  : null,
                        ),
                        title: Text(
                          riderName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    "Type: $vehicleType",
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: Colors.deepOrange.shade100,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Chip(
                                  label: Text(
                                    "Color: $vehicleColor",
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: Colors.deepOrange.shade100,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: _buildAvailabilityChips(availability),
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // Generate a conversation id consistently.
                            final conversationId =
                                currentUserId.compareTo(riderId) < 0
                                    ? '${currentUserId}_$riderId'
                                    : '${riderId}_$currentUserId';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MessageScreen(
                                      conversationId: conversationId,
                                      receiverId: riderId,
                                      receiverName: riderName,
                                      receiverPhotoUrl: vehiclePhoto,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFAAE2B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Message",
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build availability chips.
  List<Widget> _buildAvailabilityChips(List<dynamic> availability) {
    final allDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return allDays.map((day) {
      final isAvailable = availability.contains(day);
      return Chip(
        label: Text(
          day,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        backgroundColor: isAvailable ? Colors.green : Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        visualDensity: VisualDensity.compact,
      );
    }).toList();
  }
}
