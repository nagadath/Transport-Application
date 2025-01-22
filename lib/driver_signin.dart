// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, use_key_in_widget_constructors


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'navigation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'signin.dart';
import 'stop_find.dart';

class DriverSignInPage extends StatefulWidget {
  const DriverSignInPage({super.key});

  @override
  _DriverSignInPageState createState() => _DriverSignInPageState();
}

class _DriverSignInPageState extends State<DriverSignInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _eerrorMessage;
  String? _perrorMessage;
  bool _errorOccurred = false;
  bool _obscurePassword = true;

  @override
  void initState(){
    super.initState();
    _askLocPermission();
    // Check if the user is already signed in
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // User is already signed in, navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationWidget(userId: user.email!)),
        );
      }
    });
  }
  Future<void> _askLocPermission() async{
    final permissionStatus = await Permission.locationWhenInUse.request();
                if (permissionStatus.isDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location permission denied. Please enable it from settings.'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                } else if (permissionStatus.isPermanentlyDenied) {
                  openAppSettings(); // Function to open app settings
                }
  }

  Future<void> signup() async {
    setState(() {
      _eerrorMessage = null;
      _perrorMessage = null;
      _errorOccurred = false;
    });
    _emailController.clear();
    _passwordController.clear();
  }

  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _eerrorMessage = null;
      _perrorMessage = null;
      _errorOccurred = false;
    });

    FocusScope.of(context).unfocus();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StopFind(userLocation: LatLng(0, 0),description: 'none',)), // Navigate to the home page
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == "wrong-password") {
          setState(() {
            _perrorMessage = "Wrong password. Please try again.";
            _errorOccurred = true;
          });
        }
        if (e.code == "user-not-found") {
          setState(() {
            _eerrorMessage = "User does not exist, please create an account first.";
            _errorOccurred = true;
          });
        }
        if (e.code == "invalid-email") {
          setState(() {
            _eerrorMessage = "Invalid Email, please recheck!";
            _errorOccurred = true;
          });
        }
        if (e.code == "network-request-failed") {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                contentPadding: EdgeInsets.zero, // Remove default padding
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5, // Set width
                  height: MediaQuery.of(context).size.height * 0.25, // Set height
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Error", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      // Add a divider for separation
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Please check your internet connection and try again later.",),
                      ),
                      const SizedBox(height: 12),
                      const Divider(), // Add some spacing
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("OK", style: TextStyle(fontSize: 16),),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }
      throw Exception('Failed to sign up: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double containerHeight = _errorOccurred ? MediaQuery.of(context).size.height * 0.445 : MediaQuery.of(context).size.height * 0.42;
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 27, 35, 114),
        body: Stack(
          //mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Positioned(
            top: 16.0,
            left: 16.0,
            width: 40,
            height: 40,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const SignInPage()),
                            );
              },
              child: const Icon(Icons.arrow_back),
            ),),
          Center(
          child:Container( 
            decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(20),
                ),
            height: MediaQuery.of(context).size.height * 0.45,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: containerHeight,
                    child: Center(
                      child:  Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            errorText: _eerrorMessage,
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _eerrorMessage != null ? Colors.red : Colors.blue),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _eerrorMessage != null ? Colors.red : Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              iconSize: 24,
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword; // Toggle the password visibility
                                });
                              },
                            ),
                            errorText: _perrorMessage,
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _perrorMessage != null ? Colors.red : Colors.blue),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: _perrorMessage != null ? Colors.red : Colors.grey),
                            ),
                          ),
                          obscureText: _obscurePassword,
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _signInWithEmailAndPassword,
                          child: const Text('Sign In'),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),)
                  
                ],
              ),
            ),
          ),
        ),
      ]),
    ),);
  }
}

