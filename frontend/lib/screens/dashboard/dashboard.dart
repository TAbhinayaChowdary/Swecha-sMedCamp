import 'package:flutter/material.dart';
import 'dart:io';
import 'patientRegistration.dart';
import 'vitals.dart';
import 'doctorAssigning.dart';
import 'doctorPrescription.dart';
import 'medicinePickup.dart';
import 'doctorPatientQueues.dart';
import '../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class VolunteerMainPage extends StatefulWidget {
  const VolunteerMainPage({Key? key}) : super(key: key);

  @override
  State<VolunteerMainPage> createState() => _VolunteerMainPageState();
}

class _VolunteerMainPageState extends State<VolunteerMainPage> {
  final List<_GridOption> _options = const [
    _GridOption('Patient registration', '👤', Color(0xFF80DEEA)),
    _GridOption('Vitals', '💓', Color(0xFFB39DDB)),
    _GridOption('Doctor assigning', '👨‍⚕️', Color(0xFFFFAB91)),
    _GridOption('View queue', '📋', Color(0xFFA5D6A7)),
    _GridOption('Doctor prescription', '💊', Color(0xFFFFF59D)),
    _GridOption('Medicine pickup', '🏥', Color(0xFFFFCCBC)),
  ];

  void _onOptionTap(BuildContext context, String title) {
    if (title == 'Patient registration') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const PatientRegistrationPage()),
      );
      return;
    }
    if (title == 'Vitals') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VitalsPage()),
      );
      return;
    }
    if (title == 'Doctor assigning') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DoctorAssigningPage()),
      );
      return;
    }
    if (title == 'View queue') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DoctorPatientQueuesPage()),
      );
      return;
    }
    if (title == 'Doctor prescription') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DoctorPrescriptionPage()),
      );
      return;
    }
    if (title == 'Medicine pickup') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MedicinePickupPage()),
      );
      return;
    }
    // TODO: Implement navigation or action for each option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped: $title (implement logic)')),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit'),
        content: const Text('Do you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // No
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Yes
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: MedicalGradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Volunteer Dashboard', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.transparent),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mascot and welcome
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text('🩺', style: TextStyle(fontSize: 32)),
                    ).animate().fadeIn(duration: 500.ms).scale(),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to the Camp!',
                          style: GoogleFonts.quicksand(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ).animate().fadeIn(duration: 700.ms).slideX(begin: 0.2),
                        Text(
                          "Let's make a difference today.",
                          style: GoogleFonts.quicksand(
                            fontSize: 15,
                            color: Colors.teal[900],
                          ),
                        ).animate().fadeIn(duration: 900.ms).slideX(begin: 0.3),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 32,
                    mainAxisSpacing: 32,
                    childAspectRatio: 0.75,
                    children: _options.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final option = entry.value;
                      return GestureDetector(
                        onTap: () => _onOptionTap(context, option.title),
                        child: Card(
                          elevation: 8,
                          color: Colors.white.withOpacity(0.92),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: option.bgColor.withOpacity(0.18),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  option.emoji,
                                  style: const TextStyle(fontSize: 40),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  option.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms + (idx * 100).ms).scaleXY(begin: 0.9, end: 1.0, duration: 300.ms),
                      );
                    }).toList(),
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

class _GridOption {
  final String title;
  final String emoji;
  final Color bgColor;
  const _GridOption(this.title, this.emoji, this.bgColor);
}
