import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart'; // Opsional, buat animasi loading
import 'login_screen.dart';
import 'main_screen.dart'; // Impor MainScreen buat navigasi
import 'package:confetti/confetti.dart'; // Opsional, buat efek particle

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late ConfettiController _confettiController; // Buat efek particle

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 500), // Kurangin durasi buat performa
    );
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
    _confettiController = ConfettiController(
        duration: const Duration(seconds: 2)); // Inisialisasi particle
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Simpan user.uid sebagai token di SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', userCredential.user!.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Selamat Datang',
                textAlign: TextAlign.center),
            backgroundColor: Colors.green,
          ),
        );
        _confettiController.play(); // Efek particle saat sukses
        await Future.delayed(const Duration(seconds: 2)); // Tunggu efek
        // Navigasi ke MainScreen tanpa arrow back, reset stack navigasi
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false, // Remove semua route sebelumnya
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // Menyesuaikan layout saat keyboard muncul
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
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
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        32, // Sesuain dengan padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Logo kecil, bulat, dengan animasi fade-in
                      FadeTransition(
                        opacity: _animation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            'assets/logo_warungkupintar.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.black,
                                child: Icon(Icons.store,
                                    size: 50, color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'WarungkuPintar',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          shadows: [
                            Shadow(
                              color: Colors.yellow.withOpacity(0.5),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Form register dengan card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.green.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          // Kurangin padding buat performa
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Email
                                FadeTransition(
                                  opacity: _animation,
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.email,
                                          color: Colors.green),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.green, width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      fillColor: Colors.grey[100],
                                      filled: true,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) => value!.isEmpty
                                        ? 'Email wajib diisi'
                                        : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value)
                                            ? 'Email tidak valid'
                                            : null,
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Password
                                FadeTransition(
                                  opacity: _animation,
                                  child: TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.lock,
                                          color: Colors.green),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.green, width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      fillColor: Colors.grey[100],
                                      filled: true,
                                    ),
                                    obscureText: true,
                                    validator: (value) => value!.isEmpty
                                        ? 'Password wajib diisi'
                                        : value.length < 6
                                            ? 'Password minimal 6 karakter'
                                            : null,
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Konfirmasi Password
                                FadeTransition(
                                  opacity: _animation,
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    decoration: InputDecoration(
                                      labelText: 'Konfirmasi Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.lock,
                                          color: Colors.green),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.green, width: 2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      fillColor: Colors.grey[100],
                                      filled: true,
                                    ),
                                    obscureText: true,
                                    validator: (value) => value!.isEmpty
                                        ? 'Konfirmasi password wajib diisi'
                                        : value != _passwordController.text
                                            ? 'Password tidak cocok'
                                            : null,
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _isLoading
                                    ? Lottie.asset(
                                        'assets/loading.json',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ) // Ganti Lottie dengan CircularProgressIndicator buat performa
                                    : ElevatedButton(
                                        onPressed: _register,
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size(double.infinity, 50),
                                          backgroundColor: Colors.yellow,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 4,
                                          animationDuration:
                                              const Duration(milliseconds: 200),
                                        ).merge(
                                          ButtonStyle(
                                            overlayColor:
                                                MaterialStateProperty.all(Colors
                                                    .green
                                                    .withOpacity(0.2)),
                                          ),
                                        ),
                                        child: Text(
                                          'Daftar',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            const LoginScreen(),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          const begin =
                                              Offset(-1.0, 0.0); // Dari kiri
                                          const end = Offset.zero;
                                          const curve = Curves.easeInOut;
                                          var tween = Tween(
                                                  begin: begin, end: end)
                                              .chain(CurveTween(curve: curve));
                                          var offsetAnimation =
                                              animation.drive(tween);
                                          return SlideTransition(
                                            position: offsetAnimation,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sudah punya akun? Login',
                                    style: GoogleFonts.poppins(
                                      color: Colors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Efek particle (opsional)
          if (_isLoading ||
              _confettiController.state == ConfettiControllerState.playing)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 10,
              // Kurangin buat performa
              gravity: 0.05,
              colors: const [Colors.yellow, Colors.green],
            ),
        ],
      ),
    );
  }
}
