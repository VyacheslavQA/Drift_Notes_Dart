// Путь: lib/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? country;
  final String? city;
  final String? experience;
  final List<String> fishingTypes;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.country,
    this.city,
    this.experience,
    this.fishingTypes = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      country: json['country'],
      city: json['city'],
      experience: json['experience'],
      fishingTypes: List<String>.from(json['fishingTypes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'country': country,
      'city': city,
      'experience': experience,
      'fishingTypes': fishingTypes,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? country,
    String? city,
    String? experience,
    List<String>? fishingTypes,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      country: country ?? this.country,
      city: city ?? this.city,
      experience: experience ?? this.experience,
      fishingTypes: fishingTypes ?? this.fishingTypes,
    );
  }
}