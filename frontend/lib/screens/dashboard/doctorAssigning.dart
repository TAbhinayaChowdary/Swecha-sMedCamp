import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'doctorPatientQueues.dart';
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DoctorAssigningPage extends StatefulWidget {
  const DoctorAssigningPage({super.key});

  @override
  State<DoctorAssigningPage> createState() => _DoctorAssigningPageState();
}

class _DoctorAssigningPageState extends State<DoctorAssigningPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bookNumberController = TextEditingController();
  List<dynamic> _doctors = [];
  List<String> _selectedDoctors = [];
  String? _successMessage;
  String? _errorMessage;

  // Replace with your backend base URL
  final String _baseUrl = 'http://192.168.71.211:5002/api'; // <-- CHANGE THIS TO YOUR BACKEND IP

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/doctor-assign/get_doctors'));
      if (response.statusCode == 200) {
        setState(() {
          _doctors = json.decode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load doctors';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching doctors';
      });
    }
  }

  void _submit() async {
    setState(() {
      _successMessage = null;
      _errorMessage = null;
    });
    if ((_formKey.currentState?.validate() ?? false) && _selectedDoctors.isNotEmpty) {
      final bookNo = _bookNumberController.text.trim();
      final body = json.encode({
        'book_no': bookNo,
        'doctor_names': _selectedDoctors,
      });
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/queue/add'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
        if (response.statusCode == 201) {
          setState(() {
            _successMessage = 'Queue entry created successfully';
            _selectedDoctors.clear();
            _bookNumberController.clear();
          });
        } else {
          final resp = json.decode(response.body);
          setState(() {
            _errorMessage = resp['message'] ?? 'Failed to assign doctors';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Network error';
        });
      }
    } else if (_selectedDoctors.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one doctor';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MedicalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Doctor Assigning', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Mascot and playful header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.teal[50],
                      child: Text('👨‍⚕️', style: TextStyle(fontSize: 32)),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(),
                  Text(
                    'Doctor Assigning',
                    style: GoogleFonts.quicksand(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Assign one or more doctors to a patient',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      color: Colors.teal[900],
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _bookNumberController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Book Number',
                            prefixIcon: Icon(Icons.book, color: Colors.teal[400]),
                          ),
                          cursorColor: Colors.teal,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter Book Number'
                              : null,
                        ).animate().fadeIn(duration: 900.ms).slideX(begin: -0.2),
                        const SizedBox(height: 18),
                        const Text(
                          'Select Doctor(s)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_doctors.isEmpty)
                          const Center(child: CircularProgressIndicator()),
                        ..._doctors.map((doctor) => CheckboxListTile(
                              title: Text(
                                '${doctor['doctor_name']} (${doctor['specialization']})',
                                style: const TextStyle(color: Colors.black),
                              ),
                              value: _selectedDoctors.contains(doctor['doctor_name']),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedDoctors.add(doctor['doctor_name']);
                                  } else {
                                    _selectedDoctors.remove(doctor['doctor_name']);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            )),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[400],
                            foregroundColor: Colors.white,
                            shape: StadiumBorder(),
                            elevation: 6,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _submit,
                          child: const Text('Submit'),
                        ).animate().scale(duration: 300.ms),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.1),
                  if (_successMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(duration: 1200.ms),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(duration: 1200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
