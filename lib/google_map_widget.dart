// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'stop_find.dart';
import 'profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});


  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _controller;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng _currentPosition = const LatLng(0, 0); // Initial placeholder for current location
  List<LatLng> _routePoints = []; // List of route points fetched from Firestore
  String _busNumber = ''; // Example bus number, replace with actual bus number from Firestore
  late StreamSubscription<Position> _positionStream;
  final String _studentEmail = FirebaseAuth.instance.currentUser!.email!;
  late double latitudeput;
  late LatLng locationput;
  late double longitudeput;

  @override
  void initState() {
    super.initState();
    // late GoogleMapController _controller;
    _getUserData();
    _markers = {};
    _getLocation();
    _positionload();
    _startLocationUpdates();
    print('hello');
  }

  Future<BitmapDescriptor> _createMarkerIcon(IconData icon, Color color) async {
    final size = 100.0; // Adjust size as needed
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Create a TextPainter for the icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, 0));

    // Create the marker icon from the canvas
    final image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  static const IconData directions_bus_filled_sharp = IconData(0xe8d1, fontFamily: 'MaterialIcons');

//   Future<void> _getRouteFromFirestore() async {
//   try {
//     final BitmapDescriptor markerIcon = await _createMarkerIcon(
//       directions_bus_filled_sharp,
//       Colors.blue, // You can change the color as needed
//     );
    
//     CollectionReference snapshot = await FirebaseFirestore.instance
//         .collection('Route')
//         .doc(_busNumber)
//         .collection('stops')
//         .get();

//     if (snapshot.exists) {
//       Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//       List<LatLng> routePoints = [];

//       // Loop through the document keys and values to get GeoPoints
//       data.forEach((key, value) {
//         if (value is GeoPoint) {
//           LatLng point = LatLng(value.latitude, value.longitude);
          
          
//           // Fetch additional info (time and students) for each stop
//           // Exclude marker with the name "location"
//           if (key != 'location') {
//             routePoints.add(point);
//             _markers.add(
//               Marker(
//                 markerId: MarkerId(key),
//                 position: point,
//                 infoWindow: InfoWindow(
//                   title: key, // Display stop name
//                   snippet: 'Arriving at: 10:00 AM\nStudents Boarding: 5', // Placeholder info
//                   onTap: () {
//                     _showStopInfo(key, '10:00 AM', 5); // Call method to show detailed info
//                   },
//                 ),
//               ),
//             );
//           }
//           if(key == 'location'){
//           _markers.add(
//               Marker(
//                 markerId: MarkerId(key),
//                 position: point,
//                 icon: markerIcon,
//                 infoWindow: InfoWindow(
//                   title: key, // Display stop name
//                   snippet: 'Arriving at: 10:00 AM\nStudents Boarding: 5', // Placeholder info
//                   onTap: () {
//                     _showStopInfo(key, '10:00 AM', 5); // Call method to show detailed info
//                   },
//                 ),
//               ),
//             );
//           }
//         }
//       });

//       // Remove any existing "location" marker just in case
//       // _markers.removeWhere((marker) => marker.markerId.value == 'location');

