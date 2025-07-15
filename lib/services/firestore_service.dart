import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/cashier_model.dart';
import '../model/item_model.dart';
import '../model/sale_model.dart';
import '../services/kategorisasi_service.dart';
import '../services/prediction_service.dart';
import '../provider/inventory_provider.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createItem(String userId, Item item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final predictedCategory = await KategorisasiService.predictCategory(item.name ?? '');
    final barcodeValue =
        '${item.name}-$userId-${DateTime.now().millisecondsSinceEpoch}'; // Barcode unik
    final itemWithCategory = Item(
      name: item.name,
      quantity: item.quantity,
      buyPrice: item.buyPrice,
      sellPrice: item.sellPrice,
      barcode: barcodeValue,
      category: predictedCategory,
      stockPrediction: null,
      unit: item.unit,
      userId: userId, // Tambahkan userId ke model Item
    );

    final docRef = await _firestore
        .collection('inventory')
        .add(itemWithCategory.toMap());

    final provider = InventoryProvider();
    provider.loadSales();
    final stockPrediction = PredictionService.predictStockExhaustion(
        itemWithCategory, provider.sales);
    await docRef.update({
      'stock_prediction': stockPrediction,
    });
  }

  Future<void> updateItem(String userId, Item item) async {
    if (item.docId == null) throw Exception('Item ID not found');

    await _firestore
        .collection('inventory')
        .doc(item.docId)
        .update(item.toMap());
  }

  Future<void> deleteItem(String userId, String docId) async {
    await _firestore
        .collection('inventory')
        .doc(docId)
        .delete();
  }

  Stream<List<Item>> getItems(String userId) {
    return _firestore
        .collection('inventory')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Item.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<Sale>> getSales(String userId) {
    return _firestore
        .collection('sales')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Sale.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> createSale(String userId, Sale sale) async {
    final saleWithUserId = Sale(
      itemName: sale.itemName,
      quantitySold: sale.quantitySold,
      totalPrice: sale.totalPrice,
      date: sale.date,
      userId: userId, // Tambahkan userId ke model Sale
      docId: sale.docId,
    );

    await _firestore
        .collection('sales')
        .add(saleWithUserId.toMap());
  }

  Future<void> deleteSale(String userId, String docId) async {
    await _firestore
        .collection('sales')
        .doc(docId)
        .delete();
  }

  Future<void> createCashier(Cashier cashier) async {
    await _firestore.collection('cashiers').add(cashier.toMap());
  }

  Future<void> deleteCashier(String docId) async {
    await _firestore.collection('cashiers').doc(docId).delete();
  }

  Stream<List<Cashier>> getCashiers(String ownerId) {
    return _firestore
        .collection('cashiers')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Cashier.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<Cashier?> getCashierByEmail(String email) async {
    final query = await _firestore
        .collection('cashiers')
        .where('email', isEqualTo: email)
        .get();
    if (query.docs.isNotEmpty) {
      return Cashier.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }
}