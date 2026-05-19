import 'api_item.dart';

class CartLine {
  const CartLine({required this.product, this.quantity = 1});

  final ApiItem product;
  final int quantity;

  double get total => (product.price ?? 0) * quantity;

  CartLine copyWith({int? quantity}) {
    return CartLine(product: product, quantity: quantity ?? this.quantity);
  }
}
