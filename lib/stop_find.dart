// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'dart:math' show cos, sqrt, sin, atan2, pi;
import 'package:http/http.dart' as http;
import 'search_loc.dart';

class StopFind extends StatefulWidget {
  //const MapScreen({super.key, required LatLng userLocation});
  final LatLng userLocation;
  final String description;

  const StopFind({required this.userLocation,required this.description, super.key});

  @override
  _StopFindState createState() => _StopFindState();
}

class _StopFindState extends State<StopFind> {
  late GoogleMapController mapController;
  Set<Marker> allMarkers = <Marker>{};
  Set<Marker> visibleMarkers = <Marker>{};
  //String _busNumber = '31';

  @override
  void initState() {
    super.initState();
    setState(() {
      _getLocation();
    });    
  }

  Future<void> _getLocation() async {
    var position = widget.userLocation;
    setState(() {
        allMarkers.add(
              Marker(
                markerId: const MarkerId('currentLocation'),
                position: LatLng(position.latitude,position.longitude),
              ),
            );
        _addMarkers();
      });
  }

  void _addMarkers() async{
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Route').get();

      if (snapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot doc in snapshot.docs) {
          print(doc.id);
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          List<String> keys = data.keys.toList();
          print(keys);
          for (var i = 0; i < keys.length; i++) {
            GeoPoint? geoPoint = data[keys[i]] as GeoPoint?;
            if(geoPoint != null && keys[i] != 'location'){
              double latitude = geoPoint.latitude;
              double longitude = geoPoint.longitude;
              allMarkers.add(
                Marker(
                  markerId: MarkerId(doc.id + keys[i]),
                  position: LatLng(latitude,longitude),
                ),
              );          
            }
          }
        }
        print(allMarkers);

         setState(() {
          visibleMarkers.addAll(allMarkers);
        });
      } else {
        print('Document does not exist');
      }
      updateVisibleMarkers(widget.userLocation);
    } catch (e) {
      print('Error retrieving location data: $e');
    }
  }

  Future<num> calculateDistance(LatLng origin, LatLng destination) async {
    try {
      const String apiKey = 'AIzaSyDk1QAh0VBQFdkIoCBNXdUu_HaSigidsGE';
      final String url = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${origin.latitude},${origin.longitude}&destinations=${destination.latitude},${destination.longitude}&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      print("hii1");
      if (response.statusCode == 200) {
        print("hello");
        final data = json.decode(response.body);

        int distanceInMeters = data['rows'][0]['elements'][0]['distance']['value'];

        double distanceInKm = distanceInMeters / 1000;
        print(distanceInKm);
        return distanceInKm;
      } else {
        throw Exception('Failed to fetch distance data');
      }
    } catch (e) {
      throw Exception('Error calculating distance: $e');
      //return double.infinity;
    }
  }
  
  void updateVisibleMarkers(LatLng newUserLocation) async {
    Set<Marker> newVisibleMarkers = <Marker>{};
    for (Marker marker in allMarkers) {
      num distance = await calculateDistance(newUserLocation, marker.position);
      if (distance <= 8.0) { // Change 1.0 to your desired radius in kilometers
        newVisibleMarkers.add(marker);
      }
    }
    setState(() {
      visibleMarkers = newVisibleMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.userLocation,
              zoom: 15.0,
            ),
            markers: visibleMarkers,
            onMapCreated: (GoogleMapController controller) {
              setState(() {
                mapController = controller;
              });
            },
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 60.0,
            right: 0.0,
            left: 0.0,
            child: Row(
              children: [
                const SizedBox(width: 20.0,),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  }, 
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    ),
                    child:  const Icon(Icons.arrow_back_ios_new)
                  ),
                ),
                const SizedBox(width: 30.0,),
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) =>  SearchLoc(desc: widget.description, location: widget.userLocation,),),
                      );
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              maxLines: 1,
                              widget.description,
                              style: const TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ),
                          const Icon(Icons.search),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
