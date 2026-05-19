import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/api_item.dart';
import '../models/cart_line.dart';

class AppState extends ChangeNotifier {
  AppState({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  final ApiClient apiClient;
  final List<ApiItem> products = [];
  final List<ApiItem> categories = [];
  final List<ApiItem> orders = [];
  final List<CartLine> cart = [];

  bool isLoading = false;
  bool isBootstrapped = false;
  String? error;
  String? userMobile;

  bool get isAuthenticated => apiClient.isAuthenticated;
  int get cartCount => cart.fold(0, (sum, line) => sum + line.quantity);
  double get cartTotal => cart.fold(0, (sum, line) => sum + line.total);

  Future<void> login({required String mobile, required String password}) async {
    await _guard(() async {
      final payload = await apiClient.post(
        ApiEndpoints.login,
        body: {'mobile': mobile, 'password': password},
      );
      final token = _extractToken(payload);
      apiClient.setToken(token);
      userMobile = mobile;
      await loadHome();
    });
  }

  Future<void> loadHome() async {
    await _guard(() async {
      final results = await Future.wait<dynamic>([
        apiClient.get(ApiEndpoints.categories).catchError((_) => []),
        apiClient.get(ApiEndpoints.products).catchError((_) => []),
        apiClient.get(ApiEndpoints.orders).catchError((_) => []),
      ]);

      categories
        ..clear()
        ..addAll(parseItems(results[0]));
      products
        ..clear()
        ..addAll(parseItems(results[1]));
      orders
        ..clear()
        ..addAll(parseItems(results[2]));
      isBootstrapped = true;
    });
  }

  Future<void> checkout() async {
    if (cart.isEmpty) return;
    await _guard(() async {
      await apiClient.post(
        ApiEndpoints.orders,
        body: {
          'items': cart
              .map((line) => {
                    'product_id': line.product.id,
                    'quantity': line.quantity,
                    'price': line.product.price,
                  })
              .toList(),
          'total': cartTotal,
        },
      );
      cart.clear();
      await loadHome();
    });
  }

  void addToCart(ApiItem product) {
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) {
      cart.add(CartLine(product: product));
    } else {
      final current = cart[index];
      cart[index] = current.copyWith(quantity: current.quantity + 1);
    }
    notifyListeners();
  }

  void updateCartQuantity(ApiItem product, int quantity) {
    if (quantity <= 0) {
      cart.removeWhere((line) => line.product.id == product.id);
    } else {
      final index = cart.indexWhere((line) => line.product.id == product.id);
      if (index != -1) cart[index] = cart[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void logout() {
    apiClient.setToken(null);
    userMobile = null;
    products.clear();
    categories.clear();
    orders.clear();
    cart.clear();
    isBootstrapped = false;
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? _extractToken(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      for (final key in ['token', 'access_token', 'api_token']) {
        final value = payload[key];
        if (value is String && value.isNotEmpty) return value;
      }
      final data = payload['data'];
      if (data is Map<String, dynamic>) return _extractToken(data);
      final user = payload['user'];
      if (user is Map<String, dynamic>) return _extractToken(user);
    }
    return null;
  }
}
