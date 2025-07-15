import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UploadFoodService {
  /// 📸 Pick image (web/mobile)
  static final String? _googleGeocodingApiKey = dotenv.env['GEOCODING_API_KEY'];

  static Future<dynamic> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      return kIsWeb ? await picked.readAsBytes() : File(picked.path);
    }
    return null;
  }

  /// ☁️ Upload image to Firebase Storage
  static Future<String?> uploadImage(dynamic imageFile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final ref = FirebaseStorage.instance
          .ref()
          .child("food_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg");

      UploadTask uploadTask = kIsWeb
          ? ref.putData(imageFile as Uint8List)
          : ref.putFile(imageFile as File);

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }



  static Future<LatLng?> geocodeAddress(String address) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleGeocodingApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          final location = json['results'][0]['geometry']['location'];
          return LatLng(lat: location['lat'], lng: location['lng']);
        }
      }
    } catch (e) {
      print("Geocoding failed: $e");
    }

    return null;
  }


  /// 🔼 Upload food data
 static Future<bool> uploadFood({
    required String title,
    required String description,
    required String contactNumber,
    required String locationText,
  required double latitude,
     required double longitude,
    required String pickupTime,
    required String foodType,
    required dynamic imageFile,
    required BuildContext context,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      final donorName = user?.displayName ?? user?.email ?? 'Donor';

      final imageUrl = await uploadImage(imageFile);
      if (imageUrl == null) {
        showError(context, "Image upload failed.");
        return false;
      }

      await FirebaseFirestore.instance.collection('surplus_food').add({
        'donorId': uid,
        'donorName': donorName,
        'foodTitle': title,
        'description': description,
        'contactNumber': contactNumber,
        'location': locationText,
        'lat': latitude,
        'lng': longitude,
        'pickupBefore': pickupTime,
        'foodType': foodType,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unclaimed',
      });

      return true;
    } catch (e) {
      showError(context, "Upload failed: $e");
      return false;
    }
  }

  /// ❗ Show error
  static void showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}


/// For internal coordinate use
class LatLng {
  final double lat;
  final double lng;
  LatLng({required this.lat, required this.lng});
}
