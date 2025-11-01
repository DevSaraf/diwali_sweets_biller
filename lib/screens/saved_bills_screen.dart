// lib/screens/saved_bills_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:diwali_sweets_biller/models/order_model.dart';
import 'package:diwali_sweets_biller/screens/order_details_screen.dart';
import 'package:diwali_sweets_biller/screens/sales_stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavedBillsScreen extends StatefulWidget {
  const SavedBillsScreen({super.key});

  @override
  State<SavedBillsScreen> createState() => _SavedBillsScreenState();
}

class _SavedBillsScreenState extends State<SavedBillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Saved Bills'),
        backgroundColor: Colors.blueGrey,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle), text: 'Done'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // "Pending" list
          BillListStream(status: 'Pending'),
          // "Done" list
          BillListStream(status: 'Done'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SalesStatsScreen()),
          );
        },
        label: const Text('Sells'),
        icon: const Icon(Icons.bar_chart),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
}

// This widget fetches and displays the list of bills
class BillListStream extends StatelessWidget {
  final String status;

  const BillListStream({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // The Firebase query is now filtered by status
    final query = FirebaseFirestore.instance
        .collection('orders')
        .where('orderStatus', isEqualTo: status)
        .orderBy('receiptNumber', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong!'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $status bills found.',
              style: const TextStyle(fontSize: 18),
            ),
          );
        }

        final documents = snapshot.data!.docs;

        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final order = Order.fromFirestore(documents[index]);
            final pendingAmount =
                order.totalAmount - (order.partialPayment ?? 0.0);

            // Logic for subtitle
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

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderDetailsScreen(orderId: order.id!),
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
    );
  }
}