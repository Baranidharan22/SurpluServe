// services/receiver_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class ReceiverService {


  static Future<List<DocumentSnapshot>> fetchClaimedFoods() async {
    print("[DEBUG] fetchClaimedFoods() called");

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print("[ClaimedFoods] No user logged in");
      return [];
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('claimed_food')
          .where('receiverId', isEqualTo: uid)
          .get();

      print("[ClaimedFoods] Found ${snap.docs.length} items for receiver $uid");
      return snap.docs;
    } catch (e) {
      print("[ClaimedFoods] Error fetching claimed food: $e");
      return [];
    }
  }


  static Future<void> unclaimFood(String docId, String surplusId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Not logged in");

    final fs = FirebaseFirestore.instance;
    await fs.runTransaction((tx) async {
      tx.delete(fs.collection('claimed_food').doc(docId));
      tx.update(fs.collection('surplus_food').doc(surplusId), {
        'status': 'unclaimed',
        'claimedBy': FieldValue.delete(),
        'claimedAt': FieldValue.delete(),
      });
    });
  }

  static Future<void> markPickedUp(String docId, String surplusId) async {
    final fs = FirebaseFirestore.instance;
    await fs.runTransaction((tx) async {
      tx.update(fs.collection('surplus_food').doc(surplusId), {
        'status': 'pickedUp',
        'pickedUpAt': FieldValue.serverTimestamp(),
      });
      tx.update(fs.collection('claimed_food').doc(docId), {
        'status': 'pickedUp',
        'pickedUpAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> fetchSurplusDetail(String docId) async {
    return await FirebaseFirestore.instance.collection('surplus_food').doc(docId).get();
  }

  static Future<void> claimSurplus(String surplusId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    final firestore = FirebaseFirestore.instance;


    final surplusDoc = await firestore.collection('surplus_food').doc(surplusId).get();
    if (!surplusDoc.exists) throw Exception("Surplus food not found");

    final donorId = surplusDoc.data()?['donorId'];
    if (donorId == null) throw Exception("donorId missing in surplus food");


    await firestore.collection('surplus_food').doc(surplusId).update({
      'status': 'claimed',
      'claimedBy': uid,
      'claimedAt': FieldValue.serverTimestamp(),
    });


    await firestore.collection('claimed_food').add({
      'surplusId': surplusId,
      'receiverId': uid,
      'donorId': donorId,
      'claimedAt': FieldValue.serverTimestamp(),
    });
  }




  static Future<Map<String, double>?> fetchReceiverCoordinates() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      final lat = data?['lat'];
      final lng = data?['lng'];

      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
    }
    return null;
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
