// lib/widgets/bill_item_row.dart

import 'package:flutter/material.dart';

class BillItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final List<String> availableItems;
  final Function(Map<String, dynamic>) onItemChanged;
  final VoidCallback onRemove;

  const BillItemRow({
    super.key,
    required this.item,
    required this.availableItems,
    required this.onItemChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    double currentQuantity = item['quantity'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: item['name'],
                  hint: const Text('Select Item'),
                  isExpanded: true,
                  items: availableItems.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    item['name'] = newValue;
                    onItemChanged(item);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const Text('Quantity (kg)', style: TextStyle(fontSize: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          padding: EdgeInsets.zero,
                          onPressed: currentQuantity <= 0 ? null : () {
                            item['quantity'] = currentQuantity - 0.5;
                            onItemChanged(item);
                          },
                        ),
                        Text(
                          currentQuantity.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          padding: EdgeInsets.zero,
                          onPressed: currentQuantity >= 5 ? null : () {
                            item['quantity'] = currentQuantity + 0.5;
                            onItemChanged(item);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: InputBorder.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '₹${item['amount']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline,
                  size: 16, color: Colors.red),
              label: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          )
        ],
      ),
    );
  }
}