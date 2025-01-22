// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'google_map_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'newprofiledata.dart';

class NavigationWidget extends StatefulWidget {
  final String userId;
  const NavigationWidget({super.key, required this.userId});
  
  @override
  _NavigationWidgetState createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {

  final String _studentEmail = FirebaseAuth.instance.currentUser!.email!;
  @override
  void initState() {
    super.initState();
    checkAndCreateDocument();
  }


  Future<void> checkAndCreateDocument() async {
    try {
      // Get a reference to the Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Reference the specific document using its ID
      DocumentReference documentRef = firestore.collection('year21').doc(_studentEmail);

      // Get the document snapshot
      DocumentSnapshot documentSnapshot = await documentRef.get();

      // Check if the document exists
      if (!documentSnapshot.exists) {
        Map<String, dynamic> data = {
          'Name': '',
          'Bus Number': '',
          // Add more fields as needed
        };
        // If the document doesn't exist, add the document with the specified data
        await documentRef.set(data);
        _updateProfile();
        print('Document added successfully.');
      } else {
        print('Document already exists.');
      }
    } catch (e) {
      // Handle any errors
      print('Error checking or creating document: $e');
    }
  }

  Future<void> _updateProfile() async {
    Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewProfilePage()),
          );
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      //home: GoogleMapWidget(),
      home: GoogleMapWidget(),
    );
  }
}
