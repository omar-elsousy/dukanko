import 'package:flutter/material.dart';
import '../models/api_item.dart';

class AppDialogs {
  const AppDialogs._();

  static void showQuantityDialog(BuildContext context, dynamic state, ApiItem product, int currentQty) {
    final controller = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text);
              if (newQty != null) {
                state.setCartQuantity(product, newQty);
              }
              Navigator.pop(context);
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }
}
