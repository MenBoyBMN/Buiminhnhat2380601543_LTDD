import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class ApiService {
  static const String _tokenKey = 'jwt_auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool isJson = true}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // GET request
  static Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('${ConfigUrl.baseUrl}$endpoint');
    final headers = await _headers();
    return await http.get(uri, headers: headers);
  }

  // POST request
  static Future<http.Response> post(String endpoint, dynamic body) async {
    final uri = Uri.parse('${ConfigUrl.baseUrl}$endpoint');
    final headers = await _headers();
    return await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // PUT request
  static Future<http.Response> put(String endpoint, dynamic body) async {
    final uri = Uri.parse('${ConfigUrl.baseUrl}$endpoint');
    final headers = await _headers();
    return await http.put(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
  }

  // DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final uri = Uri.parse('${ConfigUrl.baseUrl}$endpoint');
    final headers = await _headers();
    return await http.delete(uri, headers: headers);
  }

  // Multipart POST request (Dành cho Chụp ảnh selfie minh chứng khi Chấm công)
  static Future<http.StreamedResponse> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    File? file,
    String fileParamName = 'photo',
  }) async {
    final uri = Uri.parse('${ConfigUrl.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    final headers = await _headers(isJson: false);
    request.headers.addAll(headers);
    request.fields.addAll(fields);

    if (file != null && await file.exists()) {
      request.files.add(await http.MultipartFile.fromPath(fileParamName, file.path));
    }

    return await request.send();
  }
}
