import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sattle_me/features/home/agent/agent_detalis_page.dart';
import 'package:sattle_me/features/home/pickup_services/rider_detalis_page.dart';
import 'package:sattle_me/features/home/rental_service/pages/listing_detalis_page.dart';

class MessageScreen extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final String receiverName;
  final String receiverPhotoUrl;

  const MessageScreen({
    Key? key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPhotoUrl,
  }) : super(key: key);

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _ensureConversationExists();
  }

  Future<void> _ensureConversationExists() async {
    final conversationRef = FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.conversationId);
    final docSnapshot = await conversationRef.get();
    if (!docSnapshot.exists) {
      await conversationRef.set({
        "participants": [currentUserId, widget.receiverId],
        "lastMessage": "",
        "lastTimestamp": Timestamp.now(),
      });
    }
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.conversationId)
          .collection("messages")
          .add({
            "senderId": currentUserId,
            "text": message,
            "timestamp": Timestamp.now(),
          });
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.conversationId)
          .set({
            "participants": [currentUserId, widget.receiverId],
            "lastMessage": message,
            "lastTimestamp": Timestamp.now(),
          }, SetOptions(merge: true));
      _messageController.clear();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();
    String text = data["text"] ?? "";
    String senderId = data["senderId"] ?? "";
    bool isMe = senderId == currentUserId;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isMe ? const Color.fromRGBO(250, 174, 43, 1) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }

  Future<void> _openProfileDetail() async {
    try {
      QuerySnapshot rentalSnapshot =
          await FirebaseFirestore.instance
              .collection("rentalListings")
              .where("userId", isEqualTo: widget.receiverId)
              .limit(1)
              .get();
      if (rentalSnapshot.docs.isNotEmpty) {
        DocumentSnapshot rentalDoc = rentalSnapshot.docs.first;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListingDetailPage(doc: rentalDoc)),
        );
        return;
      }

      DocumentSnapshot agentDoc =
          await FirebaseFirestore.instance
              .collection("agents")
              .doc(widget.receiverId)
              .get();
      if (agentDoc.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AgentDetailPage(doc: agentDoc)),
        );
        return;
      }

      QuerySnapshot riderSnapshot =
          await FirebaseFirestore.instance
              .collection("riderApplications")
              .where("userId", isEqualTo: widget.receiverId)
              .where("status", isEqualTo: "approved")
              .limit(1)
              .get();
      if (riderSnapshot.docs.isNotEmpty) {
        DocumentSnapshot riderDoc = riderSnapshot.docs.first;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RiderDetailPage(doc: riderDoc)),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No details available.")));
    } catch (e) {
      print("Error fetching profile details: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(250, 174, 43, 1),
        title: InkWell(
          onTap: _openProfileDetail,
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    widget.receiverPhotoUrl.isNotEmpty
                        ? NetworkImage(widget.receiverPhotoUrl)
                        : null,
                child:
                    widget.receiverPhotoUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
              ),
              const SizedBox(width: 8),
              Text(widget.receiverName),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection("chats")
                      .doc(widget.conversationId)
                      .collection("messages")
                      .orderBy("timestamp", descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading messages"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data?.docs;
                if (messages == null || messages.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageItem(messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
