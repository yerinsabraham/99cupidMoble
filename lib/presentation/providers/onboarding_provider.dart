import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds onboarding data across all three steps
/// Data is collected incrementally and saved only on the final step
class OnboardingData {
  final String? displayName;
  final String? bio;
  final int? age;
  final String? gender;
  final String? location;
  final List<String>? photoUrls;
  final List<String>? interests;

  const OnboardingData({
    this.displayName,
    this.bio,
    this.age,
    this.gender,
    this.location,
    this.photoUrls,
    this.interests,
  });

  OnboardingData copyWith({
    String? displayName,
    String? bio,
    int? age,
    String? gender,
    String? location,
    List<String>? photoUrls,
    List<String>? interests,
  }) {
    return OnboardingData(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
      interests: interests ?? this.interests,
    );
  }

  Map<String, dynamic> toMap(String uid, String email) {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName ?? '',
      'bio': bio ?? '',
      'age': age ?? 0,
      'gender': gender ?? '',
      'location': location ?? '',
      'photos': photoUrls ?? [],
      'photoURL': (photoUrls != null && photoUrls!.isNotEmpty) ? photoUrls![0] : null,
      'interests': interests ?? [],
      'profileSetupComplete': true,
    };
  }
}

class OnboardingNotifier extends Notifier<OnboardingData> {
  @override
  OnboardingData build() => const OnboardingData();

  void setProfileData({
    required String displayName,
    required String bio,
    required int age,
    required String gender,
    required String location,
  }) {
    state = state.copyWith(
      displayName: displayName,
      bio: bio,
      age: age,
      gender: gender,
      location: location,
    );
  }

  void setPhotos(List<String> photoUrls) {
    state = state.copyWith(photoUrls: photoUrls);
  }

  void setInterests(List<String> interests) {
    state = state.copyWith(interests: interests);
  }

  void clear() {
    state = const OnboardingData();
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingData>(() {
  return OnboardingNotifier();
});
