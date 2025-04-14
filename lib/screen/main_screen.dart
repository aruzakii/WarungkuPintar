import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umkm_smart_assistant/screen/sales_screen.dart';
import '../provider/inventory_provider.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'login_screen.dart';
import 'manage_cashiers_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    InventoryScreen(),
    SalesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out dari Firebase
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token'); // Hapus token dari SharedPreferences
      // Navigasi manual ke LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(
              left: 7.0, right: 2.0, top: 7.0, bottom: 7.0),
          // Margin di semua sisi (8.0 adalah contoh, bisa disesuaikan)
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              'assets/logo_warungkupintar.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.store, size: 50, color: Colors.white),
                );
              },
            ),
          ),
        ),
        title: Text(
          'WarungkuPintar',
          style: GoogleFonts.poppins(
            fontSize: 20,
            // Sedikit lebih besar untuk visibilitas
            fontWeight: FontWeight.bold,
            color: Colors.white,
            // Ubah warna teks menjadi putih agar kontras dengan gradient
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                // Ubah warna shadow agar lebih subtle
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFCA28), // Kuning
                Color(0xFF4CAF50), // Hijau
              ],
            ),
          ),
        ),
        elevation: 4,
        // Tambah elevation untuk efek shadow yang lebih menonjol
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add,
              color: Colors.yellow,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageCashiersScreen()),
              );
            },
            tooltip: 'Kelola Akun Kasir',
          ),
          IconButton(
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.red, // Ubah warna ikon menjadi putih agar kontras
            ),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'Sales',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        // Warna hijau untuk item terpilih
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        onTap: _onItemTapped,
      ),
    );
  }
}
