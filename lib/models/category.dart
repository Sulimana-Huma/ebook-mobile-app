class Category {
  final int id;
  final String categoryName;
  final int? parentId;

  Category({
    required this.id,
    required this.categoryName,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      categoryName: json['categoryName'] ?? json['category_name'] ?? '',
      parentId: json['parentId'] ?? json['parent_id'],
    );
  }

  bool get isRoot => parentId == null;
}