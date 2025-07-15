import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/donor/donor_home_screen.dart';
import 'screens/receiver/receiver_home_screen.dart';
import 'screens/donor/upload_food_page.dart';
import 'screens/donor/my_upload_page.dart';
import 'screens/receiver/surplus_detail_screen.dart';

// Import auth screens... '
// Import donor/receiver screens...

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Donation',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/donorHome': (context) => DonorHomeScreen(),
        '/receiverHome': (context) => ReceiverHomeScreen(),
        '/uploadFood': (context) => UploadFoodPage(),
        '/myUpload':(context) => MyUploadsPage(),
        '/surplusDetail':(context) => SurplusDetailScreen(docId: '',),
      },
    );
  }
}
