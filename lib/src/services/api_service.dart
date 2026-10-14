import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/deshprio_models.dart';
import 'settings_service.dart';

class ApiService {
  ApiService(this.settings);

  final SettingsService settings;

  Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final params = <String, String>{};
    query.forEach((key, value) {
      if (value != null && value.isNotEmpty) params[key] = value;
    });
    return Uri.parse('${settings.baseUrl}$cleanPath')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    Map<String, String?> query = const {},
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers['Content-Type'] = 'application/json; charset=utf-8';
    if (settings.authToken != null) {
      request.headers['Cookie'] = 'token=${settings.authToken}';
    }
    if (body != null) request.body = jsonEncode(body);

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final text = await streamed.stream.bytesToString();
    final decoded = text.isEmpty ? null : _decodeResponse(text);

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ?? 'সার্ভার অনুরোধটি নেয়নি'
          : 'সার্ভার অনুরোধটি নেয়নি';
      throw ApiException(message,
          status: decoded is Map<String, dynamic>
              ? decoded['status']?.toString()
              : null);
    }
    return decoded;
  }

  Future<List<Item>> getItems() async {
    final json = await _request('GET', '/items');
    final data = _pick(json, const ['data', 'items']);
    return _list(data).map((e) => Item.fromJson(e)).toList();
  }

  Future<void> login({required String email, required String password}) async {
    final json = await _request('POST', '/users/login',
        body: {'email': email, 'password': password});
    if (json is Map<String, dynamic>) {
      final token = json['token']?.toString();
      if (token != null && token.isNotEmpty) {
        await settings.setAuthToken(token);
        return;
      }
    }
    throw ApiException('লগইন token পাওয়া যায়নি');
  }

  Future<void> logout() async {
    await settings.setAuthToken(null);
  }

  Future<void> addItem(String name) async {
    await _request('POST', '/items', body: {'name': name});
  }

  Future<List<Store>> getStores() async {
    final json = await _request('GET', '/stores');
    final data = _pick(json, const ['data', 'stores']);
    return _list(data).map((e) => Store.fromJson(e)).toList();
  }

  Future<void> addStore(String name) async {
    await _request('POST', '/stores', body: {'name': name});
  }

  Future<List<StoreItemPriceList>> getStoreItems() async {
    final json = await _request('GET', '/store-item');
    final data = _pick(json, const ['data', 'storeItems']);
    return _list(data).map((e) => StoreItemPriceList.fromJson(e)).toList();
  }

  Future<void> addStoreItemPrices({
    required String storeId,
    required String storeName,
    required List<StorePrice> itemPrices,
  }) async {
    await _request('POST', '/store-item', body: {
      'storeId': storeId,
      'storeName': storeName,
      'itemPrices': itemPrices
          .map((item) => {
                'itemId': item.itemId,
                'itemName': item.itemName,
                'pricePerKg': item.pricePerKg,
              })
          .toList(),
    });
  }

  Future<DashboardStats> getDashboardStats() async {
    final json = await _request('GET', '/dashboard/monthly-stats');
    final data = _pick(json, const ['data']);
    return DashboardStats.fromJson(data is Map<String, dynamic> ? data : {});
  }

  Future<dynamic> getRetailSales({String? date}) async {
    final json = await _request('GET', '/retail-sale', query: {'date': date});
    return _pick(json, const ['data', 'sales']);
  }

  Future<void> createRetailSale(List<SaleDraftItem> items) async {
    await _request('POST', '/retail-sale', body: {
      'items': items
          .map((item) => {
                'itemId': item.itemId,
                'itemName': item.itemName,
                'quantity': item.quantity,
                'pricePerKg': item.pricePerKg,
                'totalPrice': item.total,
              })
          .toList(),
    });
  }

  Future<dynamic> getWholesaleSales({String? date}) async {
    final json =
        await _request('GET', '/wholesale-sale', query: {'date': date});
    return _pick(json, const ['data', 'sales']);
  }

  Future<void> createWholesaleSale(
      {required String storeId, required List<SaleDraftItem> items}) async {
    await _request('POST', '/wholesale-sale', body: {
      'storeId': storeId,
      'items': items
          .map((item) => {
                'itemId': item.itemId,
                'quantity': item.quantity,
                'pricePerKg': item.pricePerKg,
              })
          .toList(),
    });
  }

  Future<dynamic> getBuys({String? date}) async {
    final json = await _request('GET', '/buy', query: {'date': date});
    return _pick(json, const ['data', 'buys']);
  }

  Future<void> createBuy(
      {required String itemId, required double quantity}) async {
    await _request('POST', '/buy',
        body: {'itemId': itemId, 'quantity': quantity});
  }

  Future<dynamic> getExpenses({String? date}) async {
    final json = await _request('GET', '/expense', query: {'date': date});
    return _pick(json, const ['data', 'expenses']);
  }

  Future<void> createExpense(
      {required String itemId, required double quantity}) async {
    await _request('POST', '/expense',
        body: {'itemId': itemId, 'quantity': quantity});
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.status});

  final String message;
  final String? status;

  @override
  String toString() => message;
}

List<Map<String, dynamic>> _list(dynamic data) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  }
  return const [];
}

dynamic _pick(dynamic json, List<String> keys) {
  if (json is Map<String, dynamic>) {
    for (final key in keys) {
      if (json.containsKey(key)) return json[key];
    }
  }
  return json;
}

dynamic _decodeResponse(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return {'message': text};
  }
}
