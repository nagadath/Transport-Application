// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'updatedata.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _studentName = ''; // Initialize with user's data
  final String _studentEmail = FirebaseAuth.instance.currentUser!.email!; // Fetch user's email
  String _busNumber = ''; // Initialize with user's data
  String _sname = '';
  String _bnum = '';
  @override
  void initState() {
  super.initState();
  _getUserData();
  Timer.periodic(const Duration(seconds: 5), (_) => _getUserData());
}

  Future<void> _getUserData() async {
    try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('year21').doc(_studentEmail).get();
    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        _studentName = data['Name'];
        _busNumber = data['Bus Number'];
        _updateData();
      });
    }
  } catch (e) {
    throw Exception('Error fetching user data: $e');
  }
  }

  void _updateData() {
    setState(() {
      _sname = _studentName;
    _bnum = _busNumber;
    });
    
  }

  Future<void> _updateProfile() async {
    Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewProfilePage()),
          );
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
            Text(_sname),
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
            Text(_bnum),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 45.0, // Set the width of the FloatingActionButton
        height: 45.0, // Set the height of the FloatingActionButton
        child:FloatingActionButton(
          onPressed: () {
            _updateProfile();
          },
          child: const Icon(Icons.edit),
        ),),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}