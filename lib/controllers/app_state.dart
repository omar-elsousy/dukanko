import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/api_item.dart';
import '../models/cart_line.dart';

class AppState extends ChangeNotifier {
  AppState({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  final ApiClient apiClient;
  final List<ApiItem> categories = [];
  final List<ApiItem> sections = [];
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

  Future<void> register({
    required String mobile,
    required String password,
    String? name,
  }) async {
    await _guard(() async {
      await apiClient.post(
        ApiEndpoints.register,
        body: {
          'mobile': mobile,
          'password': password,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        },
      );
    });
  }

  Future<void> loadHome() async {
    await _guard(() async {
      final sectionsPayload = await apiClient.get(ApiEndpoints.sections).catchError((_) => []);
      final categoriesPayload = await apiClient.get(ApiEndpoints.categories).catchError((_) => []);

      sections
        ..clear()
        ..addAll(parseItems(sectionsPayload));
      categories
        ..clear()
        ..addAll(parseItems(categoriesPayload));

      if (sections.isEmpty && categories.isEmpty) {
        error = 'Could not load sections/categories. Check API/CORS.';
      }

      isBootstrapped = true;
    });
  }

  Future<List<ApiItem>> loadProductsByCategory(ApiItem category) async {
    final payload = await apiClient.get(
      ApiEndpoints.productsByCategory,
      query: {
        'category_id': category.id,
        'id': category.id,
      },
    );
    return parseItems(payload);
  }

  Future<void> checkout() async {
    if (cart.isEmpty) return;
    await _guard(() async {
      cart.clear();
      notifyListeners();
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

  Future<void> logout() async {
    await _guard(() async {
      await apiClient.post(ApiEndpoints.logout).catchError((_) => null);
      apiClient.setToken(null);
      userMobile = null;
      categories.clear();
      sections.clear();
      orders.clear();
      cart.clear();
      isBootstrapped = false;
    });
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
