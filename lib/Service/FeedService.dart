import 'dart:async';
import 'package:kaia/Data/UserPreferences.dart';
import 'package:kaia/Data/Users.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedService {
  Future<List<Users>> getFeedUsers(String id, int limit, int offset) async {
    // 1. Obtenemos lo que el usuario está buscando (ej: edad 18 a 25, género 'female')
    final response = await Supabase.instance.client
        .from('user_preferences')
        .select()
        .eq('user_id', id)
        .single();
    final prefs = Userpreferences.fromJson(response);

    // 2. CONVERSIÓN: De Edades (números) a Fechas de Nacimiento (DateTime)
    // Ejemplo: Si buscamos mínimo 18 años (minDate) y máximo 25 años (maxDate)

    final today = DateTime.now();

    // El límite más joven: Alguien con 18 años nació hace exactamente 18 años.
    // Usaremos esto como fecha tope: tienen que haber nacido ANTES de este día.
    DateTime maxBirthDate = DateTime(
      today.year - prefs.minDate,
      today.month,
      today.day,
    );

    // El límite más viejo: Alguien con 25 años nació hace 25 años.
    // Le restamos 1 año extra para que incluya a los que tienen 25 y 11 meses.
    // Usaremos esto como fecha base: tienen que haber nacido DESPUÉS de este día.
    DateTime minBirthDate = DateTime(
      today.year - (prefs.maxDate + 1),
      today.month,
      today.day + 1,
    );

    // 3. Consulta a Supabase
    List<Map<String, dynamic>> feedData = [];
    switch (prefs.genderFeed) {
      case 'All':
        feedData = await Supabase.instance.client
            .from('users')
            .select('*')
            .neq('id', id) // No me incluyas a mí en mi propio feed
            .gte(
              'birth_date',
              minBirthDate.toIso8601String().split('T')[0],
            ) // Nació después del límite viejo
            .lte(
              'birth_date',
              maxBirthDate.toIso8601String().split('T')[0],
            )
            .order('id') // Ordenar por ID para evitar agrupación por género
            .range(offset, offset + limit);

        break;
      case 'Male':
        feedData = await Supabase.instance.client
            .from('users')
            .select('*')
            .eq('gender', 'Male')
            .neq('id', id) // No me incluyas a mí en mi propio feed
            .gte(
              'birth_date',
              minBirthDate.toIso8601String().split('T')[0],
            ) // Nació después del límite viejo
            .lte(
              'birth_date',
              maxBirthDate.toIso8601String().split('T')[0],
            )
            .range(offset, offset + limit); // Nació antes del límite joven
            break;
      case 'Female':
        feedData = await Supabase.instance.client
            .from('users')
            .select('*')
            .eq('gender', 'Female')
            .neq('id',id) // No me incluyas a mí en mi propio feed
            .gte(
              'birth_date',
              minBirthDate.toIso8601String().split('T')[0],
            ) // Nació después del límite viejo
            .lte(
              'birth_date',
              maxBirthDate.toIso8601String().split('T')[0],
            )
            .range(offset, offset + limit);
            break;
      default:
        feedData = [];
        break;
    }
    // 4. Filtrar por género si ha elegido algo concreto

    // Ejecutamos la consulta limitando a 30 perfiles por ahora
    // Convertimos la respuesta de base de datos a lista de Objetos Users
    List<Users> users = feedData.map((json) => Users.fromJson(json)).toList();
    return users;
  }
}
