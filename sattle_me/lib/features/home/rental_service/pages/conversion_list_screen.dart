import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sattle_me/features/home/rental_service/pages/message_screen.dart';

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  // Format timestamps.
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return DateFormat.jm().format(date);
    } else {
      return DateFormat.yMd().add_jm().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(250, 174, 43, 1),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsetsDirectional.only(top: 15),
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection("chats")
                  .where("participants", arrayContains: currentUserId)
                  .orderBy("lastTimestamp", descending: false)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error.toString()}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs;
            if (docs == null || docs.isEmpty) {
              return const Center(child: Text("No conversations"));
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder:
                  (_, __) =>
                      Divider(height: 1, color: Colors.grey[300], indent: 70),
              itemBuilder: (context, index) {
                final docData = docs[index].data();
                if (docData == null || docData is! Map<String, dynamic>) {
                  return const SizedBox.shrink();
                }
                final conversation = docData as Map<String, dynamic>;
                final String conversationId = docs[index].id;
                final List<dynamic> participants =
                    conversation["participants"] ?? [];

                // Identify the other user.
                final String otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => currentUserId,
                );
                final String lastMessage = conversation["lastMessage"] ?? "";
                final Timestamp? lastTimestamp = conversation["lastTimestamp"];
                final bool unread = conversation["unread"] ?? false;

                if (lastTimestamp == null) {
                  return const SizedBox.shrink();
                }

                final String timeString = _formatTimestamp(lastTimestamp);

                return FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection("users")
                          .doc(otherUserId)
                          .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(title: Text("Loading..."));
                    }
                    if (userSnapshot.hasError ||
                        !userSnapshot.hasData ||
                        userSnapshot.data == null) {
                      return const ListTile(title: Text("Unknown"));
                    }

                    final userData = userSnapshot.data!.data();
                    if (userData == null || userData is! Map<String, dynamic>) {
                      return const ListTile(title: Text("Unknown"));
                    }

                    // Extract user info.
                    String displayName =
                        userData["fullName"] ??
                        userData["name"] ??
                        userData["displayName"] ??
                        "Unknown";
                    String photoUrl =
                        userData["photoUrl"] ?? userData["photoURL"] ?? "";
                    bool isOnline = userData["isOnline"] ?? false;
                    final String role =
                        (userData["role"] ?? "").toString().toLowerCase();
                    if (role == "agent") {
                      displayName = "Agent ($displayName)";
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => MessageScreen(
                                  conversationId: conversationId,
                                  receiverId: otherUserId,
                                  receiverName: displayName,
                                  receiverPhotoUrl: photoUrl,
                                ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      photoUrl.isNotEmpty
                                          ? NetworkImage(photoUrl)
                                          : null,
                                  child:
                                      photoUrl.isEmpty
                                          ? const Icon(Icons.person, size: 28)
                                          : null,
                                ),
                                if (isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight:
                                          unread
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  timeString,
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
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
