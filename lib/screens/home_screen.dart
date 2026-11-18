import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/category.dart';
import '../models/book.dart';
import '../utils/theme.dart';
import 'category_books_screen.dart';
import 'my_books_screen.dart';
import 'book_requests_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _rootCategories = [];
  bool _loading = true;
  String? _error;

  int? _customerId;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
    _loadCategories();
  }

  Future<void> _loadCustomer() async {
    final customer = await ApiClient.getCurrentCustomer();
    setState(() => _customerId = customer?['customerId']);
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final all = await ApiClient.getCategories();
      setState(() {
        _rootCategories = all.where((c) => c.isRoot).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _navigateToCategory(Category cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryBooksScreen(category: cat), // ← FIXED
      ),
    );
  }

  void _openMyBooks() {
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyBooksScreen(),
      ),
    );
  }

  void _openBookRequests() {
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BookRequestsScreen(), // ← fixed
      ),
    );
  }

  void _logout() async {
    await ApiClient.saveToken(null);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.menu_book, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'E-Book Reader',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer #${_customerId ?? "?"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.library_books, color: AppTheme.primary),
              title: const Text('Books Gallery',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              selected: true,
              selectedTileColor: AppTheme.primary.withOpacity(0.1),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: AppTheme.primary),
              title: const Text('My Books'),
              onTap: () {
                Navigator.pop(context);
                _openMyBooks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined,
                  color: AppTheme.primary),
              title: const Text('My Cart'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: AppTheme.primary),
              title: const Text('Book Requests'),
              onTap: () {
                Navigator.pop(context);
                _openBookRequests();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: _buildCategoryGrid(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load categories',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _loadCategories, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_rootCategories.isEmpty) {
      return const Center(child: Text('No categories yet'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _rootCategories.length,
      itemBuilder: (context, i) {
        final cat = _rootCategories[i];
        final color = _colorForIndex(i);

        return InkWell(
          onTap: () => _navigateToCategory(cat),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.folder, color: Colors.white, size: 32),
                Text(
                  cat.categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _colorForIndex(int i) {
    final colors = [
      const Color(0xFF5B2FA6),
      const Color(0xFF8B5CF6),
      const Color(0xFF0D7A5F),
      const Color(0xFFE76F51),
      const Color(0xFF264653),
      const Color(0xFF2A9D8F),
    ];
    return colors[i % colors.length];
  }
}

/*import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/category.dart';
import '../utils/theme.dart';
import 'category_books_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _rootCategories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final all = await ApiClient.getCategories();
      setState(() {
        _rootCategories = all.where((c) => c.isRoot).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiClient.saveToken(null);
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: _buildCategoryGrid(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (_rootCategories.isEmpty) {
      return const Center(child: Text('No categories yet'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _rootCategories.length,
      itemBuilder: (context, i) {
        final cat = _rootCategories[i];
        final color = _colorForIndex(i);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryBooksScreen(category: cat),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.folder, color: Colors.white, size: 32),
                Text(
                  cat.categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _colorForIndex(int i) {
    final colors = [
      const Color(0xFF5B2FA6),
      const Color(0xFF8B5CF6),
      const Color(0xFF0D7A5F),
      const Color(0xFFE76F51),
      const Color(0xFF264653),
      const Color(0xFF2A9D8F),
    ];
    return colors[i % colors.length];
  }
}*/
