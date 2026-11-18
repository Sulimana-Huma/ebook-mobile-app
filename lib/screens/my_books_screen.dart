import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../utils/theme.dart';
import 'pdf_reader_screen.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  List<Book> _books = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyBooks();
  }

  Future<void> _loadMyBooks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final books = await ApiClient.getMyBooks();
      setState(() => _books = books);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadMyBooks, child: const Text('Retry')),
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
                            Icon(Icons.library_books_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No purchased books yet',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () => _openBook(book),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  _buildCover(book),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(book.title,
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle,
                                                color: Colors.green, size: 16),
                                            const SizedBox(width: 4),
                                            const Text('Purchased',
                                                style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildCover(Book book) {
    final coverUrl = book.bookCover.isNotEmpty
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
      child: coverUrl != null
          ? CachedNetworkImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.menu_book, color: AppTheme.primary, size: 32),
              ),
            )
          : const Center(child: Icon(Icons.menu_book, color: AppTheme.primary, size: 32)),
    );
  }
}
