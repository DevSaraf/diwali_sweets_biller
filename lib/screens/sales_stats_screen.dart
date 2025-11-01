// lib/screens/sales_stats_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:diwali_sweets_biller/models/order_model.dart';
import 'package:flutter/material.dart';

class SalesStatsScreen extends StatefulWidget {
  const SalesStatsScreen({super.key});

  @override
  State<SalesStatsScreen> createState() => _SalesStatsScreenState();
}

class _SalesStatsScreenState extends State<SalesStatsScreen> {
  // A map to hold the aggregated data, e.g. {'Kaaju Katli': {'quantity': 10.5, 'amount': 8400.0}}
  Map<String, Map<String, double>> _salesData = {};
  double _grandTotal = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateSalesData();
  }

  Future<void> _calculateSalesData() async {
    final Map<String, Map<String, double>> aggregatedData = {};
    double grandTotalSales = 0.0;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderStatus', isEqualTo: 'Done')
          .get();

      for (var doc in querySnapshot.docs) {
        final order = Order.fromFirestore(doc);
        grandTotalSales += order.totalAmount;

        for (var item in order.items) {
          final String name = item['name'] ?? 'Unknown';
          final double quantity = (item['quantity'] ?? 0.0).toDouble();
          final double amount = (item['amount'] ?? 0.0).toDouble();

          if (aggregatedData.containsKey(name)) {
            aggregatedData[name]!['quantity'] = (aggregatedData[name]!['quantity'] ?? 0.0) + quantity;
            aggregatedData[name]!['amount'] = (aggregatedData[name]!['amount'] ?? 0.0) + amount;
          } else {
            aggregatedData[name] = {'quantity': quantity, 'amount': amount};
          }
        }
      }
    } catch (e) {
      print('Error calculating sales: $e');
    }

    setState(() {
      _salesData = aggregatedData;
      _grandTotal = grandTotalSales;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- THIS IS THE FIX ---
    // We filter the list to remove the 'Unknown' entry before sorting and displaying.
    final sortedItems = _salesData.entries
        .where((entry) => entry.key != 'Unknown')
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    // -----------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Statistics'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: sortedItems.length,
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                final itemName = item.key;
                final itemData = item.value;
                final qty = itemData['quantity']?.toStringAsFixed(1) ?? '0.0';
                final amount = itemData['amount']?.toStringAsFixed(2) ?? '0.00';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Total Quantity Sold: $qty kg'),
                    trailing: Text(
                      'Total Sales: ₹$amount',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount Sold:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  '₹${_grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}