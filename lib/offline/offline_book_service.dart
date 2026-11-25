import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import 'offline_book_format.dart';

class OfflineBookService {
  OfflineBookService._();
  static final instance = OfflineBookService._();

  final Dio _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();

  static const String _listFileName = 'offline_book_list.json';

  Future<Directory> _booksDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/offline_books');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(int bookId) async {
    final dir = await _booksDir();
    return File('${dir.path}/$bookId.mybook');
  }

  Future<File> _listFile() async {
    final base = await getApplicationSupportDirectory();
    return File('${base.path}/$_listFileName');
  }

  // ============================================
  // OFFLINE BOOK LIST CACHE
  // ============================================
  Future<void> saveOfflineBookList(List<Book> books) async {
    try {
      final file = await _listFile();
      final payload =
          books
              .map(
                (b) => {
                  'bookId': b.bookId,
                  'vendorId': b.vendorId,
                  'title': b.title,
                  'price': b.price,
                  'categoryId': b.categoryId,
                  'filePath': b.filePath,
                  'bookCover': b.bookCover,
                  'createdAt': b.createdAt,
                },
              )
              .toList();
      await file.writeAsString(jsonEncode(payload));
      print('OfflineBookService: saved ${books.length} books to cache');
    } catch (e) {
      print('OfflineBookService: saveOfflineBookList error: $e');
    }
  }

  Future<List<Book>> loadOfflineBookList() async {
    try {
      final file = await _listFile();
      if (!await file.exists()) {
        print('OfflineBookService: no cached list file');
        return [];
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final List data = jsonDecode(raw);
      final books =
          data.map((j) => Book.fromJson(Map<String, dynamic>.from(j))).toList();
      print('OfflineBookService: loaded ${books.length} books from cache');
      return books;
    } catch (e) {
      print('OfflineBookService: loadOfflineBookList error: $e');
      return [];
    }
  }

  Future<void> clearOfflineBookList() async {
    try {
      final file = await _listFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ============================================
  // DOWNLOAD / READ (unchanged)
  // ============================================
  Future<File> download(Book book, {void Function(double)? onProgress}) async {
    final file = await _fileFor(book.bookId);
    final token = await ApiClient.getToken();
    if (token == null) throw Exception('Not logged in');

    try {
      await _dio.download(
        '${ApiClient.baseUrl}/api/offline/download/${book.bookId}',
        file.path,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onReceiveProgress: (r, t) {
          if (t > 0 && onProgress != null) onProgress(r / t);
        },
        deleteOnError: true,
      );

      final raw = await file.readAsBytes();
      final container = OfflineBook.parse(raw);

      final resp = await _dio.post(
        '${ApiClient.baseUrl}/api/offline/unwrap-key/${book.bookId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'protectedKey': container.protectedKey,
          'protectedIv': container.protectedIv,
        },
      );

      if (resp.statusCode != 200) throw Exception('Key unwrap failed');

      await _secureStorage.write(
        key: 'offline_key_${book.bookId}',
        value: jsonEncode({
          'key': resp.data['key'],
          'iv': resp.data['iv'],
          'sha': resp.data['sha256'],
        }),
      );

      return file;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Server error: ${e.message}');
    }
  }

  Future<bool> isDownloaded(int bookId) async {
    final f = await _fileFor(bookId);
    return f.exists();
  }

  Future<void> delete(int bookId) async {
    final f = await _fileFor(bookId);
    if (await f.exists()) await f.delete();
    await _secureStorage.delete(key: 'offline_key_$bookId');
  }

  Future<Uint8List> readDecrypted(Book book) async {
    final file = await _fileFor(book.bookId);
    if (!await file.exists()) throw Exception('Book not downloaded');

    final keyJson = await _secureStorage.read(
      key: 'offline_key_${book.bookId}',
    );
    if (keyJson == null) {
      throw Exception('Decryption key missing. Please re-download the book.');
    }
    final keyData = jsonDecode(keyJson);

    final raw = await file.readAsBytes();
    final container = OfflineBook.parse(raw);

    final key = enc.Key.fromBase64(keyData['key']);
    final iv = enc.IV.fromBase64(keyData['iv']);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(container.ciphertext),
      iv: iv,
    );

    final expectedSha = keyData['sha'];
    if (expectedSha != null) {
      final actual = sha256.convert(decrypted).toString();
      if (actual != expectedSha) throw Exception('Book integrity check failed');
    }

    return Uint8List.fromList(decrypted);
  }
}








































































