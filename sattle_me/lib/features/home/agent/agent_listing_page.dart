import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sattle_me/features/home/agent/agent_detalis_page.dart';
import 'package:sattle_me/features/home/agent/agent_applicatio_screen.dart';

class AgentListPage extends StatelessWidget {
  const AgentListPage({Key? key}) : super(key: key);

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
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text("Agents", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BecomeAgentPage()),
              );
            },
            child: const Text(
              "Become an Agent",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("agentApplications")
                .where("status", isEqualTo: "approved")
                .orderBy("timestamp", descending: true)
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
            return const Center(
              child: Text(
                "No agents available.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            separatorBuilder:
                (_, __) => const Divider(height: 1, thickness: 0.5),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final agentData = docs[index].data() as Map<String, dynamic>;
              String fullName = agentData["fullName"] ?? "Unknown";
              String speciality = agentData["speciality"] ?? "No speciality";
              String rate = agentData["rate"] ?? "N/A";
              String photoUrl = agentData["photoUrl"] ?? "";
              Timestamp? ts = agentData["timestamp"];
              String timeString = ts != null ? _formatTimestamp(ts) : "";

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child:
                          photoUrl.isEmpty
                              ? const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              )
                              : null,
                      backgroundColor: Colors.grey[300],
                    ),
                    title: Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          speciality,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "Rate: $rate",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgentDetailPage(doc: docs[index]),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
