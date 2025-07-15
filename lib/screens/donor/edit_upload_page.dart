import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUploadPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditUploadPage({super.key, required this.docId, required this.data});

  @override
  State<EditUploadPage> createState() => _EditUploadPageState();
}

class _EditUploadPageState extends State<EditUploadPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _contactController;
  late TextEditingController _locationController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.data['foodTitle']);
    _descController = TextEditingController(text: widget.data['description']);
    _contactController = TextEditingController(text: widget.data['contactNumber']);
    _locationController = TextEditingController(text: widget.data['location']);
    _status = widget.data['status'];
  }

  Future<void> _updateFood() async {
    await FirebaseFirestore.instance.collection('surplus_food').doc(widget.docId).update({
      'foodTitle': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'contactNumber': _contactController.text.trim(),
      'location': _locationController.text.trim(),
      'status': _status,
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully")));
    Navigator.pop(context);
  }

  Future<void> _deleteFood() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('surplus_food').doc(widget.docId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final imageUrl = data['imageUrl'];

        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
          await storageRef.delete(); // Delete image from storage
        }

        await docRef.delete(); // Delete Firestore doc

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deleted successfully")),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document not found.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Upload")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
            TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Description")),
            TextFormField(controller: _contactController, decoration: const InputDecoration(labelText: "Contact")),
            TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: "Location")),

            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'unclaimed', child: Text('Unclaimed')),
                DropdownMenuItem(value: 'claimed', child: Text('Claimed')),
                DropdownMenuItem(value: 'pickedUp', child: Text('Picked Up')),
              ],
              onChanged: (val) => setState(() => _status = val!),
              decoration: const InputDecoration(labelText: "Status"),
            ),

            const SizedBox(height: 20),
            ElevatedButton(onPressed: _updateFood, child: const Text("Save Changes")),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _deleteFood,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Delete This Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
