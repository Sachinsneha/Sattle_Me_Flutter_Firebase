import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:sattle_me/features/home/rental_service/pages/message_screen.dart';

class ListingDetailPage extends StatelessWidget {
  final DocumentSnapshot doc;
  const ListingDetailPage({Key? key, required this.doc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract listing data.
    final data = doc.data() as Map<String, dynamic>;
    final String title = data["name"] ?? "No title";
    final String address = data["address"] ?? "No address";
    final String price = data["price"] ?? "";
    final String description = data["description"] ?? "";
    final List<dynamic> imageUrls = data["imageUrls"] ?? [];
    final String userId = data["userId"] ?? "";

    // Optionally, if you stored the poster's info in the listing,
    // these would override the data in the user doc.
    final String listingUserFullName = data["userFullName"] ?? "";
    final String listingUserPhotoUrl = data["userPhotoUrl"] ?? "";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display the header image or a placeholder.
            imageUrls.isNotEmpty
                ? Image.network(imageUrls[0], height: 250, fit: BoxFit.cover)
                : Container(
                  height: 250,
                  color: Colors.grey,
                  child: const Center(child: Text("No Image Available")),
                ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing title.
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Listing address.
                  Text(
                    address,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Listing price.
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description section.
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  // Display poster info with chat icon.
                  FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection("users")
                            .doc(userId)
                            .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Row(
                          children: const [
                            CircleAvatar(
                              radius: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text("Loading...", style: TextStyle(fontSize: 16)),
                          ],
                        );
                      }
                      if (userSnapshot.hasError ||
                          !userSnapshot.hasData ||
                          userSnapshot.data == null) {
                        return Row(
                          children: const [
                            CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person, size: 16),
                            ),
                            SizedBox(width: 8),
                            Text("Unknown", style: TextStyle(fontSize: 16)),
                          ],
                        );
                      }
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      // Debug: Print user data to console.
                      print("User data for userId $userId: $userData");

                      // Use listing's stored info if available, otherwise fallback to user document.
                      String displayName =
                          listingUserFullName.isNotEmpty
                              ? listingUserFullName
                              : (userData["fullName"] ??
                                  userData["name"] ??
                                  userData["displayName"] ??
                                  "Unknown");
                      String photoUrl =
                          listingUserPhotoUrl.isNotEmpty
                              ? listingUserPhotoUrl
                              : (userData["photoUrl"] ??
                                  userData["photoURL"] ??
                                  "");

                      return Row(
                        children: [
                          const Text('Posted by '),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                            child:
                                photoUrl.isEmpty
                                    ? const Icon(Icons.person, size: 16)
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayName,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.chat),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MessageScreen(
                                        conversationId: _generateConversationId(
                                          fb
                                              .FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                          userId,
                                        ),
                                        receiverId: userId,
                                        receiverName: displayName,
                                        receiverPhotoUrl: photoUrl,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateConversationId(String currentUserId, String receiverId) {
    return currentUserId.compareTo(receiverId) < 0
        ? "${currentUserId}_$receiverId"
        : "${receiverId}_$currentUserId";
  }
}
