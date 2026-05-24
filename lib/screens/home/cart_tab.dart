import 'package:flutter/material.dart';
import '../../controllers/app_scope.dart';
import '../../widgets/app_error_banner.dart';
import '../../utils/app_dialogs.dart';
import '../order_details_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.cart.isEmpty) return const _EmptyState(message: 'Your cart is empty.');

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: state.cart.length,
            itemBuilder: (context, index) {
              final line = state.cart[index];
              final product = line.product;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (state.error != null) ...[
                        AppErrorBanner(message: state.error!),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: state.isLoading ? null : () => state.updateCartQuantity(product, -1),
                                    icon: Icon(Icons.remove_circle_outline, color: state.isLoading ? Colors.grey : Theme.of(context).colorScheme.primary, size: 28),
                                  ),
                                  InkWell(
                                    onTap: state.isLoading ? null : () => AppDialogs.showQuantityDialog(context, state, product, line.quantity),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        '${line.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: state.isLoading ? null : () => state.updateCartQuantity(product, 1),
                                    icon: Icon(Icons.add_circle_outline, color: state.isLoading ? Colors.grey : Theme.of(context).colorScheme.primary, size: 28),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: product.imageUrl == null
                                    ? const Icon(Icons.inventory_2_outlined)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Code: ${product.id}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Price: ${product.price?.toStringAsFixed(2)} EGP',
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                ),
                                if (product.raw['unit_tax'] != null && product.raw['unit_tax'] != 0)
                                  Text(
                                    'Unit Tax: ${product.raw['unit_tax']} EGP',
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                  ),
                                if (product.raw['unit_price_after_tax'] != null)
                                  Text(
                                    'After Tax: ${product.raw['unit_price_after_tax']} EGP',
                                    style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => state.removeFromCart(product),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Item', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(
                                '${(product.raw['total_price'] ?? (product.price! * line.quantity)).toStringAsFixed(2)} EGP',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Number of Products', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      '${state.serverCartCount}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Order Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      '${state.cartTotal.toStringAsFixed(2)} EGP',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.cart.isEmpty || state.isLoading
                        ? null
                        : () async {
                            final orderId = await state.checkout();
                            if (context.mounted) {
                              if (orderId != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: orderId)),
                                );
                              } else if (state.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  AppErrorBanner(message: state.error!).asSnackBar(),
                                );
                              }
                            }
                          },
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}
