class Book {
  final int bookId;
  final int vendorId;
  final String title;
  final double price;
  final int? categoryId;
  final String filePath;
  final String bookCover;
  final String? createdAt;

  Book({
    required this.bookId,
    required this.vendorId,
    required this.title,
    required this.price,
    this.categoryId,
    required this.filePath,
    required this.bookCover,
    this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookId: json['bookId'] ?? json['book_id'] ?? 0,
      vendorId: json['vendorId'] ?? json['vendor_id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? json['category_id'],
      filePath: json['filePath'] ?? json['bookPath'] ?? '',
      bookCover: json['bookCover'] ?? json['bookCoverPath'] ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}