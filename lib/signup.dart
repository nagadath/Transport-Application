// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, use_key_in_widget_constructors


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'navigation_widget.dart';
import 'signin.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _eerrorMessage;
  String? _perrorMessage;
  bool _errorOccurred = false;
  bool _obscurePassword = true;

  Future<void> _signUpWithEmailAndPassword() async {

    setState(() {
      _eerrorMessage = null;
      _perrorMessage = null;
      _errorOccurred = false;
    });

    FocusScope.of(context).unfocus();
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // ignore: avoid_print
      print('User signed up: ${userCredential.user!.uid}');
      Navigator.pop(context);
    } catch (e) {
      if(e is FirebaseAuthException){
        if (e.code == "invalid-email") {
          setState(() {
            _eerrorMessage = "Invalid Email, please recheck!";
            _errorOccurred = true;
          });
        } 
        if (e.code == "weak-password") {
          setState(() {
            _perrorMessage = "Password should contain 6 characters";
            _eerrorMessage = null;
            _errorOccurred = true;
          });
        }
        if (e.code == "email-already-in-use") {
          setState(() {
            _eerrorMessage = "Email already exists. Please sign in instead.";
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
    double containerHeight = _errorOccurred ? MediaQuery.of(context).size.height * 0.385 : MediaQuery.of(context).size.height * 0.355;
    return MaterialApp(
      home: Scaffold(
        backgroundColor : const Color.fromARGB(255, 27, 35, 114),
        body: Center(
          child:Container( 
            decoration: BoxDecoration(
              color: Colors.white,
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(20),
                ),
            height: MediaQuery.of(context).size.height * 0.41,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: containerHeight,
                  child: Column(
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
                        onPressed: _signUpWithEmailAndPassword,
                        child: const Text('Sign Up'),
                      ),
                      const SizedBox(height: 16.0),
                      const Text("Already have an account?"),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const SignInPage()),
                            );
                          },
                          child: const Text('Sign In',style: TextStyle(color: Colors.blue),),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
