import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String? docId;
  final String? itemName;
  final int? quantitySold;
  final double? totalPrice;
  final DateTime? date;
  final String? userId;

  Sale({
    this.docId,
    this.itemName,
    this.quantitySold,
    this.totalPrice,
    this.date,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'quantitySold': quantitySold,
      'totalPrice': totalPrice,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'userId': userId,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, String docId) {
    return Sale(
      docId: docId,
      itemName: map['itemName'] as String?,
      quantitySold: map['quantitySold'] as int?,
      totalPrice: (map['totalPrice'] as num?)?.toDouble(),
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : null,
      userId: map['userId'] as String?,
    );
  }
}