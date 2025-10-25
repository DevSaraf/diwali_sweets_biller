// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String? id;
  final int receiptNumber;
  final String customerName;
  final String contactNumber;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String orderStatus;
  final double? partialPayment;
  final String deviceName;
  final Timestamp orderDate;

  Order({
    this.id,
    required this.receiptNumber,
    required this.customerName,
    required this.contactNumber,
    required this.items,
    required this.totalAmount,
    required this.orderStatus,
    this.partialPayment,
    required this.deviceName,
    required this.orderDate,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      receiptNumber: data['receiptNumber'] ?? 0,
      customerName: data['customerName'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      orderStatus: data['orderStatus'] ?? 'Pending',
      partialPayment: (data['partialPayment'] ?? 0.0).toDouble(),
      deviceName: data['deviceName'] ?? 'Unknown Device',
      orderDate: data['orderDate'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'receiptNumber': receiptNumber,
      'customerName': customerName,
      'contactNumber': contactNumber,
      'items': items,
      'totalAmount': totalAmount,
      'orderStatus': orderStatus,
      'partialPayment': partialPayment,
      'deviceName': deviceName,
      'orderDate': orderDate,
    };
  }
}