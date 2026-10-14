class ApiResponse<T> {
  ApiResponse({required this.success, this.status, this.message, this.data});

  final bool success;
  final String? status;
  final String? message;
  final T? data;
}

class Item {
  Item({required this.id, required this.name});

  final String id;
  final String name;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
        id: json['id']?.toString() ?? '', name: json['name']?.toString() ?? '');
  }
}

class Store {
  Store({required this.id, required this.name});

  final String id;
  final String name;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
        id: json['id']?.toString() ?? '', name: json['name']?.toString() ?? '');
  }
}

class StorePrice {
  StorePrice({
    required this.itemId,
    required this.itemName,
    required this.pricePerKg,
  });

  final String itemId;
  final String itemName;
  final double pricePerKg;

  factory StorePrice.fromJson(Map<String, dynamic> json) {
    return StorePrice(
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      pricePerKg: _toDouble(json['pricePerKg']),
    );
  }
}

class StoreItemPriceList {
  StoreItemPriceList({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.itemPrices,
  });

  final String id;
  final String storeId;
  final String storeName;
  final List<StorePrice> itemPrices;

  factory StoreItemPriceList.fromJson(Map<String, dynamic> json) {
    final raw = json['itemPrices'];
    return StoreItemPriceList(
      id: json['id']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      itemPrices: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(StorePrice.fromJson)
              .toList()
          : const [],
    );
  }
}

class SaleDraftItem {
  SaleDraftItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.pricePerKg,
  });

  final String itemId;
  final String itemName;
  final double quantity;
  final double pricePerKg;

  double get total => quantity * pricePerKg;
}

class DashboardStats {
  DashboardStats({
    required this.totalBuy,
    required this.totalSale,
    required this.totalStock,
    required this.monthlyData,
  });

  final double totalBuy;
  final double totalSale;
  final double totalStock;
  final List<Map<String, dynamic>> monthlyData;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final nested = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return DashboardStats(
      totalBuy: _toDouble(nested['totalBuy']),
      totalSale: _toDouble(nested['totalSale']),
      totalStock: _toDouble(nested['totalStock']),
      monthlyData: nested['monthlyData'] is List
          ? (nested['monthlyData'] as List)
              .whereType<Map<String, dynamic>>()
              .toList()
          : const [],
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
