class AppConstants {
  static const String appName = 'Book Exchange';

  // Collection Names
  static const String usersCollection = 'users';
  static const String booksCollection = 'books';
  static const String requestsCollection = 'requests';
  static const String chatsCollection = 'chats';

  // Book Conditions
  static const List<String> conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor'
  ];

  // Exchange Preferences
  static const List<String> exchangePreferences = [
    'Sell',
    'Exchange',
    'Both'
  ];

  // Book Categories
  static const List<String> categories = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Engineering',
    'Business',
    'Economics',
    'Literature',
    'History',
    'Psychology',
    'Other'
  ];

  // Book Status
  static const String statusAvailable = 'Available';
  static const String statusPending = 'Pending';
  static const String statusExchanged = 'Exchanged';
  static const String statusSold = 'Sold';

  // Request Status
  static const String requestPending = 'Pending';
  static const String requestAccepted = 'Accepted';
  static const String requestRejected = 'Rejected';
  static const String requestCancelled = 'Cancelled';
}