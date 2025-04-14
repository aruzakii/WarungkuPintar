import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/cashier_model.dart';
import '../services/firestore_service.dart';

class ManageCashiersScreen extends StatefulWidget {
  const ManageCashiersScreen({super.key});

  @override
  State<ManageCashiersScreen> createState() => _ManageCashiersScreenState();
}

class _ManageCashiersScreenState extends State<ManageCashiersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  List<Cashier> _cashiers = [];

  @override
  void initState() {
    super.initState();
    _loadCashiers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadCashiers() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.getCashiers(user.uid).listen((cashiers) {
        setState(() {
          _cashiers = cashiers;
        });
      });
    }
  }

  Future<void> _addCashier() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      final cashier = Cashier(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        ownerId: user.uid,
        // Simpan ownerId
        createdAt: DateTime.now(),
      );

      try {
        await _firestoreService.createCashier(cashier);
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun kasir berhasil ditambahkan')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah akun kasir: $e')),
        );
      }
    }
  }

  Future<void> _deleteCashier(String docId) async {
    try {
      await _firestoreService.deleteCashier(docId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun kasir berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus akun kasir: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Akun Kasir',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFCA28),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Kasir',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Kasir',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.isEmpty
                            ? 'Email wajib diisi'
                            : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value)
                                ? 'Email tidak valid'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) =>
                            value!.isEmpty ? 'Password wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addCashier,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Tambah Kasir',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Daftar Kasir',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _cashiers.isEmpty
                  ? const Center(child: Text('Belum ada akun kasir'))
                  : ListView.builder(
                      itemCount: _cashiers.length,
                      itemBuilder: (context, index) {
                        final cashier = _cashiers[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(cashier.name),
                            subtitle: Text(cashier.email),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCashier(cashier.docId!),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
