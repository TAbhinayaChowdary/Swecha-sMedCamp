import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PatientRegistrationPage extends StatefulWidget {
  const PatientRegistrationPage({super.key});

  @override
  State<PatientRegistrationPage> createState() => _PatientRegistrationPageState();
}

class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _bookNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _areaController = TextEditingController();
  final _eidController = TextEditingController();

  String _selectedGender = 'male';
  bool _isLoading = false;
  bool _showForm = false;
  bool _patientFound = false;
  String? _statusMessage;

  final List<String> _genderOptions = ['male', 'female'];

  @override
  void dispose() {
    _bookNumberController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _eidController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatient() async {
    setState(() {
      _isLoading = true;
      _showForm = false;
      _statusMessage = null;
    });
    try {
      final response = await ApiService.get('/patients/${_bookNumberController.text.trim()}');
      if (response != null && response is Map && response['book_no'] != null) {
        final patient = response;
        _nameController.text = patient['patient_name'] ?? '';
        _ageController.text = patient['patient_age']?.toString() ?? '';
        _phoneController.text = patient['patient_phone_no'] ?? '';
        _areaController.text = patient['patient_area'] ?? '';
        _eidController.text = patient['eid']?.toString() ?? '';
        _selectedGender = patient['patient_sex'] ?? 'male';
        setState(() {
          _showForm = true;
          _patientFound = true;
          _statusMessage = 'Patient data loaded successfully!';
        });
      } else {
        _clearForm();
        setState(() {
          _showForm = true;
          _patientFound = false;
          _statusMessage = 'No patient found. Please fill out the form.';
        });
      }
    } catch (e) {
      _clearForm();
      setState(() {
        _showForm = true;
        _patientFound = false;
        _statusMessage = 'No patient found. Please fill out the form.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _phoneController.clear();
    _areaController.clear();
    _eidController.clear();
    _selectedGender = 'male';
  }

  Future<void> _savePatient() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        final patientData = {
          'book_no': _bookNumberController.text.trim(),
          'patient_name': _nameController.text.trim(),
          'patient_phone_no': _phoneController.text.trim(),
          'patient_age': int.tryParse(_ageController.text) ?? '',
          'patient_sex': _selectedGender,
          'patient_area': _areaController.text.trim(),
          'eid': _eidController.text.trim(),
        };
        await ApiService.post('/patients', patientData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient saved successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MedicalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Patient Registration', style: TextStyle(color: Colors.black)),
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
                      child: Text('👩‍⚕️', style: TextStyle(fontSize: 32)),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(),
                  Text(
                    'Patient Registration',
                    style: GoogleFonts.quicksand(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Register or update patient details',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      color: Colors.teal[900],
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _bookNumberController,
                    cursorColor: Colors.teal,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Book Number',
                      prefixIcon: Icon(Icons.book, color: Colors.teal[400]),
                    ),
                    enabled: !_isLoading,
                  ).animate().fadeIn(duration: 900.ms).slideX(begin: -0.2),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: StadiumBorder(),
                        elevation: 6,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _isLoading ? null : _fetchPatient,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Fetch Patient'),
                    ).animate().scale(duration: 300.ms),
                  ),
                  if (_statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Material(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(8),
                        child: ListTile(
                          title: Text(_statusMessage!, style: TextStyle(color: _patientFound ? Colors.green : Colors.red)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _statusMessage = null),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 1000.ms),
                  if (_showForm)
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person, color: Colors.teal[400]),
                            ),
                            cursorColor: Colors.teal,
                            validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                          ).animate().fadeIn(duration: 1100.ms).slideX(begin: -0.1),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.cake, color: Colors.teal[400]),
                            ),
                            cursorColor: Colors.teal,
                            validator: (value) => value == null || value.isEmpty ? 'Enter age' : null,
                          ).animate().fadeIn(duration: 1200.ms).slideX(begin: 0.1),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone, color: Colors.teal[400]),
                            ),
                            cursorColor: Colors.teal,
                            validator: (value) => value == null || value.isEmpty ? 'Enter phone number' : null,
                          ).animate().fadeIn(duration: 1300.ms).slideX(begin: -0.1),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _areaController,
                            decoration: InputDecoration(
                              labelText: 'Area',
                              prefixIcon: Icon(Icons.location_on, color: Colors.teal[400]),
                            ),
                            cursorColor: Colors.teal,
                            validator: (value) => value == null || value.isEmpty ? 'Enter area' : null,
                          ).animate().fadeIn(duration: 1400.ms).slideX(begin: 0.1),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _eidController,
                            decoration: InputDecoration(
                              labelText: 'EID',
                              prefixIcon: Icon(Icons.badge, color: Colors.teal[400]),
                            ),
                            cursorColor: Colors.teal,
                          ).animate().fadeIn(duration: 1500.ms).slideX(begin: -0.1),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            items: _genderOptions.map((gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(gender[0].toUpperCase() + gender.substring(1)),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedGender = value ?? 'male'),
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.wc, color: Colors.teal[400]),
                            ),
                          ).animate().fadeIn(duration: 1600.ms).slideX(begin: 0.1),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[400],
                              foregroundColor: Colors.white,
                              shape: StadiumBorder(),
                              elevation: 6,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: _isLoading ? null : _savePatient,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Save Patient'),
                          ).animate().scale(duration: 300.ms),
                        ],
                      ),
                    ).animate().fadeIn(duration: 1700.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
