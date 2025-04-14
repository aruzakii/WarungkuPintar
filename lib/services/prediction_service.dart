// lib/services/prediction_service.dart
import 'package:intl/intl.dart';
import '../model/item_model.dart';
import '../model/sale_model.dart';

class PredictionService {
  static String predictStockExhaustion(Item item, List<Sale> sales) {
    if (item.quantity == null || item.quantity! <= 0) {
      return 'Stok Habis Sekarang';
    }

    // Hitung rata-rata penjualan harian (7 hari terakhir)
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentSales = sales.where((sale) =>
    sale.date != null &&
        sale.date!.isAfter(sevenDaysAgo) &&
        sale.itemName == item.name &&
        sale.quantitySold != null).toList();

    if (recentSales.isEmpty) {
      return 'Stok Aman (Tidak Ada Penjualan Terbaru)';
    }

    final totalSold = recentSales.fold(0, (total, sale) => total + sale.quantitySold!);
    final days = 7; // 7 hari terakhir
    final averageDailySales = totalSold / days;

    if (averageDailySales <= 0) {
      return 'Stok Aman (Tidak Ada Penjualan)';
    }

    // Hitung hari sampai stok habis
    final daysToExhaust = item.quantity! / averageDailySales;
    final exhaustDate = now.add(Duration(days: daysToExhaust.round()));

    return 'Stok Habis pada ${DateFormat('dd MMMM yyyy').format(exhaustDate)}';
  }
}