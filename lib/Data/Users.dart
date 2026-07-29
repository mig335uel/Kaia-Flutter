import 'dart:io';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

class Users {
  final String id;
  final String name;
  final String last_name;
  final String username;
  final DateTime? birth_date;
  final DateTime? created_at;
  final String? profile_image;
  final String? country;
  final String gender;
  final String? city;
  final String? description;

  Users({
    required this.id,
    required this.name,
    required this.last_name,
    required this.username,
    this.birth_date,
    this.created_at,
    this.profile_image,
    this.country,
    required this.gender,
    this.city,
    this.description,
  });

  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      id: json['id'],
      username: json['username'],
      name: json['name'],
      last_name: json['last_name'],
      birth_date: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
      created_at: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      profile_image: json['profile_image'],
      country: json['country'],
      gender: json['gender'],
      city: json['city'],
      description: json['description'],
    );
  }

  // Utilidad para mapear texto traducido a valor de base de datos
  static String mapGenderToDb(String localizedGender) {
    if (localizedGender == 'male'.tr()) return 'male';
    if (localizedGender == 'female'.tr()) return 'female';
    return 'other';
  }

  // Utilidad para mapear valor de base de datos a texto traducido
  static String mapDbGenderToLocalized(String dbGender) {
    if (dbGender == 'male') return 'male'.tr();
    if (dbGender == 'female') return 'female'.tr();
    return 'other'.tr();
  }

  // Utilidad para obtener el país físico directamente mediante la IP
  static Future<String> getDeviceCountry() async {
    try {
      // Usamos una API gratuita sobre HTTPS para obtener el código de país real (ej: 'ES', 'GB')
      final request = await HttpClient().getUrl(Uri.parse('https://api.country.is/'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        final data = jsonDecode(stringData);
        if (data['country'] != null) {
          return data['country'];
        }
      }
    } catch (e) {
      // Fallback por si no hay conexión
    }

    // Fallback: intentar sacarlo del idioma del móvil
    try {
      final localeName = Platform.localeName; // Ej: 'es_ES'
      if (localeName.contains('_')) {
        return localeName.split('_').last;
      }
      return localeName;
    } catch (e) {
      return 'Unknown';
    }
  }
}

class RegisterForm {
  final String email;
  final String password;
  final String name;
  final String last_name;
  final String username;
  final DateTime birth_date;
  final String gender;


  // Constructor con nombre para crear un formulario vacío
  RegisterForm.empty()
      : email = '',
        password = '',
        name = '',
        last_name = '',
        username = '',
        birth_date = DateTime(2000, 1, 1),
        gender = '';

  // Constructor principal
  RegisterForm({
    required this.email,
    required this.password,
    required this.name,
    required this.last_name,
    required this.username,
    required this.birth_date,
    required this.gender,
  });
}

class CompleteRegisterUseroAuth {
  final String name;
  final String last_name;
  final String username;
  final DateTime birth_date;
  final String gender;

  CompleteRegisterUseroAuth({
    required this.name,
    required this.last_name,
    required this.username,
    required this.birth_date,
    required this.gender,
  });

  factory CompleteRegisterUseroAuth.fromJson(Map<String, dynamic> json) {
    return CompleteRegisterUseroAuth(
      name: json['name'],
      last_name: json['last_name'],
      username: json['username'],
      birth_date: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : DateTime.now(),
      gender: json['gender'],
    );
  }
}