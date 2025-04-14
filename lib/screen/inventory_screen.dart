import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../provider/inventory_provider.dart';
import '../model/item_model.dart';
import '../services/ai_service.dart';
import 'inventory_detail_screen.dart';
import 'dart:async';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  String? _selectedCategory;
  String? _selectedUnit;
  Timer? _debounce;
  bool _showForm = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Sembako',
    'Minuman',
    'Makanan',
    'Kebutuhan Pribadi',
    'Kantor',
    'Lainnya'
  ];

  final List<String> _units = ['Liter (L)', 'Kilogram (kg)', 'Pcs/Buah'];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<InventoryProvider>(context, listen: false);

    provider.loadItems();
    provider.loadSales();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final name = _nameController.text;
      if (name.isNotEmpty) {
        final predictedCategory = await AIService.predictCategory(name);
        final normalizedCategory = _categories.contains(predictedCategory)
            ? predictedCategory
            : 'Lainnya';
        setState(() {
          _selectedCategory = normalizedCategory;
        });
      }
    });
  }

  void _submitForm(InventoryProvider provider) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
        );
        return;
      }
      if (_selectedUnit == null || _selectedUnit!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih satuan terlebih dahulu')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await provider.addItem(
          _nameController.text,
          int.parse(_quantityController.text),
          double.parse(_buyPriceController.text),
          double.parse(_sellPriceController.text),
          _selectedCategory!,
          _selectedUnit!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang ditambahkan!')),
        );
        _nameController.clear();
        _quantityController.clear();
        _buyPriceController.clear();
        _sellPriceController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedUnit = null;
          _showForm = false;
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
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
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              SafeArea(
                child: Container(
                  color: Colors.white,
                  child: _showForm
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              16.0, 16.0, 16.0, 100.0),
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
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Nama Barang',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF4CAF50)),
                                        ),
                                      ),
                                      validator: (value) => value!.isEmpty
                                          ? 'Nama wajib diisi'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _quantityController,
                                      decoration: InputDecoration(
                                        labelText: 'Jumlah',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF4CAF50)),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) => value!.isEmpty
                                          ? 'Jumlah wajib diisi'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: _selectedUnit,
                                      decoration: InputDecoration(
                                        labelText: 'Satuan',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF4CAF50)),
                                        ),
                                      ),
                                      items: _units.map((unit) {
                                        return DropdownMenuItem<String>(
                                          value: unit,
                                          child: Text(unit,
                                              style: GoogleFonts.poppins()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedUnit = value;
                                        });
                                      },
                                      validator: (value) => value == null
                                          ? 'Satuan wajib dipilih'
                                          : null,
                                      hint: Text('Pilih Satuan',
                                          style: GoogleFonts.poppins()),
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _buyPriceController,
                                      decoration: InputDecoration(
                                        labelText: 'Harga Beli',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF4CAF50)),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) => value!.isEmpty
                                          ? 'Harga beli wajib diisi'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _sellPriceController,
                                      decoration: InputDecoration(
                                        labelText: 'Harga Jual',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF4CAF50)),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) => value!.isEmpty
                                          ? 'Harga jual wajib diisi'
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: _selectedCategory,
                                      decoration: InputDecoration(
                                        labelText:
                                            'Kategori (Otomatis/Pilih Manual)',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF4CAF50)),
                                        ),
                                      ),
                                      items: _categories.map((category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(category,
                                              style: GoogleFonts.poppins()),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategory = value;
                                        });
                                      },
                                      validator: (value) => value == null
                                          ? 'Kategori wajib dipilih'
                                          : null,
                                      hint: Text('Pilih Kategori',
                                          style: GoogleFonts.poppins()),
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => _submitForm(provider),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF4CAF50),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14, horizontal: 24),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                'Tambah Barang',
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
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: provider.items.length,
                          itemBuilder: (context, index) {
                            final item = provider.items[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12.0),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          InventoryDetailScreen(item: item),
                                    ),
                                  );
                                },
                                title: Text(
                                  item.name ?? '',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  'Jumlah: ${item.quantity ?? 0} ${item.unit ?? "Pcs/Buah"} | Harga Jual: Rp ${item.sellPrice?.toStringAsFixed(0) ?? 0} | Kategori: ${item.category ?? "lainnya"}\nPrediksi: ${item.stockPrediction ?? "Belum diprediksi"}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    if (item.docId != null) {
                                      provider.deleteItem(item.docId!);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'ID dokumen tidak ditemukan')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFFFCA28),
            onPressed: () {
              setState(() {
                _showForm = !_showForm;
              });
            },
            child: Icon(
              _showForm ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
