import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:lottie/lottie.dart';
import '../provider/inventory_provider.dart';
import '../model/item_model.dart';
import 'login_screen.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedItemName;
  int _quantitySold = 1;
  bool _isScanning = false;
  bool _isLoading = false;
  String? _cashierName;
  String? _ownerId;
  List<Map<String, dynamic>> _cart = [];
  double _totalPrice = 0;
  final _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _loadCashierData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadCashierData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cashierName = prefs.getString('cashier_name') ?? 'Kasir';
      _ownerId = prefs.getString('owner_id');
    });
    if (_ownerId != null) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      provider.loadItemsForOwner(_ownerId!);
      provider.loadSalesForOwner(_ownerId!);
    }
  }

  Future<void> _scanBarcode() async {
    setState(() => _isScanning = true);
    try {
      final result = await BarcodeScanner.scan(
        options: const ScanOptions(
          restrictFormat: [BarcodeFormat.qr],
        ),
      );
      debugPrint('Barcode yang discan: ${result.rawContent}');
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final matchedItem = provider.items.firstWhere(
        (item) => item.barcode == result.rawContent,
        orElse: () => Item(
          name: null,
          quantity: 0,
          buyPrice: 0,
          sellPrice: 0,
          barcode: '',
          category: '',
          stockPrediction: '',
          unit: '',
        ),
      );
      if (matchedItem.name == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item tidak ditemukan')),
        );
      } else {
        setState(() {
          _selectedItemName = matchedItem.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _addToCart(InventoryProvider provider) {
    if (_formKey.currentState!.validate() && _selectedItemName != null) {
      final selectedItem = provider.items.firstWhere(
        (item) => item.name == _selectedItemName,
        orElse: () => throw Exception('Item tidak ditemukan'),
      );

      if (selectedItem.quantity == null ||
          selectedItem.quantity! < _quantitySold) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Stok tidak cukup! Sisa stok: ${selectedItem.quantity ?? 0}'),
          ),
        );
        return;
      }

      final price = (selectedItem.sellPrice ?? 0) * _quantitySold;
      setState(() {
        _cart.add({
          'item': selectedItem,
          'quantity': _quantitySold,
          'price': price,
        });
        _totalPrice += price;
        _selectedItemName = null;
        _quantitySold = 1;
        _quantityController.text = '1';
      });
    }
  }

  Future<void> _processTransaction(InventoryProvider provider) async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      for (var cartItem in _cart) {
        final item = cartItem['item'] as Item;
        final quantity = cartItem['quantity'] as int;
        final price = cartItem['price'] as double;
        await provider.addSale(item.name!, quantity, price, _ownerId);
      }
      setState(() {
        _cart.clear();
        _totalPrice = 0;
        _selectedItemName = null;
        _quantitySold = 1;
        _quantityController.text = '1';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses transaksi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cashier_id');
    await prefs.remove('cashier_name');
    await prefs.remove('owner_id');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventoryProvider>(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Mencegah resize saat keyboard muncul
      extendBodyBehindAppBar: true,
      // Membuat body memanjang di belakang app bar
      appBar: AppBar(
        title: Text(
          'Kasir - $_cashierName',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent, // Membuat app bar transparan
        elevation: 0, // Menghilangkan bayangan app bar
        actions: [
          IconButton(
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.red,
            ),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
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
          child: Column(
            children: [
              // Bagian input dan keranjang dalam SingleChildScrollView
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Bagian input (Scan Barcode, Pilih Item, Jumlah)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Color(0xFFFFCA28),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        _isScanning ? null : _scanBarcode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFCA28),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 20),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      elevation: 4,
                                    ),
                                    child: _isScanning
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Scan Barcode',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedItemName,
                                    decoration: InputDecoration(
                                      labelText: 'Item',
                                      labelStyle: GoogleFonts.poppins(
                                          color: Colors.grey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF4CAF50),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: provider.items
                                        .map((item) => item.name)
                                        .toSet()
                                        .map((name) => DropdownMenuItem<String>(
                                              value: name,
                                              child: Text(
                                                "${name} (Stok: ${provider.items.firstWhere((item) => item.name == name).quantity})",
                                                style: GoogleFonts.poppins(),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedItemName = value;
                                      });
                                    },
                                    validator: (value) =>
                                        value == null ? 'Pilih item' : null,
                                    hint: Text('Pilih Item',
                                        style: GoogleFonts.poppins()),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _quantityController,
                                    decoration: InputDecoration(
                                      labelText: 'Jumlah Terjual',
                                      labelStyle: GoogleFonts.poppins(
                                          color: Colors.grey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF4CAF50),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      setState(() {
                                        _quantitySold =
                                            int.tryParse(value) ?? 1;
                                      });
                                    },
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Masukkan jumlah'
                                            : null,
                                  ),
                                  const SizedBox(height: 24),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _addToCart(provider),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF4CAF50),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 24),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        'Tambah ke Keranjang',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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

                      // Bagian Keranjang (yang bisa di-scroll)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          'Keranjang',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _cart.isEmpty
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20.0),
                              child: Center(
                                child: Text(
                                  'Keranjang kosong',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.3,
                                ),
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _cart.length,
                                  itemBuilder: (context, index) {
                                    final cartItem = _cart[index];
                                    final item = cartItem['item'] as Item;
                                    final quantity =
                                        cartItem['quantity'] as int;
                                    final price = cartItem['price'] as double;
                                    return Card(
                                      elevation: 4,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          item.name!,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Jumlah: $quantity - Harga: Rp ${price.toStringAsFixed(0)}',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _totalPrice -= price;
                                              _cart.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),

              // Bagian Total Harga dan Tombol (Fixed di Bawah)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Harga: Rp ${_totalPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _processTransaction(provider),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFFFFCA28),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Proses Transaksi',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
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
  }
}
