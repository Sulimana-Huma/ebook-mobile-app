import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../utils/theme.dart';
import 'pdf_reader_screen.dart';
import '../offline/offline_book_service.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  List<Book> _books = [];
  bool _loading = true;
  String? _error;

  // NEW: per-book download state
  final Map<int, double> _downloading = {};
  final Map<int, bool> _downloaded = {};

  @override
  void initState() {
    super.initState();
    _loadMyBooks().then(
      (_) => _refreshDownloadedFlags(),
    ); // NEW: also check already-downloaded
  }

  // NEW: mark books that are already on disk
  Future<void> _refreshDownloadedFlags() async {
    for (final b in _books) {
      final done = await OfflineBookService.instance.isDownloaded(b.bookId);
      if (mounted) setState(() => _downloaded[b.bookId] = done);
    }
  }

  // NEW: download handler
  Future<void> _download(Book book) async {
    setState(() => _downloading[book.bookId] = 0);
    try {
      await OfflineBookService.instance.download(
        book,
        onProgress: (p) {
          if (mounted) setState(() => _downloading[book.bookId] = p);
        },
      );
      setState(() {
        _downloading.remove(book.bookId);
        _downloaded[book.bookId] = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title} saved for offline reading')),
        );
      }
    } catch (e) {
      setState(() => _downloading.remove(book.bookId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  Future<void> _loadMyBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // 1. Load cached list first — works without Wi-Fi
    List<Book> cached = [];
    try {
      cached = await OfflineBookService.instance.loadOfflineBookList();
    } catch (_) {}

    if (cached.isNotEmpty) {
      setState(() {
        _books = cached;
        _loading = false;
      });
      await _refreshDownloadedFlags();
    }

    // 2. Try to fetch fresh from API
    try {
      final books = await ApiClient.getMyBooks();
      setState(() {
        _books = books;
        _loading = false;
        _error = null;
      });
      await _refreshDownloadedFlags();

      // 3. Save fresh list for next offline use
      try {
        await OfflineBookService.instance.saveOfflineBookList(books);
      } catch (_) {}
    } catch (e) {
      // If API fails but cache exists → keep showing cache, no error
      if (cached.isEmpty) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMyBooks),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMyBooks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _books.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.library_books_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No purchased books yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add books to cart and complete checkout on the website to see them here.',
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
                itemBuilder: (context, i) {
                  final book = _books[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _openBook(book),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCover(book),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Purchased',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _buildDownloadAction(book),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildDownloadAction(Book book) {
    final progress = _downloading[book.bookId];
    if (progress != null) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2, value: progress),
        ),
      );
    }
    if (_downloaded[book.bookId] == true) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.offline_pin, color: Colors.green),
      );
    }
    return IconButton(
      icon: const Icon(Icons.download_for_offline_outlined),
      tooltip: 'Download for offline',
      onPressed: () => _download(book),
    );
  }

  Widget _buildCover(Book book) {
    final coverUrl =
        book.bookCover.isNotEmpty
            ? (book.bookCover.startsWith('/api/')
                ? '${ApiClient.baseUrl}${book.bookCover}'
                : '${ApiClient.baseUrl}${book.bookCover}')
            : null;

    return Container(
      width: 60,
      height: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.primary.withOpacity(0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          coverUrl != null
              ? CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                errorWidget:
                    (_, __, ___) => const Center(
                      child: Icon(
                        Icons.menu_book,
                        color: AppTheme.primary,
                        size: 32,
                      ),
                    ),
              )
              : const Center(
                child: Icon(Icons.menu_book, color: AppTheme.primary, size: 32),
              ),
    );
  }
}
