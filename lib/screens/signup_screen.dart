import 'package:firebase_auth/firebase_auth.dart'; // Added for User object
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart'; // Import DatabaseService
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true; 
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); 
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService(); // Initialize DB Service

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], 
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isLogin ? Icons.lock_person : Icons.person_add, 
                       size: 64, color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  Text(
                    isLogin ? "Welcome Back" : "Create Account",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? "Please sign in to continue" : "Fill in the details to get started",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  if (!isLogin) ...[
                    _buildTextField(_nameController, "Full Name", Icons.person_outline),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(_emailController, "Email Address", Icons.email_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_passwordController, "Password", Icons.lock_outline, isPassword: true),
                  
                  const SizedBox(height: 32),
                  
                  if (isLogin) 
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () async {
                            if (_emailController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter your email first"))
                              );
                              return;
                            }
                            String? result = await _authService.resetPassword(_emailController.text.trim());
                            if (result == "Success") {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Password reset email sent! Check your inbox."),
                                  backgroundColor: Colors.green,
                                )
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result!), backgroundColor: Colors.redAccent)
                              );
                            }
                          },
                          child: const Text(
                            "Forgot Password?", 
                            style: TextStyle(color: Color(0xFF2575FC), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2575FC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 5,
                      ),
                      onPressed: () async {
                        String email = _emailController.text.trim();
                        String password = _passwordController.text.trim();
                        String name = _nameController.text.trim();

                        String? result;

                        if (isLogin) {
                          result = await _authService.login(email, password);
                        } else {
                          // Validation for name during Signup
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter your name"))
                            );
                            return;
                          }
                          
                          result = await _authService.signUp(email, password);
                          
                          // NEW: If signup is successful, save the name to Firestore
                          if (result == "Success") {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await _dbService.saveUserData(user.uid, name, email);
                            }
                          }
                        }
                        
                        if (result == "Success") {
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => HomeScreen()),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result ?? "An error occurred"), backgroundColor: Colors.redAccent)
                            );
                          }
                        }
                      },
                      child: Text(isLogin ? "LOGIN" : "SIGN UP", 
                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                        children: [
                          TextSpan(text: isLogin ? "Don't have an account? " : "Already have an account? "),
                          TextSpan(
                            text: isLogin ? "Sign Up" : "Login",
                            style: const TextStyle(color: Color(0xFF2575FC), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF6A11CB)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}