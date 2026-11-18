import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/book.dart';

class ApiClient {
  // ⚠️ CHANGE to HTTPS domain for production. Use http only during dev.
  static const String baseUrl = 'http://39.61.50.79:8080';

  //static const String baseUrl = 'http://localhost:5158';

  static String? _authToken;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  static Future<void> saveToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('auth_token');
    } else {
      await prefs.setString('auth_token', token);
    }
  }

  static Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json'};
    if (_authToken != null) h['Authorization'] = 'Bearer $_authToken';
    return h;
  }

  // ============================================
  // LOGIN
  // ============================================
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Login failed');
    }

    // New backend returns: { token, userType, id, name, email }
    if (data['token'] != null) {
      await saveToken(data['token'] as String);
    }
    await saveCurrentCustomer({
      'customerId': data['id'],
      'fullName': data['name'],
      'email': data['email'],
      'userType': data['userType'],
    });

    return data;
  }

  // ============================================
  // CATEGORIES
  // ============================================
  static Future<List<Category>> getCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/api/categories'),
        headers: _headers());
    if (res.statusCode != 200)
      throw Exception('Failed to load categories (${res.statusCode})');
    final List data = jsonDecode(res.body);
    return data.map((j) => Category.fromJson(j)).toList();
  }

  // ============================================
  // BOOKS BY CATEGORY
  // ============================================
  static Future<List<Book>> getBooksByCategory(int categoryId,
      {int page = 1, int pageSize = 100}) async {
    final uri = Uri.parse(
        '$baseUrl/api/books/by-category-id/$categoryId?page=$page&pageSize=$pageSize');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode != 200)
      throw Exception('Failed to load books (${res.statusCode})');

    final json = jsonDecode(res.body);
    final List data = json['data'] ?? [];
    return data.map((j) => Book.fromJson(j)).toList();
  }

  static Future<int> getTotalBookCount() async {
    final res = await http.get(Uri.parse('$baseUrl/api/books/total-book-count'),
        headers: _headers());
    if (res.statusCode != 200) return 0;
    return jsonDecode(res.body)['totalBooks'] ?? 0;
  }

  // ============================================
  // BUILD BOOK URL (download via backend auth check)
  // ============================================
  static String buildBookUrl(Book book) {
    if (book.filePath.startsWith('/api/')) return '$baseUrl${book.filePath}';

    if (book.filePath.startsWith('/mnt/') ||
        book.filePath.startsWith('/home/')) {
      return '$baseUrl/api/books/serve-hard-drive-book?filePath=${Uri.encodeComponent(book.filePath)}';
    }
    return '$baseUrl/api/books/serve-file/${book.vendorId}/${Uri.encodeComponent(book.filePath)}';
  }

  static Future<Uint8List> downloadBook(Book book) async {
    final url = buildBookUrl(book);
    final res = await http.get(Uri.parse(url), headers: _headers());
    if (res.statusCode != 200)
      throw Exception('Failed to download (${res.statusCode})');
    return res.bodyBytes;
  }

  // ============================================
  // CAN-ACCESS — customer identity from token
  // ============================================
  static Future<Map<String, dynamic>> canAccessBook(int bookId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/purchaserequests/can-access?bookId=$bookId'),
      headers: _headers(),
    );
    if (res.statusCode != 200) return {'canAccess': false, 'reason': 'error'};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ============================================
  // ADD TO CART — /me route, identity from token
  // ============================================
  static Future<bool> addToCart(int bookId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/customers/me/cart'),
      headers: _headers(),
      body: jsonEncode({'bookId': bookId}),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ============================================
  // MY BOOKS — /my-books, identity from token
  // ============================================
  static Future<List<Book>> getMyBooks() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/purchaserequests/my-books'),
      headers: _headers(),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to load my books (${res.statusCode})');
    final json = jsonDecode(res.body);
    final List data = json['books'] ?? [];
    return data.map((j) => Book.fromJson(j)).toList();
  }

  // ============================================
  // MY REQUESTS — /me, identity from token
  // ============================================
  static Future<List<Map<String, dynamic>>> getMyRequests() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/purchaserequests/me'),
      headers: _headers(),
    );
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body);
    return (json['requests'] as List).cast<Map<String, dynamic>>();
  }

  // ============================================
  // CURRENT CUSTOMER (from SharedPreferences)
  // ============================================
  static Future<Map<String, dynamic>?> getCurrentCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCurrentCustomer(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user));
  }

// ============================================
// CART
// ============================================
  static Future<List<Map<String, dynamic>>> getCart() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/customers/me/cart'),
      headers: _headers(),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to load cart (${res.statusCode})');
    final json = jsonDecode(res.body);
    return (json['items'] as List).cast<Map<String, dynamic>>();
  }

  static Future<bool> removeFromCart(int cartId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/customers/me/cart/$cartId'),
      headers: _headers(),
    );
    return res.statusCode == 200;
  }

// ============================================
// PURCHASE REQUESTS
// ============================================
  static Future<Map<String, dynamic>> createPurchaseRequest(
      List<int> bookIds) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/purchaserequests/create'),
      headers: _headers(),
      body: jsonEncode({'bookIds': bookIds}),
    );
    if (res.statusCode != 200)
      throw Exception('Request failed (${res.statusCode})');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

