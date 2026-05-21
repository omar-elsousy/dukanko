import 'package:flutter/material.dart';

import '../models/api_item.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onOpen,
    this.onFavourite,
    this.isFavourite = false,
  });

  final ApiItem product;
  final VoidCallback onAdd;
  final VoidCallback onOpen;
  final VoidCallback? onFavourite;
  final bool isFavourite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: product.imageUrl == null
                          ? Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  size: 40,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // عرض الكود
                  Text(
                    'ID: ${product.id}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  // عرض الحالة
                  if (product.raw['status'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.raw['status'].toString().contains('in stock')
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.raw['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: product.raw['status'].toString().contains('in stock')
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                children: [
                  Expanded(
                    child: Text(
                      product.price == null
                          ? 'Tap for details'
                          : '${product.price!.toStringAsFixed(2)} EGP',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: IconButton.filledTonal(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (onFavourite != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onFavourite,
                        icon: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavourite ? Colors.red : Colors.grey,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFavourite ? Colors.red : Colors.grey,
                          side: BorderSide(color: isFavourite ? Colors.red : Colors.grey.shade300),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: Text(
                          isFavourite ? 'UNFAV' : 'FAV',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
}
}
