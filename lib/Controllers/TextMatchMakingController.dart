import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:kaia/Service/TextMatchMakingService.dart';
import 'package:kaia/UI/SocialMode/ChatScreen.dart' as kaia_chat;

class TextMatchmakingcontroller {
  final TextMatchMakingService _service = TextMatchMakingService();

  // Función para cancelar la búsqueda cuando el usuario se sale o le da al botón
  void cancelarBusqueda() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _service.cancelarBusqueda(currentUser.id);
      print('Búsqueda cancelada para el usuario ${currentUser.id}');
    }
  }

  // Iniciar la búsqueda desde la UI
  Future<void> iniciarBusqueda(dynamic context) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // 1. Obtener las preferencias
      final prefResponse = await Supabase.instance.client
          .from('user_preferences')
          .select('*')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (prefResponse == null) {
        print("Error: El usuario no tiene preferencias creadas.");
        return;
      }

      // 2. Obtener datos del usuario (género y fecha de nacimiento)
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('gender, birth_date')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        print("Error: No se encontraron datos del usuario.");
        return;
      }

      // Calcular edad aproximada
      final birthDate = DateTime.parse(userResponse['birth_date']);
      final myAge = DateTime.now().year - birthDate.year;

      await _service.buscarChat(
        miUserId: currentUser.id,
        miPreferenceId: prefResponse['id'],
        myGender: userResponse['gender'],
        myPrefGender: prefResponse['genderFeed'],
        myAge: myAge,
        myMinAge: prefResponse['min_age_range'],
        myMaxAge: prefResponse['max_age_range'],
        onMatchFound: (chatId) {
          // ¡ESTE CÓDIGO SE EJECUTA CUANDO HAY UN MATCH!
          print("¡Match encontrado! El ID de la sala es: $chatId");

          // AQUI NAVEGAS A TU PANTALLA DE CHAT
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => kaia_chat.ChatScreen(chatId: chatId),
            ),
          );
        },
      );
    } catch (e) {
      print("Error obteniendo datos para el match: $e");
    }
  }
}
