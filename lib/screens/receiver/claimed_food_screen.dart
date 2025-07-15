import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../services/receiver_service.dart';
import '../receiver/map.dart';
import '../../widgets/navbar.dart';

class ClaimedFoodScreen extends StatefulWidget {
  const ClaimedFoodScreen({super.key});

  @override
  State<ClaimedFoodScreen> createState() => _ClaimedFoodScreenState();
}

class _ClaimedFoodScreenState extends State<ClaimedFoodScreen> {
  late Future<List<DocumentSnapshot>> _claimedDocsFuture;
  int _selectedIndex = 2;

  double? _receiverLat;
  double? _receiverLng;

  @override
  void initState() {
    super.initState();
    _claimedDocsFuture = ReceiverService.fetchClaimedFoods();
    _loadReceiverLocation();
  }
  Future<void> _loadReceiverLocation() async {
    final coords = await ReceiverService.fetchReceiverCoordinates();
    if (coords != null) {
      setState(() {
        _receiverLat = coords['lat'];
        _receiverLng = coords['lng'];
      });
    }
  }


  Future<Map<String, dynamic>?> _getSurplusData(String surplusId) async {
    final snap = await FirebaseFirestore.instance
        .collection('surplus_food')
        .doc(surplusId)
        .get();
    if (snap.exists) {
      return snap.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Claimed Food")),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _claimedDocsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final claimedDocs = snap.data ?? [];
          if (claimedDocs.isEmpty) {
            return const Center(child: Text("No items claimed yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: claimedDocs.length,
            itemBuilder: (context, index) {
              final claimedDoc = claimedDocs[index];
              final claimData = claimedDoc.data() as Map<String, dynamic>;
              final surplusId = claimData['surplusId'];

              if (surplusId == null) {
                return const ListTile(
                  title: Text("Invalid claimed food record."),
                );
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getSurplusData(surplusId),
                builder: (context, surplusSnap) {
                  if (surplusSnap.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink(); // Placeholder
                  }

                  final surplus = surplusSnap.data;
                  if (surplus == null) {
                    return const ListTile(
                      title: Text("Surplus not found."),
                    );
                  }

                  final picked = surplus['status'] == 'pickedUp';
                  final claimedAt = (surplus['claimedAt'] as Timestamp?)?.toDate();
                  final claimedStr = claimedAt != null
                      ? DateFormat.yMd().add_jm().format(claimedAt)
                      : '';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (surplus['imageUrl'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                surplus['imageUrl'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(surplus['foodTitle'] ?? 'Untitled',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("Pickup by: ${surplus['pickupTime'] ?? 'N/A'}"),
                          const SizedBox(height: 4),
                          Text("Location: ${surplus['address'] ?? 'N/A'}"),
                          const SizedBox(height: 4),
                          Text("Claimed at: $claimedStr"),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: picked
                                    ? null
                                    : () async {
                                  await ReceiverService.unclaimFood(claimedDoc.id, surplusId);
                                  setState(() {
                                    _claimedDocsFuture = ReceiverService.fetchClaimedFoods();
                                  });
                                },
                                child: const Text("Unclaim"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: picked
                                    ? null
                                    : () async {
                                  await ReceiverService.markPickedUp(claimedDoc.id, surplusId);
                                  setState(() {
                                    _claimedDocsFuture = ReceiverService.fetchClaimedFoods();
                                  });
                                },
                                child: Text(picked ? "Picked" : "Mark Picked Up"),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final lat = surplus['lat'];
                                  final lng = surplus['lng'];
                                  if (lat != null && lng != null && _receiverLat != null && _receiverLng != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MapScreen(
                                          donorLat: lat,
                                          donorLng: lng,
                                          receiverLat: _receiverLat!,
                                          receiverLng: _receiverLng!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.map),
                                label: const Text("Map"),
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
      bottomNavigationBar: ReceiverBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
