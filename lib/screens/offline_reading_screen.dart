import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../offline/offline_book_service.dart';
import 'pdf_reader_screen.dart';

class OfflineReadingScreen extends StatefulWidget {
  const OfflineReadingScreen({super.key});
  @override
  State<OfflineReadingScreen> createState() => _OfflineReadingScreenState();
}

class _OfflineReadingScreenState extends State<OfflineReadingScreen> {
  List<Book> _books = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // ============================================
    // STEP 1 — Load local cache FIRST (works offline)
    // ============================================
    List<Book> localDownloaded = [];
    try {
      final cachedList =
          await OfflineBookService.instance.loadOfflineBookList();
      for (final b in cachedList) {
        if (await OfflineBookService.instance.isDownloaded(b.bookId)) {
          localDownloaded.add(b);
        }
      }
    } catch (e) {
      debugPrint('Offline cache read failed: $e');
    }

    if (mounted) {
      setState(() {
        _books = localDownloaded;
        _loading = false;
      });
    }

    // ============================================
    // STEP 2 — Try API to refresh cache
    // ============================================
    try {
      final all = await ApiClient.getMyBooks();
      final kept = <Book>[];
      for (final b in all) {
        if (await OfflineBookService.instance.isDownloaded(b.bookId)) {
          kept.add(b);
        }
      }
      if (mounted) setState(() => _books = kept);

      // Refresh local cache for next offline launch
      try {
        await OfflineBookService.instance.saveOfflineBookList(all);
      } catch (_) {}
    } catch (e) {
      debugPrint('API refresh failed (offline?): $e');
      // Keep local list — do nothing
    }
  }

  Future<void> _open(Book book) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final Uint8List bytes = await OfflineBookService.instance.readDecrypted(
        book,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(book: book, preloadedBytes: bytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Open failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Reading'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _books.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.offline_bolt_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No downloaded books',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Go to My Books and tap the download icon to save books for offline reading.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _books.length,
                itemBuilder: (_, i) {
                  final b = _books[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.offline_pin,
                        color: Colors.green,
                      ),
                      title: Text(b.title),
                      subtitle: const Text('Available offline'),
                      trailing: const Icon(Icons.menu_book),
                      onTap: () => _open(b),
                    ),
                  );
                },
              ),
    );
  }
}

/*import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../offline/offline_book_service.dart';
import '../utils/theme.dart';
import 'pdf_reader_screen.dart';

class OfflineReadingScreen extends StatefulWidget {
  const OfflineReadingScreen({super.key});
  @override
  State<OfflineReadingScreen> createState() => _OfflineReadingScreenState();
}

class _OfflineReadingScreenState extends State<OfflineReadingScreen> {
  List<Book> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    List<Book> localDownloaded = [];

    // STEP 1 — Read local cache first (works offline)
    try {
      final cachedList =
          await OfflineBookService.instance.loadOfflineBookList();
      for (final b in cachedList) {
        if (await OfflineBookService.instance.isDownloaded(b.bookId)) {
          localDownloaded.add(b);
        }
      }
    } catch (e) {
      debugPrint('Offline cache read error: $e');
    }

    // STEP 2 — Show whatever we have immediately
    if (mounted) {
      setState(() {
        _books = localDownloaded;
        _loading = false;
      });
    }

    // STEP 3 — Try the API. If it works, refresh; if it fails, keep local list.
    try {
      final all = await ApiClient.getMyBooks();
      final kept = <Book>[];
      for (final b in all) {
        if (await OfflineBookService.instance.isDownloaded(b.bookId)) {
          kept.add(b);
        }
      }
      if (mounted) setState(() => _books = kept);

      // Also refresh the cached list so next time works offline
      try {
        await OfflineBookService.instance.saveOfflineBookList(all);
      } catch (_) {}
    } catch (e) {
      debugPrint('API fetch failed (offline?): $e');
      // Keep local list — do NOT clear _books, do NOT show error
    }
  }

  Future<void> _open(Book book) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final Uint8List bytes = await OfflineBookService.instance.readDecrypted(
        book,
      );
      if (!mounted) return;
      Navigator.pop(context); // close loader
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(book: book, preloadedBytes: bytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Open failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Reading')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _books.isEmpty
              ? const Center(child: Text('No downloaded books'))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _books.length,
                itemBuilder: (_, i) {
                  final b = _books[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.offline_pin,
                        color: Colors.green,
                      ),
                      title: Text(b.title),
                      subtitle: const Text('Available offline'),
                      trailing: const Icon(Icons.menu_book),
                      onTap: () => _open(b),
                    ),
                  );
                },
              ),
    );
  }
}*/