//       // Set the route points
//       setState(() {
//         _routePoints = routePoints; // Save the fetched route points
//         _drawBusRoute(); // Draw the route on the map
//         _setOriginAndDestination(); // Set origin and destination
//       });
//     } else {
//       print('Route document does not exist');
//     }
//   } catch (e) {
//     print('Error fetching route data: $e');
//   }
// }
Future<void> _getRouteFromFirestore() async {
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Route')
        .doc(_busNumber)
        .collection('stops')
        .get();

    List<LatLng> routePoints = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Iterate through the data to get the dynamic key and value
      data.forEach((key, value) {
        if (value is GeoPoint) {
          // 'key' is the stop name, 'value' is the GeoPoint
          LatLng point = LatLng(value.latitude, value.longitude);
          
          // Assuming arrival time is stored as a string with the key 'arrivalTime'
          String arrivalTime = data['arrivalTime'] ?? 'Unknown'; // Adjust based on your data

          routePoints.add(point);

          // Add a marker for this stop
          _markers.add(
            Marker(
              markerId: MarkerId(key), // Use the stop name as the marker ID
              position: point,
              infoWindow: InfoWindow(
                title: key, // Stop name (the dynamic key)
                snippet: 'Arriving at: $arrivalTime', // Arrival time
              ),
            ),
          );
        }
      });
    }

    // Update state with route points and markers
    setState(() {
      _routePoints = routePoints;
      _drawBusRoute(); // Draw the route on the map
    });
    
  } catch (e) {
    print('Error fetching route data: $e');
  }
}



  // Draw polyline from the fetched route points
  void _drawBusRoute() {
    if (_routePoints.length >= 2) {
      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('busRoute'),
          points: _routePoints,
          color: Colors.blue,
          width: 5,
        ));
      });
    }
  }

  // Set origin and destination based on fetched route points
  void _setOriginAndDestination() {
    if (_routePoints.isNotEmpty) {
      LatLng origin = _routePoints.first; // First stop
      LatLng destination = _routePoints.last; // Last stop

      // Verify if current location is between the origin and destination
      if (!_isCurrentLocationBetweenStops(origin, destination)) {
        // If not, set the current location as the origin
        origin = _currentPosition;
      }

      // Now you can call getDirections with origin and destination
      getDirections(origin, destination);
    }
  }

  // Check if the current location is between the two stops
  bool _isCurrentLocationBetweenStops(LatLng origin, LatLng destination) {
    // Calculate distances
    double distanceToOrigin = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      origin.latitude,
      origin.longitude,
    );
    
    double distanceToDestination = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      destination.latitude,
      destination.longitude,
    );

    // You can set a threshold distance to determine if it is "between"
    const double threshold = 500; // meters

    // Check if the current location is within the threshold distance from both stops
    return distanceToOrigin <= threshold || distanceToDestination <= threshold;
  }

  Future<void> getDirections(LatLng origin, LatLng destination) async {
    String googleAPIKey = 'AIzaSyDc2lflt-hxc8Y_EijTnjHtB3VYbN1JfxQ'; // Replace with your API key

    // Construct the API URL with the waypoints
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&waypoints=${_routePoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|')}&key=$googleAPIKey';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['status'] == 'OK') {
        String encodedPoly = data['routes'][0]['overview_polyline']['points'];
        List<LatLng> routeCoordinates = decodePolyline(encodedPoly);

        setState(() {
          // Clear previous polylines and draw the new one
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId('directions'),
            points: routeCoordinates,
            color: const Color.fromARGB(255, 11, 89, 172),
            width: 5,
          ));

          // Move camera to the starting point
          _controller?.moveCamera(CameraUpdate.newLatLng(routeCoordinates.first));
        });
      } else {
        print('Error getting directions: ${data['status']}');
      }
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  List<LatLng> decodePolyline(String poly) {
    List<LatLng> coordinates = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result >> 1) ^ -(result & 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result >> 1) ^ -(result & 1));
      lng += dlng;

      LatLng p = LatLng(lat / 1E5, lng / 1E5);
      coordinates.add(p);
    }
    return coordinates;
  }

  // void _showStopInfo(String stopName, String arrivalTime, int studentsBoarding) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(stopName),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text('Time of Arrival: $arrivalTime'),
  //             Text('Number of Students Boarding: $studentsBoarding'),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             child: const Text('Close'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  void _showStopInfo(String stopName, String arrivalTime, int studentsBoarding) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
        ),
        elevation: 5,
        child: Container(
          width: 600,
          height: 400,
          padding: const EdgeInsets.all(20.0), // Padding inside the dialog
          decoration: BoxDecoration(
            color: Colors.white, // Background color
            borderRadius: BorderRadius.circular(12.0), // Rounded corners
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap the content
            crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
            children: [
              Text(
                stopName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10), // Space between title and content
              Text(
                'Time of Arrival: $arrivalTime',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5), // Space between lines
              Text(
                'Number of Students Boarding: $studentsBoarding',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15), // Space at the bottom
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


  Future<void> _signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInPage()),
    );
  } catch (e) {
    print('Failed to sign out: $e');
  }
}


  Future<void> _getUserData() async {
    try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('year21').doc(_studentEmail).get();
    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        _busNumber = data['Bus Number'];
        // _addMarkers();
        _getRouteFromFirestore();
      });
    }
  } catch (e) {
    print('Error fetching user data: $e');
  }
  }

  void _startLocationUpdates() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _getLocation();
    });

    _positionStream = Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _circles.clear();
        _circles.add(Circle(
          circleId: const CircleId('busLocation'),
          // center: _currentPosition,
          radius: 30,
          fillColor: Colors.blue.withOpacity(0.5),
          strokeColor: Colors.blue,
          strokeWidth: 1,
        ));

        // Animate camera to the new bus location
        // _controller?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      });
    });
  }

  void _positionload() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _getLocation();
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 18));
      timer.cancel();
    });
  }

  void _getLocation() async {
    try {
      DocumentReference documentRef = FirebaseFirestore.instance.collection('Route').doc(_busNumber);
      DocumentSnapshot snapshot = await documentRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        List<String> keys = data.keys.toList();

        for (var i = 0; i < keys.length; i++) {
          GeoPoint? geoPoint = data[keys[i]] as GeoPoint?;
          if(geoPoint != null && keys[i] == 'location'){
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            locationput = LatLng(geoPoint.latitude,geoPoint.longitude);
            latitudeput = geoPoint.latitude;
            longitudeput = geoPoint.longitude;
            
            setState(() {
              _currentPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
            });
            // _markers.add(
            //   Marker(
            //     markerId: MarkerId(keys[i]),
            //     position: LatLng(latitude,longitude),
            //   ),
            // ); 

            _circles.add(
        Circle(
          circleId: const CircleId('currentLocationCircle'),
          center: _currentPosition,
          radius: 30, // Adjust the radius as needed (in meters)
          fillColor: Colors.blue.withOpacity(0.5), // Color of the circle
          strokeColor: Colors.blue, // Color of the circle's border
          strokeWidth: 1,
        ),
      );         
          }
        }
      }

      var position = await Geolocator.getCurrentPosition();
      await documentRef.set({
      'location': GeoPoint(position.latitude,position.longitude),
    }, SetOptions(merge: true));
    // var position = await Geolocator.getCurrentPosition();
    //   await documentRef.set({
    //   'location': GeoPoint(position.latitude,position.longitude),
    // }, SetOptions(merge: true));
    // setState(() {
    //     _markers.remove(const Marker(markerId: MarkerId('currentPosition')));
    //     _currentPosition = LatLng(position.latitude, position.longitude);
    //     _markers.add(
    //       Marker(
    //         markerId: const MarkerId('currentPosition'),
    //         position: _currentPosition,
    //       ),
    //     );
    //   });
    
    // ignore: empty_catches
    } catch (e) {
    }
  }

  void _addMarkers() async{
    try {
    // Reference to your Firestore collection
      DocumentReference documentRef = FirebaseFirestore.instance.collection('Route').doc(_busNumber);
      DocumentSnapshot snapshot = await documentRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        List<String> keys = data.keys.toList();
        print(keys);
        for (var i = 0; i < keys.length; i++) {
          GeoPoint? geoPoint = data[keys[i]] as GeoPoint?;
          if(geoPoint != null && keys[i] != 'location'){
            print(geoPoint.latitude);
            double latitude = geoPoint.latitude;
            double longitude = geoPoint.longitude;
            _markers.add(
              Marker(
                markerId: MarkerId(keys[i]),
                position: LatLng(latitude,longitude),
              ),
            );          
          }
        }
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error retrieving location data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarIconBrightness: Brightness.dark, // Use dark icons for status bar
      statusBarColor: Colors.black, // Make status bar transparent
    ));
    return MaterialApp(
      home: Scaffold(
        extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Bus Location"),
        backgroundColor: Colors.transparent, // Make app bar background transparent
          elevation: 0,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Open the drawer
                },
              );
            },
          ),
        ),
      drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  // Handle drawer item tap for Home
                  Scaffold.of(context).closeDrawer(); // Close the drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  // Handle drawer item tap for Settings
                  Navigator.pop(context); // Close the drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  // Handle drawer item tap for Profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Find Your Stop'),
                onTap: () {
                  // Handle drawer item tap for Profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StopFind(userLocation: locationput,description: "Your current location",)),
                  );
                },
              ),
              const Divider(), // Add a divider between menu items
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Logout'),
                onTap: () {
                  _signOut();
                },
              ),
            ],
          ),
        ),
      body: Stack(
        children: [
          if (_currentPosition != const LatLng(0,0))
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 15.0,
              ),
              markers: _markers,
              circles: _circles,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                setState(() {
                  _controller = controller;
                });
              },
              zoomControlsEnabled: false,
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getLocation();
          setState(() {
                Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoogleMapWidget()),
        );
          });
          //_controller.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 18));
          _controller?.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentPosition,
                zoom: 18,
                bearing: 0, // Set bearing to 0 for north orientation
              ),
            ));
          //_getUserData();
        },
        child: const Icon(Icons.location_on),
      ),
      // GoogleMap(
      //   initialCameraPosition: CameraPosition(
      //     target: _currentPosition,
      //     zoom: 15.0,
      //   ),
      //   markers: _markers,
      //   onMapCreated: (GoogleMapController controller) {
      //     _controller = controller;
      //   },
      //   zoomControlsEnabled: false,
      // ),
      
    ),);
  }

  @override
  void dispose() {
    _positionStream.cancel(); // Stop location updates when the widget is disposed
    super.dispose();
  }
}
  