import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds onboarding data across all three steps
/// Data is collected incrementally and saved only on the final step
class OnboardingData {
  final String? displayName;
  final String? bio;
  final int? age;
  final String? gender;
  final String? lookingFor;
  final int? ageRangeMin;
  final int? ageRangeMax;
  final String? location;
  final List<String>? photoUrls;
  final List<String>? interests;

  const OnboardingData({
    this.displayName,
    this.bio,
    this.age,
    this.gender,
    this.lookingFor,
    this.ageRangeMin,
    this.ageRangeMax,
    this.location,
    this.photoUrls,
    this.interests,
  });

  OnboardingData copyWith({
    String? displayName,
    String? bio,
    int? age,
    String? gender,
    String? lookingFor,
    int? ageRangeMin,
    int? ageRangeMax,
    String? location,
    List<String>? photoUrls,
    List<String>? interests,
  }) {
    return OnboardingData(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      ageRangeMin: ageRangeMin ?? this.ageRangeMin,
      ageRangeMax: ageRangeMax ?? this.ageRangeMax,
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
      'lookingFor': lookingFor ?? 'everyone',
      'location': location ?? '',
      'photos': photoUrls ?? [],
      'photoURL': (photoUrls != null && photoUrls!.isNotEmpty) ? photoUrls![0] : null,
      'interests': interests ?? [],
      'preferences': {
        'ageRange': {
          'min': ageRangeMin ?? 18,
          'max': ageRangeMax ?? 50,
        },
      },
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
    required String lookingFor,
    required int ageRangeMin,
    required int ageRangeMax,
    required String location,
  }) {
    state = state.copyWith(
      displayName: displayName,
      bio: bio,
      age: age,
      gender: gender,
      lookingFor: lookingFor,
      ageRangeMin: ageRangeMin,
      ageRangeMax: ageRangeMax,
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