/*import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/book.dart';

class ApiClient {
  // ⚠️ Use your server's IP/domain here
  static const String baseUrl = 'http://39.61.50.79:8080';

  // ---- Auth token cache ----
  static String? _authToken;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  static Future<void> saveToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('auth_token');
    } else {
      await prefs.setString('auth_token', token);
    }
  }

  static Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      h['Authorization'] = 'Bearer $_authToken';
    }
    return h;
  }

  // ============================================
  // LOGIN
  // ============================================

static Future<Map<String, dynamic>> login(String email, String password) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password, 'userType': 'Customer'}),
  );

  final data = jsonDecode(res.body);
  if (res.statusCode != 200) {
    throw Exception(data['message'] ?? 'Login failed');
  }

  if (data['token'] != null) {
    await saveToken(data['token']);
  }
  if (data['user'] != null) {
    await saveCurrentCustomer(Map<String, dynamic>.from(data['user']));
  } else if (data['customer'] != null) {
    await saveCurrentCustomer(Map<String, dynamic>.from(data['customer']));
  }

  return data;
}

 

  // ============================================
  // CATEGORIES
  // ============================================
  static Future<List<Category>> getCategories() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/categories'),
      headers: _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load categories (${res.statusCode})');
    }

    final List data = jsonDecode(res.body);
    return data.map((j) => Category.fromJson(j)).toList();
  }

  // ============================================
  // BOOKS BY CATEGORY
  // ============================================
  static Future<List<Book>> getBooksByCategory(
    int categoryId, {
    int page = 1,
    int pageSize = 100,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/books/by-category-id/$categoryId?page=$page&pageSize=$pageSize',
    );
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Failed to load books (${res.statusCode})');
    }

    final json = jsonDecode(res.body);
    final List data = json['data'] ?? [];
    return data.map((j) => Book.fromJson(j)).toList();
  }

  // ============================================
  // TOTAL BOOK COUNT (for home stats)
  // ============================================
  static Future<int> getTotalBookCount() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/books/total-book-count'),
      headers: _headers(),
    );

    if (res.statusCode != 200) return 0;

    final data = jsonDecode(res.body);
    return data['totalBooks'] ?? 0;
  }

  // ============================================
  // BUILD the actual PDF URL for a book
  // ============================================
  static String buildBookUrl(Book book) {
    // Case 1: Backend already returned a ready-made URL
    if (book.filePath.startsWith('/api/')) {
      return '$baseUrl${book.filePath}';
    }

    // Case 2: Full disk path (hard-drive book)
    if (book.filePath.startsWith('/mnt/') || book.filePath.startsWith('/home/')) {
      return '$baseUrl/api/books/serve-hard-drive-book?filePath=${Uri.encodeComponent(book.filePath)}';
    }

    // Case 3: Just a filename (vendor upload)
    return '$baseUrl/api/books/serve-file/${book.vendorId}/${Uri.encodeComponent(book.filePath)}';
  }

  // ============================================
  // DOWNLOAD PDF as bytes (for offline reading)
  // ============================================
  static Future<Uint8List> downloadBook(Book book) async {
    final url = buildBookUrl(book);
    final res = await http.get(Uri.parse(url), headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('Failed to download (${res.statusCode})');
    }

    return res.bodyBytes;
  }

// ============================================
// CHECK ACCESS — Can customer open this book?
// ============================================
static Future<Map<String, dynamic>> canAccessBook(int customerId, int bookId) async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/purchaserequests/can-access?customerId=$customerId&bookId=$bookId'),
    headers: _headers(),
  );

  if (res.statusCode != 200) {
    return {'canAccess': false, 'reason': 'error'};
  }

  return jsonDecode(res.body);
}

// ============================================
// ADD TO CART
// ============================================
static Future<bool> addToCart(int customerId, int bookId) async {
  final res = await http.post(
    Uri.parse('$baseUrl/api/customers/$customerId/cart'),
    headers: _headers(),
    body: jsonEncode({'bookId': bookId}),
  );

  return res.statusCode == 200 || res.statusCode == 201;
}

// ============================================
// GET PURCHASED BOOKS (My Books)
// ============================================
static Future<List<Book>> getMyBooks(int customerId) async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/purchaserequests/my-books/$customerId'),
    headers: _headers(),
  );

  if (res.statusCode != 200) {
    throw Exception('Failed to load my books (${res.statusCode})');
  }

  final json = jsonDecode(res.body);
  final List data = json['books'] ?? [];
  return data.map((j) => Book.fromJson(j)).toList();
}

// ============================================
// GET CUSTOMER PURCHASE REQUESTS
// ============================================
static Future<List<Map<String, dynamic>>> getMyRequests(int customerId) async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/purchaserequests/customer/$customerId'),
    headers: _headers(),
  );

  if (res.statusCode != 200) return [];

  final json = jsonDecode(res.body);
  return (json['requests'] as List).cast<Map<String, dynamic>>();
}

static Future<Map<String, dynamic>?> getCurrentCustomer() async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString('current_user');
  if (userJson == null) return null;
  try {
    return jsonDecode(userJson);
  } catch (_) {
    return null;
  }
}

static Future<void> saveCurrentCustomer(Map<String, dynamic> user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(user));
}


}*/
