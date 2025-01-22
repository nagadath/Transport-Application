// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> getLocationData() async {
  try {
    // Reference to your Firestore collection
    CollectionReference locations = FirebaseFirestore.instance.collection('locations');

    // Query Firestore for documents
    QuerySnapshot querySnapshot = await locations.get();

    // Iterate over each document in the query result
    for (var document in querySnapshot.docs) {
      // Access the data within each document
      Map<String, dynamic>? data = document.data() as Map<String, dynamic>?; // Add cast here
      if (data != null) {
        GeoPoint? geoPoint = data['location'] as GeoPoint?; // Add cast here
        if (geoPoint != null) {
          double latitude = geoPoint.latitude;
          double longitude = geoPoint.longitude;

          // Now you can use latitude and longitude for further processing
          print('Latitude: $latitude, Longitude: $longitude');
        }
      }
    }
  } catch (e) {
    print('Error retrieving location data: $e');
  }
}
