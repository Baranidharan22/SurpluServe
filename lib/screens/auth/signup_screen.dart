import 'package:flutter/material.dart';
import 'package:surpluserve/services/auth_services.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String password = '';
  String role = 'donor';

  // Address fields (only for receiver)
  String flat = '';
  String area = '';
  String city = '';
  String pincode = '';
  String state = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: "Name"),
                onChanged: (val) => name = val,
                validator: (val) =>
                val == null || val.isEmpty ? "Please enter your name" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                onChanged: (val) => email = val,
                validator: (val) =>
                val != null && val.contains('@') ? null : "Invalid email",
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                onChanged: (val) => password = val,
                validator: (val) =>
                val != null && val.length >= 6 ? null : "Min 6 characters",
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: "Select Role"),
                items: const [
                  DropdownMenuItem(value: 'donor', child: Text("Donor")),
                  DropdownMenuItem(value: 'receiver', child: Text("Receiver")),
                ],
                onChanged: (val) {
                  setState(() {
                    role = val!;
                  });
                },
              ),

              // Show these fields only if user is receiver
              // if (role == 'receiver') ...[
              //   const SizedBox(height: 20),
              //   const Text("📍 Address (Required for receivers)", style: TextStyle(fontWeight: FontWeight.bold)),
              //   TextFormField(
              //     decoration: const InputDecoration(labelText: "Flat / Building / Apartment"),
              //     onChanged: (val) => flat = val,
              //     validator: (val) =>
              //     role == 'receiver' && (val == null || val.isEmpty)
              //         ? "Required"
              //         : null,
              //   ),
              //   TextFormField(
              //     decoration: const InputDecoration(labelText: "Area / Street / Village"),
              //     onChanged: (val) => area = val,
              //     validator: (val) =>
              //     role == 'receiver' && (val == null || val.isEmpty)
              //         ? "Required"
              //         : null,
              //   ),
              //   TextFormField(
              //     decoration: const InputDecoration(labelText: "City / Town"),
              //     onChanged: (val) => city = val,
              //     validator: (val) =>
              //     role == 'receiver' && (val == null || val.isEmpty)
              //         ? "Required"
              //         : null,
              //   ),
              //   TextFormField(
              //     decoration: const InputDecoration(labelText: "PIN Code"),
              //     keyboardType: TextInputType.number,
              //     onChanged: (val) => pincode = val,
              //     validator: (val) =>
              //     role == 'receiver' && (val == null || val.length != 6)
              //         ? "Enter valid PIN"
              //         : null,
              //   ),
              //   TextFormField(
              //     decoration: const InputDecoration(labelText: "State"),
              //     onChanged: (val) => state = val,
              //     validator: (val) =>
              //     role == 'receiver' && (val == null || val.isEmpty)
              //         ? "Required"
              //         : null,
              //   ),
              // ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final address = role == 'receiver'
                        ? "$flat, $area, $city, $state - $pincode"
                        : "";

                    AuthService().signUpWithEmailPassword(
                      email: email,
                      password: password,
                      name: name,
                      role: role,
                      context: context,
                    );
                  }
                },
                child: const Text("Sign Up"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
