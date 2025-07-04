import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VitalsPage extends StatefulWidget {
  final String? patientId;
  
  const VitalsPage({super.key, this.patientId});

  @override
  State<VitalsPage> createState() => _VitalsPageState();
}

class _VitalsPageState extends State<VitalsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _rbsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _lastMealController = TextEditingController();
  
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null) {
      _patientIdController.text = widget.patientId!;
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _rbsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _lastMealController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final vitalsData = {
          'book_no': _patientIdController.text.trim(),
          'bp': _bpController.text.trim(),
          'pulse': _pulseController.text.trim(),
          'rbs': _rbsController.text.trim(),
          'weight': _weightController.text.trim(),
          'height': _heightController.text.trim(),
          'last_meal': _lastMealController.text.trim(),
        };

        await ApiService.post('/vitals', vitalsData);

        if (mounted) {
          setState(() {
            _statusMessage = 'Vitals data updated successfully';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vitals data updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _formKey.currentState?.reset();
          _bpController.clear();
          _pulseController.clear();
          _rbsController.clear();
          _weightController.clear();
          _heightController.clear();
          _lastMealController.clear();
          if (widget.patientId != null) {
            _patientIdController.text = widget.patientId!;
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to record vitals: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MedicalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Record Vitals', style: TextStyle(color: Colors.black)),
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
                      child: Text('💓', style: TextStyle(fontSize: 32)),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(),
                  Text(
                    'Patient Vitals',
                    style: GoogleFonts.quicksand(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Record patient vitals quickly and accurately',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      color: Colors.teal[900],
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  if (_statusMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(duration: 1000.ms),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _patientIdController,
                          decoration: InputDecoration(
                            labelText: 'Book Number *',
                            prefixIcon: Icon(Icons.book, color: Colors.teal[400]),
                          ),
                          cursorColor: Colors.teal,
                          validator: (value) => value == null || value.isEmpty ? 'Book Number is required' : null,
                        ).animate().fadeIn(duration: 900.ms).slideX(begin: -0.2),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _bpController,
                          decoration: InputDecoration(
                            labelText: 'BP (systolic/diastolic) *',
                            prefixIcon: Icon(Icons.favorite, color: Colors.teal[400]),
                          ),
                          cursorColor: Colors.teal,
                          validator: (value) => value == null || value.isEmpty ? 'BP is required' : null,
                        ).animate().fadeIn(duration: 1000.ms).slideX(begin: 0.2),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pulseController,
                          decoration: InputDecoration(
                            labelText: 'Pulse *',
                            prefixIcon: Icon(Icons.favorite, color: Colors.teal[400]),
                          ),
                          cursorColor: Colors.teal,
                          validator: (value) => value == null || value.isEmpty ? 'Pulse is required' : null,
                        ).animate().fadeIn(duration: 1100.ms).slideX(begin: -0.2),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rbsController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'RBS (mg/dL) *',
                            prefixIcon: Icon(Icons.bloodtype, color: Colors.teal[400]),
                          ),
                          cursorColor: Colors.teal,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter RBS';
                            }
                            final rbs = double.tryParse(value);
                            if (rbs == null || rbs < 0) {
                              return 'Enter a valid RBS value';
                            }
                            return null;
                          },
                        ).animate().fadeIn(duration: 1200.ms).slideX(begin: 0.2),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg) *',
                            prefixIcon: Icon(Icons.monitor_weight, color: Colors.teal[400]),
                          ),
                          cursorColor: Colors.teal,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Weight';
                            }
                            final weight = double.tryParse(value);
                            if (weight == null || weight <= 0 || weight > 500) {
                              return 'Enter a valid weight';
                            }
                            return null;
                          },
                        ).animate().fadeIn(duration: 1300.ms).slideX(begin: -0.2),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Height (cm) *',
                            prefixIcon: Icon(Icons.height, color: Colors.teal[400]),
                          ),
                          cursorColor: Colors.teal,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter Height';
                            }
                            final height = double.tryParse(value);
                            if (height == null || height <= 0 || height > 300) {
                              return 'Enter a valid height';
                            }
                            return null;
                          },
                        ).animate().fadeIn(duration: 1400.ms).slideX(begin: 0.2),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastMealController,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            labelText: 'Last Meal and Time *',
                            prefixIcon: Icon(Icons.lunch_dining, color: Colors.teal[400]),
                          ),
                          cursorColor: Colors.teal,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter Last Meal and Time'
                              : null,
                        ).animate().fadeIn(duration: 1500.ms).slideX(begin: -0.2),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[400],
                            foregroundColor: Colors.white,
                            shape: StadiumBorder(),
                            elevation: 6,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Record Vitals'),
                        ).animate().scale(duration: 300.ms),
                      ],
                    ),
                  ).animate().fadeIn(duration: 1600.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
