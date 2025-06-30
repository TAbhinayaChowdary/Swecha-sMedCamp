import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MedicinePickupPage extends StatefulWidget {
  const MedicinePickupPage({Key? key}) : super(key: key);

  @override
  State<MedicinePickupPage> createState() => _MedicinePickupPageState();
}

class _MedicinePickupPageState extends State<MedicinePickupPage> {
  final TextEditingController _bookNoController = TextEditingController();
  List prescribedMeds = [];
  String? error;
  String? message;
  bool showVerification = false;
  bool isLoading = false;
  String get _bookNo => _bookNoController.text.trim();

  // Replace with your backend URL and port
  final String _baseUrl = 'http://192.168.71.211:5002/api';

  // For verification modal
  Map<String, dynamic> verificationData = {
    'medicines_prescribed': [],
    'medicines_given': []
  };
  bool isVerificationLoading = false;
  String? verificationError;

  @override
  void dispose() {
    _bookNoController.dispose();
    super.dispose();
  }

  Future<void> fetchPrescription() async {
    setState(() {
      error = null;
      message = null;
      prescribedMeds = [];
      showVerification = false;
      isLoading = true;
    });
    if (_bookNo.isEmpty) {
      setState(() {
        error = 'Please enter a valid Book No.';
        isLoading = false;
      });
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patient-history/medicine-pickup/$_bookNo'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['medicines_prescribed'] == null ||
            data['medicines_prescribed'].isEmpty) {
          setState(() {
            error = 'No medicines found for this patient.';
            isLoading = false;
          });
          return;
        }
        final medsWithInput = (data['medicines_prescribed'] as List).map((med) {
          return {
            ...med,
            'batches': (med['batches'] as List).map((batch) {
              return {
                ...batch,
                'quantity_taken': 0,
                'quantity': batch['available_quantity'] // for UI
              };
            }).toList()
          };
        }).toList();
        setState(() {
          prescribedMeds = medsWithInput;
          isLoading = false;
        });
      } else {
        setState(() {
          error = json.decode(response.body)['message'] ??
              'Failed to fetch prescription.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to fetch prescription: $e';
        isLoading = false;
      });
    }
  }

  void handleQuantityChange(int medIndex, int batchIndex, String value) {
    setState(() {
      prescribedMeds[medIndex]['batches'][batchIndex]['quantity_taken'] =
          value.isEmpty ? 0 : int.tryParse(value) ?? 0;
    });
  }

  Future<void> confirmPickup() async {
    setState(() {
      error = null;
      message = null;
      isLoading = true;
    });

    // Check if quantities match prescribed amounts
    final quantityMismatch = prescribedMeds.where((med) {
      final totalGiven = (med['batches'] as List)
          .fold<int>(0, (sum, batch) => sum + ((batch['quantity_taken'] ?? 0) as num).toInt());
      return totalGiven != int.parse(med['quantity'].toString());
    }).toList();

    if (quantityMismatch.isNotEmpty) {
      final mismatchItems = quantityMismatch.map((med) {
        final totalGiven = (med['batches'] as List)
            .fold<int>(0, (sum, batch) => sum + ((batch['quantity_taken'] ?? 0) as num).toInt());
        return '${med['medicine_id']} (Prescribed: ${med['quantity']}, Given: $totalGiven)';
      }).join(', ');
      setState(() {
        error =
            'Quantity mismatch for medicine(s): $mismatchItems. Please ensure the total quantity given matches the prescribed amount.';
        isLoading = false;
      });
      return;
    }

    final medicinesGiven = <Map<String, dynamic>>[];
    for (var med in prescribedMeds) {
      for (var batch in med['batches']) {
        if ((batch['quantity_taken'] ?? 0) > 0) {
          medicinesGiven.add({
            'medicine_id': med['medicine_id'],
            'medicine_name': batch['medicine_name'],
            'expiry_date': batch['expiry_date'],
            'quantity': batch['quantity_taken']
          });
        }
      }
    }

    if (medicinesGiven.isEmpty) {
      setState(() {
        error = 'No medicines were selected as given.';
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/patient-history/medicine-pickup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'book_no': _bookNo, 'medicinesGiven': medicinesGiven}),
      );
      if (response.statusCode == 200) {
        setState(() {
          message = json.decode(response.body)['message'] ??
              'Medicines given updated successfully!';
          prescribedMeds = [];
          showVerification = true;
          isLoading = false;
        });
      } else {
        setState(() {
          error = json.decode(response.body)['message'] ??
              'Failed to update medicines given.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to update medicines given: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchVerificationData() async {
    setState(() {
      isVerificationLoading = true;
      verificationError = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patient-history/medicine-verification/$_bookNo'),
      );
      if (response.statusCode == 200) {
        setState(() {
          verificationData = json.decode(response.body);
          isVerificationLoading = false;
        });
      } else {
        setState(() {
          verificationError = json.decode(response.body)['message'] ??
              'Failed to fetch verification data';
          isVerificationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        verificationError = 'Failed to fetch verification data: $e';
        isVerificationLoading = false;
      });
    }
  }

  void showVerificationDialog() async {
    await fetchVerificationData();
    setState(() {
      showVerification = true;
    });
    showDialog(
      context: context,
      builder: (context) => MedicineVerificationDialog(
        bookNo: _bookNo,
        verificationData: verificationData,
        isLoading: isVerificationLoading,
        error: verificationError,
        onClose: () {
          setState(() {
            showVerification = false;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MedicalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Medicine Pickup', style: TextStyle(color: Colors.black)),
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
                      child: Text('🏥', style: TextStyle(fontSize: 32)),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(),
                  Text(
                    'Medicine Pickup',
                    style: GoogleFonts.quicksand(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Dispense medicines to patients with ease',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      color: Colors.teal[900],
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _bookNoController,
                    cursorColor: Colors.teal,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Book Number',
                      prefixIcon: Icon(Icons.book, color: Colors.teal[400]),
                    ),
                    enabled: !isLoading,
                  ).animate().fadeIn(duration: 900.ms).slideX(begin: -0.2),
                  const SizedBox(height: 24),
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
                      onPressed: isLoading ? null : fetchPrescription,
                      child: Text(isLoading ? 'Fetching...' : 'Fetch Prescription'),
                    ).animate().scale(duration: 300.ms),
                  ),
                  const SizedBox(height: 16),
                  if (_bookNo.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: StadiumBorder(),
                          elevation: 6,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: isLoading ? null : showVerificationDialog,
                        child: Text(isLoading ? 'Loading...' : 'Verify Medicines'),
                      ).animate().scale(duration: 300.ms),
                    ),
                  // Error popup
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Material(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        child: ListTile(
                          title: Text(error!, style: const TextStyle(color: Colors.red)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => setState(() => error = null),
                            child: const Text('Close'),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 1000.ms),
                  // Success popup
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Material(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                        child: ListTile(
                          title: Text(message!, style: const TextStyle(color: Colors.green)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => setState(() => message = null),
                            child: const Text('Close'),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 1000.ms),
                  // Prescribed Medicines section
                  if (prescribedMeds.isNotEmpty)
                    Form(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Prescribed Medicines',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...prescribedMeds.asMap().entries.map((entry) {
                            final medIndex = entry.key;
                            final med = entry.value;
                            final totalGiven = (med['batches'] as List)
                                .fold<int>(0, (sum, batch) => sum + ((batch['quantity_taken'] ?? 0) as num).toInt());
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: const Color(0xFFE3F2FD),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${med['medicine_id']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Formulation: ${med['medicine_formulation']}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Prescribed Quantity: ${med['quantity']}',
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '(Given: $totalGiven)',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: totalGiven ==
                                                              int.parse(med['quantity'].toString())
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    // Batches
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: (med['batches'] as List)
                                            .asMap()
                                            .entries
                                            .map((batchEntry) {
                                          final batchIndex = batchEntry.key;
                                          final batch = batchEntry.value;
                                          return Container(
                                            width: 180,
                                            margin: const EdgeInsets.only(right: 12),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade300),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Name: ${batch['medicine_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text(
                                                    'Expiry: ${DateTime.tryParse(batch['expiry_date']) != null ? DateTime.parse(batch['expiry_date']).toLocal().toString().split(' ')[0] : batch['expiry_date']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text('Available: ${batch['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 10),
                                                TextFormField(
                                                  decoration: InputDecoration(
                                                    labelText: 'Quantity to Give',
                                                    labelStyle: const TextStyle(color: Colors.black),
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: const BorderSide(color: Colors.black, width: 2),
                                                    ),
                                                  ),
                                                  keyboardType: TextInputType.number,
                                                  enabled: !isLoading,
                                                  initialValue: batch['quantity_taken'] == 0
                                                      ? ''
                                                      : batch['quantity_taken'].toString(),
                                                  onChanged: (value) => handleQuantityChange(
                                                      medIndex, batchIndex, value),
                                                  cursorColor: Colors.teal,
                                                  style: const TextStyle(color: Colors.black),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: StadiumBorder(),
                                elevation: 6,
                              ),
                              onPressed: isLoading ? null : confirmPickup,
                              child: Text(isLoading ? 'Submitting...' : 'Confirm Pickup'),
                            ).animate().scale(duration: 300.ms),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Medicine Verification Dialog Widget
class MedicineVerificationDialog extends StatelessWidget {
  final String bookNo;
  final Map<String, dynamic> verificationData;
  final bool isLoading;
  final String? error;
  final VoidCallback onClose;

  const MedicineVerificationDialog({
    Key? key,
    required this.bookNo,
    required this.verificationData,
    required this.isLoading,
    required this.error,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFE3F2FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Medicine Verification - Book #$bookNo',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Prescribed Medicines Table
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Prescribed Medicines',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const Text('Loading prescribed medicines...')
                else if ((verificationData['medicines_prescribed'] as List).isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        dataRowHeight: 60,
                        headingRowHeight: 50,
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        headingRowColor: MaterialStateProperty.all(Colors.orange),
                        columns: const [
                          DataColumn(
                            label: Flexible(
                              child: Text(
                                'Medicine ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Flexible(
                              child: Text(
                                'Quantity',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Flexible(
                              child: Text(
                                'Schedule',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        rows: (verificationData['medicines_prescribed'] as List)
                            .asMap()
                            .entries
                            .map<DataRow>((entry) {
                          final index = entry.key;
                          final med = entry.value;
                          final schedule = med['dosage_schedule'];
                          String scheduleStr = 'No schedule';
                          if (schedule != null) {
                            scheduleStr =
                                '${schedule['days']} days\n'
                                '${schedule['morning'] == true ? '✓ Morning ' : ''}'
                                '${schedule['afternoon'] == true ? '✓ Afternoon ' : ''}'
                                '${schedule['night'] == true ? '✓ Night' : ''}';
                          }
                          return DataRow(
                            color: MaterialStateProperty.all(
                              index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                            ),
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Flexible(
                                    child: Text(
                                      '${med['medicine_id']}',
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Flexible(
                                    child: Text(
                                      '${med['quantity']}',
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Flexible(
                                    child: Text(
                                      scheduleStr,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  )
                else
                  const Text('No prescribed medicines found'),
                const SizedBox(height: 16),
                // Medicines Given Table
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Medicines Given',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  const Text('Loading medicines given...')
                else if ((verificationData['medicines_given'] as List).isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        dataRowHeight: 50,
                        headingRowHeight: 50,
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        dataTextStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        headingRowColor: MaterialStateProperty.all(Colors.green),
                        columns: const [
                          DataColumn(
                            label: Flexible(
                              child: Text(
                                'Medicine ID',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Flexible(
                              child: Text(
                                'Quantity',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        rows: (verificationData['medicines_given'] as List)
                            .asMap()
                            .entries
                            .map<DataRow>((entry) {
                          final index = entry.key;
                          final med = entry.value;
                          return DataRow(
                            color: MaterialStateProperty.all(
                              index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                            ),
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Flexible(
                                    child: Text(
                                      '${med['medicine_id']}',
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Flexible(
                                    child: Text(
                                      '${med['quantity']}',
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  )
                else
                  const Text('No medicines have been given yet'),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: isLoading ? null : onClose,
                    child: Text(isLoading ? 'Loading...' : 'Close'),
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