/*import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import 'offline_book_format.dart';

class OfflineBookService {
  OfflineBookService._();
  static final instance = OfflineBookService._();

  final Dio _dio = Dio();
  final _secureStorage = const FlutterSecureStorage();

  Future<Directory> _booksDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/offline_books');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(int bookId) async {
    final dir = await _booksDir();
    return File('${dir.path}/$bookId.mybook');
  }

  Future<File> download(Book book, {void Function(double)? onProgress}) async {
    final file = await _fileFor(book.bookId);
    final token = await ApiClient.getToken();
    if (token == null) throw Exception('Not logged in');

    try {
      // 1. Download the encrypted file
      await _dio.download(
        '${ApiClient.baseUrl}/api/offline/download/${book.bookId}',
        file.path,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onReceiveProgress: (r, t) {
          if (t > 0 && onProgress != null) onProgress(r / t);
        },
        deleteOnError: true,
      );

      // 2. Parse the file to get the protected key/IV
      final raw = await file.readAsBytes();
      final container = OfflineBook.parse(raw);

      // 3. Call the server ONCE to unwrap and get the real AES key
      final resp = await _dio.post(
        '${ApiClient.baseUrl}/api/offline/unwrap-key/${book.bookId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'protectedKey': container.protectedKey,
          'protectedIv': container.protectedIv,
        },
      );

      if (resp.statusCode != 200) throw Exception('Key unwrap failed');

      // 4. Save the unwrapped key to Secure Storage (Hardware encrypted)
      await _secureStorage.write(
        key: 'offline_key_${book.bookId}',
        value: jsonEncode({
          'key': resp.data['key'],
          'iv': resp.data['iv'],
          'sha': resp.data['sha256'],
        }),
      );

      return file;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          throw Exception(data['message']);
        }
      }
      throw Exception('Server error: ${e.message}');
    }
  }

  Future<bool> isDownloaded(int bookId) async {
    final f = await _fileFor(bookId);
    return f.exists();
  }

  Future<void> delete(int bookId) async {
    final f = await _fileFor(bookId);
    if (await f.exists()) await f.delete();
    await _secureStorage.delete(key: 'offline_key_$bookId');
  }

  /// Returns plaintext PDF bytes, fully in memory, 100% OFFLINE.
  Future<Uint8List> readDecrypted(Book book) async {
    final file = await _fileFor(book.bookId);
    if (!await file.exists()) throw Exception('Book not downloaded');

    // 1. Read the securely saved key from the phone's hardware keystore
    final keyJson = await _secureStorage.read(
      key: 'offline_key_${book.bookId}',
    );
    if (keyJson == null) {
      throw Exception('Decryption key missing. Please re-download the book.');
    }
    final keyData = jsonDecode(keyJson);

    // 2. Read the encrypted .mybook container
    final raw = await file.readAsBytes();
    final container = OfflineBook.parse(raw);

    // 3. Decrypt in memory
    final key = enc.Key.fromBase64(keyData['key']);
    final iv = enc.IV.fromBase64(keyData['iv']);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(container.ciphertext),
      iv: iv,
    );

    // 4. Integrity check
    final expectedSha = keyData['sha'];
    if (expectedSha != null) {
      final actual = sha256.convert(decrypted).toString();
      if (actual != expectedSha) throw Exception('Book integrity check failed');
    }

    return Uint8List.fromList(decrypted);
  }

  // ============================================
  // OFFLINE BOOK LIST CACHE
  // ============================================
  static const String _listFileName = 'offline_book_list.json';

  Future<File> _listFile() async {
    final base = await getApplicationSupportDirectory();
    return File('${base.path}/$_listFileName');
  }

  /// Save the list of purchased books locally, so My Books works offline.
  Future<void> saveOfflineBookList(List<Book> books) async {
    try {
      final file = await _listFile();
      final payload =
          books
              .map(
                (b) => {
                  'bookId': b.bookId,
                  'vendorId': b.vendorId,
                  'title': b.title,
                  'price': b.price,
                  'categoryId': b.categoryId,
                  'filePath': b.filePath,
                  'bookCover': b.bookCover,
                  'createdAt': b.createdAt,
                },
              )
              .toList();
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Non-fatal — offline list is a cache, not a source of truth
    }
  }

  /// Load the cached list of purchased books. Returns [] if none.
  Future<List<Book>> loadOfflineBookList() async {
    try {
      final file = await _listFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final List data = jsonDecode(raw);
      return data
          .map((j) => Book.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete the offline book list (e.g., on logout).
  Future<void> clearOfflineBookList() async {
    try {
      final file = await _listFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}*/







































