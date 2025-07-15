import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
class FCMService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<String?> getTokenAndSubscribe() async {
    // Request notification permissions (for iOS)
    await _messaging.requestPermission();

    // Get the token
    final token = await _messaging.getToken();

    print('[FCM] Token: $token');

    return token;
  }
}

