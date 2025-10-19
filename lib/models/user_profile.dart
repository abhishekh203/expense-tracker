class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? email;
  final String currency;
  final String language;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? occupation;
  final String? bio;
  final String? website;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.email,
    this.currency = 'NPR',
    this.language = 'en',
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.dateOfBirth,
    this.occupation,
    this.bio,
    this.website,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      currency: json['currency'] as String? ?? 'NPR',
      language: json['language'] as String? ?? 'en',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth'] as String) 
          : null,
      occupation: json['occupation'] as String?,
      bio: json['bio'] as String?,
      website: json['website'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'email': email,
      'currency': currency,
      'language': language,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'occupation': occupation,
      'bio': bio,
      'website': website,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    String? email,
    String? currency,
    String? language,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? occupation,
    String? bio,
    String? website,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      occupation: occupation ?? this.occupation,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, fullName: $fullName, email: $email, currency: $currency, language: $language, firstName: $firstName, lastName: $lastName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.fullName == fullName &&
        other.avatarUrl == avatarUrl &&
        other.email == email &&
        other.currency == currency &&
        other.language == language &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.phoneNumber == phoneNumber &&
        other.dateOfBirth == dateOfBirth &&
        other.occupation == occupation &&
        other.bio == bio &&
        other.website == website &&
        other.location == location;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        fullName.hashCode ^
        avatarUrl.hashCode ^
        email.hashCode ^
        currency.hashCode ^
        language.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        phoneNumber.hashCode ^
        dateOfBirth.hashCode ^
        occupation.hashCode ^
        bio.hashCode ^
        website.hashCode ^
        location.hashCode;
  }
}
