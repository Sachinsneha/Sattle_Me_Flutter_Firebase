import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sattle_me/features/home/pickup_services/request_ride.dart';
import 'package:sattle_me/features/home/rental_service/pages/message_screen.dart';

class RideRequestedTab extends StatelessWidget {
  const RideRequestedTab({Key? key}) : super(key: key);

  Future<bool> _isApprovedRider() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final snapshot =
        await FirebaseFirestore.instance
            .collection("riderApplications")
            .where("userId", isEqualTo: user.uid)
            .where("status", isEqualTo: "approved")
            .get();
    return snapshot.docs.isNotEmpty;
  }

  Widget buildAvatar(String requesterId, String docPhotoUrl) {
    return docPhotoUrl.isNotEmpty
        ? CircleAvatar(radius: 24, backgroundImage: NetworkImage(docPhotoUrl))
        : FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(requesterId)
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data?.data() != null) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              String photoUrl = userData["photoUrl"] ?? "";
              if (photoUrl.isNotEmpty) {
                return CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(photoUrl),
                );
              }
            }
            return const CircleAvatar(
              radius: 24,
              child: Icon(Icons.person, size: 20),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection("rideRequests")
              .orderBy("createdAt", descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs;
        if (docs == null || docs.isEmpty) {
          return const Center(child: Text("No ride requests"));
        }
        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final String name = data["name"] ?? "";
            final String pickup = data["pickupLocation"] ?? "";
            final String drop = data["dropLocation"] ?? "";
            final String docPhotoUrl = data["photoUrl"] ?? "";
            Timestamp? rideDateTimestamp = data["rideDate"];
            Timestamp? rideTimeTimestamp = data["rideTime"];
            String dateStr =
                rideDateTimestamp != null
                    ? DateFormat.yMd().format(rideDateTimestamp.toDate())
                    : "";
            String timeStr =
                rideTimeTimestamp != null
                    ? DateFormat.jm().format(rideTimeTimestamp.toDate())
                    : "";
            final String rideDay = data["rideDay"] ?? "";
            final String rideMonth = data["rideMonth"] ?? "";
            final String requesterId = data["userId"] ?? "";

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildAvatar(requesterId, docPhotoUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Pickup: $pickup",
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Drop: $drop",
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "($rideDay, $rideMonth)",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (requesterId == currentUserId) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => RideRequestFormScreen(
                                        rideRequestDocId: docs[index].id,
                                      ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("rideRequests")
                                  .doc(docs[index].id)
                                  .delete();
                            },
                          ),
                        ],
                        FutureBuilder<bool>(
                          future: _isApprovedRider(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 90,
                                height: 30,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            final bool isApproved = snapshot.data ?? false;
                            if (isApproved) {
                              return SizedBox(
                                width: 90,
                                height: 30,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFAAE2B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  onPressed: () {
                                    final conversationId =
                                        currentUserId.compareTo(requesterId) < 0
                                            ? '$currentUserId\_$requesterId'
                                            : '$requesterId\_$currentUserId';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => MessageScreen(
                                              conversationId: conversationId,
                                              receiverId: requesterId,
                                              receiverName: name,
                                              receiverPhotoUrl:
                                                  docPhotoUrl.isNotEmpty
                                                      ? docPhotoUrl
                                                      : "assets/images/avatar.png",
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.message, size: 12),
                                  label: const Text(
                                    "Chat",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
