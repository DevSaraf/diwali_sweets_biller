// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:diwali_sweets_biller/models/order_model.dart';
import 'package:diwali_sweets_biller/screens/order_details_screen.dart';
import 'package:diwali_sweets_biller/screens/saved_bills_screen.dart';
import 'package:diwali_sweets_biller/widgets/bill_item_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Make sure this import is here

enum OrderStatus { pending, done }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _partialPaymentController = TextEditingController();

  final Map<String, double> _sweetPrices = {
    'Kaaju Katli': 800.0,
    'Badam Katli': 860.0,
    'Besan Chakki': 460.0,
    'Chivda': 260.0,
    'Suaali': 260.0,
    'Masala Sev': 220.0,
    'Chaakli': 100.0,
  };

  List<Map<String, dynamic>> _billItems = [];
  double _grandTotal = 0.0;
  OrderStatus _orderStatus = OrderStatus.pending;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  // --- THIS IS THE FUNCTION YOU WERE LOOKING FOR ---
  void _generateAndSaveBill() async {
    if (!_formKey.currentState!.validate()) { return; }
    setState(() { _isSaving = true; });

    try {
      // 1. Get a reference to a special 'counters' document
      final counterRef = FirebaseFirestore.instance.collection('counters').doc('orders');

      int nextReceiptNumber = 1;

      // 2. Run a "transaction" to safely get the next number
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(counterRef);

        if (!counterSnapshot.exists) {
          // If it's the first bill ever, create the counter
          transaction.set(counterRef, {'lastNumber': 1});
          nextReceiptNumber = 1;
        } else {
          // Otherwise, get the last number and increment it
          final lastNumber = counterSnapshot.data()!['lastNumber'] as int;
          nextReceiptNumber = lastNumber + 1;
          transaction.update(counterRef, {'lastNumber': nextReceiptNumber});
        }
      });
      // --- End of counter logic ---

      // 3. Get Device Name
      String deviceName = 'Unknown Device';
      try {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        }
      } catch (e) {
        print('Failed to get device info: $e');
      }

      // 4. Create the new order
      final newOrder = Order(
        receiptNumber: nextReceiptNumber,
        customerName: _customerNameController.text,
        contactNumber: _contactNumberController.text,
        items: _billItems,
        totalAmount: _grandTotal,
        orderStatus: _orderStatus == OrderStatus.done ? 'Done' : 'Pending',
        partialPayment: double.tryParse(_partialPaymentController.text) ?? 0.0,
        deviceName: deviceName,
        orderDate: Timestamp.now(),
      );

      // 5. Save the order
      await FirebaseFirestore.instance.collection('orders').add(newOrder.toMap());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Bill successfully saved!')));
      _clearForm();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Failed to save bill: $e')));
    }

    if (mounted) { setState(() { _isSaving = false; }); }
  }

  void _clearForm() {
    setState(() {
      _customerNameController.clear();
      _contactNumberController.clear();
      _partialPaymentController.clear();
      _billItems = [];
      _grandTotal = 0.0;
      _orderStatus = OrderStatus.pending;
      _addItem();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _contactNumberController.dispose();
    _partialPaymentController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _billItems.add({'name': null, 'quantity': 0.0, 'amount': 0.0});
    });
  }

  void _updateItem(int index, Map<String, dynamic> item) {
    setState(() {
      final pricePerKg = _sweetPrices[item['name']] ?? 0.0;
      item['amount'] = (item['quantity'] ?? 0.0) * pricePerKg;
      _billItems[index] = item;
      _calculateGrandTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _billItems.removeAt(index);
      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    double total = 0.0;
    for (var item in _billItems) {
      total += item['amount'] ?? 0.0;
    }
    setState(() {
      _grandTotal = total;
      _partialPaymentController.text = _grandTotal.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          child: Text('Agrawal Samiti Diwali Sweets Distribution'),
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(controller: _customerNameController, decoration: const InputDecoration(labelText: 'Customer Name (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 16),
                TextFormField(controller: _contactNumberController, decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const Divider(height: 40, thickness: 1),
                ..._billItems.asMap().entries.map((entry) {
                  return BillItemRow(
                    item: entry.value,
                    availableItems: _sweetPrices.keys.toList(),
                    onItemChanged: (updatedItem) => _updateItem(entry.key, updatedItem),
                    onRemove: () => _removeItem(entry.key),
                  );
                }).toList(),
                TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Add Item')),
                const Divider(height: 40, thickness: 1),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('GRAND TOTAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('₹${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                ]),
                const Divider(height: 40, thickness: 1),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Delivery Status:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(children: [
                    Expanded(child: RadioListTile<OrderStatus>(title: const Text('Pending'), value: OrderStatus.pending, groupValue: _orderStatus, onChanged: (v) => setState(() => _orderStatus = v!))),
                    Expanded(child: RadioListTile<OrderStatus>(title: const Text('Done'), value: OrderStatus.done, groupValue: _orderStatus, onChanged: (v) => setState(() => _orderStatus = v!))),
                  ]),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _partialPaymentController,
                  decoration: const InputDecoration(labelText: 'Partial Payment Made (₹)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _generateAndSaveBill,
                    icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.receipt_long),
                    label: Text(_isSaving ? 'Saving...' : 'Generate & Save Bill'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedBillsScreen())),
        label: const Text('Saved Bills'), icon: const Icon(Icons.receipt_long), backgroundColor: Colors.blueGrey,
      ),
    );
  }
}