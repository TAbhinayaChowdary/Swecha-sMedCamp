import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DoctorPrescriptionPage extends StatefulWidget {
  const DoctorPrescriptionPage({super.key});

  @override
  State<DoctorPrescriptionPage> createState() => _DoctorPrescriptionPageState();
}

class _DoctorPrescriptionPageState extends State<DoctorPrescriptionPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bookNoController = TextEditingController();
  List<_PrescriptionItem> _items = [_PrescriptionItem()];
  String? _successMessage;
  String? _errorMessage;

  // Replace with your backend base URL
  final String _baseUrl = 'http://192.168.71.211:5002/api'; // <-- CHANGE THIS TO YOUR BACKEND IP

  @override
  void dispose() {
    _bookNoController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_PrescriptionItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      if (_items.length > 1) {
        _items[index].dispose();
        _items.removeAt(index);
      }
    });
  }

  Future<void> _fetchMedicineInfo(_PrescriptionItem item) async {
    final id = item.medicineIdController.text.trim();
    if (id.isEmpty) {
      setState(() { item.medicineInfo = null; });
      return;
    }
    try {
      final response = await http.get(Uri.parse('$_baseUrl/inventory/$id'));
      if (response.statusCode == 200) {
        final med = json.decode(response.body);
        setState(() { item.medicineInfo = med; });
      } else {
        setState(() { item.medicineInfo = null; });
      }
    } catch (e) {
      setState(() { item.medicineInfo = null; });
    }
  }

  void _onMedicineIdChanged(_PrescriptionItem item) {
    _fetchMedicineInfo(item);
  }

  void _submit() async {
    setState(() { _successMessage = null; _errorMessage = null; });
    if (_formKey.currentState?.validate() ?? false) {
      final bookNo = _bookNoController.text.trim();
      final List prescriptions = _items.map((item) {
        if (item.tabIndex == 0) {
          // By Dosing Schedule
          return {
            'medicine_id': item.medicineIdController.text.trim(),
            'days': item.daysController.text.trim(),
            'morning': item.morning,
            'afternoon': item.afternoon,
            'night': item.night,
            'quantity': item.calculatedQuantity,
          };
        } else {
          // By Quantity
          return {
            'medicine_id': item.medicineIdController.text.trim(),
            'quantity': int.tryParse(item.quantityController.text.trim()) ?? 0,
          };
        }
      }).toList();
      try {
        print('Posting to: ${_baseUrl}/patient-history/doctor-prescription');
        final response = await http.post(
          Uri.parse('$_baseUrl/patient-history/doctor-prescription'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'book_no': bookNo,
            'prescriptions': prescriptions,
          }),
        );
        if (response.statusCode == 200) {
          setState(() { _successMessage = 'Prescription submitted successfully!'; });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFFE3F2FD),
              content: const Text('Prescription submitted successfully!'),
              actions: [
                ElevatedButton(
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
          setState(() {
            for (final item in _items) {
              item.dispose();
            }
            _items = [_PrescriptionItem()];
            _bookNoController.clear();
          });
        } else {
          final resp = json.decode(response.body);
          setState(() { _errorMessage = resp['message'] ?? 'Failed to submit prescription'; });
        }
      } catch (e) {
        setState(() { _errorMessage = 'Network error'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MedicalGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Doctor Prescription', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
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
                      child: Text('💊', style: TextStyle(fontSize: 32)),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(),
                  Text(
                    'Doctor Prescription',
                    style: GoogleFonts.quicksand(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Prescribe medicines and dosages for patients',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      color: Colors.teal[900],
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                  const SizedBox(height: 24),
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
                    ).animate().fadeIn(duration: 1000.ms),
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
                    ).animate().fadeIn(duration: 1000.ms),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _bookNoController,
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
                        ..._items.asMap().entries.map((entry) {
                          int index = entry.key;
                          _PrescriptionItem item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.teal[100]!),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ToggleButtons(
                                        isSelected: [item.tabIndex == 0, item.tabIndex == 1],
                                        onPressed: (tabIdx) {
                                          setState(() {
                                            item.tabIndex = tabIdx;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        selectedColor: Colors.white,
                                        fillColor: Colors.blue,
                                        color: Colors.blue,
                                        constraints: const BoxConstraints(minHeight: 50.0, minWidth: 120.0),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                            child: Text(
                                              'By Dosing\nSchedule',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                            child: Text(
                                              'By\nQuantity',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (item.tabIndex == 0) ...[
                                    TextFormField(
                                      controller: item.medicineIdController,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        labelText: 'Medicine ID',
                                        prefixIcon: Icon(Icons.medication, color: Colors.teal[400]),
                                      ),
                                      cursorColor: Colors.teal,
                                      validator: (value) => value == null || value.isEmpty
                                          ? 'Enter Medicine ID'
                                          : null,
                                      onChanged: (_) => _onMedicineIdChanged(item),
                                    ),
                                    if (item.medicineInfo != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Formulation: ${item.medicineInfo!['medicine_formulation'] ?? ''}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                            ),
                                            if (item.medicineInfo!['details'] != null)
                                              ...List.generate(
                                                (item.medicineInfo!['details'] as List).length,
                                                (i) {
                                                  final detail = item.medicineInfo!['details'][i];
                                                  return Padding(
                                                    padding: const EdgeInsets.only(left: 8.0),
                                                    child: Text(
                                                      '${detail['medicine_name']} — Qty: ${detail['quantity']} — Exp: ${detail['expiry_date'].toString().split('T')[0]}',
                                                      style: const TextStyle(color: Colors.black),
                                                    ),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: item.daysController,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        labelText: 'Days',
                                        prefixIcon: Icon(Icons.calendar_today, color: Colors.teal[400]),
                                      ),
                                      cursorColor: Colors.teal,
                                      validator: (value) => value == null || value.isEmpty
                                          ? 'Enter Days'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CheckboxListTile(
                                          title: const Text('Morning', style: TextStyle(color: Colors.black)),
                                          value: item.morning,
                                          onChanged: (val) => setState(() => item.morning = val ?? false),
                                          controlAffinity: ListTileControlAffinity.leading,
                                          activeColor: const Color(0xFF007BFF),
                                        ),
                                        CheckboxListTile(
                                          title: const Text('Afternoon', style: TextStyle(color: Colors.black)),
                                          value: item.afternoon,
                                          onChanged: (val) => setState(() => item.afternoon = val ?? false),
                                          controlAffinity: ListTileControlAffinity.leading,
                                          activeColor: const Color(0xFF007BFF),
                                        ),
                                        CheckboxListTile(
                                          title: const Text('Night', style: TextStyle(color: Colors.black)),
                                          value: item.night,
                                          onChanged: (val) => setState(() => item.night = val ?? false),
                                          controlAffinity: ListTileControlAffinity.leading,
                                          activeColor: const Color(0xFF007BFF),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Calculated Quantity: ${item.calculatedQuantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                  ] else ...[
                                    TextFormField(
                                      controller: item.medicineIdController,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        labelText: 'Medicine ID',
                                        prefixIcon: Icon(Icons.medication, color: Colors.teal[400]),
                                      ),
                                      cursorColor: Colors.teal,
                                      validator: (value) => value == null || value.isEmpty
                                          ? 'Enter Medicine ID'
                                          : null,
                                      onChanged: (_) => _onMedicineIdChanged(item),
                                    ),
                                    if (item.medicineInfo != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Item: ${item.medicineInfo!['medicine_name'] ?? ''}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                            ),
                                            if (item.medicineInfo!['details'] != null)
                                              ...List.generate(
                                                (item.medicineInfo!['details'] as List).length,
                                                (i) {
                                                  final detail = item.medicineInfo!['details'][i];
                                                  return Padding(
                                                    padding: const EdgeInsets.only(left: 8.0),
                                                    child: Text(
                                                      '${detail['medicine_name']} — Qty: ${detail['quantity']} — Exp: ${detail['expiry_date'].toString().split('T')[0]}',
                                                      style: const TextStyle(color: Colors.black),
                                                    ),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: item.quantityController,
                                      style: const TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        labelText: 'Quantity',
                                        prefixIcon: Icon(Icons.numbers, color: Colors.teal[400]),
                                      ),
                                      cursorColor: Colors.teal,
                                      validator: (value) => value == null || value.isEmpty
                                          ? 'Enter quantity'
                                          : null,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(48),
                                      shape: StadiumBorder(),
                                      elevation: 6,
                                    ),
                                    onPressed: () => _removeItem(index),
                                    child: const Text('Remove'),
                                  ).animate().scale(duration: 200.ms),
                                ],
                              ),
                            ),
                          );
                        }),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[400],
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: StadiumBorder(),
                            elevation: 6,
                          ),
                          onPressed: _addItem,
                          child: const Text('Add Item'),
                        ).animate().scale(duration: 200.ms),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[500],
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: StadiumBorder(),
                            elevation: 6,
                          ),
                          onPressed: _submit,
                          child: const Text('Submit Prescription'),
                        ).animate().scale(duration: 300.ms),
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

class _PrescriptionItem {
  final TextEditingController medicineIdController = TextEditingController();
  final TextEditingController daysController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  bool morning = false;
  bool afternoon = false;
  bool night = false;
  Map? medicineInfo;
  int tabIndex = 0;

  void dispose() {
    medicineIdController.dispose();
    daysController.dispose();
    quantityController.dispose();
  }

  int get calculatedQuantity {
    int days = int.tryParse(daysController.text) ?? 0;
    int times = (morning ? 1 : 0) + (afternoon ? 1 : 0) + (night ? 1 : 0);
    return days * times;
  }
}
