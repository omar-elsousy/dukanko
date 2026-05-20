class ApiItem {
  const ApiItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.price,
    this.raw = const {},
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final double? price;
  final Map<String, dynamic> raw;

  factory ApiItem.fromJson(Map<String, dynamic> json) {
    final id = _first(json, ['id', 'family_id', 'code', 'item_id', 'product_id']) ?? '';
    final title = _first(json, [
          'name',
          'title',
          'product_name',
          'item_name',
          'category_name',
          'description_ar',
        ]) ??
        'Category ${id.toString()}';
    final subtitle = _first(json, ['category', 'brand', 'short_description']);
    final description = _first(json, ['description', 'details', 'notes']);
    final imageUrl = _first(json, ['image', 'image_url', 'photo', 'thumbnail']);
    final priceValue = _first(json, ['price', 'sell_price', 'unit_price', 'amount']);

    return ApiItem(
      id: id.toString(),
      title: title.toString(),
      subtitle: subtitle?.toString(),
      description: description?.toString(),
      imageUrl: imageUrl?.toString(),
      price: double.tryParse(priceValue?.toString() ?? ''),
      raw: json,
    );
  }

  static dynamic _first(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return null;
  }
}

List<ApiItem> parseItems(dynamic payload) {
  final list = _extractList(payload);
  return list
      .whereType<Map>()
      .map((item) => ApiItem.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<dynamic> _extractList(dynamic payload) {
  if (payload is List) return payload;
  if (payload is Map<String, dynamic>) {
    for (final key in ['data', 'items', 'products', 'categories', 'orders']) {
      final value = payload[key];
      if (value is List) return value;
      if (value is Map<String, dynamic>) {
        final nested = _extractList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
  }
  return const [];
}
