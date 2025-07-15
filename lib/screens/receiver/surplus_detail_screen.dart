import 'package:flutter/material.dart';
import 'package:surpluserve/services/receiver_service.dart';

class SurplusDetailScreen extends StatefulWidget {
  final String docId;

  const SurplusDetailScreen({super.key, required this.docId});

  @override
  State<SurplusDetailScreen> createState() => _SurplusDetailScreenState();
}

class _SurplusDetailScreenState extends State<SurplusDetailScreen> {
  Map<String, dynamic>? surplusData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadSurplusDetails();
  }

  Future<void> loadSurplusDetails() async {
    final doc = await ReceiverService.fetchSurplusDetail(widget.docId);
    if (doc.exists) {
      setState(() {
        surplusData = doc.data();
        _loading = false;
      });
    }
  }

  Future<void> claimFood() async {
    try {
      await ReceiverService.claimSurplus(widget.docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Food claimed successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to claim food: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Surplus Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🍽️ Title: ${surplusData!['foodTitle']}", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text("📝 Description: ${surplusData!['description']}"),
            const SizedBox(height: 10),
            Text("📍 Location: ${surplusData!['location']}"),
            const SizedBox(height: 10),
            Text("📞 Contact: ${surplusData!['contactNumber']}"),
            const SizedBox(height: 10),
            Text("⏰ Pickup Before: ${surplusData!['pickupBefore']}"),
            const SizedBox(height: 10),
            Text("🍴 Type: ${surplusData!['foodType']}"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: claimFood,
                child: const Text("Claim Food"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
