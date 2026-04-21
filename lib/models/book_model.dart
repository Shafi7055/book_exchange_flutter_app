class BookModel {
  String id;
  String title;
  String author;
  String edition;
  double conditionRating; // Changed from String condition
  String description;
  double price;
  String exchangePreference;
  String? wantedBookTitle;
  List<String> images;
  String sellerId;
  String sellerName;
  double sellerRating;
  String status;
  DateTime createdAt;
  String category;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.edition,
    required this.conditionRating,
    required this.description,
    required this.price,
    required this.exchangePreference,
    this.wantedBookTitle,
    required this.images,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRating,
    required this.status,
    required this.createdAt,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'edition': edition,
      'conditionRating': conditionRating,
      'description': description,
      'price': price,
      'exchangePreference': exchangePreference,
      'wantedBookTitle': wantedBookTitle,
      'images': images,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerRating': sellerRating,
      'status': status,
      'createdAt': createdAt,
      'category': category,
    };
  }

  factory BookModel.fromMap(String id, Map<String, dynamic> map) {
    return BookModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      edition: map['edition'] ?? '',
      conditionRating: (map['conditionRating'] ?? map['condition_rating'] ?? 3.0).toDouble(),
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      exchangePreference: map['exchangePreference'] ?? 'Sell',
      wantedBookTitle: map['wantedBookTitle'],
      images: List<String>.from(map['images'] ?? []),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerRating: (map['sellerRating'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Available',
      createdAt: (map['createdAt'] as dynamic).toDate(),
      category: map['category'] ?? '',
    );
  }
}