import 'package:flutter/material.dart';
import 'package:surpluserve/screens/receiver/claimed_food_screen.dart';
import 'package:surpluserve/screens/receiver/receiver_home_screen.dart';

class ReceiverBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ReceiverBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        onTap(index);
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ReceiverHomeScreen()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ClaimedFoodScreen()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Location"),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Claimed Food"),
      ],
    );
  }
}
