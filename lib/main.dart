import 'package:flutter/material.dart';
import 'package:flutter_application_2/signin.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firebase_options.dart';
// import 'bus_tracking.dart';
//import 'stop_find.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
await _askLocPermission();
  runApp(const MaterialApp(
    // home: StopFind(userLocation: LatLng(17.4716588,78.5459858),description: "Your current location",),
    home: SignInPage(),
    // home: BusTrackingMap()
  ));
  // runApp(const SignInPage());
}

Future<void> _askLocPermission() async {
  // Request location permission from the user
  PermissionStatus permissionStatus = await Permission.locationWhenInUse.request();
  
  // Handle cases when permission is denied or permanently denied
  if (permissionStatus.isDenied) {
    print('Location permission denied. Please enable it from settings.');
  } else if (permissionStatus.isPermanentlyDenied) {
    // Open app settings for the user to manually enable the permission
    openAppSettings();
  }
}
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'bus_tracking.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // Initialize Firebase
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
  
//   // Ask for location permissions
//   await _askLocPermission();
  
//   // Start the app
//   runApp(const MaterialApp(
//     home: BusTrackingMap(), // Entry point for the bus tracking feature
//   ));
// }

// Future<void> _askLocPermission() async {
//   // Request location permission from the user
//   PermissionStatus permissionStatus = await Permission.locationWhenInUse.request();
  
//   // Handle cases when permission is denied or permanently denied
//   if (permissionStatus.isDenied) {
//     print('Location permission denied. Please enable it from settings.');
//   } else if (permissionStatus.isPermanentlyDenied) {
//     // Open app settings for the user to manually enable the permission
//     openAppSettings();
//   }
// }
