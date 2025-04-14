import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:google_fonts/google_fonts.dart';
import '../provider/inventory_provider.dart';
import '../model/item_model.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedItemName;
  int _quantitySold = 1;
  String _scanResult = 'Scan barcode untuk memilih item';
  bool _isScanning = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pastikan data item dan penjualan dimuat
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    provider.loadItems();
    provider.loadSales();
  }

  Future<void> _scanBarcode() async {
    setState(() => _isScanning = true);
    try {
      final result = await BarcodeScanner.scan(
        options: ScanOptions(
          restrictFormat: [BarcodeFormat.qr], // Fokus ke QR Code
        ),
      );
      debugPrint('Barcode yang discan: ${result.rawContent}');
      setState(() {
        _scanResult = result.rawContent;
        final provider = Provider.of<InventoryProvider>(context, listen: false);
        debugPrint(
            'Daftar barcode: ${provider.items.map((item) => item.barcode)
                .toList()}');
        final matchedItem = provider.items.firstWhere(
              (item) => item.barcode == _scanResult,
          orElse: () => Item(name: null, quantity: 0),
        );
        if (matchedItem.name == null) {
          _scanResult =
          'Item tidak ditemukan. Scan QR Code kustom dari aplikasi.';
          _selectedItemName = null;
        } else {
          _selectedItemName = matchedItem.name;
          _scanResult = 'Item Ditemukan:\n'
              'Nama: ${matchedItem.name}\n'
              'Jumlah: ${matchedItem.quantity}\n'
              'Harga Beli: ${matchedItem.buyPrice}\n'
              'Harga Jual: ${matchedItem.sellPrice}\n'
              'Kategori: ${matchedItem.category}\n'
              'Unit: ${matchedItem.unit}';
        }
      });
    } catch (e) {
      setState(() {
        _scanResult = 'Error: $e';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _recordSale(InventoryProvider provider) async {
    if (_formKey.currentState!.validate() && _selectedItemName != null) {
      setState(() => _isLoading = true);
      try {
        final selectedItem = provider.items.firstWhere(
              (item) => item.name == _selectedItemName,
          orElse: () => throw Exception('Item tidak ditemukan'),
        );

        if (selectedItem.quantity == null ||
            selectedItem.quantity! < _quantitySold) {
          throw Exception(
              'Stok tidak cukup! Sisa stok: ${selectedItem.quantity ?? 0}');
        }

        final totalPrice = (selectedItem.sellPrice ?? 0) * _quantitySold;
        await provider.addSale(_selectedItemName!, _quantitySold, totalPrice, null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penjualan berhasil dicatat!')),
        );
        setState(() {
          _selectedItemName = null;
          _quantitySold = 1;
          _scanResult = 'Scan barcode untuk memilih item';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
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
                          Text(
                            _scanResult,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: _scanResult.startsWith('Error') ||
                                  _scanResult == 'Item tidak ditemukan'
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isScanning ? null : _scanBarcode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFCA28),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
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
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedItemName,
                            decoration: InputDecoration(
                              labelText: 'Item',
                              labelStyle:
                              GoogleFonts.poppins(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                const BorderSide(color: Color(0xFF4CAF50)),
                              ),
                            ),
                            items: provider.items
                                .map((item) => item.name)
                                .toSet() // Hilangkan duplikat
                                .map((name) =>
                                DropdownMenuItem<String>(
                                  value: name,
                                  child: Text("${name}",
                                      style: GoogleFonts.poppins()),
                                ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedItemName = value;
                                _scanResult = 'Item dipilih: $value';
                              });
                            },
                            validator: (value) =>
                            value == null ? 'Pilih item' : null,
                            hint: Text('Pilih Item',
                                style: GoogleFonts.poppins()),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _quantitySold.toString(),
                            decoration: InputDecoration(
                              labelText: 'Jumlah Terjual',
                              labelStyle:
                              GoogleFonts.poppins(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                const BorderSide(color: Color(0xFF4CAF50)),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _quantitySold = int.tryParse(value) ?? 1;
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
                                  : () => _recordSale(provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                'Simpan Penjualan',
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
              if (_isLoading)
                Center(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Lottie.asset(
                        'assets/loading.json',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
