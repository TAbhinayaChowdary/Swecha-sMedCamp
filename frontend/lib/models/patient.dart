class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String phone;
  final String? address;
  final String? emergencyContact;
  final DateTime registrationDate;
  final String? assignedDoctor;
  final String status; // 'waiting', 'in-progress', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.phone,
    this.address,
    this.emergencyContact,
    required this.registrationDate,
    this.assignedDoctor,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      phone: json['phone'],
      address: json['address'],
      emergencyContact: json['emergencyContact'],
      registrationDate: DateTime.parse(json['registrationDate']),
      assignedDoctor: json['assignedDoctor'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'phone': phone,
      'address': address,
      'emergencyContact': emergencyContact,
      'registrationDate': registrationDate.toIso8601String(),
      'assignedDoctor': assignedDoctor,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 