import 'package:flutter/material.dart';
import '../controllers/app_scope.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Favourites')),
      body: state.favourites.isEmpty
          ? const Center(child: Text('Your favourites list is empty.'))
          : GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .68,
              ),
              itemCount: state.favourites.length,
              itemBuilder: (_, index) {
                final product = state.favourites[index];
                return ProductCard(
                  product: product,
                  isFavourite: true,
                  isInCart: state.isInCart(product.id),
                  onFavourite: () => state.removeFromFavourites(product),
                  onAdd: () {
                    if (state.isInCart(product.id)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Already exists in the cart'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    state.addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.title} added to cart'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
