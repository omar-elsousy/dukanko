import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/api_item.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final ApiItem product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: product.imageUrl == null
                ? Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            product.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (product.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(product.subtitle!, style: const TextStyle(color: Colors.black54)),
          ],
          const SizedBox(height: 16),
          Text(
            product.price == null
                ? 'Price will be shown by API'
                : '${product.price!.toStringAsFixed(2)} EGP',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            product.description ??
                'No extra description is available for this item yet.',
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              AppScope.of(context).addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to cart')),
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to cart'),
          ),
        ],
      ),
    );
  }
}
