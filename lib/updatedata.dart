// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewProfilePage extends StatefulWidget {
  const NewProfilePage({super.key});


 @override
  _NewProfilePageState createState() => _NewProfilePageState();
}

class _NewProfilePageState extends State<NewProfilePage> {
  final String _studentEmail = FirebaseAuth.instance.currentUser!.email!; // Fetch user's email
  String _studentName = '';
  String _busNumber = '';

  Future<void> _updateData() async {
    print('Updated Student Name: $_studentName');
    print('Updated Bus Number: $_busNumber');
    try {
      DocumentReference documentRef = FirebaseFirestore.instance.collection('year21').doc(_studentEmail);
    
    if  (_studentName != '') {
      await documentRef.update({
      'Name': _studentName}
      );}
      
    if  (_busNumber != '') {
      await documentRef.update({
      'Bus Number': _busNumber
      });
      }
    print('Fields updated successfully!');
    Navigator.pop(context);
  } catch (e) {
    print('Error updating fields: $e');
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
            'Student Name:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            initialValue: _studentName,
            onChanged: (value) {
              setState(() {
                _studentName = value;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Student Email:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(_studentEmail),
          const SizedBox(height: 20),
          const Text(
            'Bus Number:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextFormField(
            initialValue: _busNumber,
            onChanged: (value) {
              setState(() {
                _busNumber = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _updateData();
            },
            child: const Text('Update Profile'),
          ),
          ],
        ),
      ),
    );
  }
}