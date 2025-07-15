import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/item_model.dart';
import '../model/sale_model.dart';
import '../services/firestore_service.dart';
import '../services/prediction_service.dart';

class InventoryProvider with ChangeNotifier {
  final List<Item> _items = [];
  final List<Sale> _sales = [];
  final FirestoreService _firestoreService = FirestoreService();
  double _todayProfit = 0.0; // Add variable for today's profit
  List<Item> get items => _items;

  List<Sale> get sales => _sales;

  double get todaySales => _calculateTodaySales();
  double get todayProfit => _todayProfit; // Getter for today's profit

  List<Item> get criticalStock =>
      _items.where((item) => (item.quantity ?? 0) <= 5).toList();

  Future<void> addItem(String name, int quantity, double buyPrice,
      double sellPrice, String category, String unit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final item = Item(
      name: name,
      quantity: quantity,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      barcode: "BRG-${DateTime.now().millisecondsSinceEpoch}",
      category: category,
      stockPrediction: null,
      unit: unit,
      userId: user.uid, // Tambahkan userId ke model Item
    );

    await _firestoreService.createItem(user.uid, item);
    final newItem = await _getItemFromFirestore(user.uid, item);
    if (!_items.any((existingItem) => existingItem.docId == newItem.docId)) {
      _items.add(newItem);
      notifyListeners();
    }
  }

