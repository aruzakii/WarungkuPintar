import 'package:cloud_firestore/cloud_firestore.dart';

class Cashier {
  final String? docId;
  final String email;
  final String password;
  final String name;
  final String ownerId; // Tambah field ownerId
  final DateTime createdAt;

  Cashier({
    this.docId,
    required this.email,
    required this.password,
    required this.name,
    required this.ownerId, // Tambah parameter ownerId
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'ownerId': ownerId, // Simpan ownerId
      'createdAt': createdAt,
    };
  }

  factory Cashier.fromMap(Map<String, dynamic> map, String docId) {
    return Cashier(
      docId: docId,
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '', // Ambil ownerId
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}