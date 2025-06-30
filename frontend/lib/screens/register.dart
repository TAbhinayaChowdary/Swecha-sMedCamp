import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  void _registerAs(BuildContext context, String role) {
    // TODO: Implement registration logic for each role
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Register as $role (implement logic)')),
    );
    // Example: Navigate to different registration forms based on role
    // Navigator.pushNamed(context, '/register${role}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF007BFF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _registerAs(context, 'Volunteer'),
                child: const Text('Register as Volunteer'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _registerAs(context, 'User'),
                child: const Text('Register as User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
