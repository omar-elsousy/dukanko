class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.1.104.82:81/Online-application/public/api',
  );

  static Uri uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final filteredQuery = <String, String>{};
    query?.forEach((key, value) {
      final text = value?.toString() ?? '';
      if (text.isNotEmpty) filteredQuery[key] = text;
    });

    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }
}

class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String categories = '/categories';
  static const String products = '/products';
  static const String cart = '/cart';
  static const String orders = '/orders';
}
