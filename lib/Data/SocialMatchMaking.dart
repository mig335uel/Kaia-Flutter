class Socialmatchmaking {
  final String preferences_id;
  final String user_id;
  final DateTime created_at;


  Socialmatchmaking({
    required this.preferences_id,
    required this.user_id,
    required this.created_at,

  });

  factory Socialmatchmaking.fromJson(Map<String, dynamic> json) {
    return Socialmatchmaking(
      preferences_id: json['preferences_id'],
      user_id: json['user_id'],
      created_at: json['created_at'],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferences_id': preferences_id,
      'user_id': user_id,
      'created_at': created_at,

    };
  }
}
