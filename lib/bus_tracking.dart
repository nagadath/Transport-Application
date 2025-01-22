import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';

class BusTrackingMap extends StatefulWidget {
  const BusTrackingMap({Key? key}) : super(key: key);

  @override
  _BusTrackingMapState createState() => _BusTrackingMapState();
}

class _BusTrackingMapState extends State<BusTrackingMap> {
  GoogleMapController? _controller;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng _currentPosition = const LatLng(0, 0); // Initial placeholder for current location
  List<LatLng> _routePoints = []; // List of route points fetched from Firestore
  String _busNumber = 'Bus27'; // Example bus number, replace with actual bus number from Firestore
  late StreamSubscription<Position> _positionStream;

  @override
  void initState() {
    super.initState();
    _getRouteFromFirestore();
    _startLocationUpdates();
  }

  // Fetch the route (start, middle, end) points from Firestore
  Future<void> _getRouteFromFirestore() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Route')
          .doc(_busNumber)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<LatLng> routePoints = [];

        // Loop through the document keys and values to get GeoPoints
        data.forEach((key, value) {
          if (value is GeoPoint) {
            LatLng point = LatLng(value.latitude, value.longitude);
            routePoints.add(point);
            // Fetch additional info (time and students) for each stop
            _markers.add(
              Marker(
                markerId: MarkerId(key),
                position: point,
                infoWindow: InfoWindow(
                  title: key, // Display stop name
                  snippet: 'Arriving at: 10:00 AM\nStudents Boarding: 5', // Placeholder info
                  onTap: () {
                    _showStopInfo(key, '10:00 AM', 5); // Call method to show detailed info
                  },
                ),
              ),
            );
          }
        });

        // Set the route points
        setState(() {
          _routePoints = routePoints; // Save the fetched route points
          _drawBusRoute(); // Draw the route on the map
          _setOriginAndDestination(); // Set origin and destination
        });
      } else {
        print('Route document does not exist');
      }
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
    const double threshold = 100; // meters

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
            color: Colors.red,
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


  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
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
    });
  }

  void _startLocationUpdates() {
    const locationUpdateInterval = Duration(seconds: 3);

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
        _controller?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Tracking')),
      body: Stack(
        children: [
          if (_currentPosition != const LatLng(0, 0))
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
          _getCurrentLocation();
          _controller?.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition,
              zoom: 18,
              bearing: 0, // Set bearing to 0 for north orientation
            ),
          ));
        },
        child: const Icon(Icons.location_on),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream.cancel(); // Stop location updates when the widget is disposed
    super.dispose();
  }
}
