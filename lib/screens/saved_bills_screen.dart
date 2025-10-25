// lib/screens/saved_bills_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:diwali_sweets_biller/models/order_model.dart';
import 'package:diwali_sweets_biller/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavedBillsScreen extends StatelessWidget {
  const SavedBillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Saved Bills'),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('receiptNumber', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No saved bills found.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final order = Order.fromFirestore(documents[index]);
              final pendingAmount = order.totalAmount - (order.partialPayment ?? 0.0);

              // --- NEW LOGIC FOR SUBTITLE ---
              List<String> subtitleParts = [];
              if (order.customerName.isNotEmpty) {
                subtitleParts.add(order.customerName);
              }
              if (order.contactNumber.isNotEmpty) {
                subtitleParts.add(order.contactNumber);
              }
              if (subtitleParts.isEmpty) {
                subtitleParts.add('Walk-in Customer');
              }
              final subtitleText = '${subtitleParts.join(' - ')}\n'
                  '${DateFormat.yMMMd().add_jm().format(order.orderDate.toDate())}';
              // ------------------------------

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsScreen(orderId: order.id!),
                      ),
                    );
                  },
                  isThreeLine: true,
                  title: Text(
                    'Bill #${order.receiptNumber.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subtitleText),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (pendingAmount > 0)
                        Text(
                          'To Be Paid: ₹${pendingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      Text(
                        order.orderStatus,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: order.orderStatus == 'Pending'
                              ? Colors.orange.shade800
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}