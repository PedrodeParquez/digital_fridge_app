class UserProfile {
  final String id;
  final String name;
  final String email;
  final int? age;
  final double? weight;
  final double? height;
  final String? gender;
  final String? activityLevel;
  final String? goal;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.activityLevel,
    this.goal,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'].toString(),
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    age: json['age'] as int?,
    weight: (json['weight'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    gender: json['gender'] as String?,
    activityLevel: json['activity_level'] as String?,
    goal: json['goal'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'weight': weight,
    'height': height,
    'gender': gender,
    'activity_level': activityLevel,
    'goal': goal,
  };

  UserProfile copyWith({
    String? name,
    int? age,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    String? goal,
  }) => UserProfile(
    id: id,
    email: email,
    name: name ?? this.name,
    age: age ?? this.age,
    weight: weight ?? this.weight,
    height: height ?? this.height,
    gender: gender ?? this.gender,
    activityLevel: activityLevel ?? this.activityLevel,
    goal: goal ?? this.goal,
  );
}
