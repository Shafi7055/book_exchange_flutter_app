class RequestModel {
  String id;
  String bookId;
  String requesterId;
  String sellerId;
  String? message;
  String? offeredBookId;
  String status;
  DateTime createdAt;
  DateTime? respondedAt;

  RequestModel({
    required this.id,
    required this.bookId,
    required this.requesterId,
    required this.sellerId,
    this.message,
    this.offeredBookId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'requesterId': requesterId,
      'sellerId': sellerId,
      'message': message,
      'offeredBookId': offeredBookId,
      'status': status,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }

  factory RequestModel.fromMap(String id, Map<String, dynamic> map) {
    return RequestModel(
      id: id,
      bookId: map['bookId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      message: map['message'],
      offeredBookId: map['offeredBookId'],
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as dynamic).toDate(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as dynamic).toDate()
          : null,
    );
  }
}