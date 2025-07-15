import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static final String? _googleGeocodingApiKey = dotenv.env['GEOCODING_API_KEY']; // <-- Replace this

  /// 🔐 Sign up with email/password
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    required BuildContext context,
  }) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCred.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        final Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': email,
          'name': name,
          'role': role,
        };

        // Ask address and convert to lat/lng if receiver
        if (role == 'receiver') {
          final address = await _askAddress(context);
          if (address != null) {
            final coords = await _getCoordinatesFromAddress(address);
            userData['address'] = address;
            userData['lat'] = coords?.lat;
            userData['lng'] = coords?.lng;
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);

        // if (role == 'receiver') {
        //   // Also store in 'receivers' collection
        //   await FirebaseFirestore.instance
        //       .collection('receivers')
        //       .doc(user.uid)
        //       .set(userData);
        // }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification email sent. Please verify your email.")),
        );
        await _auth.signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      _showError(context, "Signup failed: $e");
    }
  }

  /// 🔐 Sign in with email/password
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = userCred.user;
      await user?.reload();

      if (user != null && user.emailVerified) {
        final token = await FirebaseMessaging.instance.getToken();


        // Save token to Firestore under 'users' collection
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'deviceToken': token,
        }, SetOptions(merge: true));


        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final role = userDoc['role'];
        _redirectUser(role, context);
      } else {
        await _auth.signOut();
        _showError(context, "Please verify your email before logging in.");
      }
    } catch (e) {
      _showError(context, "Login failed: $e");
    }
  }

  /// 🔐 Google Sign-In
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final uid = userCred.user!.uid;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        final role = await _askUserRole(context);
        if (role == null) return;

        final Map<String, dynamic> userData = {
          'uid': uid,
          'email': userCred.user!.email,
          'name': userCred.user!.displayName ?? '',
          'role': role,
        };

        if (role == 'receiver') {
          final address = await _askAddress(context);
          if (address != null) {
            final coords = await _getCoordinatesFromAddress(address);
            userData['address'] = address;
            userData['lat'] = coords?.lat;
            userData['lng'] = coords?.lng;
          }
        }

        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

        if (role == 'receiver') {
          await FirebaseFirestore.instance.collection('receivers').doc(uid).set(userData);
        }
      }

      final role = (await FirebaseFirestore.instance.collection('users').doc(uid).get())['role'];
      _redirectUser(role, context);
    } catch (e) {
      _showError(context, "Google Sign-In failed: $e");
    }
  }

  /// 🚪 Sign out
  Future<void> signOutUser(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      _showError(context, "Logout failed: $e");
    }
  }

  /// 🧭 Role selection dialog
  Future<String?> _askUserRole(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Donor'), onTap: () => Navigator.pop(context, 'donor')),
            ListTile(title: const Text('Receiver'), onTap: () => Navigator.pop(context, 'receiver')),
          ],
        ),
      ),
    );
  }

  /// 🏡 Address prompt
  Future<String?> _askAddress(BuildContext context) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter your full address'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Address')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  /// 🌍 Convert address to coordinates
  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleGeocodingApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          final loc = json['results'][0]['geometry']['location'];
          return LatLng(lat: loc['lat'], lng: loc['lng']);
        }
      }
    } catch (_) {}
    return null;
  }

  /// 🚀 Navigate to appropriate home screen
  void _redirectUser(String role, BuildContext context) {
    if (role == 'donor') {
      Navigator.pushReplacementNamed(context, '/donorHome');
    } else {
      Navigator.pushReplacementNamed(context, '/receiverHome');
    }
  }

  /// ⚠️ Error snackbar
  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Helper class for coordinates
class LatLng {
  final double lat;
  final double lng;
  LatLng({required this.lat, required this.lng});
}
