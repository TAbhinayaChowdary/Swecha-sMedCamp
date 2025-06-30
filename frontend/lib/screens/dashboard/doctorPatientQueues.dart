import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DoctorPatientQueuesPage extends StatefulWidget {
  const DoctorPatientQueuesPage({Key? key}) : super(key: key);

  @override
  State<DoctorPatientQueuesPage> createState() => _DoctorPatientQueuesPageState();
}

class _DoctorPatientQueuesPageState extends State<DoctorPatientQueuesPage> {
  final String _baseUrl = 'http://192.168.71.211:5002/api';
  List<dynamic> _doctors = [];
  Map<int, int> _queueCounts = {};
  Map<int, dynamic> _nextPatients = {};
  Map<int, String> _status = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDoctorQueues();
  }

  Future<void> _fetchDoctorQueues() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // First, let's fetch all queue data to see what's actually in the queue
      print('=== FETCHING ALL QUEUE DATA ===');
      try {
        final allQueueRes = await http.get(Uri.parse('$_baseUrl/queue/all'));
        print('All queue response: ${allQueueRes.statusCode} - ${allQueueRes.body}');
      } catch (e) {
        print('Error fetching all queue data: $e');
      }
      
      final doctorsRes = await http.get(Uri.parse('$_baseUrl/doctor-assign/get_doctors'));
      if (doctorsRes.statusCode == 200) {
        final doctors = json.decode(doctorsRes.body);
        print('Fetched doctors: $doctors');
        
        Map<int, int> queueCounts = {};
        Map<int, dynamic> nextPatients = {};
        Map<int, dynamic> convertedDoctors = {}; // Store doctors with converted IDs
        
        for (final doc in doctors) {
          final docIdRaw = doc['doctor_id'];
          print('Raw doctor ID: $docIdRaw (type: ${docIdRaw.runtimeType})');
          
          if (docIdRaw == null) {
            print('Doctor ID is null, skipping doctor: ${doc['doctor_name']}');
            continue;
          }
          
          // Simplified ID conversion - just convert to string and then to int
          int docId;
          try {
            docId = int.parse(docIdRaw.toString());
            print('Successfully converted doctor ID: $docIdRaw -> $docId');
          } catch (e) {
            print('Failed to convert doctor ID $docIdRaw, skipping doctor: ${doc['doctor_name']}');
            continue;
          }
          
          // Store doctor with converted ID
          convertedDoctors[docId] = {
            ...doc,
            '_id': docId, // Use the converted integer ID
          };
          
          print('Processing doctor: ${doc['doctor_name']} with ID: $docId');
          
          // Fetch queue count
          try {
            final countRes = await http.get(Uri.parse('$_baseUrl/queue/count/$docId'));
            print('Queue count response for doctor $docId: ${countRes.statusCode} - ${countRes.body}');
            
            if (countRes.statusCode == 200) {
              final countData = json.decode(countRes.body);
              queueCounts[docId] = countData['queueCount'] ?? 0;
              print('Queue count for doctor $docId: ${queueCounts[docId]}');
            } else {
              // Try alternative endpoint with doctor name
              try {
                final countByNameRes = await http.get(Uri.parse('$_baseUrl/queue/count/${Uri.encodeComponent(doc['doctor_name'])}'));
                print('Queue count by name response for ${doc['doctor_name']}: ${countByNameRes.statusCode} - ${countByNameRes.body}');
                
                if (countByNameRes.statusCode == 200) {
                  final countByNameData = json.decode(countByNameRes.body);
                  queueCounts[docId] = countByNameData['queueCount'] ?? 0;
                  print('Queue count by name for ${doc['doctor_name']}: ${queueCounts[docId]}');
                } else {
                  queueCounts[docId] = 0;
                  print('Failed to get queue count by name for ${doc['doctor_name']}: ${countByNameRes.statusCode}');
                }
              } catch (e) {
                print('Error fetching queue count by name for ${doc['doctor_name']}: $e');
                queueCounts[docId] = 0;
              }
            }
          } catch (e) {
            print('Error fetching queue count for doctor $docId: $e');
            queueCounts[docId] = 0;
          }
          
          // Fetch next patient
          try {
            final nextRes = await http.get(Uri.parse('$_baseUrl/queue/next/$docId'));
            print('Next patient response for doctor $docId: ${nextRes.statusCode} - ${nextRes.body}');
            
            if (nextRes.statusCode == 200) {
              final nextData = json.decode(nextRes.body);
              final bookNo = nextData['book_no'];
              
              if (bookNo != null) {
                print('Found next patient for doctor $docId: Book #$bookNo');
                
                // Fetch patient details
                try {
                  final patientRes = await http.get(Uri.parse('$_baseUrl/patient/$bookNo'));
                  print('Patient details response for book $bookNo: ${patientRes.statusCode} - ${patientRes.body}');
                  
                  if (patientRes.statusCode == 200) {
                    final patientData = json.decode(patientRes.body);
                    nextPatients[docId] = patientData;
                    print('Patient details for book $bookNo: $patientData');
                  } else {
                    nextPatients[docId] = {'book_no': bookNo};
                    print('Failed to get patient details for book $bookNo: ${patientRes.statusCode}');
                  }
                } catch (e) {
                  print('Error fetching patient details for book $bookNo: $e');
                  nextPatients[docId] = {'book_no': bookNo};
                }
              } else {
                nextPatients[docId] = null;
                print('No next patient for doctor $docId');
              }
            } else {
              // Try alternative endpoint with doctor name
              try {
                final nextByNameRes = await http.get(Uri.parse('$_baseUrl/queue/next/${Uri.encodeComponent(doc['doctor_name'])}'));
                print('Next patient by name response for ${doc['doctor_name']}: ${nextByNameRes.statusCode} - ${nextByNameRes.body}');
                
                if (nextByNameRes.statusCode == 200) {
                  final nextByNameData = json.decode(nextByNameRes.body);
                  final bookNoByName = nextByNameData['book_no'];
                  
                  if (bookNoByName != null) {
                    print('Found next patient by name for ${doc['doctor_name']}: Book #$bookNoByName');
                    
                    // Fetch patient details
                    try {
                      final patientRes = await http.get(Uri.parse('$_baseUrl/patient/$bookNoByName'));
                      print('Patient details response for book $bookNoByName: ${patientRes.statusCode} - ${patientRes.body}');
                      
                      if (patientRes.statusCode == 200) {
                        final patientData = json.decode(patientRes.body);
                        nextPatients[docId] = patientData;
                        print('Patient details for book $bookNoByName: $patientData');
                      } else {
                        nextPatients[docId] = {'book_no': bookNoByName};
                        print('Failed to get patient details for book $bookNoByName: ${patientRes.statusCode}');
                      }
                    } catch (e) {
                      print('Error fetching patient details for book $bookNoByName: $e');
                      nextPatients[docId] = {'book_no': bookNoByName};
                    }
                  } else {
                    nextPatients[docId] = null;
                    print('No next patient by name for ${doc['doctor_name']}');
                  }
                } else {
                  nextPatients[docId] = null;
                  print('Failed to get next patient by name for ${doc['doctor_name']}: ${nextByNameRes.statusCode}');
                }
              } catch (e) {
                print('Error fetching next patient by name for ${doc['doctor_name']}: $e');
                nextPatients[docId] = null;
              }
            }
          } catch (e) {
            print('Error fetching next patient for doctor $docId: $e');
            nextPatients[docId] = null;
          }
        }
        
        print('Final queue counts: $queueCounts');
        print('Final next patients: $nextPatients');
        print('Converted doctors count: ${convertedDoctors.length}');
        print('Converted doctors: $convertedDoctors');
        
        // Use converted doctors if available, otherwise fall back to original
        final doctorsToUse = convertedDoctors.isNotEmpty ? convertedDoctors.values.toList() : doctors;
        print('Using doctors list with ${doctorsToUse.length} doctors');
        
        setState(() {
          _doctors = doctorsToUse;
          _queueCounts = queueCounts;
          _nextPatients = nextPatients;
          _isLoading = false;
          _status.clear();
        });
        
        print('Final _doctors list length: ${_doctors.length}');
        print('Final _doctors: $_doctors');
      } else {
        print('Failed to fetch doctors: ${doctorsRes.statusCode} - ${doctorsRes.body}');
        setState(() {
          _error = 'Error loading doctors: ${doctorsRes.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchDoctorQueues: $e');
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAssign(dynamic doctor) async {
    final docIdRaw = doctor['doctor_id'];
    final int docId = docIdRaw is int ? docIdRaw : int.tryParse(docIdRaw.toString()) ?? -1;
    if (docId == -1) return;
    final nextPatient = _nextPatients[docId];
    final bookNo = nextPatient != null ? nextPatient['book_no'] : null;
    if (bookNo == null) return;
    
    print('Assigning doctor ${doctor['doctor_name']} to patient Book #$bookNo');
    
    setState(() {
      _status[docId] = 'Processing...';
    });
    
    try {
      // First, assign the doctor to the patient
      final assignRes = await http.post(
        Uri.parse('$_baseUrl/doctor-assign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'book_no': bookNo,
          'doc_name': doctor['doctor_name'],
        }),
      );
      
      print('Assignment response: ${assignRes.statusCode} - ${assignRes.body}');
      
      if (assignRes.statusCode == 200 || assignRes.statusCode == 201) {
        // Then remove the patient from the queue
        try {
          final removeRes = await http.delete(
            Uri.parse('$_baseUrl/queue/remove'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'book_no': bookNo}),
          );
          
          print('Remove from queue response: ${removeRes.statusCode} - ${removeRes.body}');
          
          setState(() {
            _status[docId] = 'Assigned';
          });
          
          await Future.delayed(const Duration(milliseconds: 700));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Doctor ${doctor['doctor_name']} assigned to Book #$bookNo'),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh the queue data
            _fetchDoctorQueues();
          }
        } catch (e) {
          print('Error removing from queue: $e');
          setState(() {
            _status[docId] = 'Error';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Assigned but failed to remove from queue: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        final errorData = json.decode(assignRes.body);
        final errorMessage = errorData['message'] ?? 'Failed to assign doctor';
        print('Assignment failed: $errorMessage');
        setState(() {
          _status[docId] = 'Error';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assignment failed: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in assignment: $e');
      setState(() {
        _status[docId] = 'Error';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error during assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFB2EBF2), Color(0xFFE3F2FD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('View Queues', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchDoctorQueues,
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          child: const Icon(Icons.refresh),
          tooltip: 'Refresh Queues',
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 800 ? 800 : MediaQuery.of(context).size.width - 32,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.grey.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.teal[50],
                      child: Text('📋', style: TextStyle(fontSize: 32)),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(),
                  Text(
                    'View Queues',
                    style: GoogleFonts.quicksand(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007BFF)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading doctors and queues...',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    )
                  else if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: GoogleFonts.quicksand(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(120, 40),
                              textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _fetchDoctorQueues,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_doctors.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF80DEEA)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: Colors.grey.shade600,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No doctors available',
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are currently no doctors in the system.',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ..._doctors.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final doc = entry.value;
                          final docId = doc['doctor_id'];
                          final queueCount = _queueCounts[docId] ?? 0;
                          final nextPatient = _nextPatients[docId];
                          final statusValue = _status[docId];
                          return Animate(
                            effects: [
                              FadeEffect(duration: 400.ms, delay: (idx * 80).ms),
                              SlideEffect(duration: 400.ms, delay: (idx * 80).ms, begin: const Offset(0, 0.1)),
                            ],
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF80DEEA), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.07),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Doctor name header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade200,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text('👩‍⚕️', style: TextStyle(fontSize: 24)),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                doc['doctor_name'],
                                                style: GoogleFonts.quicksand(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: Colors.teal.shade900,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Doctor ID: ${doc['doctor_id']}',
                                                style: GoogleFonts.quicksand(
                                                  fontSize: 14,
                                                  color: Colors.teal.shade400,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Queue information
                                    Column(
                                      children: [
                                        // Queue count
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: queueCount > 0 ? Colors.green.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: queueCount > 0 ? Colors.green.shade200 : const Color(0xFF80DEEA)),
                                          ),
                                          child: Column(
                                            children: [
                                              const Text('📝', style: TextStyle(fontSize: 22)),
                                              const SizedBox(height: 8),
                                              Text(
                                                '$queueCount',
                                                style: GoogleFonts.quicksand(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: queueCount > 0 ? Colors.green : Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                'Patients in Queue',
                                                style: GoogleFonts.quicksand(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Next patient
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: nextPatient != null ? Colors.orange.shade50 : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: nextPatient != null ? Colors.orange.shade200 : const Color(0xFF80DEEA)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text('💊', style: TextStyle(fontSize: 18)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Next Patient',
                                                    style: GoogleFonts.quicksand(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (nextPatient != null && nextPatient['book_no'] != null) ...[
                                                Text(
                                                  'Book #${nextPatient['book_no']}',
                                                  style: GoogleFonts.quicksand(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                if (nextPatient['name'] != null)
                                                  Text(
                                                    '${nextPatient['name']}',
                                                    style: GoogleFonts.quicksand(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                              ] else
                                                Text(
                                                  'No patients',
                                                  style: GoogleFonts.quicksand(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade500,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Action button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: nextPatient != null && nextPatient['book_no'] != null 
                                              ? (statusValue == 'Processing...' ? Colors.orange : Colors.green)
                                              : Colors.grey.shade400,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size.fromHeight(48),
                                          textStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: nextPatient != null && nextPatient['book_no'] != null && 
                                                  (statusValue != 'Assigned' && statusValue != 'Processing...')
                                              ? () => _handleAssign(doc)
                                              : null,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (statusValue == 'Processing...')
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            else
                                              const Text('✅', style: TextStyle(fontSize: 18)),
                                            const SizedBox(width: 8),
                                            Text(
                                              nextPatient != null && nextPatient['book_no'] != null && statusValue != null && statusValue != 'Error'
                                                  ? statusValue
                                                  : 'Assign Patient',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Error message
                                    if (nextPatient != null && nextPatient['book_no'] != null && statusValue == 'Error')
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red.shade700,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Assignment failed. Please try again.',
                                                style: GoogleFonts.quicksand(
                                                  color: Colors.red.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}