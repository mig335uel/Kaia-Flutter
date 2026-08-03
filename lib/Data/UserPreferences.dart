



class Userpreferences {
  final String id;
  final String user_id;
  final int minDate;
  final int maxDate;
  final String genderFeed;

  Userpreferences({
    required this.id,
    required this.user_id,
    required this.maxDate,
    required this.minDate,
    required this.genderFeed,
  });

  factory Userpreferences.fromJson(Map<String, dynamic> json) {
    return Userpreferences(
      id: json['id'],
      user_id: json['user_id'],
      maxDate: json['max_age_range'],
      minDate: json['min_age_range'],
      genderFeed: json['genderFeed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': user_id,
      'max_age_range': maxDate,
      'min_age_range': minDate,
      'genderFeed': genderFeed,
    };
  }
}