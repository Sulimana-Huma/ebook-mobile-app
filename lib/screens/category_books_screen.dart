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
