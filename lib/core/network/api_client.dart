import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({HttpClient? httpClient}) : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;
  String? _token;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  void setToken(String? token) {
    _token = token;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) {
    return _send('DELETE', path, body: body);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient
        .openUrl(method, ApiConfig.uri(path, query))
        .timeout(const Duration(seconds: 20));

    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (_token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_token');
    }

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 30));
    final text = await response.transform(utf8.decoder).join();
    final payload = text.isEmpty ? null : jsonDecode(text);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractMessage(payload) ?? 'Request failed. Please try again.',
        statusCode: response.statusCode,
      );
    }

    return payload;
  }

  String? _extractMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      for (final key in ['message', 'error', 'msg']) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
      final errors = payload['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    return null;
  }
}
