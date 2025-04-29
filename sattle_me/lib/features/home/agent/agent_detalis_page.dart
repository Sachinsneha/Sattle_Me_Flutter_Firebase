import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sattle_me/features/home/agent/payment_page.dart';
import 'package:sattle_me/features/home/rental_service/pages/message_screen.dart';

class AgentDetailPage extends StatefulWidget {
  final DocumentSnapshot doc;
  const AgentDetailPage({Key? key, required this.doc}) : super(key: key);

  @override
  _AgentDetailPageState createState() => _AgentDetailPageState();
}

class _AgentDetailPageState extends State<AgentDetailPage> {
  bool hasPaid = false;

  Future<void> _handlePayment() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PaymentPage()),
    );
    if (result != null && result) {
      setState(() {
        hasPaid = true;
      });
    }
  }

  String _generateConversationId(String currentUserId, String receiverId) {
    return currentUserId.compareTo(receiverId) < 0
        ? "${currentUserId}_$receiverId"
        : "${receiverId}_$currentUserId";
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    String fullName = data["fullName"] ?? "Agent";
    String speciality = data["speciality"] ?? "No speciality provided";
    String rate = data["rate"] ?? "";
    String contact = data["contact"] ?? "";
    String bio = data["bio"] ?? "";
    String photoUrl = data["photoUrl"] ?? "";
    String userId = data["userId"] ?? "";

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text(fullName, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child:
                    photoUrl.isEmpty
                        ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        )
                        : null,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Speciality: $speciality",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Rate: $rate",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              "Contact: $contact",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bio",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(bio, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!hasPaid)
              buildGradientButton("Pay to Chat", _handlePayment)
            else
              buildGradientButton("Chat Now", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => MessageScreen(
                          conversationId: _generateConversationId(
                            FirebaseAuth.instance.currentUser!.uid,
                            userId,
                          ),
                          receiverId: userId,
                          receiverName: fullName,
                          receiverPhotoUrl: photoUrl,
                        ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget buildGradientButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.blueAccent,
          shadowColor: Colors.blueAccent.withOpacity(0.5),
          elevation: 5,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