/*import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import 'offline_book_format.dart';

class OfflineBookService {
  OfflineBookService._();
  static final instance = OfflineBookService._();

  final Dio _dio = Dio();

  Future<Directory> _booksDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/offline_books');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _fileFor(int bookId) async {
    final dir = await _booksDir();
    return File('${dir.path}/$bookId.mybook');
  }

  /// Downloads .mybook for [book] using the existing auth header.
  Future<File> download(Book book, {void Function(double)? onProgress}) async {
    final file = await _fileFor(book.bookId);
    final token = await ApiClient.getToken();
    if (token == null) throw Exception('Not logged in');

    await _dio.download(
      '${ApiClient.baseUrl}/api/offline/download/${book.bookId}',
      file.path,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      onReceiveProgress: (r, t) {
        if (t > 0 && onProgress != null) onProgress(r / t);
      },
      deleteOnError: true,
    );
    return file;
  }

  Future<bool> isDownloaded(int bookId) async {
    final f = await _fileFor(bookId);
    return f.exists();
  }

  Future<void> delete(int bookId) async {
    final f = await _fileFor(bookId);
    if (await f.exists()) await f.delete();
  }

  /// Returns plaintext PDF bytes, fully in memory, never written to disk.
  Future<Uint8List> readDecrypted(Book book) async {
    final file = await _fileFor(book.bookId);
    if (!await file.exists()) throw Exception('Book not downloaded');

    final raw = await file.readAsBytes();
    final container = OfflineBook.parse(raw);

    // 1. Ask server to unwrap the key+iv for THIS user
    final token = await ApiClient.getToken();
    if (token == null) throw Exception('Not logged in');

    final resp = await _dio.post(
      '${ApiClient.baseUrl}/api/offline/unwrap-key/${book.bookId}',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {
        'protectedKey': container.protectedKey,
        'protectedIv': container.protectedIv,
      },
    );

    if (resp.statusCode != 200) throw Exception('Key unwrap failed');
    final keyB64 = resp.data['key'] as String;
    final ivB64 = resp.data['iv'] as String;
    final expectedSha = resp.data['sha256'] as String?;

    // 2. Decrypt in memory
    final key = enc.Key.fromBase64(keyB64);
    final iv = enc.IV.fromBase64(ivB64);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(
      enc.Encrypted(container.ciphertext),
      iv: iv,
    );

    // 3. Integrity check (optional but cheap)
    if (expectedSha != null) {
      final actual = sha256.convert(decrypted).toString();
      if (actual != expectedSha) throw Exception('Book integrity check failed');
    }

    return Uint8List.fromList(decrypted);
  }
}
*/