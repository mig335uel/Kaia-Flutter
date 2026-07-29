import 'dart:io';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static const _storage = FlutterSecureStorage();
  
  static Future<String?> requestNotificationPermission() async {
    print("--- Iniciando requestNotificationPermission ---");
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized && 
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      print("Permiso de notificaciones denegado por el usuario.");
      return null;
    }

    try {
      String? token = await messaging.getToken();
      
      print("✅ Token push (FCM) obtenido: $token");
      return token;
    } catch (e) {
      final devToken = "DEV_${Platform.operatingSystem.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}";
      print("⚠️ Token push no disponible. Usando token de desarrollo: $devToken. Error: $e");
      return devToken;
    }
  }

  static Future<void> saveDeviceToken(String userId, String token) async {
    try {
      String? myDeviceIdentifier = await _storage.read(key: 'kaia_device_identifier');
      if (myDeviceIdentifier == null) {
        myDeviceIdentifier = "device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999999)}";
        await _storage.write(key: 'kaia_device_identifier', value: myDeviceIdentifier);
      }

      // Limpieza previa: borramos si existe el token o si este usuario ya tiene este dispositivo
      await Supabase.instance.client
          .from('devices')
          .delete()
          .or('fcm_token.eq."$token",and(user_id.eq."$userId",device_identifier.eq."$myDeviceIdentifier")');

      String deviceName = Platform.operatingSystem; // Al no tener device_info_plus, usamos el SO de base

      final response = await Supabase.instance.client
          .from('devices')
          .insert({
            'user_id': userId,
            'device_identifier': myDeviceIdentifier,
            'device_name': deviceName,
            'platform': Platform.operatingSystem,
            'fcm_token': token,
          })
          .select('id')
          .maybeSingle();

      if (response != null && response['id'] != null) {
        await _storage.write(key: 'kaia_device_db_id', value: response['id'].toString());
        print('✅ Dispositivo registrado en la BD: ${response['id']}');
      }

    } catch (err) {
      print('❌ Error en saveDeviceToken: $err');
    }
  }

  static Future<void> removeDeviceToken() async {
    try {
      final deviceDbId = await _storage.read(key: 'kaia_device_db_id');
      if (deviceDbId != null) {
        await Supabase.instance.client.from('devices').delete().eq('id', deviceDbId);
        await _storage.delete(key: 'kaia_device_db_id');
        print('✅ Dispositivo desregistrado de la BD');
      }
    } catch (err) {
      print('❌ Error en removeDeviceToken: $err');
    }
  }
}
