// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneSignInPage extends StatelessWidget {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  PhoneSignInPage({super.key});

  Future<void> _verifyPhoneNumber(BuildContext context) async {
    String phoneNumber = '+91${_phoneNumberController.text}'; // Get the entered phone number
    FirebaseAuth auth = FirebaseAuth.instance;

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Automatically signs in the user on Android devices
        await auth.signInWithCredential(credential);
        // Navigate to the next screen
      },
      verificationFailed: (FirebaseAuthException e) {
        // Handle verification failure
        print('Verification failed: $e');
      },
      codeSent: (String verificationId, int? resendToken) {
        // Save the verification ID
        String smsCode = _smsCodeController.text;

        // Prompt user to enter the code
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Enter SMS Code"),
              content: TextField(controller: _smsCodeController),
              actions: [
                TextButton(
                  onPressed: () async {
                    PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
                    // Sign in the user with the SMS code
                    await auth.signInWithCredential(credential);
                    // Navigate to the next screen
                  },
                  child: const Text("Verify"),
                ),
              ],
            );
          },
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle timeout
        print('Code auto retrieval timeout');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Phone Sign In")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _phoneNumberController, decoration: const InputDecoration(labelText: "Phone Number")),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _verifyPhoneNumber(context),
                child: const Text("Send Verification Code"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
