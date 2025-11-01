// lib/utils/pdf_generator.dart

import 'package:diwali_sweets_biller/models/order_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateAndPrintBill(Order order) async {
  final pdf = pw.Document();

  final pendingAmount = order.totalAmount - (order.partialPayment ?? 0.0);
  final items = order.items;

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // --- Header ---
            pw.Text(
              'Agrawal Samiti Diwali Sweets',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Bill #${order.receiptNumber}',
              style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),

            // --- Customer Details ---
            pw.Text('Customer: ${order.customerName.isNotEmpty ? order.customerName : 'Walk-in'}'),
            pw.Text('Contact: ${order.contactNumber.isNotEmpty ? order.contactNumber : 'N/A'}'),
            pw.Text('Date: ${DateFormat.yMMMd().add_jm().format(order.orderDate.toDate())}'),
            pw.Text('Billed By: ${order.deviceName}'),
            pw.SizedBox(height: 20),

            // --- Items Table Header ---
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 2)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty (kg)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Amount (₹)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
            ),

            // --- Items Table Rows ---
            for (var item in items)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text(item['name'] ?? 'Unknown')),
                    pw.Expanded(flex: 1, child: pw.Text(item['quantity'].toString())),
                    pw.Expanded(flex: 1, child: pw.Text('₹${item['amount'].toStringAsFixed(2)}')),
                  ],
                ),
              ),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // --- Totals Section ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Grand Total: ₹${order.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    if (order.partialPayment != null && order.partialPayment! > 0)
                      pw.Text('Paid: ₹${order.partialPayment!.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
                    if (pendingAmount > 0)
                      pw.Text('Balance Due: ₹${pendingAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Status: ${order.orderStatus}', style: const pw.TextStyle(fontSize: 16)),
          ],
        );
      },
    ),
  );

  // Show the print preview screen
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}