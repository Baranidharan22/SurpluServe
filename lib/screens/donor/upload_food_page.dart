import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:surpluserve/services/upload_food_service.dart';

import '../../services/upload_food_service.dart';

class UploadFoodPage extends StatefulWidget {
  const UploadFoodPage({super.key});
  @override
  State<UploadFoodPage> createState() => _UploadFoodPageState();
}

class _UploadFoodPageState extends State<UploadFoodPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();

  final _flatController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _stateController = TextEditingController();

  String _foodType = 'veg';
  TimeOfDay? _pickupTime;
  dynamic _imageFile;
  bool _loading = false;

  Future<void> _pickImage() async {
    final file = await UploadFoodService.pickImage();
    if (file != null) setState(() => _imageFile = file);
  }

  Future<void> _uploadFood() async {
    if (!_formKey.currentState!.validate() || _pickupTime == null || _imageFile == null) {
      return UploadFoodService.showError(context, "Complete all fields and pick image.");
    }

    final fullAddress =
        "${_flatController.text}, ${_areaController.text}, ${_cityController.text}, ${_stateController.text} - ${_pincodeController.text}";

     final coords = await UploadFoodService.geocodeAddress(fullAddress);
     if (coords == null) {
       return UploadFoodService.showError(context, "Failed to fetch coordinates.");
     }

    setState(() => _loading = true);

    final result = await UploadFoodService.uploadFood(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      contactNumber: _contactController.text.trim(),
      locationText: fullAddress,
      latitude: coords.lat,
       longitude: coords.lng,
      pickupTime: _pickupTime!.format(context),
      foodType: _foodType,
      imageFile: _imageFile,
      context: context,
    );

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Food uploaded!")));
      Navigator.pushReplacementNamed(context, '/myUploads');
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Surplus Food"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/donorHome'),
        ),

      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Food Title"),
              validator: (v) => v!.isEmpty ? "Enter title" : null,
            ),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description"),
              validator: (v) => v!.isEmpty ? "Enter description" : null,
            ),
            TextFormField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Contact Number"),
              validator: (v) => v!.length < 10 ? "Enter valid number" : null,
            ),
            const SizedBox(height: 16),
            const Text("📍 Address", style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _flatController,
              decoration: const InputDecoration(labelText: "Flat, Building, Apartment"),
              validator: (v) => v!.isEmpty ? "Enter this field" : null,
            ),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: "Area, Street, Village"),
              validator: (v) => v!.isEmpty ? "Enter this field" : null,
            ),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: "Town / City"),
              validator: (v) => v!.isEmpty ? "Enter this field" : null,
            ),
            TextFormField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "PIN Code"),
              validator: (v) => v!.length != 6 ? "Enter valid PIN" : null,
            ),
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(labelText: "State"),
              validator: (v) => v!.isEmpty ? "Enter state" : null,
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Pickup Before"),
              subtitle: Text(_pickupTime == null ? "Select time" : _pickupTime!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (picked != null) setState(() => _pickupTime = picked);
              },
            ),
            const Text("Food Type"),
            Row(
              children: [
                Radio(value: 'veg', groupValue: _foodType, onChanged: (v) => setState(() => _foodType = v!)),
                const Text('Veg'),
                Radio(value: 'non-veg', groupValue: _foodType, onChanged: (v) => setState(() => _foodType = v!)),
                const Text('Non-Veg'),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: _imageFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: kIsWeb
                    ? Image.memory(_imageFile, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.file(_imageFile, height: 200, width: double.infinity, fit: BoxFit.cover),
              )
                  : Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text("Tap to select image")),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _uploadFood, child: const Text("Submit Food Details")),
            )
          ]),
        ),
      ),
    );
  }
}
