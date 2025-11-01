// lib/screens/order_details_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:diwali_sweets_biller/models/order_model.dart';
import 'package:diwali_sweets_biller/utils/pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

enum OrderStatus { pending, done }

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _partialPaymentController = TextEditingController();
  OrderStatus? _orderStatus;
  bool _isSaving = false;

  Future<void> _updateOrder() async {
    if (_orderStatus == null) return;
    setState(() { _isSaving = true; });

    final newPartialPayment = double.tryParse(_partialPaymentController.text) ?? 0.0;
    final newStatus = _orderStatus == OrderStatus.done ? 'Done' : 'Pending';

    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'orderStatus': newStatus,
        'partialPayment': newPartialPayment,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Order updated successfully!')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Failed to update order: $e')));
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Bill?'),
          content: const SingleChildScrollView(
            child: Text('Are you sure you want to delete this bill? This action cannot be undone.'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteOrder();
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteOrder() async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text('Order deleted successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Failed to delete order: $e')),
      );
    }
  }

  @override
  void dispose() {
    _partialPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Bill',
            onPressed: () {
              _showDeleteDialog(context);
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final order = Order.fromFirestore(snapshot.data!);

          if (_orderStatus == null) {
            _partialPaymentController.text = (order.partialPayment ?? 0.0).toString();
            _orderStatus = order.orderStatus == 'Done' ? OrderStatus.done : OrderStatus.pending;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bill #${order.receiptNumber.toString()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      )),
                  const SizedBox(height: 10),
                  Text('Customer: ${order.customerName.isNotEmpty ? order.customerName : 'Walk-in'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Contact: ${order.contactNumber}', style: const TextStyle(fontSize: 16)),
                  Text('Date: ${DateFormat.yMMMd().add_jm().format(order.orderDate.toDate())}'),
                  const Divider(height: 30),
                  const Text('Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  for (var item in order.items)
                    ListTile(title: Text(item['name'] ?? 'No item'), subtitle: Text('${item['quantity']} kg'), trailing: Text('₹${item['amount']?.toStringAsFixed(2) ?? '0.00'}')),
                  const Divider(height: 30),
                  const Text('Delivery Status:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(child: RadioListTile<OrderStatus>(title: const Text('Pending'), value: OrderStatus.pending, groupValue: _orderStatus, onChanged: (v) => setState(() => _orderStatus = v!))),
                      Expanded(child: RadioListTile<OrderStatus>(title: const Text('Done'), value: OrderStatus.done, groupValue: _orderStatus, onChanged: (v) => setState(() => _orderStatus = v!))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _partialPaymentController,
                    decoration: const InputDecoration(labelText: 'Partial Payment Made (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        generateAndPrintBill(order);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print/Share Bill'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateOrder,
                      icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Update Order'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}