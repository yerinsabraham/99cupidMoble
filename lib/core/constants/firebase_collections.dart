/// Firebase Firestore collection names
/// IMPORTANT: These must match exactly with the web app
class FirebaseCollections {
  static const String users = 'users';
  static const String swipes = 'swipes';
  static const String likes = 'likes';
  static const String matches = 'matches';
  static const String chats = 'chats';
  static const String messages = 'messages';
  static const String reports = 'reports';
  static const String subscriptions = 'subscriptions';
  static const String verifications = 'verifications';
  static const String analytics = 'analytics';
  static const String blockedUsers = 'blockedUsers';
  static const String gameSessions = 'game_sessions';
}

/// Firebase Storage bucket paths
class FirebaseStoragePaths {
  static const String profilePhotos = 'profile-photos';
  static const String verificationPhotos = 'verification-photos';
  static const String chatMedia = 'chat-media';
}
