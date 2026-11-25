import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../widgets/book_card.dart';
import 'pdf_reader_screen.dart';

class CategoryBooksScreen extends StatefulWidget {
  final Category category;
  const CategoryBooksScreen({super.key, required this.category});

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  List<Book> _books = [];
  List<Category> _subCategories = [];
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
    try {
      // 1. Fetch ALL categories and filter children locally
      final all = await ApiClient.getCategories();
      final children =
          all.where((c) => c.parentId == widget.category.id).toList();

      debugPrint(
        'Category "${widget.category.categoryName}" (id=${widget.category.id}) '
        'has ${children.length} children',
      );

      // 2. Fetch books (backend now includes subtree)
      final books = await ApiClient.getBooksByCategory(widget.category.id);

      setState(() {
        _subCategories = children;
        _books = books;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openBook(Book book) async {
    if (book.price <= 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
      );
      return;
    }

    try {
      final access = await ApiClient.canAccessBook(book.bookId);
      if (access['canAccess'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
        );
        return;
      }
      _showPurchaseDialog(book);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not check access: $e')));
    }
  }

  void _showPurchaseDialog(Book book) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(book.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price: \$${book.price.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                const Text(
                  'This is a paid book. Add it to your cart and complete the purchase to read it.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final ok = await ApiClient.addToCart(book.bookId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Added to cart. Go to Cart → Request Purchase to buy.'
                              : 'Failed to add to cart',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Add to Cart'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.categoryName)),
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
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : _books.isEmpty && _subCategories.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No books or sub-categories here yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // ============================================
                  // SUB-CATEGORIES (shown first)
                  // ============================================
                  if (_subCategories.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Text(
                        'Sub-Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    ..._subCategories.map(
                      (sub) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.folder,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            sub.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CategoryBooksScreen(category: sub),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ============================================
                  // BOOKS (shown after sub-categories)
                  // ============================================
                  if (_books.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Text(
                        'Books',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    ..._books.map(
                      (book) =>
                          BookCard(book: book, onTap: () => _openBook(book)),
                    ),
                  ],
                ],
              ),
    );
  }
}





























































/*import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../widgets/book_card.dart';
import 'pdf_reader_screen.dart';

class CategoryBooksScreen extends StatefulWidget {
  final Category category;
  const CategoryBooksScreen({super.key, required this.category});

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  List<Book> _books = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final books = await ApiClient.getBooksByCategory(widget.category.id);
      setState(() => _books = books);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openBook(Book book) async {
    if (book.price <= 0) {
      // FREE — open directly
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
      );
      return;
    }

    // PAID — check access first
    try {
      final access = await ApiClient.canAccessBook(book.bookId);
      if (access['canAccess'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
        );
        return;
      }

      // Not purchased — show purchase dialog
      _showPurchaseDialog(book);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check access: $e')),
      );
    }
  }

  void _showPurchaseDialog(Book book) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(book.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: \$${book.price.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Text(
              'This is a paid book. Add it to your cart and complete the purchase to read it.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ApiClient.addToCart(book.bookId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Added to cart. Go to Cart → Request Purchase to buy.'
                        : 'Failed to add to cart'),
                  ),
                );
              }
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.categoryName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadBooks, child: const Text('Retry')),
                    ],
                  ),
                )
              : _books.isEmpty
                  ? const Center(child: Text('No books in this category yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _books.length,
                      itemBuilder: (context, i) {
                        final book = _books[i];
                        return BookCard(
                          book: book,
                          onTap: () => _openBook(book),
                        );
                      },
                    ),
    );
  }
}
*/