  Future<void> updateItem(Item item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    if (item.docId == null) throw Exception('Item ID not found');

    await _firestoreService.updateItem(userId, item);
    final index =
    _items.indexWhere((existingItem) => existingItem.docId == item.docId);
    if (index != -1) {
      final updatedItem = Item(
        docId: item.docId,
        name: item.name,
        quantity: item.quantity,
        buyPrice: item.buyPrice,
        sellPrice: item.sellPrice,
        barcode: item.barcode,
        category: item.category,
        stockPrediction: predictStockForItem(item),
        unit: item.unit,
        userId: item.userId, // Pastikan userId dipertahankan
      );
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  Future<Item> _getItemFromFirestore(String userId, Item item) async {
    final query = await FirebaseFirestore.instance
        .collection('inventory')
        .where('userId', isEqualTo: userId)
        .where('name', isEqualTo: item.name)
        .where('quantity', isEqualTo: item.quantity)
        .where('buy_price', isEqualTo: item.buyPrice)
        .where('sell_price', isEqualTo: item.sellPrice)
        .get();
    if (query.docs.isNotEmpty) {
      return Item.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return item;
  }

  Future<void> deleteItem(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    await _firestoreService.deleteItem(userId, docId);
    _items.removeWhere((item) => item.docId == docId);
    notifyListeners();
  }

  void loadItems() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.getItems(user.uid).listen((items) {
        final uniqueItems = <Item>[];
        for (final item in items) {
          final updatedItem = Item(
            docId: item.docId,
            name: item.name,
            quantity: item.quantity,
            buyPrice: item.buyPrice,
            sellPrice: item.sellPrice,
            barcode: item.barcode,
            category: item.category,
            stockPrediction: predictStockForItem(item),
            unit: item.unit,
            userId: item.userId, // Pastikan userId dimuat
          );
          if (!uniqueItems
              .any((existingItem) => existingItem.docId == updatedItem.docId)) {
            uniqueItems.add(updatedItem);
          }
        }
        _items.clear();
        _items.addAll(uniqueItems);
        notifyListeners();
      }, onError: (error) {
        debugPrint('Error loading items: $error');
      });
    }
  }

  String predictStockForItem(Item item) {
    return PredictionService.predictStockExhaustion(item, _sales);
  }

  void loadSales() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.getSales(user.uid).listen((sales) {
        _sales.clear();
        _sales.addAll(sales);
        final updatedItems = _items.map((item) {
          return Item(
            docId: item.docId,
            name: item.name,
            quantity: item.quantity,
            buyPrice: item.buyPrice,
            sellPrice: item.sellPrice,
            barcode: item.barcode,
            category: item.category,
            stockPrediction: predictStockForItem(item),
            unit: item.unit,
            userId: item.userId, // Pastikan userId dipertahankan
          );
        }).toList();
        _items.clear();
        _items.addAll(updatedItems);
        _todayProfit = _calculateTodayProfit();
        notifyListeners();
      }, onError: (error) {
        debugPrint('Error loading sales: $error');
      });
    }
  }

  double _calculateTodaySales() {
    final now = DateTime.now();
    return _sales
        .where((sale) =>
    sale.date != null &&
        sale.date!.day == now.day &&
        sale.date!.month == now.month &&
        sale.date!.year == now.year)
        .fold(0, (total, sale) => total + (sale.totalPrice ?? 0));
  }

  double _calculateTodayProfit() {
    final now = DateTime.now();
    return _sales
        .where(
          (sale) =>
      sale.date != null &&
          sale.date!.day == now.day &&
          sale.date!.month == now.month &&
          sale.date!.year == now.year,
    )
        .fold(0, (total, sale) => total + calculateSaleProfit(sale));
  }

  double calculateSaleProfit(Sale sale) {
    if (sale.itemName == null || sale.quantitySold == null) return 0.0;
    final item = _items.firstWhere(
          (i) => i.name == sale.itemName,
      orElse: () => Item(),
    );
    final sellPrice = item.sellPrice ?? 0.0;
    final buyPrice = item.buyPrice ?? 0.0;
    return (sellPrice - buyPrice) * (sale.quantitySold ?? 0);
  }

  Future<void> addSale(
      String itemName, int quantitySold, double totalPrice, String? ownerId) async {
    final userId = ownerId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final sale = Sale(
      itemName: itemName,
      quantitySold: quantitySold,
      totalPrice: totalPrice,
      date: DateTime.now(),
      userId: userId, // Tambahkan userId ke model Sale
    );

    // Simpan penjualan ke Firestore
    await _firestoreService.createSale(userId, sale);
    _sales.add(sale);

    // Cari item yang sesuai dan kurangi stok
    final itemIndex = _items.indexWhere((item) => item.name == itemName);
    if (itemIndex != -1) {
      final item = _items[itemIndex];
      if (item.quantity == null || item.quantity! < quantitySold) {
        throw Exception('Stok tidak cukup! Sisa stok: ${item.quantity ?? 0}');
      }

      // Buat item baru dengan stok yang dikurangi
      final updatedItem = Item(
        docId: item.docId,
        name: item.name,
        quantity: item.quantity! - quantitySold,
        buyPrice: item.buyPrice,
        sellPrice: item.sellPrice,
        barcode: item.barcode,
        category: item.category,
        stockPrediction: predictStockForItem(item),
        unit: item.unit,
        userId: item.userId, // Pastikan mempertahankan userId
      );

      // Update item di Firestore
      await _firestoreService.updateItem(userId, updatedItem);

      // Update item di daftar lokal
      _items[itemIndex] = updatedItem;
      notifyListeners();
    } else {
      throw Exception('Item tidak ditemukan');
    }
  }

  Future<void> deleteSale(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    final userId = user.uid;

    await _firestoreService.deleteSale(userId, docId);
    final saleToDelete = _sales.firstWhere((sale) => sale.docId == docId);
    _sales.removeWhere((sale) => sale.docId == docId);
    notifyListeners();
  }

  void loadItemsForOwner(String ownerId) {
    _firestoreService.getItems(ownerId).listen((items) {
      final uniqueItems = <Item>[];
      for (final item in items) {
        final updatedItem = Item(
          docId: item.docId,
          name: item.name,
          quantity: item.quantity,
          buyPrice: item.buyPrice,
          sellPrice: item.sellPrice,
          barcode: item.barcode,
          category: item.category,
          stockPrediction: predictStockForItem(item),
          unit: item.unit,
          userId: item.userId, // Pastikan userId dimuat
        );
        if (!uniqueItems
            .any((existingItem) => existingItem.docId == updatedItem.docId)) {
          uniqueItems.add(updatedItem);
        }
      }
      _items.clear();
      _items.addAll(uniqueItems);
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error loading items: $error');
    });
  }

  void loadSalesForOwner(String ownerId) {
    _firestoreService.getSales(ownerId).listen((sales) {
      _sales.clear();
      _sales.addAll(sales);
      final updatedItems = _items.map((item) {
        return Item(
          docId: item.docId,
          name: item.name,
          quantity: item.quantity,
          buyPrice: item.buyPrice,
          sellPrice: item.sellPrice,
          barcode: item.barcode,
          category: item.category,
          stockPrediction: predictStockForItem(item),
          unit: item.unit,
          userId: item.userId, // Pastikan userId dipertahankan
        );
      }).toList();
      _items.clear();
      _items.addAll(updatedItems);
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error loading sales: $error');
    });
  }
}