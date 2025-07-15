import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/receiver_service.dart';
import 'package:surpluserve/screens/receiver/surplus_detail_screen.dart';
import 'package:surpluserve/widgets/navbar.dart'; // 👈 import

class ReceiverHomeScreen extends StatefulWidget {
  const ReceiverHomeScreen({super.key});

  @override
  State<ReceiverHomeScreen> createState() => _ReceiverHomeScreenState();
}

class _ReceiverHomeScreenState extends State<ReceiverHomeScreen> {
  int _selectedIndex = 0;
  double? _receiverLat;
  double? _receiverLng;

  @override
  void initState() {
    super.initState();
    _checkInitialMessage();
    loadReceiverLocation();
  }

  void _checkInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null && message.data['surplusId'] != null) {
      final surplusId = message.data['surplusId'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SurplusDetailScreen(docId: surplusId),
        ),
      );
    }
  }

  Future<void> loadReceiverLocation() async {
    final coords = await ReceiverService.fetchReceiverCoordinates();
    if (coords != null) {
      setState(() {
        _receiverLat = coords['lat'];
        _receiverLng = coords['lng'];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please update your address.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Food Listings")),
      body: (_receiverLat == null || _receiverLng == null)
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('surplus_food')
            .where('status', isEqualTo: 'unclaimed')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          final itemsWithDistance = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final lat = data['lat'];
            final lng = data['lng'];
            final distance = (lat != null && lng != null)
                ? ReceiverService.calculateDistance(_receiverLat!, _receiverLng!, lat, lng)
                : double.infinity;

            return {
              'doc': doc,
              'data': data,
              'distance': distance,
            };
          }).toList();

          itemsWithDistance.sort((a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double));

          return ListView.builder(
            itemCount: itemsWithDistance.length,
            itemBuilder: (context, index) {
              final item = itemsWithDistance[index];
              final data = item['data'] as Map<String, dynamic>;
              final distance = item['distance'] as double;
              final foodTitle = data['foodTitle']?.toString() ?? 'Unnamed Food';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurplusDetailScreen(
                        docId: (item['doc'] as DocumentSnapshot).id,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          foodTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text("${distance.toStringAsFixed(2)} km"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: ReceiverBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
