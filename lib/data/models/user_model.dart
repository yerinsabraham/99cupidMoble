import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// UserModel - Represents a user in Firestore
/// Mirrors the web app UserModel exactly for data consistency
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final List<String> photos;
  final String bio;
  final int? age;
  final String gender;
  final String location;
  final List<String> interests;
  
  // Profile details
  final String? job;
  final String? education;
  
  // Verification and account status
  final bool isVerifiedAccount;
  final bool isVerified;
  final bool isPhoneVerified;
  final bool isPhotoVerified;
  final bool isIDVerified;
  final bool profileSetupComplete;
  
  // Subscription info
  final bool hasActiveSubscription;
  final String subscriptionStatus;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final String? stripeCustomerId;
  final String? subscriptionId;
  
  // Block and report
  final List<String> blockedUsers;
  final List<String> blockedByUsers;
  final List<String> reportedBy;
  
  // Admin fields
  final bool isAdmin;
  final String accountStatus;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActiveAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoURL,
    this.photos = const [],
    this.bio = '',
    this.age,
    this.gender = '',
    this.location = '',
    this.interests = const [],
    this.job,
    this.education,
    this.isVerifiedAccount = false,
    this.isVerified = false,
    this.isPhoneVerified = false,
    this.isPhotoVerified = false,
    this.isIDVerified = false,
    this.profileSetupComplete = false,
    this.hasActiveSubscription = false,
    this.subscriptionStatus = 'inactive',
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.stripeCustomerId,
    this.subscriptionId,
    this.blockedUsers = const [],
    this.blockedByUsers = const [],
    this.reportedBy = const [],
    this.isAdmin = false,
    this.accountStatus = 'active',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'photos': photos,
      'bio': bio,
      'age': age,
      'gender': gender,
      'location': location,
      'interests': interests,
      'job': job,
      'education': education,
      'isVerifiedAccount': isVerifiedAccount,
      'isVerified': isVerified,
      'isPhoneVerified': isPhoneVerified,
      'isPhotoVerified': isPhotoVerified,
      'isIDVerified': isIDVerified,
      'profileSetupComplete': profileSetupComplete,
      'hasActiveSubscription': hasActiveSubscription,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'stripeCustomerId': stripeCustomerId,
      'subscriptionId': subscriptionId,
      'blockedUsers': blockedUsers,
      'blockedByUsers': blockedByUsers,
      'reportedBy': reportedBy,
      'isAdmin': isAdmin,
      'accountStatus': accountStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(data);
    } catch (e) {
      debugPrint('❌ Error parsing user ${doc.id}: $e');
      debugPrint('Data: ${doc.data()}');
      rethrow;
    }
  }

  /// Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? data['name'] ?? '',
      photoURL: data['photoURL'] is String ? data['photoURL'] : null,
      photos: _parseStringList(data['photos']),
      bio: data['bio'] is String ? data['bio'] : '',
      age: data['age'] is int ? data['age'] : null,
      gender: data['gender'] is String ? data['gender'] : '',
      location: data['location'] is String ? data['location'] : '',
      interests: _parseStringList(data['interests']),
      job: data['job'] is String ? data['job'] : null,
      education: data['education'] is String ? data['education'] : null,
      isVerifiedAccount: data['isVerifiedAccount'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isPhotoVerified: data['isPhotoVerified'] ?? false,
      isIDVerified: data['isIDVerified'] ?? false,
      profileSetupComplete: data['profileSetupComplete'] ?? false,
      hasActiveSubscription: data['hasActiveSubscription'] ?? false,
      subscriptionStatus: data['subscriptionStatus'] ?? 'inactive',
      subscriptionStartDate: data['subscriptionStartDate'] != null
          ? DateTime.parse(data['subscriptionStartDate'])
          : null,
      subscriptionEndDate: data['subscriptionEndDate'] != null
          ? DateTime.parse(data['subscriptionEndDate'])
          : null,
      stripeCustomerId: data['stripeCustomerId'],
      subscriptionId: data['subscriptionId'],
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      blockedByUsers: List<String>.from(data['blockedByUsers'] ?? []),
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
      isAdmin: data['isAdmin'] ?? false,
      accountStatus: data['accountStatus'] ?? 'active',
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']) ?? DateTime.now(),
      lastActiveAt: _parseTimestamp(data['lastActiveAt']) ?? DateTime.now(),
    );
  }

  /// Parse Timestamp or String to DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  /// Safely parse a list of strings from dynamic data
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Create UserModel from Firebase Auth user
  factory UserModel.fromAuthUser(
    String uid,
    String email, {
    String? displayName,
    String? photoURL,
    bool emailVerified = false,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? email.split('@')[0],
      photoURL: photoURL,
      isVerifiedAccount: emailVerified,
      profileSetupComplete: false,
    );
  }

  /// Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    List<String>? photos,
    String? bio,
    int? age,
    String? gender,
    String? location,
    List<String>? interests,
    String? job,
    String? education,
    bool? isVerifiedAccount,
    bool? isVerified,
    bool? isPhoneVerified,
    bool? isPhotoVerified,
    bool? isIDVerified,
    bool? profileSetupComplete,
    bool? hasActiveSubscription,
    String? subscriptionStatus,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    String? stripeCustomerId,
    String? subscriptionId,
    List<String>? blockedUsers,
    List<String>? blockedByUsers,
    List<String>? reportedBy,
    bool? isAdmin,
    String? accountStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      photos: photos ?? this.photos,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      job: job ?? this.job,
      education: education ?? this.education,
      isVerifiedAccount: isVerifiedAccount ?? this.isVerifiedAccount,
      isVerified: isVerified ?? this.isVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isPhotoVerified: isPhotoVerified ?? this.isPhotoVerified,
      isIDVerified: isIDVerified ?? this.isIDVerified,
      profileSetupComplete: profileSetupComplete ?? this.profileSetupComplete,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      blockedByUsers: blockedByUsers ?? this.blockedByUsers,
      reportedBy: reportedBy ?? this.reportedBy,
      isAdmin: isAdmin ?? this.isAdmin,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
