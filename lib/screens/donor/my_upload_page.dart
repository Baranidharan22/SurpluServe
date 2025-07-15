import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_upload_page.dart'; // Replace with actual path

class MyUploadsPage extends StatelessWidget {
  const MyUploadsPage({super.key});

  // Color based on status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'unclaimed':
        return Colors.red;
      case 'claimed':
        return Colors.orange;
      case 'pickedup':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final currentUserId = snapshot.data!.uid;

        return Scaffold(
          appBar: AppBar(title: const Text("My Uploads"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pushReplacementNamed(context, '/donorHome'),
            ),

          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('surplus_food')
                .where('donorId', isEqualTo: currentUserId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No uploads found."));
              }

              final uploads = snapshot.data!.docs;

              return ListView.builder(
                itemCount: uploads.length,
                itemBuilder: (context, index) {
                  final doc = uploads[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'unknown';
                  final statusColor = getStatusColor(status);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditUploadPage(
                            docId: uploads[index].id,
                            data: data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Status indicator dot
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),

                          // Title and status
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['foodTitle'] ?? 'No Title',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
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
              );
            },
          ),
        );
      },
    );
  }
}
