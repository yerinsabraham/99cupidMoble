import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds onboarding data across all four steps
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
  // Disability / inclusive dating fields
  final bool? hasDisability;
  final List<String>? disabilityTypes;
  final String? disabilityDescription;
  final String? disabilityVisibility;
  final String? disabilityPreference;
  final bool? showBadgeOnProfile;

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
    this.hasDisability,
    this.disabilityTypes,
    this.disabilityDescription,
    this.disabilityVisibility,
    this.disabilityPreference,
    this.showBadgeOnProfile,
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
    bool? hasDisability,
    List<String>? disabilityTypes,
    String? disabilityDescription,
    String? disabilityVisibility,
    String? disabilityPreference,
    bool? showBadgeOnProfile,
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
      hasDisability: hasDisability ?? this.hasDisability,
      disabilityTypes: disabilityTypes ?? this.disabilityTypes,
      disabilityDescription: disabilityDescription ?? this.disabilityDescription,
      disabilityVisibility: disabilityVisibility ?? this.disabilityVisibility,
      disabilityPreference: disabilityPreference ?? this.disabilityPreference,
      showBadgeOnProfile: showBadgeOnProfile ?? this.showBadgeOnProfile,
    );
  }

  Map<String, dynamic> toMap(String uid, String email) {
    final map = <String, dynamic>{
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

    // Include disability data if the user opted in
    if (hasDisability == true) {
      map['hasDisability'] = true;
      map['disabilityTypes'] = disabilityTypes ?? [];
      map['disabilityDescription'] = disabilityDescription ?? '';
      map['disabilityVisibility'] = disabilityVisibility ?? 'matches_only';
      map['disabilityPreference'] = disabilityPreference ?? 'open_to_all';
      map['showBadgeOnProfile'] = showBadgeOnProfile ?? false;
    } else {
      map['hasDisability'] = false;
    }

    return map;
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

  void setDisabilityData({
    required bool hasDisability,
    List<String>? disabilityTypes,
    String? disabilityDescription,
    String? disabilityVisibility,
    String? disabilityPreference,
    bool? showBadgeOnProfile,
  }) {
    state = state.copyWith(
      hasDisability: hasDisability,
      disabilityTypes: disabilityTypes ?? [],
      disabilityDescription: disabilityDescription ?? '',
      disabilityVisibility: disabilityVisibility ?? 'matches_only',
      disabilityPreference: disabilityPreference ?? 'open_to_all',
      showBadgeOnProfile: showBadgeOnProfile ?? false,
    );
  }

  void clear() {
    state = const OnboardingData();
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingData>(() {
  return OnboardingNotifier();
});
