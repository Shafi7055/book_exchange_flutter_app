class UserModel {
  String uid;
  String name;
  String nickname; // Added field
  String email;
  String collegeName;
  String department;
  int semester;
  String phoneNumber;
  String? profileImage;
  DateTime createdAt;
  double rating;
  int totalExchanges;
  String role; // "admin" or "user"
  List<String> friends; // Added field

  UserModel({
    required this.uid,
    required this.name,
    required this.nickname,
    required this.email,
    required this.collegeName,
    required this.department,
    required this.semester,
    required this.phoneNumber,
    this.profileImage,
    required this.createdAt,
    this.rating = 0.0,
    this.totalExchanges = 0,
    this.role = 'user',
    this.friends = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'nickname': nickname,
      'email': email,
      'collegeName': collegeName,
      'department': department,
      'semester': semester,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'createdAt': createdAt,
      'rating': rating,
      'totalExchanges': totalExchanges,
      'role': role,
      'friends': friends,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      nickname: map['nickname'] ?? (map['name'] ?? ''), // Fallback to name
      email: map['email'] ?? '',
      collegeName: map['collegeName'] ?? '',
      department: map['department'] ?? '',
      semester: map['semester'] ?? 1,
      phoneNumber: map['phoneNumber'] ?? '',
      profileImage: map['profileImage'],
      createdAt: (map['createdAt'] as dynamic).toDate(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalExchanges: map['totalExchanges'] ?? 0,
      role: map['role'] ?? 'user',
      friends: List<String>.from(map['friends'] ?? []),
    );
  }
}