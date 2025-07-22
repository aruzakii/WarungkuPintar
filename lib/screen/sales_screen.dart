import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import '../provider/inventory_provider.dart';
import '../model/item_model.dart';
import 'dart:async';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _selectedItemName;
  int _quantitySold = 1;
  String _scanResult = 'Scan barcode untuk memilih item';
  bool _isScanning = false;
  bool _isLoading = false;

  // Warna dari tema aplikasi dengan latar belakang putih solid
  final Color primaryColor = const Color(0xFF6366F1); // Indigo
  final Color secondaryColor = const Color(0xFF14B8A6); // Teal
  final Color accentColor = const Color(0xFFEC4899); // Pink
  final Color backgroundColor = const Color(0xFFFFFFFF); // White solid

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    provider.loadItems();
    provider.loadSales();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    setState(() => _isScanning = true);
    try {
      final result = await BarcodeScanner.scan(
        options: const ScanOptions(
          restrictFormat: [BarcodeFormat.qr],
        ),
      );
      setState(() {
        _scanResult = result.rawContent;
        final provider = Provider.of<InventoryProvider>(context, listen: false);
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
          _scanResult =
          'Item Ditemukan:\n'
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
        print('Record Sale triggered, item: $_selectedItemName, quantity: $_quantitySold');
        final selectedItem = provider.items.firstWhere(
              (item) => item.name == _selectedItemName,
          orElse: () => throw Exception('Item tidak ditemukan'),
        );

        if (selectedItem.quantity == null ||
            selectedItem.quantity! < _quantitySold) {
          throw Exception(
            'Stok tidak cukup! Sisa stok: ${selectedItem.quantity ?? 0}',
          );
        }

        final totalPrice = (selectedItem.sellPrice ?? 0) * _quantitySold;
        await provider.addSale(
          _selectedItemName!,
          _quantitySold,
          totalPrice,
          null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Penjualan berhasil dicatat!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: secondaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() {
          _selectedItemName = null;
          _quantitySold = 1;
          _scanResult = 'Scan barcode untuk memilih item';
        });
      } catch (e) {
        print('Error in recordSale: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      print('Validation failed or _selectedItemName is null');
    }
  }

  Future<void> _downloadSalesReport(InventoryProvider provider) async {
    setState(() => _isLoading = true);
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Laporan Penjualan'];

      sheet.appendRow([
        TextCellValue('No'),
        TextCellValue('Nama Item'),
        TextCellValue('Jumlah Terjual'),
        TextCellValue('Harga Jual'),
        TextCellValue('Total Harga'),
        TextCellValue('Tanggal'),
      ]);

      for (int i = 0; i < provider.sales.length; i++) {
        final sale = provider.sales[i];
        final item = provider.items.firstWhere(
              (item) => item.name == sale.itemName,
          orElse: () => Item(sellPrice: 0.0),
        );
        sheet.appendRow([
          TextCellValue((i + 1).toString()),
          TextCellValue(sale.itemName ?? ''),
          TextCellValue(sale.quantitySold?.toString() ?? '0'),
          TextCellValue(item.sellPrice?.toStringAsFixed(2) ?? '0.00'),
          TextCellValue(sale.totalPrice?.toStringAsFixed(2) ?? '0.00'),
          TextCellValue(sale.date?.toIso8601String().substring(0, 10) ?? ''),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final now = DateTime.now();
        final fileName = 'laporan_penjualan_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';
        await FileSaver.instance.saveAs(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Laporan berhasil diunduh sebagai $fileName',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        throw Exception('Gagal menghasilkan file Excel');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saat mengunduh laporan: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        return Container(
          height: MediaQuery.of(context).size.height,
          color: backgroundColor, // Putih solid untuk seluruh layar
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Catat Penjualan',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _scanResult,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: _scanResult.startsWith('Error') ||
                                              _scanResult ==
                                                  'Item tidak ditemukan. Scan QR Code kustom dari aplikasi.'
                                              ? accentColor
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _isScanning ? null : _scanBarcode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 24,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(
                                        color: secondaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: _isScanning
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Text(
                                      'Scan Barcode',
                                      style: GoogleFonts.poppins(
                                        color: secondaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                  value: _selectedItemName,
                                  decoration: InputDecoration(
                                    labelText: 'Item',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                  ),
                                  dropdownColor: Colors.white,
                                  items: provider.items
                                      .map((item) => item.name)
                                      .toSet()
                                      .map(
                                        (name) => DropdownMenuItem<String>(
                                      value: name,
                                      child: Text(name ?? ''),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedItemName = value;
                                      _scanResult = 'Item dipilih: $value';
                                    });
                                  },
                                  validator: (value) =>
                                  value == null ? 'Pilih item' : null,
                                  hint: Text(
                                    'Pilih Item',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  initialValue: _quantitySold.toString(),
                                  decoration: InputDecoration(
                                    labelText: 'Jumlah Terjual',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
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
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed:
                                      _isLoading ? null : () => _recordSale(provider),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 24,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        side: BorderSide(
                                          color: secondaryColor,
                                          width: 2,
                                        ),
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
                                        'Simpan Penjualan',
                                        style: GoogleFonts.poppins(
                                          color: secondaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: ElevatedButton(
                                    onPressed:
                                    _isLoading ? null : () => _downloadSalesReport(provider),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 24,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      side: BorderSide(
                                        color: primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      'Download Excel',
                                      style: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_isLoading)
                Center(
                  child: Lottie.asset(
                    'assets/loading.json',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}