// lib/model/item_model.dart
class Item {
  final String? docId;
  final String? name;
  final int? quantity;
  final double? buyPrice;
  final double? sellPrice;
  final String? barcode;
  final String? category;
  final String? prediction;
  final String? stockPrediction;
  final String? imageUrl;
  final String? unit; // Tambah field buat satuan (contoh: "Liter (L)", "Kilogram (kg)", "Pcs/Buah")
  // final String? barcodePath;

  Item({
    this.docId,
    this.name,
    this.quantity,
    this.buyPrice,
    this.sellPrice,
    this.barcode,
    this.category,
    this.prediction,
    this.stockPrediction,
    this.imageUrl,
    this.unit, // Tambah parameter unit
    // this.barcodePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'barcode': barcode,
      'category': category ?? 'lainnya',
      'prediction': prediction ?? 'Belum diprediksi',
      'stock_prediction': stockPrediction,
      'image_url': imageUrl,
      'unit': unit ?? 'Pcs/Buah', // Default ke "Pcs/Buah" kalau null
      // 'barcode_path': barcodePath,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Item(
      docId: docId,
      name: map['name'] as String?,
      quantity: map['quantity'] as int?,
      buyPrice: (map['buy_price'] as num?)?.toDouble(),
      sellPrice: (map['sell_price'] as num?)?.toDouble(),
      barcode: map['barcode'] as String?,
      category: map['category'] as String?,
      prediction: map['prediction'] as String?,
      stockPrediction: map['stock_prediction'] as String?,
      imageUrl: map['image_url'] as String?,
      unit: map['unit'] as String?, // Ambil satuan dari Firestore
      // barcodePath: map['barcode_path'] as String?,
    );
  }
}