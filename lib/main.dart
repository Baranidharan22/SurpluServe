import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:surpluserve/screens/receiver/surplus_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request notification permission
  await _requestNotificationPermission();

  runApp(MyApp());
}

Future<void> _requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Notification permission granted');
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print('Notification permission denied');
  } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    print('Notification permission not determined');
  }
}

void setupInteractedMessage(BuildContext context) {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final surplusId = message.data['surplusId'];
    if (surplusId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SurplusDetailScreen(docId: surplusId),
        ),
      );
    }
  });
}
