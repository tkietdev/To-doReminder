import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'auth_token';
  static String? _token;

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  bool get hasToken => _token != null && _token!.isNotEmpty;

  static String get baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _send('GET', path, query: query);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) {
    return _send('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send('DELETE', path);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map((key, value) {
        return MapEntry(key, value.toString());
      }),
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw ApiException('Unsupported method: $method');
      }
    } catch (e) {
      throw ApiException('Khong the ket noi backend: $e');
    }

    final payload = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        payload['message'] as String? ?? 'Yeu cau that bai',
        response.statusCode,
      );
    }

    if (payload['success'] != true) {
      throw ApiException(payload['message'] as String? ?? 'Yeu cau that bai');
    }

    return payload['data'] as Map<String, dynamic>? ?? {};
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ApiException('Backend tra ve du lieu khong hop le');
    }
  }
}
