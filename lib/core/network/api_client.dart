import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
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
    final uri = ApiConfig.uri(path, query);

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    final bodyEncoded = body != null ? jsonEncode(body) : null;

    final http.Response response;

    switch (method) {
      case 'GET':
        response = await _client
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 30));
        break;
      case 'POST':
        response = await _client
            .post(uri, headers: headers, body: bodyEncoded)
            .timeout(const Duration(seconds: 30));
        break;
      case 'PUT':
        response = await _client
            .put(uri, headers: headers, body: bodyEncoded)
            .timeout(const Duration(seconds: 30));
        break;
      case 'DELETE':
        response = await _client
            .delete(uri, headers: headers, body: bodyEncoded)
            .timeout(const Duration(seconds: 30));
        break;
      default:
        throw ApiException('Unsupported method: $method');
    }

    final text = response.body;
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