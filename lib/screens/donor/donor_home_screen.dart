import 'package:flutter/material.dart';
import 'package:surpluserve/services/auth_services.dart';

class DonorHomeScreen extends StatelessWidget {
  const DonorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Home"),
        actions: [
          IconButton(
            onPressed: () {
              AuthService().signOutUser(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome, Donor!", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/uploadFood');
              },
              child: const Text("Upload Surplus Food"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/myUpload');
              },
              child: const Text("View My Uploads"),
            ),
          ],
        ),
      ),
    );
  }
}
