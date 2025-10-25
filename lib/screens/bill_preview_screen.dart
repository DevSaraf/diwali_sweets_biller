// lib/screens/bill_preview_screen.dart

import 'package:diwali_sweets_biller/models/order_model.dart';
import 'package:flutter/material.dart';

class BillPreviewScreen extends StatelessWidget {
  // This screen will receive an Order object
  final Order order;

  const BillPreviewScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Preview'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Customer Details
            Text('Customer: ${order.customerName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Contact: ${order.contactNumber}',
                style: const TextStyle(fontSize: 16)),
            const Divider(height: 30),

            // Display Items
            const Text('Items:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // A loop to display each item in the list
            for (var item in order.items)
              ListTile(
                title: Text(item['name'] ?? 'No item'),
                subtitle: Text('${item['quantity']} gm'),
                trailing: Text('₹${item['amount']?.toStringAsFixed(2) ?? '0.00'}'),
              ),
            const Divider(height: 30),

            // Display Totals and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GRAND TOTAL:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
              ],
            ),
            const SizedBox(height: 10),
            Text('Status: ${order.orderStatus}',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),

            const Spacer(), // Pushes the button to the bottom

            // The final "Confirm & Save" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // In our final step, this will save to Firebase.
                  // For now, it will just show a message and go back.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.blue,
                      content: Text('Order Saved (simulation)!'),
                    ),
                  );
                  Navigator.of(context).pop(); // Go back to the home screen
                },
                icon: const Icon(Icons.save),
                label: const Text('Confirm & Save Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}