// lib/model/sale_model.dart
class Sale {
  final String? itemName; // Nama barang yang dijual
  final int? quantitySold; // Jumlah yang terjual
  final double? totalPrice; // Total harga penjualan
  final DateTime? date; // Tanggal penjualan
  final String? docId; // ID dokumen Firestore (opsional, buat hapus)

  Sale({
    this.itemName,
    this.quantitySold,
    this.totalPrice,
    this.date,
    this.docId,
  });

  Map<String, dynamic> toMap() {
    return {
      'item_name': itemName,
      'quantity_sold': quantitySold,
      'total_price': totalPrice,
      'date': date?.toIso8601String(), // Simpan tanggal dalam format ISO8601
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Sale(
      itemName: map['item_name'] as String?,
      quantitySold: map['quantity_sold'] as int?,
      totalPrice: (map['total_price'] as num?)?.toDouble(),
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      docId: docId, // Tambah docId dari Firestore
    );
  }
}