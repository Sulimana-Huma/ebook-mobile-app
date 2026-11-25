import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../utils/theme.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final double? downloadProgress; // optional: pass from parent

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.downloadProgress,
  });

  String _cleanTitle(String raw) {
    var t = raw;
    if (t.toLowerCase().endsWith('.pdf')) t = t.substring(0, t.length - 4);
    t = t.replaceAll('_', ' ').replaceAll('-', ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty ? 'Untitled' : t;
  }

  String? _coverUrl() {
    final cover = book.bookCover.trim();
    if (cover.isEmpty) return null;
    if (cover.startsWith('http://') || cover.startsWith('https://'))
      return cover;
    if (cover.startsWith('/api/')) return '${ApiClient.baseUrl}$cover';
    return '${ApiClient.baseUrl}/api/books/serve-file/${book.vendorId}/${Uri.encodeComponent(cover)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = book.price > 0;
    final displayTitle = _cleanTitle(book.title);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // ← top-aligned
            children: [
              // Cover
              Stack(
                children: [
                  SizedBox(
                    width: 60,
                    height: 85,
                    child: _buildCover(displayTitle),
                  ),
                  if (isPaid)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Text block — takes remaining width, height determined by content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // ← critical: no forced fill
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isPaid
                                ? Colors.orange.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isPaid
                            ? 'Paid · \$${book.price.toStringAsFixed(2)}'
                            : 'Free',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              isPaid
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                        ),
                      ),
                    ),
                    if (downloadProgress != null) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: downloadProgress),
                    ],
                  ],
                ),
              ),

              // Trailing icon
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  isPaid ? Icons.lock_outline : Icons.chevron_right,
                  color: isPaid ? Colors.orange : Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String displayTitle) {
    final url = _coverUrl();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.primary.withOpacity(0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          url != null
              ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                errorWidget: (_, __, ___) => _placeholder(displayTitle),
              )
              : _placeholder(displayTitle),
    );
  }

  Widget _placeholder(String displayTitle) {
    return Container(
      color: AppTheme.primary.withOpacity(0.15),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Text(
        displayTitle,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 8,
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}






































































/*import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../utils/theme.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  String _cleanTitle(String raw) {
    var t = raw;
    if (t.toLowerCase().endsWith('.pdf')) t = t.substring(0, t.length - 4);
    t = t.replaceAll('_', ' ').replaceAll('-', ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty ? 'Untitled' : t;
  }

  String? _coverUrl() {
    final cover = book.bookCover.trim();
    if (cover.isEmpty) return null;

    // Full URL already
    if (cover.startsWith('http://') || cover.startsWith('https://')) return cover;

    // Backend-relative path
    if (cover.startsWith('/api/')) return '${ApiClient.baseUrl}$cover';

    // Just a filename — assume it's a vendor cover under serve-file
    return '${ApiClient.baseUrl}/api/books/serve-file/${book.vendorId}/${Uri.encodeComponent(cover)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = book.price > 0;
    final displayTitle = _cleanTitle(book.title);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  _buildCover(displayTitle),
                  if (isPaid)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.orange.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isPaid ? 'Paid · \$${book.price.toStringAsFixed(2)}' : 'Free',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPaid ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (book.createdAt != null)
                      Text(
                        'Added: ${book.createdAt!.split('T').first}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              Icon(isPaid ? Icons.lock_outline : Icons.chevron_right,
                  color: isPaid ? Colors.orange : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String displayTitle) {
    final url = _coverUrl();
    return Container(
      width: 60,
      height: 85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.primary.withOpacity(0.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (_, __, ___) => _placeholder(displayTitle),
            )
          : _placeholder(displayTitle),
    );
  }

  Widget _placeholder(String displayTitle) {
    // Styled text fallback — looks like a mini book cover
    return Container(
      color: AppTheme.primary.withOpacity(0.15),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Text(
        displayTitle,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9,
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}*/
















































/*import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../utils/theme.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaid = book.price > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  _buildCover(),
                  if (isPaid)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.orange.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isPaid ? 'Paid · \$${book.price.toStringAsFixed(2)}' : 'Free',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPaid ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (book.createdAt != null)
                      Text(
                        'Added: ${book.createdAt!.split('T').first}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              Icon(isPaid ? Icons.lock_outline : Icons.chevron_right,
                  color: isPaid ? Colors.orange : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
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
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.menu_book, color: AppTheme.primary, size: 32),
    );
  }
}*/



















































/*import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/book.dart';
import '../utils/theme.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover
              _buildCover(),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
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
                    Text(
                      'Price: \$${book.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (book.createdAt != null)
                      Text(
                        'Added: ${book.createdAt!.split('T').first}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
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
  }

  Widget _buildCover() {
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
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.menu_book, color: AppTheme.primary, size: 32),
    );
  }
}*/
